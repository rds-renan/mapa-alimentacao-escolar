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
} from '@/food-items/catalog'
import { useFoodItems } from '@/food-items/queries'
import { normalizedName, type FoodItemPayload } from '@/local/day'

import { FOOD_ITEM_SHEET_MESSAGES, dayTitle } from './messages'

/*
 * Escolher gênero — tela 3b (US009, US003).
 *
 * Uma folha que sobe sobre o registro, e não uma tela de destino: mandar a
 * merendeira ao catálogo no meio do registro é literalmente sair do fluxo
 * — ela perderia o lugar, e o item cadastrado lá não se prenderia sozinho ao
 * dia (decisão 7 da E3). Por isso o cadastro de um gênero novo mora aqui
 * dentro, no fim da lista, e o gênero escolhido entra no dia já com a
 * quantidade em 1.
 *
 * **Ela marca vários e adiciona de uma vez** (issue #173). Na medição da E7, o
 * que mais pesava no registro era repetir "Adicionar gênero → escolher →
 * voltar" para cada item. Por isso o toque na linha só marca, e o botão fixo
 * no rodapé põe todos os marcados no dia. O gênero cadastrado aqui entra
 * marcado, junto com os outros, e assim só um botão fecha a folha.
 *
 * O gênero cadastrado aqui nasce de verdade no envio, não agora: `save_meal_map`
 * cria no catálogo o que ainda não existir, na mesma operação que grava o dia.
 * É o que permite cadastrar sem rede.
 *
 * Quem a abre a monta, e quem a fecha a desmonta — por isso a busca e o
 * cadastro começam em branco a cada abertura, sem nada a limpar.
 */
type Choice = Omit<FoodItemPayload, 'quantity'>

export function FoodItemSheet({
  open,
  mapDate,
  chosen,
  onOpenChange,
  onAdd,
}: {
  open: boolean
  mapDate: string
  /** Os nomes normalizados que já estão na lista de destino. */
  chosen: string[]
  onOpenChange(open: boolean): void
  /** Os gêneros marcados, na ordem em que ela marcou. */
  onAdd(items: Choice[]): void
}) {
  const searchId = useId()
  const nameId = useId()
  const unitId = useId()
  const [search, setSearch] = useState('')
  /** Nulo enquanto ela não mexeu no campo: aí vale o que está na busca. */
  const [typedName, setTypedName] = useState<string | null>(null)
  const [unit, setUnit] = useState<string | null>(null)
  /*
   * O que ela marcou, pelo nome normalizado e na ordem em que marcou: os do
   * catálogo e os cadastrados aqui, que ainda não têm identificador.
   */
  const [marked, setMarked] = useState<Map<string, Choice>>(() => new Map())
  const catalog = useFoodItems()

  const found = (catalog.data ?? []).filter((item) =>
    matchesSearch(item, search)
  )
  const created = [...marked.values()].filter(
    (item) => item.food_item_id === null
  )
  const newName = typedName ?? search
  const canCreate = newName.trim() !== '' && unit !== null

  function toggle(key: string, item: Choice) {
    setMarked((current) => {
      const next = new Map(current)
      if (!next.delete(key)) next.set(key, item)
      return next
    })
  }

  /*
   * O gênero novo entra marcado e o cadastro volta ao começo, pronto para o
   * próximo. Se o nome já existe no catálogo, quem fica marcado é o do
   * catálogo: a gravação juntaria os dois pelo nome de qualquer jeito, e assim
   * a unidade que vale é a que já está lá.
   */
  function create() {
    if (!canCreate) return

    const name = newName.trim()
    const key = normalizedName(name)
    const existing = (catalog.data ?? []).find(
      (item) => normalizedName(item.name) === key
    )

    if (!chosen.includes(key)) {
      setMarked((current) =>
        new Map(current).set(
          key,
          existing
            ? {
                food_item_id: existing.id,
                name: existing.name,
                unit: existing.default_unit,
              }
            : { food_item_id: null, name, unit }
        )
      )
    }
    setSearch('')
    setTypedName(null)
    setUnit(null)
  }

  function add() {
    if (marked.size === 0) return

    onAdd([...marked.values()])
    onOpenChange(false)
  }

  return (
    <Sheet open={open} onOpenChange={onOpenChange}>
      <SheetContent side="bottom" className="gap-0">
        <div className="flex items-start gap-2 px-4 pt-3 pb-3">
          <div className="flex min-w-0 flex-1 flex-col gap-0.5">
            <SheetTitle>{FOOD_ITEM_SHEET_MESSAGES.title}</SheetTitle>
            <SheetDescription>{dayTitle(mapDate)}</SheetDescription>
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
          {/*
           * Os que ela cadastrou aqui ficam no alto, marcados, seja qual for a
           * busca: ainda não estão no catálogo, e é aqui que ela os desmarca.
           */}
          {created.map((item) => (
            <ChoiceRow
              key={`novo-${normalizedName(item.name)}`}
              name={item.name}
              unit={item.unit ?? ''}
              marked
              onToggle={() => toggle(normalizedName(item.name), item)}
            />
          ))}

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
              const key = normalizedName(item.name)

              return (
                <ChoiceRow
                  key={item.id}
                  name={item.name}
                  unit={item.default_unit}
                  already={isAlreadyChosen(item, chosen)}
                  marked={marked.has(key)}
                  onToggle={() =>
                    toggle(key, {
                      food_item_id: item.id,
                      name: item.name,
                      unit: item.default_unit,
                    })
                  }
                />
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

          <Button
            type="button"
            variant="outline"
            disabled={!canCreate}
            onClick={create}
          >
            {FOOD_ITEM_SHEET_MESSAGES.create}
          </Button>
        </div>

        {/*
         * Fixo embaixo, fora da rolagem: com a lista comprida, ela não precisa
         * descer até o fim para adicionar o que marcou.
         */}
        <div className="sticky bottom-0 mt-3 border-t border-border bg-card px-4 pt-3 pb-4">
          <Button
            type="button"
            className="w-full"
            disabled={marked.size === 0}
            onClick={add}
          >
            {FOOD_ITEM_SHEET_MESSAGES.add(marked.size)}
          </Button>
        </div>
      </SheetContent>
    </Sheet>
  )
}

/*
 * Uma linha da lista: a caixa de marcar, o nome e a unidade. O gênero que já
 * está no dia aparece marcado e apagado, com "já está aqui" no lugar da
 * unidade, e não se mexe.
 */
function ChoiceRow({
  name,
  unit,
  marked,
  already = false,
  onToggle,
}: {
  name: string
  unit: string
  marked: boolean
  already?: boolean
  onToggle(): void
}) {
  return (
    <label className="flex min-h-touch cursor-pointer items-center gap-3 border-b border-muted py-2 last:border-b-0 has-disabled:cursor-default has-disabled:opacity-50">
      <input
        type="checkbox"
        checked={already || marked}
        disabled={already}
        onChange={onToggle}
        className="size-4.5 shrink-0 accent-primary"
      />
      <span className="flex-1 truncate text-sm font-medium">{name}</span>
      <span className="rounded-full border border-border bg-muted px-2.5 py-0.5 text-2xs font-medium text-muted-foreground">
        {already ? FOOD_ITEM_SHEET_MESSAGES.alreadyChosen : unit}
      </span>
    </label>
  )
}
