import type { AcceptanceLevel, DayPayload, MealType } from '@/local/day'

/*
 * O mês, como a visão do mês precisa dele.
 *
 * Tudo aqui é função pura sobre texto e número: nada de rede, nada de React.
 * É de propósito — o que esta tela tem de difícil não é desenhar a lista, é
 * decidir em que estado está cada dia, e essa decisão é a **decisão 4 da E4**
 * levada à letra: só o bloqueio vem gravado do servidor; vazio, pendente e
 * completo são calculados aqui, na leitura, a cada vez.
 *
 * As datas são tratadas como texto AAAA-MM-DD e aritmética de número inteiro,
 * nunca como `Date` local. Um `new Date('2026-09-01')` é meia-noite em UTC, e
 * no fuso de Brasília isso é 31 de agosto — o mês inteiro andaria um dia para
 * trás na tela de quem está a oeste de Greenwich.
 */

/** O mês em AAAA-MM. É a chave de tudo nesta tela, inclusive da URL. */
export type MonthKey = string

export type DayState =
  /** Incluído em documento gerado: somente leitura para a merendeira. */
  'locked' | 'non_school' | 'complete' | 'pending' | 'empty'

/** Uma refeição, reduzida ao que decide o estado do dia. */
export interface MealRecord {
  type: MealType
  description: string | null
  acceptance: AcceptanceLevel | null
}

/**
 * Um dia, venha ele do servidor ou do rascunho guardado no aparelho. As duas
 * origens desembocam nesta forma para que a derivação do estado não precise
 * saber de onde o dia veio.
 */
export interface DayRecord {
  mapDate: string
  nonSchoolDay: boolean
  note: string | null
  mealsServed: number | null
  locked: boolean
  meals: MealRecord[]
  /** Está guardado no aparelho e ainda não foi confirmado pelo servidor. */
  pendingUpload: boolean
}

export const MEAL_ORDER: MealType[] = [
  'morning_snack',
  'lunch',
  'afternoon_snack',
]

export const MEAL_LABELS: Record<MealType, string> = {
  morning_snack: 'lanche da manhã',
  lunch: 'almoço',
  afternoon_snack: 'lanche da tarde',
}

const MONTH_NAMES = [
  'janeiro',
  'fevereiro',
  'março',
  'abril',
  'maio',
  'junho',
  'julho',
  'agosto',
  'setembro',
  'outubro',
  'novembro',
  'dezembro',
]

const WEEKDAY_LABELS = ['dom', 'seg', 'ter', 'qua', 'qui', 'sex', 'sáb']

// ---------------------------------------------------------------------------
// Datas
// ---------------------------------------------------------------------------

function pad(value: number): string {
  return String(value).padStart(2, '0')
}

function parts(date: string): [number, number, number] {
  const [year, month, day] = date.split('-').map(Number)
  return [year, month, day]
}

/** O dia da semana, 0 = domingo. Em UTC, que é onde a data não escorrega. */
export function weekdayOf(date: string): number {
  const [year, month, day] = parts(date)
  return new Date(Date.UTC(year, month - 1, day)).getUTCDay()
}

export function weekdayLabel(date: string): string {
  return WEEKDAY_LABELS[weekdayOf(date)]
}

/** Segunda a sexta. Fim de semana não conta como pendência (RN#1 da US008). */
export function isWeekday(date: string): boolean {
  const weekday = weekdayOf(date)
  return weekday >= 1 && weekday <= 5
}

export function monthKeyOf(date: string): MonthKey {
  return date.slice(0, 7)
}

/** O mês de hoje, pelo relógio do aparelho — é o mês em que a tela abre. */
export function monthKeyToday(today = new Date()): MonthKey {
  return `${today.getFullYear()}-${pad(today.getMonth() + 1)}`
}

/** Hoje em AAAA-MM-DD, no fuso de quem está olhando. */
export function dateToday(today = new Date()): string {
  return `${today.getFullYear()}-${pad(today.getMonth() + 1)}-${pad(today.getDate())}`
}

export function shiftMonth(month: MonthKey, months: number): MonthKey {
  const [year, index] = month.split('-').map(Number)
  const shifted = new Date(Date.UTC(year, index - 1 + months, 1))
  return `${shifted.getUTCFullYear()}-${pad(shifted.getUTCMonth() + 1)}`
}

