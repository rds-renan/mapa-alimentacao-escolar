import { LoaderCircle } from 'lucide-react'

/*
 * A espera enquanto a sessão guardada no aparelho é conferida. É curta por
 * construção — a sessão já está no aparelho —, mas sem ela a tela de login
 * piscaria na frente de quem já está logada.
 */
export function LoadingScreen() {
  return (
    <div
      role="status"
      className="flex min-h-dvh items-center justify-center bg-background text-muted-foreground"
    >
      <LoaderCircle className="size-6 animate-spin" />
      <span className="sr-only">Abrindo o MAE…</span>
    </div>
  )
}
