import { useEffect, useRef, useState } from 'react'
import {
  ChevronLeft,
  ChevronRight,
  CircleAlert,
  LoaderCircle,
  Lock,
} from 'lucide-react'
import { Link, Navigate, useNavigate, useParams } from 'react-router'

import { Button } from '@/components/ui/button'
import { MealCard } from '@/day/meal-card'
import { MealsServedCard } from '@/day/meals-served-card'
import { DAY_MESSAGES, dayTitle } from '@/day/messages'
import { NonSchoolDayCard } from '@/day/non-school-day-card'
import { useDay } from '@/day/queries'
import {
  dayProgress,
  firstUnfinishedMeal,
  mealOf,
  schoolDayContent,
  setAcceptance,
  setDescription,
  setMealsServed,
  setNonSchoolDay,
  setNote,
  NOTHING_TO_RESTORE,
  type SchoolDayContent,
} from '@/day/register'
import { MEAL_ORDER, type MealType } from '@/local/day'
import { ConflictNotice } from '@/local/conflict-notice'
import { SyncBanner } from '@/local/sync-banner'
import { dayAndMonth, monthKeyOf, monthLabel, shiftDate } from '@/month/month'
import { dayPath, MONTH_PARAM, ROUTES } from '@/routes'

/*
 * O registro do dia — tela 3 da E3, e o centro do produto (US001).
 *
 * Tudo o que um dia tem cabe aqui: as três refeições em cartões, a aceitação em
 * três botões, o número de refeições do dia e a alternância de dia não letivo.
 * Não há botão de salvar (decisão 3 da E3) — cada tecla vira rascunho no
 * aparelho na hora, e quem leva ao servidor é a fila. A faixa logo abaixo do
 * cabeçalho é o que diz em que pé está o envio.
 *
 * O dia bloqueado abre, e abre só para consulta: ele é justamente o dia que ela
 * vai querer conferir depois de gerar o documento (RN#1 da US007).
 */

/** AAAA-MM-DD que existe de verdade: 31 de fevereiro não abre tela nenhuma. */
function validDate(value: string | undefined): value is string {
  return (
    value !== undefined &&
    /^\d{4}-\d{2}-\d{2}$/.test(value) &&
    shiftDate(value, 0) === value
  )
}

export function DayRegister() {
  const { mapDate } = useParams()

  if (!validDate(mapDate)) return <Navigate to={ROUTES.cookHome} replace />

  return <DayScreen mapDate={mapDate} />
}

