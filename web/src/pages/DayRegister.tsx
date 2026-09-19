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
import type { FoodItemActions } from '@/day/food-item-list'
import { FoodItemSheet } from '@/day/food-item-sheet'
import { MealCard } from '@/day/meal-card'
import { MealsServedCard } from '@/day/meals-served-card'
import { DAY_MESSAGES, dayTitle } from '@/day/messages'
import { MenuChangeDialog } from '@/day/menu-change-dialog'
import { NonSchoolDayCard } from '@/day/non-school-day-card'
import { useDay } from '@/day/queries'
import {
  addFoodItem,
  dayProgress,
  firstUnfinishedMeal,
  mealOf,
  menuChangeIsEmpty,
  schoolDayContent,
  setAcceptance,
  setDescription,
  setFoodItemQuantity,
  setMealsServed,
  setMenuChange,
  setMenuChangeReason,
  setNonSchoolDay,
  setNote,
  stepFoodItemQuantity,
  NOTHING_TO_RESTORE,
  type FoodItemList,
  type SchoolDayContent,
} from '@/day/register'
import { chosenNames } from '@/food-items/catalog'
import { MEAL_ORDER, type MealType, type MenuChangePayload } from '@/local/day'
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
  /** Em qual refeição a tela 3a está aberta. */
  const [changeFor, setChangeFor] = useState<MealType | null>(null)
  /** Para qual das duas listas a folha 3b vai entregar o gênero escolhido. */
  const [sheetFor, setSheetFor] = useState<{
    type: MealType
    list: FoodItemList
  } | null>(null)
  /*
   * A alteração como estava quando a tela 3a abriu. É o que o "Cancelar"
   * devolve — sem isto ele não teria como desfazer, porque o que ela digita
   * ali já foi para o aparelho na hora.
   */
  const changeBefore = useRef<MenuChangePayload | null>(null)
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
   * As setas do cabeçalho continuam funcionando com a tela 3a aberta, e a
   * alteração de terça não pode ficar de pé sobre o dia de quarta. O ajuste é
   * no próprio desenho, e não num efeito: um efeito só fecharia a folha depois
   * de ela já ter aparecido por um quadro sobre o dia errado.
   */
  const [shownFor, setShownFor] = useState(mapDate)
  if (shownFor !== mapDate) {
    setShownFor(mapDate)
    setChangeFor(null)
    setSheetFor(null)
  }

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

  /*
   * O que os steppers de uma lista fazem. O mesmo trio serve às duas listas da
   * refeição — os gêneros dela e os da troca —, e é o `list` que diz qual.
   */
  function foodItemActions(
    type: MealType,
    list: FoodItemList
  ): FoodItemActions {
    return {
      add: () => setSheetFor({ type, list }),
      step: (key, delta) => {
        if (day) change(stepFoodItemQuantity(day, type, list, key, delta))
      },
      setQuantity: (key, quantity) => {
        if (day) change(setFoodItemQuantity(day, type, list, key, quantity))
      },
    }
  }

  function openMenuChange(type: MealType) {
    if (!day) return

    changeBefore.current = mealOf(day, type)?.menu_change ?? null
    setChangeFor(type)
  }

  /*
   * Confirmar é fechar — o que está escrito já está gravado. O que ele decide
   * é o que fica: a alteração aberta e fechada sem nada dentro sai do dia, em
   * vez de virar um registro vazio que o servidor recusaria para sempre.
   */
  function confirmMenuChange() {
    const type = changeFor
    setChangeFor(null)
    if (!day || type === null) return

    const current = mealOf(day, type)?.menu_change ?? null
    if (menuChangeIsEmpty(current)) change(setMenuChange(day, type, null))
  }

  function cancelMenuChange() {
    const type = changeFor
    setChangeFor(null)
    if (!day || type === null) return

    change(setMenuChange(day, type, changeBefore.current))
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
                    foodItems={foodItemActions(type, 'meal')}
                    onOpenChange={(open) => setOpenMeal(open ? type : null)}
                    onDescriptionChange={(description) =>
                      change(setDescription(day, type, description))
                    }
                    onAcceptanceChange={(acceptance) =>
                      change(setAcceptance(day, type, acceptance))
                    }
                    onOpenMenuChange={() => openMenuChange(type)}
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

      {/*
       * As duas telas que sobem sobre o registro. Ficam aqui, e não dentro do
       * cartão, porque a 3b abre tanto da refeição quanto de dentro da 3a — e
       * porque as duas precisam do dia inteiro para gravar o que ela escolher.
       */}
      {day && changeFor !== null ? (
        <MenuChangeDialog
          open
          type={changeFor}
          mapDate={mapDate}
          change={mealOf(day, changeFor)?.menu_change ?? null}
          readOnly={readOnly}
          actions={foodItemActions(changeFor, 'menu_change')}
          onReasonChange={(reason) =>
            change(setMenuChangeReason(day, changeFor, reason))
          }
          onRemove={() => {
            change(setMenuChange(day, changeFor, null))
            setChangeFor(null)
          }}
          onCancel={cancelMenuChange}
          onConfirm={confirmMenuChange}
        />
      ) : null}

      {day && sheetFor !== null ? (
        <FoodItemSheet
          open
          type={sheetFor.type}
          mapDate={mapDate}
          chosen={chosenNames(
            sheetFor.list === 'meal'
              ? (mealOf(day, sheetFor.type)?.food_items ?? [])
              : (mealOf(day, sheetFor.type)?.menu_change?.food_items ?? [])
          )}
          onOpenChange={(open) => {
            if (!open) setSheetFor(null)
          }}
          onChoose={(item) =>
            change(addFoodItem(day, sheetFor.type, sheetFor.list, item))
          }
        />
      ) : null}

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
