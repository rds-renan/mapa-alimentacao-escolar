import { vi } from 'vitest'

import type { Session } from '@supabase/supabase-js'

import type { Profile } from '@/auth/auth-context'

/*
 * O Supabase de mentira dos testes. Imita só o que as telas usam: a inscrição
 * em mudanças de sessão — que entrega a sessão guardada no aparelho logo ao se
 * inscrever, como a biblioteca de verdade faz —, o login, a saída, o pedido de
 * senha nova, a leitura do perfil e a consulta dos mapas de um mês.
 */

/** Uma linha de `food_item`: o catálogo da escola, como a folha 3b o lê. */
export interface FoodItemRow {
  id: string
  name: string
  default_unit: string
  /** Ausente é ativo: a folha 3b só recebe ativos, e não pergunta por isto. */
  active?: boolean
}

/** Um gênero usado, do jeito que a leitura do dia o traz do banco. */
export interface UsedFoodItemRow {
  food_item_id: string
  name: string
  default_unit: string
  quantity: number
}

/**
 * Uma linha de `generated_document`, como a lista de documentos a pede. As
 * datas viram a ligação `document_meal_map`, que é de onde a tela deriva o
 * período e a quantidade de mapas.
 */
export interface GeneratedDocumentRow {
  id: string
  status: 'processing' | 'available' | 'failed'
  requested_at: string
  completed_at?: string | null
  expires_at?: string | null
  file_path?: string | null
  file_name?: string | null
  dates: string[]
}

function documentRow(row: GeneratedDocumentRow) {
  return {
    id: row.id,
    status: row.status,
    requested_at: row.requested_at,
    completed_at: row.completed_at ?? null,
    expires_at: row.expires_at ?? null,
    file_path: row.file_path ?? null,
    file_name: row.file_name ?? null,
    document_meal_map: row.dates.map((map_date) => ({
      meal_map: { map_date },
    })),
  }
}

/**
 * Uma linha de `profile` como a gestão de acessos a lê (issue #68). O papel
 * não entra: a lista pede `role = 'cook'`, e o mock só guarda merendeiras.
 */
export interface CookRow {
  id: string
  name: string
  email: string
  active: boolean
  last_access: string | null
}

/**
 * Uma linha de `meal_map_unlock` como a tela Mapas a lê (issue #69). O nome de
 * quem reabriu entra direto: no banco ele vem do vínculo com `profile`, e é isso
 * que o mock monta na leitura.
 */
export interface MapUnlockRow {
  id: string
  map_date: string
  unlocked_at: string
  unlocked_by: string
  reason: string
}

/** A escola, como o cartão de dados institucionais a lê. */
export interface SchoolRow {
  id: string
  name: string
  city: string
  school_year: number
}

/** A versão vigente do modelo oficial. */
export interface TemplateRow {
  id: string
  file_name: string
  file_path: string
  uploaded_at: string
}

/** Uma linha de `meal_map` como a visão do mês a pede, com as refeições dentro. */
export interface MealMapRow {
  map_date: string
  non_school_day: boolean
  note: string | null
  meals_served: number | null
  locked: boolean
  /**
   * As reaberturas deste mapa (US023). Ausente é nenhuma — é o caso da imensa
   * maioria dos dias, e os testes que não falam de reabertura não perguntam.
   */
  unlocks?: { unlocked_at: string; reason: string; unlocked_by?: string }[]
  meal: {
    type: 'morning_snack' | 'lunch' | 'afternoon_snack'
    description: string | null
    acceptance: 'great' | 'good' | 'poor' | null
    /** Só o registro do dia lê estes dois; o mês não pergunta por eles. */
    food_items?: UsedFoodItemRow[]
    menu_change?: { id: string; reason: string; food_items: UsedFoodItemRow[] }
  }[]
  /** Só o registro do dia lê estes; o mês não pergunta por eles. */
  id?: string
  updated_at?: string
}

function usedRow(item: UsedFoodItemRow) {
  return {
    food_item_id: item.food_item_id,
    quantity: item.quantity,
    food_item: { name: item.name, default_unit: item.default_unit },
  }
}

/*
 * A mesma linha, como o registro do dia a pede: com o identificador do mapa e
 * de cada refeição, e com os gêneros e a alteração do cardápio dentro.
 */
