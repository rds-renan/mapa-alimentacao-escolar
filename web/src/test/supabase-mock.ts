import { vi } from 'vitest'

import type { Session } from '@supabase/supabase-js'

import type { Profile } from '@/auth/auth-context'

/*
 * O Supabase de mentira dos testes. Imita só o que as telas usam: a inscrição
 * em mudanças de sessão — que entrega a sessão guardada no aparelho logo ao se
 * inscrever, como a biblioteca de verdade faz —, o login, a saída, o pedido de
 * senha nova, a leitura do perfil e a consulta dos mapas de um mês.
 */

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
  }[]
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

export function resetSupabaseMock() {
  listeners.clear()
  currentSession = null
  profileRow = null
  profileError = null
  signInError = null
  mealMapRows = []
  mealMapError = null
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
   * O construtor de consulta, reduzido ao que as telas encadeiam. Ele é o
   * mesmo objeto em cada passo — `select`, `eq`, `gte`, `lte`, `order` só
   * devolvem ele mesmo —, e o resultado sai por `maybeSingle` (o perfil) ou
   * por esperar o próprio objeto (a lista do mês), como na biblioteca real.
   */
  from: vi.fn((table: string) => {
    const chain = {
      select: () => chain,
      eq: () => chain,
      gte: () => chain,
      lte: () => chain,
      order: () => chain,
      maybeSingle: async () => ({ data: profileRow, error: profileError }),
      then: (
        resolve: (result: {
          data: MealMapRow[] | null
          error: { message: string } | null
        }) => unknown
      ) =>
        Promise.resolve(
          resolve(
            mealMapError
              ? { data: null, error: mealMapError }
              : { data: table === 'meal_map' ? mealMapRows : [], error: null }
          )
        ),
    }

    return chain
  }),
}

export const AUTH_STORAGE_KEY = 'mae.auth'