/** O primeiro e o último dia do mês — o recorte que a consulta ao servidor usa. */
export function monthRange(month: MonthKey): { first: string; last: string } {
  const [year, index] = month.split('-').map(Number)
  const lastDay = new Date(Date.UTC(year, index, 0)).getUTCDate()
  return { first: `${month}-01`, last: `${month}-${pad(lastDay)}` }
}

/** "Setembro de 2026", com a inicial maiúscula do título da tela. */
export function monthLabel(month: MonthKey): string {
  const [year, index] = month.split('-').map(Number)
  const name = MONTH_NAMES[index - 1]
  return `${name.charAt(0).toUpperCase()}${name.slice(1)} de ${year}`
}

/** "1 de setembro" — como ela lê a data no rótulo da semana e no leitor de tela. */
export function dayAndMonth(date: string): string {
  const [, month, day] = parts(date)
  return `${day} de ${MONTH_NAMES[month - 1]}`
}

/**
 * Os dias que a tela lista.
 *
 * Segunda a sexta sempre, porque é neles que pode faltar mapa. Sábado e
 * domingo entram **só** quando têm registro: a regra diz que fim de semana não
 * é pendência, não que um dia registrado possa ficar inalcançável — e se ele
 * não aparecesse aqui, não haveria por onde abri-lo para corrigir.
 */
export function listedDays(month: MonthKey, registered: Set<string>): string[] {
  const { last } = monthRange(month)
  const lastDay = Number(last.slice(-2))
  const days: string[] = []

  for (let day = 1; day <= lastDay; day += 1) {
    const date = `${month}-${pad(day)}`
    if (isWeekday(date) || registered.has(date)) days.push(date)
  }

  return days
}

export interface Week {
  /** Sequencial dentro do mês: é o que a merendeira chama de "semana 1". */
  number: number
  label: string
  days: string[]
}

/**
 * Agrupa os dias listados em semanas de segunda a domingo.
 *
 * A quebra é pela segunda-feira e não por um bloco de sete dias, senão a
 * primeira semana de um mês que começa numa quinta arrastaria o sábado
 * seguinte para dentro dela.
 */
export function groupIntoWeeks(days: string[]): Week[] {
  const weeks: Week[] = []

  for (const date of days) {
    const startsWeek = weeks.length === 0 || weekdayOf(date) === 1
    if (startsWeek)
      weeks.push({ number: weeks.length + 1, label: '', days: [] })
    weeks[weeks.length - 1].days.push(date)
  }

  return weeks.map((week) => {
    const first = week.days[0]
    const last = week.days[week.days.length - 1]
    const range =
      first === last
        ? dayAndMonth(first)
        : `${Number(first.slice(-2))} a ${dayAndMonth(last)}`

    return { ...week, label: `Semana ${week.number} · ${range}` }
  })
}

// ---------------------------------------------------------------------------
// O estado de cada dia (decisão 4 da E4, decisão 4 da E3)
// ---------------------------------------------------------------------------

function filled(text: string | null): boolean {
  return text !== null && text.trim() !== ''
}

/**
 * Uma refeição está pronta quando descreve o que foi servido **e** tem a
 * aceitação: sem ela o registro da refeição não se conclui (CA#3 da US004).
 * Gêneros continuam opcionais (RN#3 da US001) e por isso não entram na conta.
 */
function mealIsComplete(meal: MealRecord | undefined): boolean {
  return (
    meal !== undefined && filled(meal.description) && meal.acceptance !== null
  )
}

/** Um dia que existe mas em que ninguém escreveu nada ainda é um dia vazio. */
function hasContent(record: DayRecord): boolean {
  return (
    record.nonSchoolDay ||
    record.mealsServed !== null ||
    record.meals.some(
      (meal) => filled(meal.description) || meal.acceptance !== null
    )
  )
}

export function dayState(record: DayRecord | undefined): DayState {
  if (!record) return 'empty'

  /*
   * O bloqueio vem primeiro porque é o único estado que muda o que ela PODE
   * fazer: o dia já saiu num documento oficial e virou somente leitura (RN#1
   * da US007). Saber que ele também estava completo não muda nada para ela.
   */
  if (record.locked) return 'locked'
  if (record.nonSchoolDay) return 'non_school'
  if (!hasContent(record)) return 'empty'

  const byType = new Map(record.meals.map((meal) => [meal.type, meal]))
  const complete =
    record.mealsServed !== null &&
    MEAL_ORDER.every((type) => mealIsComplete(byType.get(type)))

  return complete ? 'complete' : 'pending'
}

