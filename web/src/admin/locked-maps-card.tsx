import { useState } from 'react'
import { CircleAlert, LoaderCircle, Lock } from 'lucide-react'

import { FormMessage } from '@/components/form-message'
import { Button } from '@/components/ui/button'
import { monthKeyOf, monthLabel } from '@/month/month'

import {
  dayLabel,
  inDocumentLabel,
  LOCKED_MAPS_MESSAGES,
  recentOnlyLabel,
  reopenedLabel,
  reopenLabel,
} from './messages'
import {
  RECENT_LOCKED,
  useLockedMaps,
  useReopenMap,
  type LockedMap,
} from './maps-queries'
import { ReopenDialog } from './reopen-dialog'

/*
 * Os dias que saíram em documento, e a reabertura de um deles (US023).
 *
 * A lista é de leitura: ela identifica o dia e diz em que documento ele foi
 * parar, e nada além disso. Não abre o mapa, não mostra o que está escrito
 * nele e não tem por onde editá-lo — a direção reabre, e quem corrige é a
 * merendeira (RN#1 da US023). Foi decisão explícita não dar à direção uma
 * leitura do mapa nesta issue: quem viu o erro foi a merendeira, e é ela que
 * pede a reabertura.
 *
 * Esta é a única ação de toda a administração que pede confirmação, e é a
 * mesma razão que dá a confirmação à geração do documento (decisão 11 da E3):
 * as outras têm volta na própria linha — desativar reativa, modelo se
 * substitui —, e esta não tem. O que ela deixa é registro permanente. Aqui a
 * confirmação também é o formulário: sem justificativa não há reabertura, e é
 * o banco que recusa, não a tela.
 */
export function LockedMapsCard() {
  const maps = useLockedMaps()
  const reopen = useReopenMap()

  /** Qual dia está com o diálogo aberto. */
  const [reopening, setReopening] = useState<LockedMap | null>(null)
  /** O que acabou de acontecer, dito no lugar onde aconteceu. */
  const [done, setDone] = useState<string | null>(null)

  function open(map: LockedMap) {
    setDone(null)
    reopen.reset()
    setReopening(map)
  }

  function close() {
    setReopening(null)
    reopen.reset()
  }

  function confirm(reason: string) {
    if (!reopening) return

    const label = dayLabel(reopening.mapDate)

    reopen.mutate(
      { mapId: reopening.id, reason },
      {
        onSuccess: () => {
          close()
          setDone(reopenedLabel(label))
        },
      }
    )
  }

  return (
    <section
      aria-labelledby="locked-maps-title"
      className="flex flex-col overflow-hidden rounded-xl border border-border bg-card"
    >
      <div className="flex flex-wrap items-center gap-3 border-b border-muted px-4 py-3.5">
        <hgroup className="flex min-w-0 flex-1 flex-col gap-0.5">
          <h2 id="locked-maps-title" className="text-base font-semibold">
            {LOCKED_MAPS_MESSAGES.title}
          </h2>
          <p className="text-xs text-muted-foreground">
            {LOCKED_MAPS_MESSAGES.subtitle}
          </p>
        </hgroup>
      </div>

      {done ? (
        <div className="border-b border-muted px-4 py-3">
          <FormMessage kind="success">{done}</FormMessage>
        </div>
      ) : null}

      {maps.isPending ? (
        <p
          role="status"
          className="flex items-center gap-2 px-4 py-6 text-sm text-muted-foreground"
        >
          <LoaderCircle className="size-4 animate-spin" aria-hidden="true" />
          {LOCKED_MAPS_MESSAGES.loading}
        </p>
      ) : maps.isError ? (
        <div role="alert" className="flex flex-col gap-3 px-4 py-6">
          <p className="flex items-start gap-2 text-sm text-muted-foreground">
            <CircleAlert
              className="mt-0.5 size-4 shrink-0"
              aria-hidden="true"
            />
            {LOCKED_MAPS_MESSAGES.loadFailed}
          </p>
          <Button
            variant="outline"
            className="self-start"
            onClick={() => void maps.refetch()}
          >
            {LOCKED_MAPS_MESSAGES.retry}
          </Button>
        </div>
      ) : maps.data.length === 0 ? (
        <p className="px-4 py-6 text-sm text-muted-foreground">
          {LOCKED_MAPS_MESSAGES.empty}
        </p>
      ) : (
        <>
          {groupByMonth(maps.data).map((group) => (
            <div key={group.month}>
              {/*
               * O mês como cabeçalho, e não como coluna de cada linha: a lista
               * vem do mais recente para o mais antigo, então o mês muda poucas
               * vezes — e repeti-lo em vinte linhas seguidas esconderia o dia,
               * que é o que ela está procurando.
               */}
              <h3 className="border-b border-muted bg-muted/40 px-4 py-1.5 text-2xs font-medium tracking-wide text-muted-foreground uppercase">
                {monthLabel(group.month)}
              </h3>

              <ul className="flex flex-col">
                {group.maps.map((map) => (
                  <LockedMapRow
                    key={map.id}
                    map={map}
                    busy={reopen.isPending}
                    onReopen={() => open(map)}
                  />
                ))}
              </ul>
            </div>
          ))}

          {maps.data.length >= RECENT_LOCKED ? (
            <p className="px-4 py-3 text-xs text-muted-foreground">
              {recentOnlyLabel(RECENT_LOCKED)}
            </p>
          ) : null}
        </>
      )}

      <ReopenDialog
        dayLabel={reopening ? dayLabel(reopening.mapDate) : ''}
        open={reopening !== null}
        busy={reopen.isPending}
        failure={reopen.isError ? reopen.error.message : null}
        onCancel={close}
        onConfirm={confirm}
      />
    </section>
  )
}

interface MonthGroup {
  month: string
  maps: LockedMap[]
}

/** Agrupa pelos meses na ordem em que a consulta os trouxe: do mais novo. */
function groupByMonth(maps: LockedMap[]): MonthGroup[] {
  const groups: MonthGroup[] = []

  for (const map of maps) {
    const month = monthKeyOf(map.mapDate)
    const last = groups[groups.length - 1]

    if (last?.month === month) last.maps.push(map)
    else groups.push({ month, maps: [map] })
  }

  return groups
}

/** Um dia bloqueado: qual é, em que documento saiu e o botão que o reabre. */
function LockedMapRow({
  map,
  busy,
  onReopen,
}: {
  map: LockedMap
  busy: boolean
  onReopen(): void
}) {
  return (
    <li className="flex flex-wrap items-center gap-x-3 gap-y-1.5 border-b border-muted px-4 py-3 last:border-b-0">
      <div className="flex min-w-0 flex-1 basis-48 items-center gap-2.5">
        <Lock
          className="size-4 shrink-0 text-muted-foreground"
          aria-hidden="true"
        />
        <span className="truncate text-sm font-medium">
          {dayLabel(map.mapDate)}
        </span>
      </div>

      <span className="shrink-0 text-xs text-muted-foreground">
        {inDocumentLabel(map.generatedAt)}
      </span>

      <Button
        variant="outline"
        size="sm"
        className="shrink-0"
        disabled={busy}
        aria-label={reopenLabel(dayLabel(map.mapDate))}
        onClick={onReopen}
      >
        {LOCKED_MAPS_MESSAGES.reopen}
      </Button>
    </li>
  )
}
