import { Info } from 'lucide-react'

import { Button } from '@/components/ui/button'

import { useSync } from './useSync'

/*
 * O aviso de que o dia foi registrado em outro aparelho depois da edição que
 * estava subindo.
 *
 * Existe porque a convergência **nunca** se resolve em silêncio: prevalece a
 * edição mais recente, por decisão, e a usuária é avisada de que aquilo
 * aconteceu (decisão 5 da E5, CA#3 da US011). Ele não some sozinho — some
 * quando ela diz que leu.
 */
export function ConflictNotice() {
  const { state, dismissConflict } = useSync()

  if (state.conflicts.length === 0) return null

  return (
    <div className="flex flex-col gap-2 border-b border-accent-border bg-accent px-4 py-3">
      {state.conflicts.map((conflict) => (
        <div
          key={conflict.mapDate}
          role="alert"
          className="flex items-start gap-2 text-sm text-accent-foreground"
        >
          <Info className="mt-0.5 size-4 shrink-0" aria-hidden="true" />
          <span className="flex-1">{conflict.message}</span>
          <Button
            variant="ghost"
            size="sm"
            onClick={() => dismissConflict(conflict.mapDate)}
          >
            Entendi
          </Button>
        </div>
      ))}
    </div>
  )
}
