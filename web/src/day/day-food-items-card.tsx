import { useId } from 'react'
import { ChevronRight, Replace } from 'lucide-react'

import { Button } from '@/components/ui/button'
import { quantityLabel } from '@/food-items/catalog'
import type { DayPayload, MenuChangePayload } from '@/local/day'
import { dayHasFoodItems } from '@/month/month'

import { FoodItemList, type FoodItemActions } from './food-item-list'
import { MealBadge } from './meal-badge'
import {
  DAY_MESSAGES,
  FOOD_ITEMS_STATE_LABELS,
  MENU_CHANGE_MESSAGES,
} from './messages'
import { menuChangeIsComplete } from './register'

/*
 * Os gêneros do dia (decisão 14 da E4).
 *
 * Vêm depois das três refeições porque é a ordem em que ela trabalha: primeiro
 * o que foi servido, depois o que saiu da despensa para servir. É um cartão
 * só, e não um por refeição, porque é como ela confere — pelo dia — e é como o
 * documento imprime, numa célula por dia.
 *
 * A alteração do cardápio é o último bloco, porque também é gênero: o que
 * entrou no lugar do previsto. Enquanto não houver troca, ela é só um botão —
 * registrada, vira um resumo do que entrou e do motivo, dentro do próprio
 * cartão, porque é isso que sai impresso e ela precisa conferir sem abrir a
 * tela 3a no escuro (decisão 8 da E3).
 *
 * O cartão não fecha, ao contrário dos das refeições: é o que ela mais mexe
 * depois de abrir o dia, e fechado ele esconderia justamente a lista que ela
 * está montando.
 */
export function DayFoodItemsCard({
  day,
  readOnly,
  foodItems,
  onOpenMenuChange,
}: {
  day: DayPayload
  readOnly: boolean
  foodItems: FoodItemActions
  onOpenMenuChange(): void
}) {
  const titleId = useId()
  const change = day.menu_change

  return (
    <section
      aria-labelledby={titleId}
      className="flex flex-col gap-4 rounded-xl border border-border bg-card px-3.5 pt-3 pb-4"
    >
      <div className="flex min-h-[2.125rem] items-center gap-2.5">
        <h2 id={titleId} className="flex-1 text-lg font-semibold">
          {DAY_MESSAGES.foodItemsTitle}
        </h2>
        <MealBadge
          state={dayHasFoodItems(day) ? 'complete' : 'empty'}
          labels={FOOD_ITEMS_STATE_LABELS}
        />
      </div>

      <div role="group" aria-label={DAY_MESSAGES.foodItemsLabel}>
        <FoodItemList
          items={day.food_items}
          readOnly={readOnly}
          actions={foodItems}
        />
      </div>

      {change ? (
        <MenuChangeSummary change={change} onOpen={onOpenMenuChange} />
      ) : readOnly ? null : (
        <Button type="button" variant="outline" onClick={onOpenMenuChange}>
          <Replace aria-hidden="true" />
          {DAY_MESSAGES.menuChange}
        </Button>
      )}
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
