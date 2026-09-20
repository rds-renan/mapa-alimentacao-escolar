import { TriangleAlert } from 'lucide-react'

import { dayAndMonth } from '@/month/month'

import { MISSING_LABELS, missingTitle, SELECTION_MESSAGES } from './messages'
import { missingReason, type DayOption } from './selection'

/*
 * O aviso de que o período não fecha — o CA#3 da US012 levado além do que ele
 * pedia.
 *
 * A história pedia que os dias pendentes fossem *apontados* antes da geração.
 * A decisão do projeto foi mais dura: mapa pendente não vai para a prefeitura,
 * então o atalho de semana ou de mês **não seleciona nada** quando o período
 * tem buraco. Se ele selecionasse "o que dá", o documento sairia com dias
 * faltando e os mapas incluídos ficariam bloqueados — o preço do engano é alto
 * demais para uma seleção que ela fez com um toque.
 *
 * Por isso o aviso nomeia dia por dia. Ele é a lista de tarefas que separa a
 * merendeira do documento, e serve de nada dizer só "há pendências".
 */
export function MissingNotice({
  scope,
  missing,
}: {
  /** O período, em português: "setembro", "a semana 2". */
  scope: string
  missing: DayOption[]
}) {
  return (
    <div
      role="status"
      className="flex flex-col gap-2 rounded-lg border border-warning-border bg-warning-subtle px-3.5 py-3 text-warning"
    >
      <p className="flex items-start gap-2 text-sm font-medium">
        <TriangleAlert className="mt-0.5 size-4 shrink-0" aria-hidden="true" />
        {missingTitle(scope, missing.length)}
      </p>

      <ul className="flex flex-col gap-1 pl-6 text-xs">
        {missing.map((option) => (
          <li key={option.date}>
            {dayAndMonth(option.date)} ·{' '}
            {MISSING_LABELS[missingReason(option)!].toLowerCase()}
          </li>
        ))}
      </ul>

      <p className="pl-6 text-xs">{SELECTION_MESSAGES.pickByHand}</p>
    </div>
  )
}