function DayScreen({ mapDate }: { mapDate: string }) {
  const navigate = useNavigate()
  const { day, locked, loading, failed, status, retry, change } =
    useDay(mapDate)

  const [openMeal, setOpenMeal] = useState<MealType | null>(null)
  /*
   * Qual dia já teve o cartão aberto. A escolha é uma vez por dia aberto: se
   * ela recalculasse a cada tecla, o cartão se fecharia sozinho na hora em que
   * a refeição ficasse pronta — no meio da digitação dela.
   */
  const openedFor = useRef<string | null>(null)

  useEffect(() => {
    if (!day || openedFor.current === mapDate) return
    openedFor.current = mapDate
    setOpenMeal(firstUnfinishedMeal(day))
  }, [day, mapDate])

  /*
   * O que o dia tinha antes de ela marcar "dia não letivo", guardado por data:
   * desmarcar devolve (CA#3 da US006). Por data porque a tela sobrevive à
   * troca de dia pelas setas, e o almoço de segunda não pode reaparecer na
   * terça.
   */
  const preserved = useRef<Record<string, SchoolDayContent>>({})

  const progress = day ? dayProgress(day) : { done: 0, total: 1 }
  const monthPath = `${ROUTES.cookHome}?${MONTH_PARAM}=${monthKeyOf(mapDate)}`
  const readOnly = locked

  function goToDay(days: number) {
    void navigate(dayPath(shiftDate(mapDate, days)))
  }

  function toggleNonSchoolDay(on: boolean) {
    if (!day) return
    if (on) preserved.current[mapDate] = schoolDayContent(day)

    change(
      setNonSchoolDay(day, on, preserved.current[mapDate] ?? NOTHING_TO_RESTORE)
    )
  }

  return (
    <div className="flex min-h-dvh flex-col bg-background">
      <header className="sticky top-0 z-10 border-b border-border bg-card">
        <div className="mx-auto flex w-full max-w-screen items-center gap-0.5 p-2">
          <Button
            variant="ghost"
            size="icon"
            aria-label={`Dia anterior, ${dayAndMonth(shiftDate(mapDate, -1))}`}
            onClick={() => goToDay(-1)}
          >
            <ChevronLeft aria-hidden="true" />
          </Button>

          {/*
           * `aria-live`: andar de dia pelas setas troca a tela inteira, e o
           * título é a única coisa que diz em qual dia ela caiu.
           *
           * O caminho de volta é o mês, no subtítulo. O desenho da E3 não tem
           * botão de voltar porque no aplicativo quem volta é o botão do
           * aparelho; na web esse botão não existe, e um link no texto que já
           * está ali resolve sem roubar o lugar das setas.
           */}
          <h1
            aria-live="polite"
            className="flex flex-1 flex-col items-center gap-px overflow-hidden"
          >
            <span className="truncate text-lg font-semibold tracking-tight">
              {dayTitle(mapDate)}
            </span>
            <Link
              to={monthPath}
              aria-label={DAY_MESSAGES.backToMonth}
              className="text-xs font-normal text-muted-foreground underline-offset-4 hover:underline"
            >
              {monthLabel(monthKeyOf(mapDate))}
            </Link>
          </h1>

          <Button
            variant="ghost"
            size="icon"
            aria-label={`Próximo dia, ${dayAndMonth(shiftDate(mapDate, 1))}`}
            onClick={() => goToDay(1)}
          >
            <ChevronRight aria-hidden="true" />
          </Button>
        </div>
      </header>

      <SyncBanner status={status} />
      <ConflictNotice />

      {locked ? (
        <p
          role="status"
          className="flex items-start gap-2 border-b border-border bg-muted px-4 py-2.5 text-sm text-muted-foreground"
        >
          <Lock className="mt-0.5 size-4 shrink-0" aria-hidden="true" />
          <span>{DAY_MESSAGES.locked}</span>
        </p>
      ) : null}

      <main className="mx-auto flex w-full max-w-screen flex-1 flex-col gap-3 px-4 pt-3.5 pb-6">
        {loading ? (
          <p
            role="status"
            className="flex flex-1 items-center justify-center gap-2 text-base text-muted-foreground"
          >
            <LoaderCircle className="size-4 animate-spin" aria-hidden="true" />
            {DAY_MESSAGES.loading}
          </p>
        ) : failed || !day ? (
          /*
           * Sem o dia inteiro na mão não se edita: a lista que sobe é o dia
           * todo, e deixar ela escrever por cima de um dia que não foi lido
           * apagaria o que está no servidor (decisão 2 da E5).
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
              {DAY_MESSAGES.loadFailed}
            </p>
            <Button variant="outline" onClick={retry}>
              {DAY_MESSAGES.retry}
            </Button>
          </div>
        ) : (
          <>
            <NonSchoolDayCard
              nonSchoolDay={day.non_school_day}
              note={day.note}
              readOnly={readOnly}
              onToggle={toggleNonSchoolDay}
              onNoteChange={(note) => change(setNote(day, note))}
            />

            {day.non_school_day ? null : (
              <>
                {MEAL_ORDER.map((type) => (
                  <MealCard
                    key={type}
                    type={type}
                    meal={mealOf(day, type)}
                    open={openMeal === type}
                    readOnly={readOnly}
                    onOpenChange={(open) => setOpenMeal(open ? type : null)}
                    onDescriptionChange={(description) =>
                      change(setDescription(day, type, description))
                    }
                    onAcceptanceChange={(acceptance) =>
                      change(setAcceptance(day, type, acceptance))
                    }
                  />
                ))}

                <MealsServedCard
                  value={day.meals_served}
                  readOnly={readOnly}
                  onChange={(value) => change(setMealsServed(day, value))}
                />
              </>
            )}
          </>
        )}
      </main>

      <footer className="sticky bottom-0 border-t border-border bg-card">
        <div className="mx-auto flex w-full max-w-screen flex-col gap-2 px-4 pt-3 pb-4">
          <span className="text-xs text-muted-foreground">
            {DAY_MESSAGES.autosave}
          </span>
          <div
            role="progressbar"
            aria-valuemin={0}
            aria-valuemax={progress.total}
            aria-valuenow={progress.done}
            aria-label={DAY_MESSAGES.progress}
            className="h-1.5 overflow-hidden rounded-full bg-muted"
          >
            <div
              className="h-full rounded-full bg-primary transition-[width]"
              style={{
                width: `${Math.round((progress.done / progress.total) * 100)}%`,
              }}
            />
          </div>
        </div>
      </footer>
    </div>
  )
}
