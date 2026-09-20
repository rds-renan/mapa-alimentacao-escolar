import { useMemo } from 'react'
import {
  ChevronLeft,
  ChevronRight,
  CircleAlert,
  FileText,
  LoaderCircle,
} from 'lucide-react'
import { Link, useSearchParams } from 'react-router'

import { AppMenu } from '@/components/app-menu'
import { Button } from '@/components/ui/button'
import { Card, CardContent } from '@/components/ui/card'
import { ConflictNotice } from '@/local/conflict-notice'
import { DayRow } from '@/month/day-row'
import {
  keptOnDeviceLabel,
  MONTH_MESSAGES,
  progressBreakdown,
  progressLabel,
  schoolDaysLabel,
} from '@/month/messages'
import {
  dateToday,
  groupIntoWeeks,
  isMonthKey,
  listedDays,
  monthKeyToday,
  monthLabel,
  monthProgress,
  shiftMonth,
} from '@/month/month'
import { useMonth } from '@/month/queries'
import { MONTH_PARAM, selectMapsPath } from '@/routes'

/*
 * A visão do mês — tela 2 da E3, a tela-casa da merendeira (US008).
 *
 * Ela responde a uma pergunta só, que hoje é respondida de cabeça e de
 * caderno: **o que ainda falta antes de gerar o mapa?** Por isso a lista é de
 * dias e não um calendário em grade — num calendário cabe o número do dia e
 * mais nada, e aqui o que decide é a linha ao lado dele, que diz o que falta.
 *
 * Os estados vêm da decisão 4 da E4: só o bloqueio é lido do servidor, o resto
 * é derivado do conteúdo a cada desenho da tela.
 */

export function MonthView() {
  const [params, setParams] = useSearchParams()
  const requested = params.get(MONTH_PARAM)
  const month = isMonthKey(requested) ? requested : monthKeyToday()
  const today = dateToday()

  const { byDate, loading, failed, pending, retry } = useMonth(month)

  const { weeks, progress } = useMemo(() => {
    const days = listedDays(month, new Set(byDate.keys()))
    return {
      weeks: groupIntoWeeks(days),
      progress: monthProgress(days, byDate),
    }
  }, [month, byDate])

  function goToMonth(months: number) {
    setParams({ [MONTH_PARAM]: shiftMonth(month, months) })
  }

  const done =
    progress.schoolDays === 0
      ? 0
      : Math.round((progress.done / progress.schoolDays) * 100)

  return (
    <div className="flex min-h-dvh flex-col bg-background">
      <header className="sticky top-0 z-10 border-b border-border bg-card">
        <div className="mx-auto flex w-full max-w-screen items-center gap-0.5 p-2">
          <AppMenu />

          <Button
            variant="ghost"
            size="icon"
            aria-label="Mês anterior"
            onClick={() => goToMonth(-1)}
          >
            <ChevronLeft aria-hidden="true" />
          </Button>

          {/*
           * `aria-live`: quem navega de mês com o leitor de tela precisa ouvir
           * em que mês caiu — a lista inteira trocou, e o título é a única
           * coisa que diz qual deles é.
           */}
          <h1
            aria-live="polite"
            className="flex flex-1 flex-col items-center gap-px"
          >
            <span className="text-lg font-semibold tracking-tight">
              {monthLabel(month)}
            </span>
            <span className="text-xs font-normal text-muted-foreground">
              {schoolDaysLabel(progress.schoolDays)}
            </span>
          </h1>

          <Button
            variant="ghost"
            size="icon"
            aria-label="Próximo mês"
            onClick={() => goToMonth(1)}
          >
            <ChevronRight aria-hidden="true" />
          </Button>
        </div>
      </header>

      <ConflictNotice />

      <main className="mx-auto flex w-full max-w-screen flex-1 flex-col gap-3.5 px-4 pt-3.5 pb-6">
        {loading ? (
          <p
            role="status"
            className="flex flex-1 items-center justify-center gap-2 text-base text-muted-foreground"
          >
            <LoaderCircle className="size-4 animate-spin" aria-hidden="true" />
            {MONTH_MESSAGES.loading}
          </p>
        ) : failed ? (
          /*
           * A web não promete navegar sem internet (decisão 2 da E5) — o
           * offline integral é do aplicativo, na E6. O que ela precisa saber
           * aqui é que a falha é da lista, não do que ela digitou: mostrar um
           * mês meio vazio seria pior que não mostrar mês nenhum, porque é
           * justamente contando os dias que faltam que ela decide gerar.
           */
          <div
            role="alert"
            className="flex flex-1 flex-col items-center justify-center gap-3 text-center"
          >
            <CircleAlert
              className="size-6 text-muted-foreground"
              aria-hidden="true"
            />
            <p className="text-base text-muted-foreground">
              {MONTH_MESSAGES.loadFailed}
            </p>
            {pending > 0 ? (
              <p className="text-sm text-muted-foreground">
                {keptOnDeviceLabel(pending)}
              </p>
            ) : null}
            <Button variant="outline" onClick={retry}>
              {MONTH_MESSAGES.retry}
            </Button>
          </div>
        ) : (
          <>
            <Card size="sm">
              <CardContent className="flex flex-col gap-2.5">
                <div className="flex items-baseline justify-between gap-2">
                  <span className="text-base font-semibold">
                    Andamento do mês
                  </span>
                  <span className="text-xs text-muted-foreground">
                    {progressLabel(progress.done, progress.schoolDays)}
                  </span>
                </div>

                <div
                  role="progressbar"
                  aria-valuemin={0}
                  aria-valuemax={progress.schoolDays}
                  aria-valuenow={progress.done}
                  aria-label="Dias prontos no mês"
                  className="h-1.5 overflow-hidden rounded-full bg-muted"
                >
                  <div
                    className="h-full rounded-full bg-primary transition-[width]"
                    style={{ width: `${done}%` }}
                  />
                </div>

                <span className="text-xs text-muted-foreground">
                  {progressBreakdown(progress.counts)}
                </span>
              </CardContent>
            </Card>

            {weeks.length === 0 ? (
              <p className="text-base text-muted-foreground">
                {MONTH_MESSAGES.empty}
              </p>
            ) : null}

            {weeks.map((week) => (
              <section key={week.number} className="flex flex-col gap-2">
                <h2 className="pt-0.5 text-xs font-semibold text-secondary-foreground">
                  {week.label}
                </h2>
                <div className="flex flex-col overflow-hidden rounded-xl border border-border bg-card">
                  {week.days.map((date) => (
                    <DayRow
                      key={date}
                      date={date}
                      record={byDate.get(date)}
                      isToday={date === today}
                    />
                  ))}
                </div>
              </section>
            ))}
          </>
        )}
      </main>

      {/*
       * O segundo dos dois caminhos da tela-casa: a seleção de mapas. O mês
       * aberto vai junto no endereço, porque a tela 5 não tem navegação de mês
       * — ela mostra os dias do mês de onde a merendeira veio.
       */}
      <footer className="sticky bottom-0 border-t border-border bg-card">
        <div className="mx-auto w-full max-w-screen px-4 pt-3 pb-4">
          <Button size="lg" className="w-full" asChild>
            <Link to={selectMapsPath(month)}>
              <FileText aria-hidden="true" />
              Gerar documento
            </Link>
          </Button>
        </div>
      </footer>
    </div>
  )
}
