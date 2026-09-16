import { createContext } from 'react'

import type { Session } from '@supabase/supabase-js'

import type { Tables } from '@/lib/database.types'

export type UserRole = Tables<'profile'>['role']

/*
 * O que a interface precisa saber de quem está logado. Não é a linha inteira
 * da tabela: `active` e `last_access` são assunto da administração (US016), e
 * o que a sessão carrega é só o suficiente para saber quem é e o que mostrar.
 */
export type Profile = Pick<
  Tables<'profile'>,
  'id' | 'name' | 'email' | 'role' | 'school_id'
>

/** O que `signIn` e companhia devolvem: uma mensagem pronta para a tela. */
export interface AuthResult {
  error?: string
}

export interface AuthContextValue {
  /** A sessão e o perfil ainda estão sendo resolvidos. */
  loading: boolean
  session: Session | null
  profile: Profile | null
  /**
   * A sessão veio do link de redefinição de senha, e não de um login. Enquanto
   * isto for verdade, o único destino é a tela da senha nova.
   */
  recovering: boolean
  /**
   * Há sessão, mas não deu para confirmar o perfil — quase sempre falta de
   * rede. A sessão é mantida de propósito: deslogar quem está sem sinal seria
   * o pior desfecho possível numa escola sem sinal de operadora.
   */
  profileUnavailable: boolean
  /** Aviso a mostrar na tela de login, como o acesso desativado. */
  notice: string | null
  signIn(
    email: string,
    password: string,
    captchaToken?: string | null
  ): Promise<AuthResult>
  signOut(): Promise<void>
  requestPasswordReset(
    email: string,
    captchaToken?: string | null
  ): Promise<AuthResult>
  setNewPassword(password: string): Promise<AuthResult>
  retryProfile(): void
  dismissNotice(): void
}

export const AuthContext = createContext<AuthContextValue | null>(null)
