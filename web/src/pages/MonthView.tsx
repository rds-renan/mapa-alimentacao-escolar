import { useAuth } from '@/auth/useAuth'
import { SignOutButton } from '@/auth/sign-out-button'

/*
 * A tela-casa da merendeira. O que está aqui é só o suficiente para a
 * autenticação ter destino: a visão do mês de verdade — estado de cada dia,
 * andamento e os dois caminhos — é a issue #61, e substitui este arquivo.
 */
export function MonthView() {
  const { profile } = useAuth()

  return (
    <div className="flex min-h-dvh flex-col bg-background">
      <header className="flex items-center justify-between gap-3 border-b border-border bg-card px-4 py-3">
        <div className="flex items-center gap-2.5">
          <img src="/logo.png" alt="" className="size-8" />
          <div className="flex flex-col">
            <span className="text-lg font-semibold">MAE</span>
            <span className="text-2xs text-muted-foreground">
              {profile?.name}
            </span>
          </div>
        </div>
        <SignOutButton />
      </header>

      <main className="mx-auto flex w-full max-w-screen flex-1 flex-col justify-center gap-2 px-4 py-6 text-center">
        <h1 className="text-xl font-semibold">Visão do mês</h1>
        <p className="text-base text-muted-foreground">
          Esta tela entra na issue #61. Por enquanto, o que existe é o caminho
          até aqui: entrar, continuar entrando amanhã sem redigitar a senha e
          sair.
        </p>
      </main>
    </div>
  )
}
