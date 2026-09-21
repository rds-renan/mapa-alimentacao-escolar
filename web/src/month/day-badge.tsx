import {
  CalendarOff,
  CircleCheck,
  CircleDashed,
  Clock,
  Lock,
  LockOpen,
} from 'lucide-react'

import { DAY_STATE_LABELS, REOPENED_LABEL } from './messages'
import type { DayState } from './month'

/*
 * O estado do dia, em cor **e** ícone — nunca só em cor (RNF#1 da US008).
 *
 * Não é acessibilidade de formulário preenchido: quem lê esta lista pode estar
 * na cozinha, com o celular na bancada e a tela lavada de luz, e "no documento"
 * e "vazio" partilham o mesmo cinza de propósito, como no desenho da E3. O que
 * separa os dois é o cadeado, e é ele que precisa ser legível.
 */

const APPEARANCE: Record<DayState, { icon: typeof Clock; className: string }> =
  {
    complete: {
      icon: CircleCheck,
      className: 'border-success-border bg-success-subtle text-success',
    },
    pending: {
      icon: Clock,
      className: 'border-warning-border bg-warning-subtle text-warning',
    },
    non_school: {
      icon: CalendarOff,
      className: 'border-accent-border bg-accent text-accent-foreground',
    },
    locked: {
      icon: Lock,
      className: 'border-border bg-muted text-muted-foreground',
    },
    empty: {
      icon: CircleDashed,
      className: 'border-border bg-muted text-muted-foreground',
    },
  }

export function DayBadge({ state }: { state: DayState }) {
  const { icon: Icon, className } = APPEARANCE[state]

  return (
    <span
      data-slot="day-badge"
      data-state={state}
      // O rótulo já é dito na etiqueta de acessibilidade da linha inteira:
      // repeti-lo aqui faria o leitor de tela anunciar "Pendente" duas vezes.
      aria-hidden="true"
      className={`inline-flex shrink-0 items-center gap-1.5 rounded-full border px-2.5 py-1 text-2xs font-medium whitespace-nowrap ${className}`}
    >
      <Icon className="size-3.5" />
      {DAY_STATE_LABELS[state]}
    </span>
  )
}

/*
 * O dia reaberto pela direção (CA#2 da US023).
 *
 * Vem ao lado da etiqueta de estado, e não no lugar dela: o dia reaberto
 * continua completo ou pendente, e o que ele tem de diferente é ser o dia que
 * voltou para a mão dela. Mesma regra da etiqueta ao lado — cor **e** ícone —,
 * e o cadeado aberto é de propósito o mesmo cadeado do "no documento", do outro
 * lado.
 */
export function ReopenedBadge() {
  return (
    <span
      data-slot="reopened-badge"
      aria-hidden="true"
      className="inline-flex shrink-0 items-center gap-1.5 rounded-full border border-warning-border bg-warning-subtle px-2.5 py-1 text-2xs font-medium whitespace-nowrap text-warning"
    >
      <LockOpen className="size-3.5" />
      {REOPENED_LABEL}
    </span>
  )
}
