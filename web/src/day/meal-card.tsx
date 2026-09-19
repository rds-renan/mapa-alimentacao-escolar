import { useId } from 'react'
import { ChevronDown, ChevronRight, Replace } from 'lucide-react'

import { Button } from '@/components/ui/button'
import { Label } from '@/components/ui/label'
import { Textarea } from '@/components/ui/textarea'
import { quantityLabel } from '@/food-items/catalog'
import type {
  AcceptanceLevel,
  MealPayload,
  MealType,
  MenuChangePayload,
} from '@/local/day'

import { AcceptanceChoice } from './acceptance-choice'
import { FoodItemList, type FoodItemActions } from './food-item-list'
import { MealBadge } from './meal-badge'
import { DAY_MESSAGES, MENU_CHANGE_MESSAGES, MEAL_TITLES } from './messages'
import { mealState, menuChangeIsComplete } from './register'

/*
 * O cartão de uma refeição (decisão 5 da E3).
 *
 * As três refeições ficam numa tela só, em cartões que abrem e fecham: uma
 * tela por refeição triplicaria a navegação de um fluxo que precisa caber na
 * rotina, e o registro de um dia comum tem de terminar em menos de dois
 * minutos (RNF#1 da US001). Fechado, o cartão ainda diz o que foi servido e em
 * que pé está — é assim que ela acha, de relance, onde o trabalho parou.
 *
 * Os gêneros utilizados são opcionais (RN#3 da US001) e ficam abaixo da
 * aceitação; a alteração do cardápio é o último bloco. Enquanto não houver
 * troca, ela é só um botão — registrada, vira um resumo do que entrou e do
 * motivo, dentro do próprio cartão, porque é isso que sai impresso e ela
 * precisa conferir sem abrir a tela 3a no escuro (decisão 8 da E3).
 */
export function MealCard({
  type,
  meal,
  open,
  readOnly,
  foodItems,
  onOpenChange,
  onDescriptionChange,
  onAcceptanceChange,
  onOpenMenuChange,
}: {
  type: MealType
  meal: MealPayload | undefined
  open: boolean
  readOnly: boolean
  foodItems: FoodItemActions
  onOpenChange(open: boolean): void
  onDescriptionChange(description: string): void
  onAcceptanceChange(acceptance: AcceptanceLevel): void
  onOpenMenuChange(): void
}) {
  const bodyId = useId()
  const descriptionId = useId()
  const acceptanceId = useId()
  const foodItemsId = useId()
  const state = mealState(meal)
  const description = meal?.description ?? ''
  const change = meal?.menu_change ?? null

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

          <div className="flex flex-col gap-2">
            <span className="flex items-center gap-2">
              <span id={foodItemsId} className="text-sm font-medium">
                {DAY_MESSAGES.foodItemsLabel}
              </span>
              <span className="rounded-full border border-border px-2 py-0.5 text-2xs text-muted-foreground">
                {DAY_MESSAGES.foodItemsOptional}
              </span>
            </span>
            <div role="group" aria-labelledby={foodItemsId}>
              <FoodItemList
                items={meal?.food_items ?? []}
                readOnly={readOnly}
                actions={foodItems}
              />
            </div>
          </div>

          {change ? (
            <MenuChangeSummary change={change} onOpen={onOpenMenuChange} />
          ) : readOnly ? null : (
            <Button type="button" variant="outline" onClick={onOpenMenuChange}>
              <Replace aria-hidden="true" />
              {DAY_MESSAGES.menuChange}
            </Button>
          )}
        </div>
      ) : null}
    </section>
  )
}

/*
 * A alteração registrada, dentro do cartão: os gêneros que entraram e o
 * motivo, tocáveis para editar (decisão 8 da E3). É o que sai impresso — se
 * não aparecesse aqui, ela teria de abrir a tela 3a às cegas para lembrar o
 * que registrou.
 *
 * Faltando o motivo ou o gênero, a linha de baixo diz o que falta, com as
 * mesmas palavras da tela 3a: o dia fica guardado no aparelho até isso se
 * resolver, e essa é a única pista disso no cartão fechado.
 */
function MenuChangeSummary({
  change,
  onOpen,
}: {
  change: MenuChangePayload
  onOpen(): void
}) {
  const items = change.food_items
    .map(
      (item) =>
        `${quantityLabel(item.quantity, item.unit)} de ${item.name.toLowerCase()}`
    )
    .join(' · ')

  const missing = menuChangeIsComplete(change)
    ? null
    : change.food_items.length === 0
      ? MENU_CHANGE_MESSAGES.itemsMissing
      : MENU_CHANGE_MESSAGES.reasonMissing

  return (
    <div className="flex flex-col gap-1.5">
      <span className="text-sm font-medium">{DAY_MESSAGES.menuChange}</span>

      <button
        type="button"
        onClick={onOpen}
        className="flex min-h-touch items-center gap-2.5 rounded-lg border border-accent-border bg-accent px-3 py-2.5 text-left"
      >
        <span className="flex min-w-0 flex-1 flex-col gap-0.5">
          {items === '' ? null : (
            <span className="truncate text-sm font-medium">{items}</span>
          )}
          {change.reason.trim() === '' ? null : (
            <span className="truncate text-xs text-accent-foreground">
              {change.reason}
            </span>
          )}
        </span>
        <ChevronRight
          aria-hidden="true"
          className="size-4.5 shrink-0 text-primary"
        />
      </button>

      {missing ? (
        <span className="text-xs text-muted-foreground">{missing}</span>
      ) : null}
    </div>
  )
}