function dayRow(row: MealMapRow) {
  return {
    id: row.id ?? `map-${row.map_date}`,
    map_date: row.map_date,
    meal_map_unlock: (row.unlocks ?? []).map((unlock) => ({
      unlocked_at: unlock.unlocked_at,
    })),
    updated_at: row.updated_at ?? `${row.map_date}T12:00:00.000Z`,
    non_school_day: row.non_school_day,
    note: row.note,
    meals_served: row.meals_served,
    locked: row.locked,
    meal: row.meal.map((meal) => ({
      id: `meal-${row.map_date}-${meal.type}`,
      type: meal.type,
      description: meal.description,
      acceptance: meal.acceptance,
      meal_food_item: (meal.food_items ?? []).map(usedRow),
      menu_change: meal.menu_change
        ? {
            id: meal.menu_change.id,
            reason: meal.menu_change.reason,
            menu_change_food_item: meal.menu_change.food_items.map(usedRow),
          }
        : null,
    })),
  }
}

type Listener = (event: string, session: Session | null) => void

const listeners = new Set<Listener>()

let currentSession: Session | null = null
let profileRow: Profile | null = null
let profileError: { message: string } | null = null
let signInError: { code?: string; status?: number; message: string } | null =
  null
let mealMapRows: MealMapRow[] = []
let mealMapError: { message: string } | null = null
let foodItemRows: FoodItemRow[] = []
let foodItemError: { message: string } | null = null
let foodItemWriteError: { message: string } | null = null
let nextFoodItemId = 1
let generationFailure: {
  status: number
  message: string
  hint?: string
} | null = null
let generationRequests: string[][] = []
let generatedDocumentRows: GeneratedDocumentRow[] = []
let generatedDocumentsError: { message: string } | null = null
let signedUrlError: { message: string } | null = null
let signedUrlRequests: {
  bucket: string
  path: string
  seconds: number
  download?: string
}[] = []
let unlockRows: MapUnlockRow[] = []
let unlocksError: { message: string } | null = null
let unlockRpcError: { code?: string; message: string } | null = null
let unlockRequests: { mapId: string; reason: string }[] = []
let nextUnlockId = 1
let cookRows: CookRow[] = []
let cooksError: { message: string } | null = null
let cookWriteError: { message: string } | null = null
let schoolRow: SchoolRow | null = null
let schoolError: { message: string } | null = null
let schoolWriteError: { message: string } | null = null
let templateRow: TemplateRow | null = null
let templateError: { message: string } | null = null
let templateRpcError: { code?: string; message: string } | null = null
let createAccessFailure: {
  status: number
  message: string
  hint?: string
} | null = null
let createdAccessRequests: { name: string; email: string }[] = []
let passwordEmailRequests: string[] = []
let passwordEmailError: { message: string } | null = null
let uploadError: { message: string } | null = null
let uploadedFiles: { bucket: string; path: string; name: string }[] = []
let removedFiles: string[] = []
let nextCookId = 1
let nextTemplateId = 1

function sessionFor(profile: Profile): Session {
  return {
    user: { id: profile.id, email: profile.email },
  } as Session
}

export function emitAuthEvent(event: string, session: Session | null) {
  currentSession = session
  for (const listener of listeners) listener(event, session)
}

/** Um evento vindo de outra aba do mesmo navegador, com a sessão que já existe. */
export function emitFromAnotherTab(event: string) {
  for (const listener of listeners) listener(event, currentSession)
}

/** Conta que existe no banco, mas ninguém logado ainda: o aplicativo abre no login. */
export function givenAccount(profile: Profile) {
  profileRow = profile
}

/** Já logada quando o aplicativo abre: é a sessão que sobreviveu ao navegador. */
export function givenSignedIn(profile: Profile) {
  currentSession = sessionFor(profile)
  profileRow = profile
}

/** Há sessão, mas o perfil não aparece — acesso desativado pela direção. */
export function givenProfileMissing(profile: Profile) {
  currentSession = sessionFor(profile)
  profileRow = null
}

export function givenSignInFails(error: { code?: string; message: string }) {
  signInError = error
}

/** Os mapas que o servidor devolve para o recorte do mês consultado. */
export function givenMealMaps(rows: MealMapRow[]) {
  mealMapRows = rows
  mealMapError = null
}

/** O servidor não respondeu — na escola, quase sempre é a internet. */
export function givenMealMapsFail(message = 'sem rede') {
  mealMapError = { message }
}

