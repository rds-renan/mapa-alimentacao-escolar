import { MEAL_STATE_LABELS } from './messages'
import type { MealState } from './register'

/*
 * O estado de cada refeição, no cabeçalho do cartão — é o que ela lê com os
 * três cartões fechados para saber onde parou.
 *
 * Aqui a etiqueta leva o texto junto, e não só a cor: são as mesmas cores da
 * visão do mês, e a palavra é o que as separa quando a tela está lavada de luz
 * na bancada da cozinha.
 */

const APPEARANCE: Record<MealState, string> = {
  complete: 'border-success-border bg-success-subtle text-success',
  pending: 'border-warning-border bg-warning-subtle text-warning',
  empty: 'border-border bg-muted text-muted-foreground',
}

export function MealBadge({ state }: { state: MealState }) {
  return (
    <span
      data-slot="meal-badge"
      data-state={state}
      className={`inline-flex shrink-0 items-center rounded-full border px-2.5 py-1 text-2xs font-medium whitespace-nowrap ${APPEARANCE[state]}`}
    >
      {MEAL_STATE_LABELS[state]}
    </span>
  )
}
