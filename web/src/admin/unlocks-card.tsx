import { CircleAlert, LoaderCircle, LockOpen } from 'lucide-react'

import { Button } from '@/components/ui/button'

import { dayLabel, unlockedByLabel, UNLOCKS_MESSAGES } from './messages'
import { useMapUnlocks, type MapUnlock } from './maps-queries'

/*
 * O histórico de reaberturas (CA#3 e RNF#1 da US023).
 *
 * Ele é permanente porque o banco não tem como ele deixar de ser: em
 * `meal_map_unlock` não existe política de insert, update nem delete — quem
 * grava é `unlock_meal_map()`, e o navegador só lê. Esta tela é o "consultável"
 * da regra; o "permanente" não depende dela.
 *
 * A justificativa aparece aqui, na área da direção, e **não** na tela da
 * merendeira: foi decisão de escopo que o texto continue sendo prestação de
 * contas, e não recado. Na tela dela o que aparece é o fato — o dia foi
 * reaberto para correção — e quem diz o que corrigir é a direção, por fora do
 * sistema, como já acontece hoje.
 */
export function UnlocksCard() {
  const unlocks = useMapUnlocks()

  return (
    <section
      aria-labelledby="unlocks-title"
      className="flex flex-col overflow-hidden rounded-xl border border-border bg-card"
    >
      <div className="flex flex-wrap items-center gap-3 border-b border-muted px-4 py-3.5">
        <hgroup className="flex min-w-0 flex-1 flex-col gap-0.5">
          <h2 id="unlocks-title" className="text-base font-semibold">
            {UNLOCKS_MESSAGES.title}
          </h2>
          <p className="text-xs text-muted-foreground">
            {UNLOCKS_MESSAGES.subtitle}
          </p>
        </hgroup>
      </div>

      {unlocks.isPending ? (
        <p
          role="status"
          className="flex items-center gap-2 px-4 py-6 text-sm text-muted-foreground"
        >
          <LoaderCircle className="size-4 animate-spin" aria-hidden="true" />
          {UNLOCKS_MESSAGES.loading}
        </p>
      ) : unlocks.isError ? (
        <div role="alert" className="flex flex-col gap-3 px-4 py-6">
          <p className="flex items-start gap-2 text-sm text-muted-foreground">
            <CircleAlert
              className="mt-0.5 size-4 shrink-0"
              aria-hidden="true"
            />
            {UNLOCKS_MESSAGES.loadFailed}
          </p>
          <Button
            variant="outline"
            className="self-start"
            onClick={() => void unlocks.refetch()}
          >
            {UNLOCKS_MESSAGES.retry}
          </Button>
        </div>
      ) : unlocks.data.length === 0 ? (
        <p className="px-4 py-6 text-sm text-muted-foreground">
          {UNLOCKS_MESSAGES.empty}
        </p>
      ) : (
        <ul className="flex flex-col">
          {unlocks.data.map((unlock) => (
            <UnlockRow key={unlock.id} unlock={unlock} />
          ))}
        </ul>
      )}
    </section>
  )
}

/** Uma reabertura: de qual dia, por quem, quando e por quê. */
function UnlockRow({ unlock }: { unlock: MapUnlock }) {
  return (
    <li className="flex gap-2.5 border-b border-muted px-4 py-3 last:border-b-0">
      <LockOpen
        className="mt-0.5 size-4 shrink-0 text-muted-foreground"
        aria-hidden="true"
      />

      <div className="flex min-w-0 flex-col gap-0.5">
        <span className="text-sm font-medium">
          {unlock.mapDate ? dayLabel(unlock.mapDate) : UNLOCKS_MESSAGES.title}
        </span>
        <span className="text-xs text-muted-foreground">
          {unlockedByLabel(unlock.unlockedBy, unlock.unlockedAt)}
        </span>
        {/*
         * A justificativa como ela foi escrita, e entre aspas: é citação de
         * alguém, não texto do sistema.
         */}
        <p className="text-sm text-secondary-foreground">“{unlock.reason}”</p>
      </div>
    </li>
  )
}