/** O que ainda falta num dia pendente, em português corrente. */
function missingParts(record: DayRecord): string {
  const byType = new Map(record.meals.map((meal) => [meal.type, meal]))
  const missingMeals = MEAL_ORDER.filter(
    (type) => !mealIsComplete(byType.get(type))
  )

  const items =
    missingMeals.length === MEAL_ORDER.length
      ? ['as três refeições']
      : missingMeals.map((type) => `o ${MEAL_LABELS[type]}`)

  if (record.mealsServed === null) items.push('o número de refeições')

  const verb =
    items.length > 1 || items[0] === 'as três refeições' ? 'faltam' : 'falta'
  const list =
    items.length > 1
      ? `${items.slice(0, -1).join(', ')} e ${items[items.length - 1]}`
      : items[0]

  return `${verb} ${list}`
}

/**
 * A linha de apoio de cada dia: o que ele tem, quando tem; o que falta, quando
 * falta. O "Hoje" na frente é o único destaque de data da lista — é o dia que
 * ela abre nove vezes em dez.
 */
export function daySummary(
  record: DayRecord | undefined,
  options: { isToday?: boolean } = {}
): string {
  const prefix = options.isToday ? 'Hoje · ' : ''

  if (!record || !hasContent(record)) return `${prefix}Sem registro`
  if (record.nonSchoolDay)
    return `${prefix}${record.note?.trim() || 'Dia não letivo'}`

  const state = dayState(record)
  if (state === 'pending') return `${prefix}${missingParts(record)}`

  const meals = record.meals.filter((meal) => filled(meal.description)).length
  const served =
    record.mealsServed === null ? null : `${record.mealsServed} servidas`

  return `${prefix}${[`${meals} refeições`, served].filter(Boolean).join(' · ')}`
}

// ---------------------------------------------------------------------------
// O andamento do mês
// ---------------------------------------------------------------------------

export interface MonthProgress {
  /** Dias letivos do mês: os listados, menos os marcados como não letivos. */
  schoolDays: number
  /** Dias prontos — completos ou já dentro de um documento. */
  done: number
  counts: Record<DayState, number>
}

export function monthProgress(
  days: string[],
  byDate: Map<string, DayRecord>
): MonthProgress {
  const counts: Record<DayState, number> = {
    locked: 0,
    non_school: 0,
    complete: 0,
    pending: 0,
    empty: 0,
  }

  for (const date of days) counts[dayState(byDate.get(date))] += 1

  return {
    schoolDays: days.length - counts.non_school,
    done: counts.complete + counts.locked,
    counts,
  }
}

// ---------------------------------------------------------------------------
// Origens: o servidor e o rascunho
// ---------------------------------------------------------------------------

/** O rascunho guardado no aparelho, na forma que esta tela lê. */
export function recordFromDraft(draft: DayPayload): DayRecord {
  return {
    mapDate: draft.map_date,
    nonSchoolDay: draft.non_school_day,
    note: draft.note,
    mealsServed: draft.meals_served,
    /*
     * Rascunho nunca nasce bloqueado: o bloqueio é do servidor, e o cliente
     * não tem como sabê-lo sem perguntar. Quando as duas origens existem para
     * o mesmo dia, `mergeDays` recupera esse fato da linha do servidor.
     */
    locked: false,
    meals: draft.meals.map((meal) => ({
      type: meal.type,
      description: meal.description,
      acceptance: meal.acceptance,
    })),
    pendingUpload: true,
  }
}

/**
 * Junta o que veio do servidor com o que ainda está no aparelho.
 *
 * A fronteira da decisão 4 da E5 diz qual dos dois vale: **o rascunho, quando
 * existe** — ele é mais novo por construção, porque só está guardado enquanto
 * o servidor não confirmou. O que não se herda do rascunho é o bloqueio, que
 * ele não tem como conhecer: esse continua vindo da linha do servidor, senão
 * um dia já dentro de um documento voltaria a parecer editável.
 */
export function mergeDays(
  fromServer: DayRecord[],
  fromDevice: DayRecord[]
): Map<string, DayRecord> {
  const byDate = new Map(fromServer.map((record) => [record.mapDate, record]))

  for (const draft of fromDevice) {
    const server = byDate.get(draft.mapDate)
    byDate.set(draft.mapDate, {
      ...draft,
      locked: server?.locked ?? false,
    })
  }

  return byDate
}
