import { Check } from 'lucide-react'

import { DAY_STATE_LABELS } from '@/month/messages'
import { dayAndMonth, weekdayName } from '@/month/month'

import { MISSING_LABELS } from './messages'
import { missingReason, type DayOption } from './selection'

/*
 * Uma linha da tela 5: o dia, se ele entra, e o que ele é.
 *
 * A linha diz sempre o **porquê** quando o dia não pode entrar — "pendente",
 * "sem registro", "esperando enviar". Sem isso, a lista teria dias apagados e a
 * merendeira ficaria com a pergunta que este produto existe para responder: o
 * que falta antes de gerar?
 *
 * O dia já incluído em outro documento aparece marcado como tal e continua
 * selecionável: o bloqueio é sobre editar, não sobre sair de novo.
 */

/**
 * O rótulo da direita: o que falta no dia, ou o que ele tem.
 *
 * O dia pronto mostra quantas refeições descreve, como a E3 desenhou: nesta
 * tela ela está conferindo antes de mandar à prefeitura, e "3 refeições" é o
 * que responde a conferência — "preenchido" ela já sabe pelo próprio fato de
 * a linha estar selecionável. As outras palavras são as da visão do mês, sem
 * tradução no meio: um mesmo dia não muda de nome ao trocar de tela.
 */
function label(option: DayOption): string {
  const reason = missingReason(option)
  if (reason) return MISSING_LABELS[reason]
  if (option.state === 'complete') {
    return option.meals === 1 ? '1 refeição' : `${option.meals} refeições`
  }

  return DAY_STATE_LABELS[option.state]
}

export function DayOptionRow({
  option,
  selected,
  readOnly,
  onToggle,
}: {
  option: DayOption
  selected: boolean
  /** A escolha está num período inteiro: a linha mostra, mas não decide. */
  readOnly: boolean
  onToggle(): void
}) {
  const reason = missingReason(option)
  const dayNumber = Number(option.date.slice(-2))

  return (
    <button
      type="button"
      role="checkbox"
      aria-checked={selected}
      aria-label={`${dayAndMonth(option.date)}, ${label(option).toLowerCase()}`}
      disabled={readOnly || !option.eligible}
      onClick={onToggle}
      className="flex min-h-[3.5rem] items-center gap-3 border-b border-muted px-3.5 py-2 text-left last:border-b-0 not-disabled:hover:bg-muted/60 disabled:cursor-default disabled:opacity-60 aria-checked:disabled:opacity-100"
    >
      <span
        aria-hidden="true"
        className={`flex size-6 shrink-0 items-center justify-center rounded-md border-2 ${
          selected
            ? 'border-primary bg-primary text-primary-foreground'
            : 'border-input bg-card'
        }`}
      >
        {selected ? <Check className="size-3.5" strokeWidth={3} /> : null}
      </span>

      <span aria-hidden="true" className="flex-1 text-sm font-medium">
        {weekdayName(option.date)}, {dayNumber}
      </span>

      <span
        aria-hidden="true"
        className={`text-xs whitespace-nowrap ${
          reason === null ? 'text-muted-foreground' : 'text-warning'
        }`}
      >
        {label(option)}
      </span>
    </button>
  )
}
