import { useId } from 'react'
import { ChevronDown } from 'lucide-react'

import { Label } from '@/components/ui/label'
import { Textarea } from '@/components/ui/textarea'
import type { AcceptanceLevel, MealPayload, MealType } from '@/local/day'

import { AcceptanceChoice } from './acceptance-choice'
import { MealBadge } from './meal-badge'
import { DAY_MESSAGES, MEAL_TITLES } from './messages'
import { mealState } from './register'

/*
 * O cartão de uma refeição (decisão 5 da E3).
 *
 * As três refeições ficam numa tela só, em cartões que abrem e fecham: uma
 * tela por refeição triplicaria a navegação de um fluxo que precisa caber na
 * rotina, e o registro de um dia comum tem de terminar em menos de dois
 * minutos (RNF#1 da US001). Fechado, o cartão ainda diz o que foi servido e em
 * que pé está — é assim que ela acha, de relance, onde o trabalho parou.
 *
 * Gêneros utilizados e alteração do cardápio entram aqui na issue #63. Ficam
 * fora, e não desabilitados: botão que não faz nada é promessa falsa.
 */
export function MealCard({
  type,
  meal,
  open,
  readOnly,
  onOpenChange,
  onDescriptionChange,
  onAcceptanceChange,
}: {
  type: MealType
  meal: MealPayload | undefined
  open: boolean
  readOnly: boolean
  onOpenChange(open: boolean): void
  onDescriptionChange(description: string): void
  onAcceptanceChange(acceptance: AcceptanceLevel): void
}) {
  const bodyId = useId()
  const descriptionId = useId()
  const acceptanceId = useId()
  const state = mealState(meal)
  const description = meal?.description ?? ''

  return (
    <section className="overflow-hidden rounded-xl border border-border bg-card">
      <button
        type="button"
        aria-expanded={open}
        aria-controls={bodyId}
        onClick={() => onOpenChange(!open)}
        className="flex min-h-[3.625rem] w-full items-center gap-2.5 px-3.5 py-3 text-left hover:bg-muted/50"
      >
        <span className="flex min-w-0 flex-1 flex-col gap-0.5">
          <span className="text-lg font-semibold">{MEAL_TITLES[type]}</span>
          {!open && description.trim() !== '' ? (
            <span className="truncate text-xs text-muted-foreground">
              {description}
            </span>
          ) : null}
        </span>

        <MealBadge state={state} />

        <ChevronDown
          aria-hidden="true"
          className={`size-4.5 shrink-0 text-muted-foreground transition-transform ${
            open ? 'rotate-180' : ''
          }`}
        />
      </button>

      {open ? (
        <div id={bodyId} className="flex flex-col gap-4 px-3.5 pt-0.5 pb-4">
          <div className="flex flex-col gap-1.5">
            <Label htmlFor={descriptionId} className="text-sm text-foreground">
              {DAY_MESSAGES.descriptionLabel}
            </Label>
            <Textarea
              id={descriptionId}
              rows={2}
              disabled={readOnly}
              placeholder={DAY_MESSAGES.descriptionPlaceholder}
              value={description}
              onChange={(event) => onDescriptionChange(event.target.value)}
            />
          </div>

          <div className="flex flex-col gap-1.5">
            <span id={acceptanceId} className="text-sm font-medium">
              {DAY_MESSAGES.acceptanceLabel}
            </span>
            <AcceptanceChoice
              value={meal?.acceptance ?? null}
              disabled={readOnly}
              labelledBy={acceptanceId}
              onChange={onAcceptanceChange}
            />
          </div>
        </div>
      ) : null}
    </section>
  )
}
