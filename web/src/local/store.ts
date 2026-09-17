import type { DayPayload } from './day'

/*
 * O armazenamento local: um banco IndexedDB com um único depósito, o dos dias
 * que ainda não estão confirmados no servidor.
 *
 * É um depósito só de propósito. O rascunho e a fila de envio seriam duas
 * coisas se o rascunho sobrevivesse ao envio — e ele não sobrevive: **existir
 * aqui é ser dado que o servidor ainda não confirmou** (RN#1 da US011).
 * Confirmado, o dia sai daqui e passa a ser lido do servidor, que é a fronteira
 * da decisão 4 da E5. Dois depósitos guardariam o mesmo dia duas vezes e
 * abririam a pergunta de qual dos dois está certo.
 *
 * IndexedDB e não `localStorage` porque o objeto é o dia inteiro, com listas
 * dentro, e porque escrever de forma síncrona a cada tecla, na thread que
 * desenha a tela, é como se fabrica travamento (decisão 3 da E5).
 */

/*
 * O nome é conhecido fora daqui: quem apaga o aparelho ao sair da conta precisa
 * saber qual banco é o nosso para NÃO apagá-lo.
 */
export const LOCAL_DATABASE_NAME = 'mae.local'
const VERSION = 1
const DAY_STORE = 'day'
const BY_USER = 'by_user'

/** Por que um dia parou de ser reenviado. */
export interface Rejection {
  /** O SQLSTATE que veio do servidor, para o teste e o relato dizerem qual foi. */
  code: string
  /** A frase do servidor, que já vem legível para quem vai lê-la. */
  message: string
}

/**
 * Um dia guardado no aparelho. Está aqui porque ainda não subiu — ou porque
 * subiu e voltou recusado, e jogá-lo fora seria perder o que ela digitou.
 */
export interface StoredDay {
  /** `userId|mapDate`: o dia é de quem o preencheu. */
  key: string
  userId: string
  mapDate: string
  day: DayPayload
  /** Tentativas de envio seguidas sem sucesso. Comanda a espera até a próxima. */
  attempts: number
  /** Recusa que não se resolve reenviando. Enquanto existir, a fila não insiste. */
  rejection: Rejection | null
  /** Quando entrou na fila. É a ordem de envio. */
  queuedAt: string
}

export function dayKey(userId: string, mapDate: string): string {
  return `${userId}|${mapDate}`
}

let connection: Promise<IDBDatabase> | null = null

function openDatabase(): Promise<IDBDatabase> {
  connection ??= new Promise<IDBDatabase>((resolve, reject) => {
    const request = indexedDB.open(LOCAL_DATABASE_NAME, VERSION)

    request.onupgradeneeded = () => {
      const database = request.result
      if (!database.objectStoreNames.contains(DAY_STORE)) {
        const store = database.createObjectStore(DAY_STORE, { keyPath: 'key' })
        // As duas merendeiras se revezam no mesmo aparelho: todo percurso da
        // fila é por usuária, nunca pelo depósito inteiro.
        store.createIndex(BY_USER, 'userId', { unique: false })
      }
    }

    request.onsuccess = () => resolve(request.result)
    request.onerror = () => reject(request.error ?? new Error('IndexedDB'))
  })

  return connection
}

/**
 * Fecha a conexão, e devolve quando ela estiver fechada de fato.
 *
 * Quem sai da conta precisa esperar por isto: `deleteDatabase` com uma conexão
 * aberta não apaga nada — dispara `onblocked` e fica esperando. Era assim que o
 * apagamento da saída falharia em silêncio.
 */
export async function closeLocalDatabase(): Promise<void> {
  const opening = connection
  connection = null
  if (!opening) return

  try {
    ;(await opening).close()
  } catch {
    // Conexão que nunca chegou a abrir não tem o que fechar.
  }
}