/** O catálogo de gêneros da escola, como a folha 3b o encontra. */
export function givenFoodItems(rows: FoodItemRow[]) {
  foodItemRows = rows
  foodItemError = null
}

/** O catálogo não veio — e a folha ainda tem de deixar cadastrar. */
export function givenFoodItemsFail(message = 'sem rede') {
  foodItemError = { message }
}

/** A gravação no catálogo não passou: a tela 4 escreve direto no servidor. */
export function givenFoodItemWriteFails(message = 'sem rede') {
  foodItemWriteError = { message }
}

/**
 * A geração do documento não passa: a Edge Function devolve o corpo de erro que
 * a borda HTTP dela escreve, e é dele que a tela tira a frase do diálogo.
 */
export function givenGenerationFails(
  message: string,
  status = 400,
  hint?: string
) {
  generationFailure = { status, message, hint }
}

/** Os documentos que o servidor devolve para a lista, na ordem em que vierem. */
export function givenGeneratedDocuments(rows: GeneratedDocumentRow[]) {
  generatedDocumentRows = rows
  generatedDocumentsError = null
}

/** A lista não veio — na escola, quase sempre é a internet. */
export function givenGeneratedDocumentsFail(message = 'sem rede') {
  generatedDocumentsError = { message }
}

/** O balde recusou assinar o link do arquivo. */
export function givenSignedUrlFails(message = 'sem rede') {
  signedUrlError = { message }
}

/** Os links que a tela pediu ao balde, com o nome que pediu para cada um. */
export function signedUrls() {
  return signedUrlRequests
}

/** Os pedidos de geração que chegaram, na ordem, com os dias de cada um. */
export function sentGenerations(): string[][] {
  return generationRequests
}

/** O catálogo como ficou depois do que a tela gravou. */
export function storedFoodItems(): FoodItemRow[] {
  return foodItemRows
}

/** As merendeiras que a gestão de acessos encontra (issue #68). */
export function givenCooks(rows: CookRow[]) {
  cookRows = rows
  cooksError = null
}

export function givenCooksFail(message = 'sem rede') {
  cooksError = { message }
}

/** Desativar/reativar não passa: a gestão escreve direto no servidor. */
export function givenCookWriteFails(message = 'sem rede') {
  cookWriteError = { message }
}

/** O histórico de reaberturas que a tela Mapas encontra (issue #69). */
export function givenMapUnlocks(rows: MapUnlockRow[]) {
  unlockRows = rows
  unlocksError = null
}

export function givenMapUnlocksFail(message = 'sem rede') {
  unlocksError = { message }
}

/**
 * A reabertura é recusada pelo banco. Com código, a frase da função chega à
 * tela como ela foi escrita; sem código, é rede — e vale a frase da tela.
 */
export function givenReopenFails(message: string, code?: string) {
  unlockRpcError = { code, message }
}

/** As reaberturas que a tela pediu, na ordem, com a justificativa de cada uma. */
export function reopenRequests() {
  return unlockRequests
}

/** O histórico como ficou depois do que a tela gravou. */
export function storedMapUnlocks(): MapUnlockRow[] {
  return unlockRows
}

/** Os mapas como ficaram: é aqui que se confere o bloqueio que saiu. */
export function storedMealMaps(): MealMapRow[] {
  return mealMapRows
}

/** A escola de quem está logada, que é a única que o RLS devolve. */
export function givenSchool(row: SchoolRow) {
  schoolRow = row
  schoolError = null
}

export function givenSchoolFail(message = 'sem rede') {
  schoolError = { message }
}

export function givenSchoolWriteFails(message = 'sem rede') {
  schoolWriteError = { message }
}

/** O modelo oficial vigente, ou a falta dele. */
export function givenCurrentTemplate(row: TemplateRow | null) {
  templateRow = row
  templateError = null
}

export function givenTemplateFail(message = 'sem rede') {
  templateError = { message }
}

/** O envio do modelo sobe o arquivo e falha ao registrá-lo. */
export function givenTemplateRegisterFails(message = 'recusado') {
  templateRpcError = { code: '42501', message }
}

/** O balde recusa o arquivo do modelo. */
export function givenTemplateUploadFails(message = 'sem rede') {
  uploadError = { message }
}

/** A Edge Function que cria o acesso recusa o pedido. */
export function givenCreateAccessFails(
  message: string,
  status = 400,
  hint?: string
) {
  createAccessFailure = { status, message, hint }
}

