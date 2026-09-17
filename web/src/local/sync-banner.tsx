import { CircleAlert, CircleCheck, Smartphone } from 'lucide-react'

import type { DaySyncState } from './sync'

/*
 * A faixa de salvamento da decisão 3 da E3: não há botão "Salvar", e é esta
 * faixa que diz em que pé está o registro. Três estados, três frases fixas —
 * e a frase de falha afirma, antes de qualquer coisa, que nada foi perdido,
 * porque é essa a ansiedade real.
 *
 * `detail` é a frase que o servidor mandou quando a recusa tem explicação
 * própria — quantidade inválida, mapa já dentro de um documento gerado. Ela
 * vem pronta para ser lida por quem vai lê-la: não há tradução a fazer aqui.
 */

const APPEARANCE: Record<
  DaySyncState['status'],
  { icon: typeof Smartphone; className: string }
> = {
  pending: {
    icon: Smartphone,
    className: 'bg-muted text-muted-foreground border-border',
  },
  sent: {
    icon: CircleCheck,
    className: 'bg-success-subtle text-success border-success-border',
  },
  failed: {
    icon: CircleAlert,
    className: 'bg-warning-subtle text-warning border-warning-border',
  },
}

export function SyncBanner({ status }: { status: DaySyncState | null }) {
  // Dia que ela ainda não tocou nesta sessão não tem o que dizer: afirmar
  // "enviado" antes da primeira tecla seria a faixa mentindo.
  if (!status) return null

  const { icon: Icon, className } = APPEARANCE[status.status]

  return (
    <p
      // `status` e não `alert`: a faixa muda sozinha o tempo todo, e interromper
      // o leitor de tela a cada mudança de estado seria insuportável.
      role="status"
      className={`flex items-start gap-2 border-b px-4 py-2.5 text-sm ${className}`}
    >
      <Icon className="mt-0.5 size-4 shrink-0" aria-hidden="true" />
      <span>
        {status.message}
        {status.detail ? <> {status.detail}</> : null}
      </span>
    </p>
  )
}
