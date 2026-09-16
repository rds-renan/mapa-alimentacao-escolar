import { CircleAlert, CircleCheck } from 'lucide-react'

/*
 * A mensagem que fica dentro da tela, no lugar onde a coisa aconteceu, e
 * permanece enquanto valer — a primeira família do catálogo de avisos da E3.
 * `role="alert"` é o que faz o leitor de tela anunciá-la sem que a pessoa
 * precise procurar o texto.
 */
export function FormMessage({
  id,
  kind = 'error',
  children,
}: {
  /** Para o campo apontar a mensagem com `aria-describedby`. */
  id?: string
  kind?: 'error' | 'success'
  children: React.ReactNode
}) {
  const Icon = kind === 'error' ? CircleAlert : CircleCheck

  return (
    <p
      id={id}
      role="alert"
      className={
        kind === 'error'
          ? 'flex items-start gap-2 text-sm text-destructive'
          : 'flex items-start gap-2 text-sm text-success'
      }
    >
      <Icon className="mt-0.5 size-4 shrink-0" aria-hidden="true" />
      <span>{children}</span>
    </p>
  )
}
