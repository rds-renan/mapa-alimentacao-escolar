import { Link } from 'react-router'

import { dayPath } from '@/routes'

import { DayBadge, ReopenedBadge } from './day-badge'
import { DAY_STATE_LABELS, REOPENED_LABEL } from './messages'
import {
  dayAndMonth,
  daySummary,
  dayState,
  weekdayLabel,
  type DayRecord,
} from './month'

/*
 * Uma linha da lista: o dia, o que ele tem (ou o que falta nele) e o estado.
 *
 * A linha inteira é o toque — não um botão dentro dela (CA#2 da US008). É um
 * link e não um `button` de propósito: o destino é um endereço, e isso faz o
 * "abrir em nova aba" e o voltar do navegador funcionarem sem código nosso.
 *
 * Dia bloqueado também abre. Ele é somente leitura, não inalcançável: é
 * exatamente o dia que ela vai querer conferir depois de gerar o documento.
 */
export function DayRow({
  date,
  record,
  isToday,
}: {
  date: string
  record: DayRecord | undefined
  isToday: boolean
}) {
  const state = dayState(record)
  const summary = daySummary(record, { isToday })
  const dayNumber = Number(date.slice(-2))
  const reopened = record?.reopened ?? false

  return (
    <Link
      to={dayPath(date)}
      aria-label={`${dayAndMonth(date)}, ${DAY_STATE_LABELS[state].toLowerCase()}${
        reopened ? `, ${REOPENED_LABEL.toLowerCase()} para correção` : ''
      }. ${summary}`}
      className={`flex min-h-[3.625rem] items-center gap-3 border-b border-muted px-3.5 py-2 last:border-b-0 hover:bg-muted/60 ${
        isToday ? 'bg-accent/45' : ''
      }`}
    >
      <span
        aria-hidden="true"
        className="flex w-10.5 shrink-0 flex-col items-center"
      >
        <span
          className={`text-2xs font-medium uppercase ${isToday ? 'text-primary' : 'text-muted-foreground'}`}
        >
          {weekdayLabel(date)}
        </span>
        <span
          className={`text-xl font-semibold ${isToday ? 'text-primary' : ''}`}
        >
          {dayNumber}
        </span>
      </span>

      <span
        aria-hidden="true"
        className={`flex-1 text-sm ${state === 'empty' ? 'text-muted-foreground/75' : 'text-muted-foreground'}`}
      >
        {summary}
      </span>

      {reopened ? <ReopenedBadge /> : null}
      <DayBadge state={state} />
    </Link>
  )
}
