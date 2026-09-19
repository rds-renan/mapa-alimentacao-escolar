import { Button } from '@/components/ui/button'
import type { AcceptanceLevel } from '@/local/day'

import { ACCEPTANCE_LABELS, ACCEPTANCE_ORDER } from './messages'

/*
 * A aceitação em três botões (US004).
 *
 * Um toque, sem lista suspensa e sem digitar nada (RNF#1): a avaliação é
 * conhecimento que ela já tem — sobra, reação das crianças, repetições — e o
 * aplicativo só captura. Os três ocupam a linha inteira em partes iguais
 * porque nenhum é o padrão: escolher "Ruim" tem de ser tão fácil quanto
 * escolher "Ótimo".
 *
 * Tocar no que já está escolhido não desmarca. Um registro sem aceitação
 * existe (o dia pode ficar parcial), mas ninguém o faz de propósito com o dedo
 * — desmarcar aqui seria sempre acidente.
 */
export function AcceptanceChoice({
  value,
  disabled,
  labelledBy,
  onChange,
}: {
  value: AcceptanceLevel | null
  disabled?: boolean
  labelledBy: string
  onChange(acceptance: AcceptanceLevel): void
}) {
  return (
    <div role="group" aria-labelledby={labelledBy} className="flex gap-2">
      {ACCEPTANCE_ORDER.map((level) => {
        const chosen = value === level

        return (
          <Button
            key={level}
            type="button"
            size="lg"
            variant={chosen ? 'default' : 'outline'}
            aria-pressed={chosen}
            disabled={disabled}
            onClick={() => onChange(level)}
            className="h-[3.125rem] flex-1"
          >
            {ACCEPTANCE_LABELS[level]}
          </Button>
        )
      })}
    </div>
  )
}
