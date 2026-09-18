import { ArrowLeft } from 'lucide-react'
import { Link } from 'react-router'

import { Button } from '@/components/ui/button'
import { ROUTES } from '@/routes'

/*
 * O destino que ainda não existe.
 *
 * A visão do mês e o menu ficaram prontos antes das telas para onde apontam, e
 * um caminho que não leva a lugar nenhum é pior do que um que leva a uma tela
 * dizendo de quem ela é: assim a navegação da issue #61 é verificável de ponta
 * a ponta hoje, e cada issue seguinte substitui um arquivo destes.
 *
 * O mesmo recurso que a issue #59 usou para a visão do mês, que era isto aqui
 * até esta issue.
 */
export function PendingScreen({
  title,
  issue,
  children,
}: {
  title: string
  issue: number
  children: React.ReactNode
}) {
  return (
    <div className="flex min-h-dvh flex-col bg-background">
      <header className="flex items-center gap-1 border-b border-border bg-card p-2">
        <Button variant="ghost" size="icon" asChild>
          <Link to={ROUTES.cookHome} aria-label="Voltar para a visão do mês">
            <ArrowLeft aria-hidden="true" />
          </Link>
        </Button>
        <h1 className="text-xl font-semibold">{title}</h1>
      </header>

      <main className="mx-auto flex w-full max-w-screen flex-1 flex-col justify-center gap-2 px-4 py-6 text-center">
        <p className="text-base text-muted-foreground">{children}</p>
        <p className="text-sm text-muted-foreground">
          Esta tela entra na issue #{issue}.
        </p>
      </main>
    </div>
  )
}
