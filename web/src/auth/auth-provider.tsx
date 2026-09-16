import { useCallback, useEffect, useMemo, useState } from 'react'

import type { AuthError, Session } from '@supabase/supabase-js'

import { clearLocalData } from '@/lib/local-data'
import { cameFromRecoveryLink } from '@/lib/recovery-link'
import { supabase } from '@/lib/supabase'

import {
  AuthContext,
  type AuthContextValue,
  type Profile,
} from './auth-context'
import { AUTH_MESSAGES } from './messages'

/*
 * A sessão e o perfil de quem está usando o aplicativo, num contexto só.
 *
 * O que está aqui é conveniência de interface: saber quem é para mostrar a
 * tela certa. Quem decide o que cada perfil pode ler e escrever são as
 * políticas de RLS da E4, no banco (decisão 6 da E5) — nada nesta camada é
 * controle de acesso, e é por isso que o perfil pode vir daqui sem cerimônia.
 */

/** Traduz o erro da biblioteca para uma frase do catálogo da E3. */
function messageFor(error: AuthError): string {
  switch (error.code) {
    case 'invalid_credentials':
      return AUTH_MESSAGES.invalidCredentials
    case 'weak_password':
      return AUTH_MESSAGES.passwordTooShort
    case 'captcha_failed':
      return AUTH_MESSAGES.captchaFailed
    case 'over_request_rate_limit':
    case 'over_email_send_rate_limit':
      return AUTH_MESSAGES.tooManyAttempts
    default:
      // Erro de rede não tem `code`; o resto é falha do sistema, e em nenhum
      // dos dois casos há o que a merendeira possa corrigir no formulário.
      return error.status === 429
        ? AUTH_MESSAGES.tooManyAttempts
        : AUTH_MESSAGES.connection
  }
}

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [session, setSession] = useState<Session | null>(null)
  const [profile, setProfile] = useState<Profile | null>(null)
  const [loading, setLoading] = useState(true)
  /*
   * Só a aba que abriu o link é a aba da senha nova. O estado nasce do
   * endereço desta aba e nunca do aviso do Supabase, que é compartilhado entre
   * todas elas — era exatamente assim que a aba do "esqueci minha senha"
   * virava uma segunda tela de trocar senha.
   */
  const [recovering, setRecovering] = useState(cameFromRecoveryLink)
  const [profileUnavailable, setProfileUnavailable] = useState(false)
  const [notice, setNotice] = useState<string | null>(null)
  // Muda para pedir o perfil de novo depois de uma falha de rede.
  const [profileAttempt, setProfileAttempt] = useState(0)

  useEffect(() => {
    /*
     * `onAuthStateChange` também entrega a sessão que já estava guardada no
     * aparelho, logo na inscrição — é ela que faz a sessão sobreviver ao
     * fechar do navegador (RNF#2 da US016). Não se chama o Supabase de dentro
     * deste retorno: a própria biblioteca avisa que a chamada aninhada pode
     * travar. O perfil é buscado no efeito seguinte.
     */
    const { data } = supabase.auth.onAuthStateChange((_event, nextSession) => {
      setSession(nextSession)

      if (!nextSession) {
        setProfile(null)
        setProfileUnavailable(false)
        setLoading(false)
      }
    })

    return () => data.subscription.unsubscribe()
  }, [])

  const userId = session?.user.id ?? null

  useEffect(() => {
    if (!userId) return

    let active = true

    void (async () => {
      // Dentro da função assíncrona de propósito: setState direto no corpo do
      // efeito é o que a regra react-hooks/set-state-in-effect proíbe, e aqui
      // o estado só muda porque vamos falar com o servidor a seguir.
      setLoading(true)
      setProfileUnavailable(false)

      const { data, error } = await supabase
        .from('profile')
        .select('id, name, email, role, school_id')
        .eq('id', userId)
        .maybeSingle()

      if (!active) return

      if (error) {
        setProfileUnavailable(true)
        setLoading(false)
        return
      }

      if (!data) {
        /*
         * Sessão válida e nenhum perfil à vista: o acesso foi desativado pela
         * direção (CA#2 da US016) e a política de RLS deixou de enxergar a
         * linha. Não há aplicativo nenhum para mostrar a quem está neste
         * estado — encerra a sessão e explica na tela de login.
         */
        setNotice(AUTH_MESSAGES.accessDisabled)
        try {
          await supabase.auth.signOut()
        } finally {
          if (active) {
            setProfile(null)
            setSession(null)
            setLoading(false)
          }
        }
        return
      }

      setProfile(data)
      setLoading(false)
    })()

    return () => {
      active = false
    }
  }, [userId, profileAttempt])

  const signIn = useCallback(
    async (email: string, password: string, captchaToken?: string | null) => {
      setNotice(null)

      const { error } = await supabase.auth.signInWithPassword({
        email: email.trim(),
        password,
        // O desafio contra robôs, quando estiver ligado. Quem o confere é o
        // Supabase, com a chave secreta que só ele tem.
        options: captchaToken ? { captchaToken } : undefined,
      })

      return error ? { error: messageFor(error) } : {}
    },
    []
  )

  const signOut = useCallback(async () => {
    /*
     * Primeiro a sessão, depois o que ficou no aparelho (CA#5 da issue #59).
     * Se a revogação no servidor não for possível — sem rede, que é o comum
     * aqui —, a sessão sai do aparelho do mesmo jeito: ficar preso dentro do
     * aplicativo por falta de internet seria o pior desfecho.
     */
    const { error } = await supabase.auth.signOut()
    if (error) await supabase.auth.signOut({ scope: 'local' })

    await clearLocalData()

    setSession(null)
    setProfile(null)
    setRecovering(false)
    setProfileUnavailable(false)
    setLoading(false)
  }, [])

  const requestPasswordReset = useCallback(
    async (email: string, captchaToken?: string | null) => {
      const { error } = await supabase.auth.resetPasswordForEmail(
        email.trim(),
        {
          redirectTo: `${window.location.origin}/nova-senha`,
          ...(captchaToken ? { captchaToken } : {}),
        }
      )

      /*
       * Erro aqui nunca é "este e-mail não existe" — o Supabase responde igual
       * para e-mail conhecido e desconhecido, e é assim que deve ser: dizer que
       * o e-mail não tem acesso seria a mesma entrega que o erro de login evita.
       */
      return error ? { error: messageFor(error) } : {}
    },
    []
  )

  const setNewPassword = useCallback(async (password: string) => {
    const { error } = await supabase.auth.updateUser({ password })

    if (error) return { error: messageFor(error) }

    /*
     * Trocada a senha, as outras sessões caem — a desta aba fica. Um pedido de
     * senha nova quase sempre significa "perdi o acesso", e o que não pode
     * acontecer é o acesso antigo continuar aberto em outro aparelho depois de
     * a senha mudar. Se a chamada falhar, a troca continua valendo: a senha
     * antiga já não abre mais nada.
     */
    await supabase.auth.signOut({ scope: 'others' })

    setRecovering(false)
    return {}
  }, [])

  const retryProfile = useCallback(() => {
    setProfileAttempt((attempt) => attempt + 1)
  }, [])

  const dismissNotice = useCallback(() => setNotice(null), [])

  const value = useMemo<AuthContextValue>(
    () => ({
      loading,
      session,
      profile,
      recovering,
      profileUnavailable,
      notice,
      signIn,
      signOut,
      requestPasswordReset,
      setNewPassword,
      retryProfile,
      dismissNotice,
    }),
    [
      loading,
      session,
      profile,
      recovering,
      profileUnavailable,
      notice,
      signIn,
      signOut,
      requestPasswordReset,
      setNewPassword,
      retryProfile,
      dismissNotice,
    ]
  )

  return <AuthContext value={value}>{children}</AuthContext>
}
