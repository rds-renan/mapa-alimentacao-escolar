import type { Json } from '@/lib/database.types'
import { supabase } from '@/lib/supabase'

import { adoptServerIds, type DayPayload, type SaveResponse } from './day'
import { SYNC_MESSAGES, conflictMessage, type SyncStatus } from './messages'
import {
  dayKey,
  getStoredDay,
  listStoredDays,
  markStoredDay,
  putStoredDay,
  settleStoredDay,
  type Rejection,
  type StoredDay,
} from './store'

/*
 * A fila de envio.
 *
 * Ela existe porque a gravação e o envio são dois tempos diferentes: a tecla é
 * agora, a internet é quando der. Cada alteração de campo vira rascunho no
 * aparelho **imediatamente**, e o envio é uma tentativa que se repete sozinha
 * até o servidor confirmar (decisão 3 da E5).
 *
 * A unidade é o dia inteiro, como a decisão 9 da E4 definiu, e é isso que torna
 * a fila idempotente: reenviar é reescrever o mesmo dia, com o mesmo carimbo de
 * edição, e dá o mesmo dia. Quando a rede cai entre a gravação e a confirmação,
 * o aparelho reenvia sem saber se chegou, e o servidor não duplica nada.
 */

/*
 * A espera entre a última tecla e o envio. Não é para poupar o servidor: é para
 * não mandar o dia inteiro a cada letra digitada na descrição da refeição. O
 * rascunho, esse, já foi escrito antes da espera começar.
 */
const SEND_DELAY = 1_200

/** A espera antes de tentar de novo, dobrando a cada falha, com teto de um minuto. */
function retryDelay(attempts: number): number {
  return Math.min(2_000 * 2 ** Math.max(0, attempts - 1), 60_000)
}

export interface DaySyncState {
  status: SyncStatus
  /** O texto da faixa, dos três da E3. */
  message: string
  /** A frase do servidor, quando a recusa tem explicação própria. */
  detail: string | null
}

export interface Conflict {
  mapDate: string
  message: string
  /** O carimbo que passou a valer no servidor. */
  updatedAt: string
}

export interface SyncState {
  /** O estado de cada dia que esta sessão conhece, pela data. */
  days: Record<string, DaySyncState>
  /** Quantos dias estão guardados no aparelho, ainda não confirmados. */
  pending: number
  /** A fila está tentando enviar agora. */
  sending: boolean
  /** Um por dia, e nenhum some sem a usuária ver. */
  conflicts: Conflict[]
}

export const EMPTY_SYNC_STATE: SyncState = {
  days: {},
  pending: 0,
  sending: false,
  conflicts: [],
}

export interface SyncEngine {
  start(): void
  stop(): void
  getState(): SyncState
  subscribe(listener: () => void): () => void
  /** Grava o dia no aparelho e agenda o envio. É o autosave. */
  save(day: DayPayload): Promise<void>
  /** O rascunho local do dia, ou nulo quando ele já está confirmado. */
  load(mapDate: string): Promise<DayPayload | null>
  /**
   * Quantos dias estão guardados agora, perguntando ao disco.
   *
   * `state.pending` responde o mesmo e serve para desenhar tela, mas ele só
   * fica quente depois que a fila termina de contar o disco no arranque. Quem
   * vai **decidir** com esse número — como o botão de sair, que apaga tudo —
   * pergunta aqui.
   */
  pendingCount(): Promise<number>
  /**
   * Os dias guardados no aparelho cuja data cai dentro do prefixo — `2026-09`
   * para um mês inteiro. A visão do mês precisa deles porque um dia por enviar
   * é um dia que já está preenchido: sem isto, ele apareceria vazio na lista
   * que ela usa justamente para saber o que falta.
   */
  pendingDays(prefix: string): Promise<DayPayload[]>
  /** Tenta enviar tudo o que está na fila, agora. */
  flush(): Promise<void>
  dismissConflict(mapDate: string): void
}

function stateFor(record: StoredDay): DaySyncState {
  if (record.rejection) {
    return {
      status: 'failed',
      message: SYNC_MESSAGES.failed,
      detail: record.rejection.message,
    }
  }

  /*
   * Falhou tentando, mas é falha que passa: a fila continua insistindo. Só a
   * partir da primeira tentativa frustrada a faixa muda de tom — antes dela o
   * estado honesto é "salvo no aparelho", que é o que de fato aconteceu.
   */
  const status: SyncStatus = record.attempts > 0 ? 'failed' : 'pending'

  return {
    status,
    message: SYNC_MESSAGES[status],
    detail: null,
  }
}

