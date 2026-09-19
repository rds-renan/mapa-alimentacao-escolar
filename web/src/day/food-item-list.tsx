import { useState } from 'react'
import { Minus, Plus } from 'lucide-react'

import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import type { FoodItemPayload } from '@/local/day'

import { DAY_MESSAGES } from './messages'
import { foodItemKey, parseQuantity } from './register'

/*
 * Os gêneros de uma lista, cada um com o seu stepper (decisão 2 da E3).
 *
 * É a mesma peça nos dois lugares em que a lista aparece: os gêneros da
 * refeição, no cartão, e os gêneros da troca, na tela 3a. São duas listas
 * porque alimentam colunas diferentes do documento (decisão 7 da E4) — mas o
 * gesto é um só, e desenhá-lo duas vezes faria as duas divergirem na primeira
 * correção.
 *
 * As quantidades reais são inteiros pequenos ("1 saco de leite em pó", "4
 * quilos de pão"), então o "−" e o "+" resolvem o caso comum num toque. O
 * número no meio é campo de verdade, com teclado numérico (RNF#1 da US003),
 * porque 12 potes não se alcançam a toques. A unidade vem do catálogo e não se
 * edita aqui: é ela que mantém as quantidades comparáveis entre as duas
 * merendeiras (RN#1 da US009).
 */

export interface FoodItemActions {
  add(): void
  step(key: string, delta: number): void
  setQuantity(key: string, quantity: number): void
}

export function FoodItemList({
  items,
  readOnly,
  actions,
}: {
  items: FoodItemPayload[]
  readOnly: boolean
  actions: FoodItemActions
}) {
  return (
    <div className="flex flex-col gap-2">
      {items.map((item) => (
        <FoodItemRow
          key={foodItemKey(item)}
          item={item}
          readOnly={readOnly}
          actions={actions}
        />
      ))}

      {readOnly ? null : (
        <Button
          type="button"
          variant="outline"
          onClick={actions.add}
          className="border-dashed text-muted-foreground"
        >
          <Plus aria-hidden="true" />
          {DAY_MESSAGES.addFoodItem}
        </Button>
      )}
    </div>
  )
}

function FoodItemRow({
  item,
  readOnly,
  actions,
}: {
  item: FoodItemPayload
  readOnly: boolean
  actions: FoodItemActions
}) {
  /*
   * O que está no campo enquanto ela o edita. Nulo é "mostre a quantidade
   * gravada"; um texto é o que ela está digitando, inclusive o vazio do
   * instante em que apagou o número para trocá-lo. Sem isto, apagar devolveria
   * 1 debaixo do dedo e o número seguinte sairia grudado nele.
   */
  const [typed, setTyped] = useState<string | null>(null)
  const key = foodItemKey(item)
  const last = item.quantity <= 1

  return (
    <div className="flex items-center gap-2.5 rounded-lg border border-border bg-card py-1.5 pr-1.5 pl-3">
      <span className="flex min-w-0 flex-1 flex-col">
        <span className="truncate text-sm font-medium">{item.name}</span>
        {item.unit ? (
          <span className="truncate text-xs text-muted-foreground">
            {item.unit}
          </span>
        ) : null}
      </span>

      <span className="flex items-center rounded-lg border border-border bg-muted/50 p-0.5">
        <Button
          type="button"
          variant="ghost"
          size="icon-sm"
          aria-label={DAY_MESSAGES.foodItemLess(item.name, last)}
          disabled={readOnly}
          onClick={() => actions.step(key, -1)}
        >
          <Minus aria-hidden="true" />
        </Button>

        <Input
          // `text` e não `number`, pela mesma razão do número de refeições: o
          // campo numérico do navegador aceita sinal, ponto e notação
          // científica, e some com o que ele considera inválido ao digitar.
          type="text"
          inputMode="numeric"
          aria-label={DAY_MESSAGES.foodItemQuantity(item.name, item.unit)}
          disabled={readOnly}
          value={typed ?? String(item.quantity)}
          onChange={(event) => {
            const quantity = parseQuantity(event.target.value)
            setTyped(quantity === null ? '' : String(quantity))
            if (quantity !== null) actions.setQuantity(key, quantity)
          }}
          onBlur={() => setTyped(null)}
          className="h-10 w-12 border-0 bg-transparent px-0 text-center text-base font-semibold tabular-nums shadow-none focus-visible:ring-0 md:text-base dark:bg-transparent"
        />

        <Button
          type="button"
          variant="ghost"
          size="icon-sm"
          aria-label={DAY_MESSAGES.foodItemMore(item.name)}
          disabled={readOnly}
          onClick={() => actions.step(key, 1)}
        >
          <Plus aria-hidden="true" />
        </Button>
      </span>
    </div>
  )
}