async function run<T>(
  mode: IDBTransactionMode,
  work: (store: IDBObjectStore) => IDBRequest<T>
): Promise<T> {
  const database = await openDatabase()

  return new Promise<T>((resolve, reject) => {
    const transaction = database.transaction(DAY_STORE, mode)
    const request = work(transaction.objectStore(DAY_STORE))

    request.onsuccess = () => resolve(request.result)
    request.onerror = () => reject(request.error ?? new Error('IndexedDB'))
  })
}

export function putStoredDay(record: StoredDay): Promise<unknown> {
  return run('readwrite', (store) => store.put(record))
}

export async function getStoredDay(
  userId: string,
  mapDate: string
): Promise<StoredDay | null> {
  const record = await run<StoredDay | undefined>('readonly', (store) =>
    store.get(dayKey(userId, mapDate))
  )

  return record ?? null
}

/** Os dias por enviar de quem está logada, na ordem em que entraram na fila. */
export async function listStoredDays(userId: string): Promise<StoredDay[]> {
  const records = await run<StoredDay[]>('readonly', (store) =>
    store.index(BY_USER).getAll(userId)
  )

  return records.sort((a, b) => a.queuedAt.localeCompare(b.queuedAt))
}

export function deleteStoredDay(key: string): Promise<unknown> {
  return run('readwrite', (store) => store.delete(key))
}

/*
 * Ler e escrever o mesmo dia numa transação só.
 *
 * Fazer isto em duas idas ao banco abriria uma janela entre a leitura e a
 * escrita, e é uma janela por onde some preenchimento: entre uma e outra cabe
 * a tecla seguinte, e a escrita de volta devolveria o dia antigo por cima do
 * novo. Numa transação só, o que a mão de fora escreveu ou já está aqui dentro,
 * ou acontece depois — nunca no meio.
 */
function change(
  key: string,
  decide: (record: StoredDay, store: IDBObjectStore) => Outcome
): Promise<Outcome> {
  return openDatabase().then(
    (database) =>
      new Promise<Outcome>((resolve, reject) => {
        const transaction = database.transaction(DAY_STORE, 'readwrite')
        const store = transaction.objectStore(DAY_STORE)
        const request = store.get(key)
        let outcome: Outcome = 'gone'

        request.onsuccess = () => {
          const record = request.result as StoredDay | undefined
          if (record) outcome = decide(record, store)
        }

        transaction.oncomplete = () => resolve(outcome)
        const fail = () => reject(transaction.error ?? new Error('IndexedDB'))
        transaction.onerror = fail
        transaction.onabort = fail
      })
  )
}

/** O que aconteceu com o dia depois de o servidor responder. */
export type Outcome = 'removed' | 'kept' | 'gone'

/**
 * O servidor confirmou. O dia sai do aparelho — **a não ser** que ela tenha
 * continuado digitando enquanto aquilo subia: nesse caso o que está aqui já é
 * mais novo que o confirmado, e fica na fila, com os identificadores que o
 * servidor devolveu já adotados.
 */
export function settleStoredDay(
  key: string,
  sentUpdatedAt: string,
  adopt: (day: DayPayload) => DayPayload
): Promise<Outcome> {
  return change(key, (record, store) => {
    if (record.day.updated_at === sentUpdatedAt) {
      store.delete(key)
      return 'removed'
    }

    store.put({
      ...record,
      day: adopt(record.day),
      attempts: 0,
      rejection: null,
    })
    return 'kept'
  })
}

/**
 * Marca o desfecho da tentativa sem tocar no dia. O que ela digitou enquanto o
 * envio estava no ar continua sendo o que está guardado.
 */
export function markStoredDay(
  key: string,
  marks: {
    attempts?: number
    bumpAttempts?: boolean
    rejection?: Rejection | null
  }
): Promise<Outcome> {
  return change(key, (record, store) => {
    store.put({
      ...record,
      attempts: marks.bumpAttempts
        ? record.attempts + 1
        : (marks.attempts ?? record.attempts),
      rejection:
        marks.rejection === undefined ? record.rejection : marks.rejection,
    })
    return 'kept'
  })
}