/** O e-mail de criar senha não sai. */
export function givenPasswordEmailFails(message = 'sem rede') {
  passwordEmailError = { message }
}

/** Os acessos que a tela pediu para criar, na ordem. */
export function createdAccesses() {
  return createdAccessRequests
}

/** Os e-mails de criar senha que a tela disparou, na ordem. */
export function passwordEmails() {
  return passwordEmailRequests
}

/** As merendeiras como ficaram depois do que a tela gravou. */
export function storedCooks(): CookRow[] {
  return cookRows
}

/** A escola como ficou depois do que a tela gravou. */
export function storedSchool(): SchoolRow | null {
  return schoolRow
}

/** O modelo vigente como ficou depois do envio. */
export function storedTemplate(): TemplateRow | null {
  return templateRow
}

/** Os arquivos que subiram ao balde, e os que foram apagados de lá. */
export function uploads() {
  return uploadedFiles
}

export function removals() {
  return removedFiles
}

export function resetSupabaseMock() {
  listeners.clear()
  currentSession = null
  profileRow = null
  profileError = null
  signInError = null
  mealMapRows = []
  mealMapError = null
  foodItemRows = []
  foodItemError = null
  foodItemWriteError = null
  nextFoodItemId = 1
  generationFailure = null
  generationRequests = []
  generatedDocumentRows = []
  generatedDocumentsError = null
  signedUrlError = null
  signedUrlRequests = []
  unlockRows = []
  unlocksError = null
  unlockRpcError = null
  unlockRequests = []
  nextUnlockId = 1
  cookRows = []
  cooksError = null
  cookWriteError = null
  schoolRow = null
  schoolError = null
  schoolWriteError = null
  templateRow = null
  templateError = null
  templateRpcError = null
  createAccessFailure = null
  createdAccessRequests = []
  passwordEmailRequests = []
  passwordEmailError = null
  uploadError = null
  uploadedFiles = []
  removedFiles = []
  nextCookId = 1
  nextTemplateId = 1
  vi.clearAllMocks()
}

/**
 * A recusa de uma Edge Function, como a biblioteca a embrulha: o corpo do erro
 * fica em `context`, e é de lá que a tela tira a frase já escrita.
 */
function functionFailure(failure: {
  status: number
  message: string
  hint?: string
}) {
  return {
    data: null,
    error: {
      name: 'FunctionsHttpError',
      message: 'Edge Function returned a non-2xx status code',
      context: {
        status: failure.status,
        json: async () => ({
          error: { message: failure.message, hint: failure.hint ?? null },
        }),
      },
    },
  }
}

