import { Navigate, Outlet, useLocation } from 'react-router'

import { Button } from '@/components/ui/button'
import { LoadingScreen } from '@/components/loading-screen'
import { homePathFor, ROUTES } from '@/routes'

import type { UserRole } from './auth-context'
import { AUTH_MESSAGES } from './messages'
import { useAuth } from './useAuth'

/*
 * As guardas de rota. Vale repetir o que a decisão 6 da E5 diz, porque é fácil
 * de esquecer ao ler este arquivo: **isto não é controle de acesso**. Esconder
 * a administração de quem é merendeira é cortesia de interface; quem impede a
 * leitura e a escrita são as políticas de RLS da E4, no banco, onde ninguém
 * contorna abrindo o DevTools.
 */

/** Exige sessão, e o perfil junto: sem saber o papel não há tela a escolher. */
export function RequireSession() {
  const {
    loading,
    session,
    profile,
    recovering,
    profileUnavailable,
    retryProfile,
  } = useAuth()
  const location = useLocation()

  if (loading) return <LoadingScreen />

  if (!session) {
    // De onde veio, para voltar ao mesmo lugar depois de entrar.
    return (
      <Navigate
        to={ROUTES.signIn}
        replace
        state={{ from: location.pathname }}
      />
    )
  }

  // Sessão nascida do link do e-mail: o único destino é criar a senha nova.
  if (recovering) return <Navigate to={ROUTES.newPassword} replace />

  if (profileUnavailable) {
    return (
      <div className="flex min-h-dvh flex-col items-center justify-center gap-4 bg-background px-6 text-center">
        <p className="text-base text-muted-foreground">
          {AUTH_MESSAGES.profileUnavailable}
        </p>
        <Button onClick={retryProfile}>Tentar de novo</Button>
      </div>
    )
  }

  if (!profile) return <LoadingScreen />

  return <Outlet />
}

/** Exige o perfil certo; quem não é dele volta para a sua própria casa. */
export function RequireRole({ role }: { role: UserRole }) {
  const { profile } = useAuth()

  // Só se chega aqui por dentro de <RequireSession>, que já garantiu o perfil.
  if (!profile) return <LoadingScreen />

  if (profile.role !== role) {
    return <Navigate to={homePathFor(profile.role)} replace />
  }

  return <Outlet />
}
