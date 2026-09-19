import { useId } from 'react'
import { Minus, Plus } from 'lucide-react'

import { Button } from '@/components/ui/button'
import { Card, CardContent } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'

import { DAY_MESSAGES } from './messages'
import { parseMealsServed, stepMealsServed } from './register'

/*
 * O número de refeições do dia (US005).
 *
 * Um campo só, do dia inteiro, e não um por refeição: na escola integral as
 * crianças ficam o dia todo, e o número vem das professoras para a direção e
 * da direção para a cozinha — é um número, e é do dia (RN#1).
 *
 * O campo é numérico e os dois botões existem para a correção de um a mais ou
 * um a menos, que é o ajuste que acontece; digitar 312 no stepper seria
 * absurdo, e por isso o número no meio é o campo de verdade, com teclado
 * numérico (RNF#1).
 */
export function MealsServedCard({
  value,
  readOnly,
  onChange,
}: {
  value: number | null
  readOnly: boolean
  onChange(value: number | null): void
}) {
  const fieldId = useId()
  const hintId = useId()

  return (
    <Card>
      <CardContent className="flex flex-col gap-3">
        <div className="flex flex-col gap-0.5">
          <Label htmlFor={fieldId} className="text-lg font-semibold">
            {DAY_MESSAGES.mealsServedTitle}
          </Label>
          <span id={hintId} className="text-xs text-muted-foreground">
            {DAY_MESSAGES.mealsServedHint}
          </span>
        </div>

        <div className="flex items-center gap-3">
          <Button
            type="button"
            variant="outline"
            size="icon"
            aria-label={DAY_MESSAGES.mealsServedLess}
            disabled={readOnly || value === null}
            onClick={() => onChange(stepMealsServed(value, -1))}
          >
            <Minus aria-hidden="true" />
          </Button>

          <Input
            id={fieldId}
            // `text` e não `number`: o campo numérico do navegador aceita
            // sinal, ponto e notação científica, e ainda some com o que ele
            // considera inválido enquanto ela digita.
            type="text"
            inputMode="numeric"
            aria-describedby={hintId}
            disabled={readOnly}
            value={value === null ? '' : String(value)}
            onChange={(event) => onChange(parseMealsServed(event.target.value))}
            className="flex-1 text-center text-2xl font-semibold tabular-nums md:text-2xl"
          />

          <Button
            type="button"
            variant="outline"
            size="icon"
            aria-label={DAY_MESSAGES.mealsServedMore}
            disabled={readOnly}
            onClick={() => onChange(stepMealsServed(value, 1))}
          >
            <Plus aria-hidden="true" />
          </Button>
        </div>
      </CardContent>
    </Card>
  )
}
