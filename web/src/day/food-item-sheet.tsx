import { useId, useState } from 'react'
import { CircleAlert, LoaderCircle, Search, X } from 'lucide-react'

import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import {
  Sheet,
  SheetClose,
  SheetContent,
  SheetDescription,
  SheetTitle,
} from '@/components/ui/sheet'
import {
  isAlreadyChosen,
  matchesSearch,
  UNIT_SUGGESTIONS,
  type FoodItem,
} from '@/food-items/catalog'
import { useFoodItems } from '@/food-items/queries'
import type { FoodItemPayload, MealType } from '@/local/day'

import { FOOD_ITEM_SHEET_MESSAGES, mealSubtitle } from './messages'

/*
 * Escolher gênero — tela 3b (US009, US003).
 *
 * Uma folha que sobe sobre o registro, e não uma tela de destino: mandar a
 * merendeira ao catálogo no meio de uma refeição é literalmente sair do fluxo
 * — ela perderia o lugar, e o item cadastrado lá não se prenderia sozinho à
 * refeição (decisão 7 da E3). Por isso o cadastro de um gênero novo mora aqui
 * dentro, no fim da lista: o pior caso vira dois gestos, e o gênero escolhido
 * entra na refeição já com a quantidade em 1.
 *
 * O gênero cadastrado aqui nasce de verdade no envio, não agora: `save_meal_map`
 * cria no catálogo o que ainda não existir, na mesma operação que grava o dia.
 * É o que permite cadastrar sem rede.
 *
 * Quem a abre a monta, e quem a fecha a desmonta — por isso a busca e o
 * cadastro começam em branco a cada abertura, sem nada a limpar.
 */
export function FoodItemSheet({
  open,
  type,
  mapDate,
  chosen,
  onOpenChange,
  onChoose,
}: {
  open: boolean
  type: MealType
  mapDate: string
  /** Os nomes normalizados que já estão na lista de destino. */
  chosen: string[]
  onOpenChange(open: boolean): void
  onChoose(item: Omit<FoodItemPayload, 'quantity'>): void
}) {
  const searchId = useId()
  const nameId = useId()
  const unitId = useId()
  const [search, setSearch] = useState('')
  /** Nulo enquanto ela não mexeu no campo: aí vale o que está na busca. */
  const [typedName, setTypedName] = useState<string | null>(null)
  const [unit, setUnit] = useState<string | null>(null)
  const catalog = useFoodItems()

  const found = (catalog.data ?? []).filter((item) =>
    matchesSearch(item, search)
  )
  const newName = typedName ?? search
  const canAdd = newName.trim() !== '' && unit !== null

  function choose(item: FoodItem) {
    onChoose({
      food_item_id: item.id,
      name: item.name,
      unit: item.default_unit,
    })
    onOpenChange(false)
  }

  function create() {
    if (!canAdd) return

    onChoose({ food_item_id: null, name: newName.trim(), unit })
    onOpenChange(false)
  }

  return (
    <Sheet open={open} onOpenChange={onOpenChange}>
      <SheetContent side="bottom" className="gap-0 pb-4">
        <div className="flex items-start gap-2 px-4 pt-3 pb-3">
          <div className="flex min-w-0 flex-1 flex-col gap-0.5">
            <SheetTitle>{FOOD_ITEM_SHEET_MESSAGES.title}</SheetTitle>
            <SheetDescription>{mealSubtitle(type, mapDate)}</SheetDescription>
          </div>

          <SheetClose asChild>
            <Button
              variant="ghost"
              size="icon"
              aria-label={FOOD_ITEM_SHEET_MESSAGES.close}
            >
              <X aria-hidden="true" />
            </Button>
          </SheetClose>
        </div>

        <div className="relative px-4 pb-3">
          <Search
            aria-hidden="true"
            className="pointer-events-none absolute top-1/2 left-7 size-4.5 -translate-y-1/2 text-muted-foreground"
          />
          <Input
            id={searchId}
            type="search"
            aria-label={FOOD_ITEM_SHEET_MESSAGES.search}
            placeholder={FOOD_ITEM_SHEET_MESSAGES.search}
            value={search}
            onChange={(event) => setSearch(event.target.value)}
            className="pl-10"
          />
        </div>

        <div className="flex flex-col border-t border-muted px-4">
          {catalog.isPending ? (
            <p
              role="status"
              className="flex items-center gap-2 py-4 text-sm text-muted-foreground"
            >
              <LoaderCircle
                className="size-4 animate-spin"
                aria-hidden="true"
              />
              {FOOD_ITEM_SHEET_MESSAGES.loading}
            </p>
          ) : catalog.isError ? (
            <p
              role="status"
              className="flex items-start gap-2 py-4 text-sm text-muted-foreground"
            >
              <CircleAlert
                className="mt-0.5 size-4 shrink-0"
                aria-hidden="true"
              />
              {FOOD_ITEM_SHEET_MESSAGES.loadFailed}
            </p>
          ) : found.length === 0 ? (
            <p className="py-4 text-sm text-muted-foreground">
              {FOOD_ITEM_SHEET_MESSAGES.noResults}
            </p>
          ) : (
            found.map((item) => {
              const already = isAlreadyChosen(item, chosen)

              return (
                <button
                  key={item.id}
                  type="button"
                  disabled={already}
                  onClick={() => choose(item)}
                  className="flex min-h-touch items-center gap-3 border-b border-muted py-2 text-left last:border-b-0 disabled:opacity-50"
                >
                  <span className="flex-1 truncate text-sm font-medium">
                    {item.name}
                  </span>
                  <span className="rounded-full border border-border bg-muted px-2.5 py-0.5 text-2xs font-medium text-muted-foreground">
                    {already
                      ? FOOD_ITEM_SHEET_MESSAGES.alreadyChosen
                      : item.default_unit}
                  </span>
                </button>
              )
            })
          )}
        </div>

        <div className="mx-4 mt-3 flex flex-col gap-3 rounded-xl border border-accent-border bg-accent p-3.5">
          <div className="flex flex-col gap-0.5">
            <span className="text-sm font-semibold">
              {FOOD_ITEM_SHEET_MESSAGES.newTitle}
            </span>
            <span className="text-xs text-accent-foreground">
              {FOOD_ITEM_SHEET_MESSAGES.newHint}
            </span>
          </div>

          <div className="flex flex-col gap-1.5">
            <Label htmlFor={nameId} className="sr-only">
              {FOOD_ITEM_SHEET_MESSAGES.newNameLabel}
            </Label>
            <Input
              id={nameId}
              placeholder={FOOD_ITEM_SHEET_MESSAGES.newNamePlaceholder}
              value={newName}
              onChange={(event) => setTypedName(event.target.value)}
            />
          </div>

          <div className="flex flex-col gap-2">
            <span id={unitId} className="text-xs font-medium">
              {FOOD_ITEM_SHEET_MESSAGES.newUnitLabel}
            </span>
            <div
              role="group"
              aria-labelledby={unitId}
              className="flex flex-wrap gap-2"
            >
              {UNIT_SUGGESTIONS.map((one) => (
                <Button
                  key={one}
                  type="button"
                  size="sm"
                  variant={unit === one ? 'default' : 'outline'}
                  aria-pressed={unit === one}
                  onClick={() => setUnit(one)}
                  className="rounded-full"
                >
                  {one}
                </Button>
              ))}
            </div>
          </div>

          <Button type="button" disabled={!canAdd} onClick={create}>
            {FOOD_ITEM_SHEET_MESSAGES.add}
          </Button>
        </div>
      </SheetContent>
    </Sheet>
  )
}