const SENT: DaySyncState = {
  status: 'sent',
  message: SYNC_MESSAGES.sent,
  detail: null,
}

/*
 * A distinção que decide tudo na fila: **o que se resolve reenviando e o que
 * não se resolve**. A tabela de erros da gravação do dia é a fonte.
 */
function classify(code: string | undefined): 'retry' | 'rejected' {
  switch (code) {
    // Payload incoerente ou mapa bloqueado; e perfil sem permissão de registrar.
    // Reenviar daria exatamente o mesmo erro.
    case '23514':
    case '42501':
      return 'rejected'

    // Dois aparelhos criando o mesmo dia no mesmo instante. Na segunda vez o
    // dia já existe e vale a comparação de datas.
    case '40001':
      return 'retry'

    // Sem código é falha de rede, que é o caso comum aqui e sempre se reenvia.
    default:
      return 'retry'
  }
}

export function createSyncEngine(userId: string): SyncEngine {
  let state: SyncState = EMPTY_SYNC_STATE
  const listeners = new Set<() => void>()

  let started = false
  let sendTimer: ReturnType<typeof setTimeout> | null = null
  let running: Promise<void> | null = null
  let rerun = false

  function emit() {
    for (const listener of listeners) listener()
  }

  function patch(next: Partial<SyncState>) {
    state = { ...state, ...next }
    emit()
  }

  function setDay(mapDate: string, day: DaySyncState) {
    patch({ days: { ...state.days, [mapDate]: day } })
  }

  async function refreshPending() {
    const records = await listStoredDays(userId)
    const days = { ...state.days }
    for (const record of records) days[record.mapDate] = stateFor(record)
    patch({ days, pending: records.length })
  }

  function scheduleFlush(delay: number) {
    if (!started) return
    if (sendTimer) clearTimeout(sendTimer)
    sendTimer = setTimeout(() => {
      sendTimer = null
      void flush()
    }, delay)
  }

  /**
   * Manda um dia e decide o que fazer com a resposta. `again` é o caso em que
   * ela continuou digitando enquanto aquilo subia: o dia continua na fila, e o
   * que sobe na volta seguinte já é o texto novo.
   */
  async function send(record: StoredDay): Promise<'ok' | 'retry' | 'again'> {
    const sentUpdatedAt = record.day.updated_at

    const { data, error } = await supabase.rpc('save_meal_map', {
      payload: record.day as unknown as Json,
    })

    if (error) {
      if (classify(error.code) === 'retry') {
        await markStoredDay(record.key, { bumpAttempts: true })
        return 'retry'
      }

      /*
       * Recusa que não passa. O item sai da fila — insistir daria o mesmo erro
       * —, **mas o dia continua guardado no aparelho**: jogá-lo fora seria
       * perder o que ela digitou, que é exatamente o que a RN#1 da US011
       * proíbe. Ele volta a ser enviado quando ela corrigir e o rascunho for
       * escrito de novo.
       */
      const rejection: Rejection = {
        code: error.code ?? '',
        message: error.message,
      }

      await markStoredDay(record.key, { attempts: 0, rejection })
      setDay(record.mapDate, stateFor({ ...record, attempts: 0, rejection }))
      return 'ok'
    }

    const response = data as unknown as SaveResponse

    if (response.status === 'superseded') {
      /*
       * O servidor tem edição mais recente e nada foi gravado. Prevalece a mais
       * recente, por decisão, e o caso é **sinalizado** — o rascunho local sai
       * do aparelho e a tela recarrega o dia do servidor, mas não em silêncio
       * (decisão 5 da E5, CA#3 da US011).
       */
      /*
       * A saída do aparelho é a mesma comparação atômica do caminho do
       * sucesso: se ela digitou de novo enquanto isto subia, o que está aqui é
       * mais novo que a edição do outro aparelho e ainda tem de subir — quem
       * some é só o que perdeu a convergência.
       */
      const settled = await settleStoredDay(record.key, sentUpdatedAt, (day) =>
        adoptServerIds(day, response)
      )

      if (settled !== 'kept') setDay(record.mapDate, SENT)

      patch({
        conflicts: [
          ...state.conflicts.filter((one) => one.mapDate !== record.mapDate),
          {
            mapDate: record.mapDate,
            message: conflictMessage(record.mapDate),
            updatedAt: response.updated_at,
          },
        ],
      })

      return settled === 'kept' ? 'again' : 'ok'
    }

    /*
     * Gravou. Antes de sair da fila, o dia adota o identificador do mapa e os
     * dos gêneros que o servidor devolveu — são eles que fazem o próximo envio
     * encontrar o registro em vez de tentar criá-lo de novo.
     *
     * A comparação com o carimbo enviado e a saída da fila acontecem na mesma
     * transação: entre uma e outra cabe a tecla seguinte, e apagar aí seria
     * descartar o que ela acabou de digitar.
     */
    const outcome = await settleStoredDay(record.key, sentUpdatedAt, (day) =>
      adoptServerIds(day, response)
    )

    if (outcome !== 'kept') setDay(record.mapDate, SENT)

    return outcome === 'kept' ? 'again' : 'ok'
  }

  async function drain(): Promise<void> {
    do {
      rerun = false

      const records = await listStoredDays(userId)
      const queue = records.filter((record) => !record.rejection)

      patch({ pending: records.length, sending: queue.length > 0 })

      if (queue.length === 0) {
        patch({ sending: false })
        return
      }

      /*
       * Sem rede não se tenta. A tentativa falharia do mesmo jeito, e a faixa
       * passaria a dizer "ainda não deu para enviar" quando a verdade é a outra
       * frase, a que a E3 escreveu para este caso: "salvo no aparelho, envia
       * sozinho quando houver internet".
       */
      if (typeof navigator !== 'undefined' && navigator.onLine === false) {
        patch({ sending: false })
        return
      }

      let worstAttempts = 0
      let again = false

      for (const record of queue) {
        let outcome: 'ok' | 'retry' | 'again'
        try {
          outcome = await send(record)
        } catch {
          // Erro que nem chegou a virar resposta — rede caindo no meio.
          await markStoredDay(record.key, { bumpAttempts: true })
          outcome = 'retry'
        }

        if (outcome === 'retry') {
          worstAttempts = Math.max(worstAttempts, record.attempts + 1)
        }

        if (outcome === 'again') again = true
      }

      await refreshPending()
      patch({ sending: false })

      if (worstAttempts > 0) scheduleFlush(retryDelay(worstAttempts))
      // Sobrou texto novo que chegou durante o envio: sobe já, sem esperar.
      else if (again) scheduleFlush(SEND_DELAY)
    } while (rerun)
  }

  async function flush(): Promise<void> {
    if (running) {
      rerun = true
      return running
    }

    running = drain().finally(() => {
      running = null
    })

    return running
  }

  /** A rede voltou: é a hora de tentar, sem a usuária pedir (CA#1 da US011). */
  const onOnline = () => {
    void flush()
  }

  const onVisible = () => {
    if (document.visibilityState === 'visible') void flush()
  }

  return {
    start() {
      if (started) return
      started = true

      window.addEventListener('online', onOnline)
      document.addEventListener('visibilitychange', onVisible)

      // Reabrir o navegador no meio do preenchimento não perde nada (CA#3 da
      // US010): o que estava na fila é lido do aparelho e volta a subir.
      void refreshPending().then(() => flush())
    },

    stop() {
      started = false
      if (sendTimer) clearTimeout(sendTimer)
      sendTimer = null
      window.removeEventListener('online', onOnline)
      document.removeEventListener('visibilitychange', onVisible)
    },

    getState: () => state,

    subscribe(listener) {
      listeners.add(listener)
      return () => {
        listeners.delete(listener)
      }
    },

    async save(day) {
      const existing = await getStoredDay(userId, day.map_date)

      await putStoredDay({
        key: dayKey(userId, day.map_date),
        userId,
        mapDate: day.map_date,
        day,
        // Ela mexeu de novo: o que fez a recusa da vez passada pode ter sido
        // corrigido agora, e a fila volta a tentar.
        attempts: 0,
        rejection: null,
        queuedAt: existing?.queuedAt ?? new Date().toISOString(),
      })

      setDay(day.map_date, {
        status: 'pending',
        message: SYNC_MESSAGES.pending,
        detail: null,
      })

      await refreshPending()
      scheduleFlush(SEND_DELAY)
    },

    async load(mapDate) {
      const record = await getStoredDay(userId, mapDate)
      return record?.day ?? null
    },

    async pendingCount() {
      return (await listStoredDays(userId)).length
    },

    async pendingDays(prefix) {
      const records = await listStoredDays(userId)
      return records
        .filter((record) => record.mapDate.startsWith(prefix))
        .map((record) => record.day)
    },

    flush,

    dismissConflict(mapDate) {
      patch({
        conflicts: state.conflicts.filter((one) => one.mapDate !== mapDate),
      })
    },
  }
}
