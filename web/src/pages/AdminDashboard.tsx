import { useAuth } from '@/auth/useAuth'
import { SignOutButton } from '@/auth/sign-out-button'

/*
 * A tela-casa da direção. Igual à da merendeira em estado: o painel gerencial
 * é a issue #70 e a gestão é a #68. O que importa aqui é que o destino de
 * quem entra como direção **não** é o fluxo do mapa — são dois fluxos, e é
 * isso que as guardas de rota separam.
 */
export function AdminDashboard() {
  const { profile } = useAuth()

  return (
    <div className="flex min-h-dvh flex-col bg-background">
      <header className="flex items-center justify-between gap-3 border-b border-border bg-card px-4 py-3">
        <div className="flex items-center gap-2.5">
          <img src="/logo.png" alt="" className="size-8" />
          <div className="flex flex-col">
            <span className="text-lg font-semibold">MAE · Administração</span>
            <span className="text-2xs text-muted-foreground">
              {profile?.name}
            </span>
          </div>
        </div>
        <SignOutButton />
      </header>

      <main className="mx-auto flex w-full max-w-3xl flex-1 flex-col justify-center gap-2 px-6 py-6 text-center">
        <h1 className="text-2xl font-semibold">Painel</h1>
        <p className="text-base text-muted-foreground">
          O painel gerencial entra na issue #70 e a gestão de acessos, modelo
          oficial e dados da escola, na #68.
        </p>
      </main>
    </div>
  )
}
