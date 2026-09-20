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

/** Uma linha de `meal_map` como a visão do mês a pede, com as refeições dentro. */
export interface MealMapRow {
  map_date: string
  non_school_day: boolean
  note: string | null
  meals_served: number | null
  locked: boolean
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
let signedUrlRequests: { path: string; seconds: number; download?: string }[] =
  []

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
  vi.clearAllMocks()
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

    resetPasswordForEmail: vi.fn(async () => ({ data: {}, error: null })),

    updateUser: vi.fn(async () => ({ data: {}, error: null })),
  },

  /*
   * A gravação do dia. Responde como uma rede que não está lá: o dia continua
   * na fila, que é o estado que interessa a estes testes.
   */
  rpc: vi.fn(async () => ({
    data: null,
    error: { code: '', message: 'sem rede', details: '', hint: '' },
  })),

  /*
   * A Edge Function da geração do documento. Ela responde como a de verdade:
   * o corpo do erro vem embrulhado num `context`, que é de onde a tela tira a
   * frase já escrita para a merendeira.
   */
  functions: {
    invoke: vi.fn(
      async (_name: string, options: { body: { meal_map_ids: string[] } }) => {
        generationRequests = [...generationRequests, options.body.meal_map_ids]

        if (generationFailure) {
          const { status, message, hint } = generationFailure
          return {
            data: null,
            error: {
              name: 'FunctionsHttpError',
              message: 'Edge Function returned a non-2xx status code',
              context: {
                status,
                json: async () => ({ error: { message, hint: hint ?? null } }),
              },
            },
          }
        }

        const dates = options.body.meal_map_ids
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
    from: vi.fn(() => ({
      createSignedUrl: vi.fn(
        async (
          path: string,
          seconds: number,
          options?: { download?: string }
        ) => {
          signedUrlRequests = [
            ...signedUrlRequests,
            { path, seconds, download: options?.download },
          ]

          if (signedUrlError) return { data: null, error: signedUrlError }

          return {
            data: { signedUrl: `https://exemplo/${path}?assinado` },
            error: null,
          }
        }
      ),
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
    let written: FoodItemRow | null = null
    /*
     * O que `update` recebeu. Ele vem ANTES do `eq` que diz qual linha é — é a
     * ordem da biblioteca real —, então a troca só acontece quando o resultado
     * é pedido, e não na hora da chamada.
     */
    let changes: Partial<FoodItemRow> | null = null

    const chain = {
      select: () => chain,
      eq: (column: string, value: unknown) => {
        filters[column] = value
        return chain
      },
      gte: () => chain,
      lte: () => chain,
      order: () => chain,
      limit: () => chain,

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

      update: (values: Partial<FoodItemRow>) => {
        changes = values
        return chain
      },

      /*
       * Duas telas terminam aqui: o perfil, que é uma linha só por definição,
       * e o registro do dia, que pede o mapa de uma data.
       */
      maybeSingle: async () => {
        if (table !== 'meal_map') {
          return { data: profileRow, error: profileError }
        }
        if (mealMapError) return { data: null, error: mealMapError }

        const row = mealMapRows.find((one) => one.map_date === filters.map_date)
        return { data: row ? dayRow(row) : null, error: null }
      },

      /** O que a gravação devolve: a linha escrita, ou a recusa do servidor. */
      single: async () => {
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
          data:
            | MealMapRow[]
            | FoodItemRow[]
            | ReturnType<typeof documentRow>[]
            | null
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
         * A visão do mês e a seleção de mapas pedem o identificador do mapa
         * junto: é ele que a geração do documento recebe.
         */
        const rows =
          table === 'meal_map'
            ? mealMapRows.map((row) => ({
                ...row,
                id: row.id ?? `map-${row.map_date}`,
              }))
            : []

        return Promise.resolve(resolve({ data: rows, error: null }))
      },
    }

    return chain
  }),
}

export const AUTH_STORAGE_KEY = 'mae.auth'