export const supabase = {
  auth: {
    onAuthStateChange(callback: Listener) {
      listeners.add(callback)
      queueMicrotask(() => callback('INITIAL_SESSION', currentSession))

      return {
        data: {
          subscription: {
            unsubscribe: () => {
              listeners.delete(callback)
            },
          },
        },
      }
    },

    signInWithPassword: vi.fn(async ({ email }: { email: string }) => {
      if (signInError) return { data: null, error: signInError }

      const profile = profileRow
      if (!profile) return { data: null, error: { message: 'sem perfil' } }

      emitAuthEvent('SIGNED_IN', sessionFor({ ...profile, email }))
      return { data: { session: currentSession }, error: null }
    }),

    signOut: vi.fn(
      async (options?: { scope?: 'global' | 'local' | 'others' }) => {
        // Sair das OUTRAS sessões não mexe nesta — é o que acontece ao trocar a
        // senha, e o servidor de verdade se comporta assim.
        if (options?.scope !== 'others') emitAuthEvent('SIGNED_OUT', null)
        return { error: null }
      }
    ),

    resetPasswordForEmail: vi.fn(async (email: string) => {
      passwordEmailRequests = [...passwordEmailRequests, email]
      return passwordEmailError
        ? { data: null, error: passwordEmailError }
        : { data: {}, error: null }
    }),

    updateUser: vi.fn(async () => ({ data: {}, error: null })),
  },

  /*
   * As funções do banco. Três telas chegam aqui, e cada uma por um motivo:
   *
   *   save_meal_map              responde como uma rede que não está lá — o dia
   *                              continua na fila, que é o estado que interessa
   *   touch_last_access          o carimbo do último acesso, que nunca atrapalha
   *   replace_document_template  a troca do modelo, que é uma operação só
   *   unlock_meal_map            a reabertura, que desbloqueia e registra junto
   *
   * O retorno é um objeto que se pode esperar **ou** encadear com `single()`,
   * como o construtor da biblioteca de verdade.
   */
  rpc: vi.fn((name: string, args?: Record<string, unknown>) => {
    const result = () => {
      if (name === 'touch_last_access') return { data: null, error: null }

      /*
       * A reabertura (US023). No banco ela é uma transação só — registra e
       * desbloqueia —, e o mock guarda as duas coisas de uma vez, para que a
       * tela seja conferida contra o efeito, e não contra a chamada.
       */
      if (name === 'unlock_meal_map') {
        const mapId = String(args?.map_id ?? '')
        const reason = String(args?.unlock_reason ?? '')
        unlockRequests = [...unlockRequests, { mapId, reason }]

        if (unlockRpcError) return { data: null, error: unlockRpcError }

        const reopened = mealMapRows.find(
          (row) => (row.id ?? `map-${row.map_date}`) === mapId
        )

        mealMapRows = mealMapRows.map((row) =>
          row === reopened ? { ...row, locked: false } : row
        )

        unlockRows = [
          {
            id: `unlock-${nextUnlockId++}`,
            map_date: reopened?.map_date ?? '',
            unlocked_at: new Date().toISOString(),
            unlocked_by: 'Direção',
            reason,
          },
          ...unlockRows,
        ]

        return { data: { id: mapId, locked: false }, error: null }
      }

      if (name === 'replace_document_template') {
        if (templateRpcError) return { data: null, error: templateRpcError }

        templateRow = {
          id: `template-${nextTemplateId++}`,
          file_name: String(args?.p_file_name ?? '').trim(),
          file_path: String(args?.p_file_path ?? ''),
          uploaded_at: new Date().toISOString(),
        }
        return { data: templateRow, error: null }
      }

      return {
        data: null,
        error: { code: '', message: 'sem rede', details: '', hint: '' },
      }
    }

    return {
      single: async () => result(),
      then: (resolve: (value: ReturnType<typeof result>) => unknown) =>
        Promise.resolve(resolve(result())),
    }
  }),

  /*
   * A Edge Function da geração do documento. Ela responde como a de verdade:
   * o corpo do erro vem embrulhado num `context`, que é de onde a tela tira a
   * frase já escrita para a merendeira.
   */
  functions: {
    invoke: vi.fn(
      async (
        name: string,
        options: {
          body: { meal_map_ids?: string[]; name?: string; email?: string }
        }
      ) => {
        /*
         * A criação do acesso (issue #68). A conta nasce em `auth.users`, que
         * só a chave secreta escreve, e é por isso que ela é uma Edge Function
         * e não mais um insert da tela.
         */
        if (name === 'create-access') {
          const wanted = {
            name: String(options.body.name ?? ''),
            email: String(options.body.email ?? ''),
          }
          createdAccessRequests = [...createdAccessRequests, wanted]

          if (createAccessFailure) return functionFailure(createAccessFailure)

          const created: CookRow = {
            id: `cook-${nextCookId++}`,
            name: wanted.name,
            email: wanted.email,
            active: true,
            last_access: null,
          }
          cookRows = [...cookRows, created].sort((a, b) =>
            a.name.localeCompare(b.name)
          )

          return { data: created, error: null }
        }

        generationRequests = [
          ...generationRequests,
          options.body.meal_map_ids ?? [],
        ]

        if (generationFailure) return functionFailure(generationFailure)

        const dates = (options.body.meal_map_ids ?? [])
          .map((id) => id.replace('map-', ''))
          .sort()

        return {
          data: {
            generated_document_id: 'doc-1',
            status: 'available',
            requested_at: '2026-09-09T12:00:00.000Z',
            completed_at: '2026-09-09T12:00:00.300Z',
            expires_at: '2026-09-16T12:00:00.300Z',
            meal_map_count: dates.length,
            period: { from: dates[0], to: dates[dates.length - 1] },
            file_name: 'mapa-da-alimentacao-escolar-setembro-2026.docx',
            download_url: 'https://exemplo/documento.docx',
          },
          error: null,
        }
      }
    ),
  },

  /*
   * O balde dos documentos gerados. A lista assina o link ela mesma — a
   * política do balde deixa —, e o que interessa conferir é o que ela pede:
   * o caminho do arquivo e o nome com que ele deve chegar.
   */
  storage: {
    from: vi.fn((bucket: string) => ({
      createSignedUrl: vi.fn(
        async (
          path: string,
          seconds: number,
          options?: { download?: string }
        ) => {
          signedUrlRequests = [
            ...signedUrlRequests,
            { bucket, path, seconds, download: options?.download },
          ]

          if (signedUrlError) return { data: null, error: signedUrlError }

          return {
            data: { signedUrl: `https://exemplo/${path}?assinado` },
            error: null,
          }
        }
      ),

      /** O envio do modelo oficial, que vai para o balde privado (issue #68). */
      upload: vi.fn(async (path: string, file: File) => {
        if (uploadError) return { data: null, error: uploadError }

        uploadedFiles = [...uploadedFiles, { bucket, path, name: file.name }]
        return { data: { path }, error: null }
      }),

      /** O arquivo que subiu e não virou versão nenhuma é apagado. */
      remove: vi.fn(async (paths: string[]) => {
        removedFiles = [...removedFiles, ...paths]
        return { data: [], error: null }
      }),
    })),
  },

  /*
   * O construtor de consulta, reduzido ao que as telas encadeiam. Ele é o
   * mesmo objeto em cada passo — `select`, `eq`, `gte`, `lte`, `order` só
   * devolvem ele mesmo —, e o resultado sai por `maybeSingle` (o perfil) ou
   * por esperar o próprio objeto (a lista do mês), como na biblioteca real.
   */
  from: vi.fn((table: string) => {
    const filters: Record<string, unknown> = {}
    /* A linha que a gravação acabou de escrever, que é o que `single` devolve. */
    let written: FoodItemRow | CookRow | SchoolRow | null = null
    /*
     * O que `update` recebeu. Ele vem ANTES do `eq` que diz qual linha é — é a
     * ordem da biblioteca real —, então a troca só acontece quando o resultado
     * é pedido, e não na hora da chamada.
     */
    let changes: Partial<FoodItemRow & CookRow & SchoolRow> | null = null
    /*
     * A ordem e o teto que a consulta pediu. A tela Mapas (issue #69) lê a
     * mesma tabela do mês em ordem contrária — do dia mais recente para o mais
     * antigo —, e sem isto as duas leituras chegariam iguais aqui.
     */
    let sort: { column: string; ascending: boolean } | null = null
    let ceiling: number | null = null

    /** O `limit()` da consulta, aplicado onde a lista sai. */
    const capped = <T>(rows: T[]): T[] =>
      ceiling === null ? rows : rows.slice(0, ceiling)

    const chain = {
      select: () => chain,
      eq: (column: string, value: unknown) => {
        filters[column] = value
        return chain
      },
      gte: () => chain,
      lte: () => chain,
      order: (column: string, options?: { ascending?: boolean }) => {
        sort = { column, ascending: options?.ascending !== false }
        return chain
      },
      limit: (count: number) => {
        ceiling = count
        return chain
      },

      /*
       * As duas escritas da tela 4 (issue #64). O catálogo do mock é a fonte:
       * o que entra por aqui aparece na leitura seguinte, que é o que permite
       * conferir o gênero cadastrado sem simular a invalidação à mão.
       */
      insert: (values: { name: string; default_unit: string }) => {
        if (!foodItemWriteError) {
          written = {
            id: `food-${nextFoodItemId++}`,
            name: values.name,
            default_unit: values.default_unit,
            active: true,
          }
          foodItemRows = [...foodItemRows, written].sort((a, b) =>
            a.name.localeCompare(b.name)
          )
        }
        return chain
      },

      update: (values: Partial<FoodItemRow & CookRow & SchoolRow>) => {
        changes = values
        return chain
      },

      /*
       * Duas telas terminam aqui: o perfil, que é uma linha só por definição,
       * e o registro do dia, que pede o mapa de uma data.
       */
      maybeSingle: async () => {
        if (table === 'school') {
          return { data: schoolRow, error: schoolError }
        }
        if (table === 'document_template') {
          return { data: templateRow, error: templateError }
        }
        if (table !== 'meal_map') {
          return { data: profileRow, error: profileError }
        }
        if (mealMapError) return { data: null, error: mealMapError }

        const row = mealMapRows.find((one) => one.map_date === filters.map_date)
        return { data: row ? dayRow(row) : null, error: null }
      },

      /** O que a gravação devolve: a linha escrita, ou a recusa do servidor. */
      single: async () => {
        /*
         * As duas escritas da gestão (issue #68). Desativar uma merendeira é
         * `active = false` e nunca um delete: a linha sustenta a autoria dos
         * registros dela, e o mock guarda isso como o banco guarda.
         */
        if (table === 'profile') {
          if (cookWriteError) return { data: null, error: cookWriteError }

          let saved: CookRow | null = null
          cookRows = cookRows.map((row) => {
            if (row.id !== filters.id) return row
            saved = { ...row, ...changes }
            return saved
          })
          return { data: saved, error: null }
        }

        if (table === 'school') {
          if (schoolWriteError) return { data: null, error: schoolWriteError }

          schoolRow = schoolRow ? { ...schoolRow, ...changes } : schoolRow
          return { data: schoolRow, error: null }
        }

        if (foodItemWriteError) return { data: null, error: foodItemWriteError }

        if (changes !== null) {
          foodItemRows = foodItemRows.map((row) => {
            if (row.id !== filters.id) return row

            written = { ...row, ...changes }
            return written
          })
        }

        return { data: written, error: null }
      },

      then: (
        resolve: (result: {
          data: unknown[] | null
          error: { message: string } | null
        }) => unknown
      ) => {
        if (table === 'food_item') {
          /*
           * O `eq('active', true)` da folha 3b: a tela 4 lê sem ele, e é essa
           * a diferença entre as duas leituras do catálogo.
           */
          const rows = foodItemRows
            .map((row) => ({ ...row, active: row.active ?? true }))
            .filter(
              (row) =>
                filters.active === undefined || row.active === filters.active
            )
            .sort((a, b) => a.name.localeCompare(b.name))

          return Promise.resolve(
            resolve(
              foodItemError
                ? { data: null, error: foodItemError }
                : { data: rows, error: null }
            )
          )
        }

        if (table === 'profile') {
          return Promise.resolve(
            resolve(
              cooksError
                ? { data: null, error: cooksError }
                : { data: cookRows, error: null }
            )
          )
        }

        /* O histórico da tela Mapas, com o dia e o nome de quem reabriu. */
        if (table === 'meal_map_unlock') {
          if (unlocksError) {
            return Promise.resolve(resolve({ data: null, error: unlocksError }))
          }

          const rows = unlockRows.map((row) => ({
            id: row.id,
            unlocked_at: row.unlocked_at,
            reason: row.reason,
            meal_map: { map_date: row.map_date },
            profile: { name: row.unlocked_by },
          }))

          return Promise.resolve(resolve({ data: capped(rows), error: null }))
        }

        if (table === 'generated_document') {
          return Promise.resolve(
            resolve(
              generatedDocumentsError
                ? { data: null, error: generatedDocumentsError }
                : { data: generatedDocumentRows.map(documentRow), error: null }
            )
          )
        }

        if (mealMapError) {
          return Promise.resolve(resolve({ data: null, error: mealMapError }))
        }

        /*
         * A visão do mês, a seleção de mapas e a tela Mapas leem a mesma tabela.
         * As duas primeiras pedem o identificador junto — é ele que a geração do
         * documento recebe —, e a terceira filtra pelos bloqueados e pede o
         * documento em que cada um saiu. O vínculo com o documento é montado a
         * partir dos documentos gerados do próprio mock: uma fonte só, como no
         * banco, onde é `document_meal_map` que sabe quais dias entraram.
         */
        const rows =
          table === 'meal_map'
            ? mealMapRows
                .filter(
                  (row) =>
                    filters.locked === undefined ||
                    row.locked === filters.locked
                )
                .map((row) => ({
                  ...row,
                  id: row.id ?? `map-${row.map_date}`,
                  meal_map_unlock: (row.unlocks ?? []).map((unlock) => ({
                    unlocked_at: unlock.unlocked_at,
                  })),
                  document_meal_map: generatedDocumentRows
                    .filter((document) => document.dates.includes(row.map_date))
                    .map((document) => ({
                      generated_document: {
                        id: document.id,
                        requested_at: document.requested_at,
                        completed_at: document.completed_at ?? null,
                      },
                    })),
                }))
                .sort((a, b) =>
                  sort?.column === 'map_date' && !sort.ascending
                    ? b.map_date.localeCompare(a.map_date)
                    : a.map_date.localeCompare(b.map_date)
                )
            : []

        return Promise.resolve(resolve({ data: capped(rows), error: null }))
      },
    }

    return chain
  }),
}

export const AUTH_STORAGE_KEY = 'mae.auth'
