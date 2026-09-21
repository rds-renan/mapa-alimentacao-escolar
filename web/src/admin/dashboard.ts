import type { AcceptanceLevel, MealType } from '@/local/day'
import {
  listedDays,
  monthProgress,
  type DayRecord,
  type MonthKey,
} from '@/month/month'
import { MEAL_ORDER } from '@/local/day'

/*
 * O mês da direção, agregado (US017).
 *
 * Tudo aqui é função pura sobre os dias que o servidor devolveu: nada de rede,
 * nada de React. É o mesmo arranjo do `month.ts` da merendeira, e pelo mesmo
 * motivo — o que esta tela tem de difícil não é desenhar as barras, é decidir
 * o que entra em cada conta.
 *
 * **A régua do que está registrado é a da merendeira, não uma segunda.** O
 * andamento do mês sai de `monthProgress`, o mesmo que a visão do mês usa: se
 * o painel inventasse o seu próprio "dia completo", a direção e a merendeira
 * discordariam sobre o que falta no mês, cada uma olhando uma tela.
 *
 * **Dia não letivo sai pelo atributo, nunca pela ausência de refeições**
 * (RN#2 da US017). Não é preciosismo: marcar um dia como não letivo
 * **preserva** as refeições já digitadas (decisão 1 da E4), justamente para
 * que desmarcar devolva o que estava lá. Filtrar "dias sem refeição" deixaria
 * essas refeições entrarem na média e no ranking de um dia que não houve.
 */

// ---------------------------------------------------------------------------
// Os números do topo
// ---------------------------------------------------------------------------

export interface MonthSummary {
  /** Refeições servidas no mês: a soma dos números dos dias letivos. */
  mealsServed: number
  /** Dias letivos com o número informado — é o divisor da média. */
  daysCounted: number
  /** A média por dia letivo, arredondada. Nulo quando não há dia contado. */
  averagePerDay: number | null
  /** Dias letivos do mês: os listados, menos os marcados como não letivos. */
  schoolDays: number
  /** Dias prontos — completos ou já dentro de um documento. */
  registered: number
  pending: number
  empty: number
  nonSchoolDays: number
}

/**
 * A média divide pelos dias **com o número informado**, e não por todos os
 * dias letivos do mês.
 *
 * É a diferença entre "cada dia serviu 312 refeições" e "o mês ainda não
 * acabou". Dividir pelos 22 dias letivos no dia 10 daria uma média de menos de
 * metade do real, e a direção olharia para um número que só sobe porque o mês
 * passa — não porque a escola serviu mais.
 */
export function monthSummary(
  month: MonthKey,
  byDate: Map<string, DayRecord>
): MonthSummary {
  const days = listedDays(month, new Set(byDate.keys()))
  const progress = monthProgress(days, byDate)

  let mealsServed = 0
  let daysCounted = 0

  for (const date of days) {
    const day = byDate.get(date)
    if (!day || day.nonSchoolDay || day.mealsServed === null) continue

    mealsServed += day.mealsServed
    daysCounted += 1
  }

  return {
    mealsServed,
    daysCounted,
    averagePerDay:
      daysCounted === 0 ? null : Math.round(mealsServed / daysCounted),
    schoolDays: progress.schoolDays,
    registered: progress.done,
    pending: progress.counts.pending,
    empty: progress.counts.empty,
    nonSchoolDays: progress.counts.non_school,
  }
}

// ---------------------------------------------------------------------------
// A aceitação por refeição
// ---------------------------------------------------------------------------

export type AcceptanceCounts = Record<AcceptanceLevel, number>

export interface MealAcceptance {
  type: MealType
  counts: AcceptanceCounts
  /** Quantas avaliações a refeição recebeu no mês. Zero é barra vazia. */
  rated: number
  /**
   * A fatia de cada grau, em porcentagem exata — é a largura de cada pedaço da
   * barra. Sem arredondar: três inteiros arredondados somam 99 ou 101, e a
   * barra fica com uma sobra ou uma falta visível na ponta.
   */
  shares: Record<AcceptanceLevel, number>
}

const EMPTY_COUNTS: AcceptanceCounts = { great: 0, good: 0, poor: 0 }

/** A distribuição ótimo/bom/ruim de cada uma das três refeições do dia. */
export function acceptanceByMeal(
  days: DayRecord[]
): Record<MealType, MealAcceptance> {
  const counts = new Map<MealType, AcceptanceCounts>(
    MEAL_ORDER.map((type) => [type, { ...EMPTY_COUNTS }])
  )

  for (const day of days) {
    if (day.nonSchoolDay) continue

    for (const meal of day.meals) {
      if (meal.acceptance === null) continue
      const tally = counts.get(meal.type)
      if (tally) tally[meal.acceptance] += 1
    }
  }

  const result = {} as Record<MealType, MealAcceptance>

  for (const type of MEAL_ORDER) {
    const tally = counts.get(type) ?? { ...EMPTY_COUNTS }
    const rated = tally.great + tally.good + tally.poor

    result[type] = {
      type,
      counts: tally,
      rated,
      shares: {
        great: share(tally.great, rated),
        good: share(tally.good, rated),
        poor: share(tally.poor, rated),
      },
    }
  }

  return result
}

function share(part: number, whole: number): number {
  return whole === 0 ? 0 : (part / whole) * 100
}

// ---------------------------------------------------------------------------
// As merendas mais bem aceitas
// ---------------------------------------------------------------------------

export interface TopMeal {
  /** Como a merendeira escreveu a merenda na primeira vez que ela apareceu. */
  name: string
  /** Quantas vezes foi servida e avaliada no mês. */
  times: number
  great: number
  /** A fatia de "ótimo" entre as avaliações dela, de 0 a 100. */
  greatShare: number
}

/** Quantas merendas o cartão mostra — as cinco do desenho da E3. */
export const TOP_MEALS = 5

/**
 * A mesma normalização que o banco aplica ao nome de um gênero: minúsculas,
 * sem espaço nas pontas e sem espaço repetido no meio.
 *
 * A merenda não é um cadastro, é texto livre — o cardápio previsto, digitado
 * por quem transcreve o papel (decisão 3 da E4). Por isso "Arroz com frango" e
 * "arroz  com frango" são a mesma merenda aqui, e "Arroz c/ frango" **não** é:
 * é a limitação declarada do MVP, e o lugar de resolvê-la é a ingestão do
 * cardápio (US019), não uma adivinhação no painel.
 */
export function normalizeMeal(description: string): string {
  return description.trim().toLowerCase().replace(/\s+/g, ' ')
}

/**
 * O ranking das merendas do mês.
 *
 * Só entram refeições **avaliadas**: uma merenda servida e não avaliada não
 * diz nada sobre aceitação, e contá-la como não-ótimo seria inventar uma
 * avaliação que a merendeira não deu.
 *
 * A ordem é a fatia de ótimo, depois quantas vezes, depois o nome. O desempate
 * pelo número de vezes importa mais do que parece: num mês uma merenda aparece
 * uma ou duas vezes, então 100% de uma vez só é comum — e é por isso que cada
 * linha diz quantas vezes foi servida em vez de o painel esconder o caso único
 * atrás de um mínimo. A direção lê o número e decide o que ele vale; um corte
 * silencioso apagaria da lista uma merenda que existiu.
 */
export function topMeals(days: DayRecord[], limit = TOP_MEALS): TopMeal[] {
  const tally = new Map<string, TopMeal>()

  for (const day of days) {
    if (day.nonSchoolDay) continue

    for (const meal of day.meals) {
      const description = meal.description?.trim()
      if (!description || meal.acceptance === null) continue

      const key = normalizeMeal(description)
      const found = tally.get(key)

      if (found) {
        found.times += 1
        if (meal.acceptance === 'great') found.great += 1
      } else {
        tally.set(key, {
          name: description,
          times: 1,
          great: meal.acceptance === 'great' ? 1 : 0,
          greatShare: 0,
        })
      }
    }
  }

  return [...tally.values()]
    .map((meal) => ({ ...meal, greatShare: share(meal.great, meal.times) }))
    .sort(
      (a, b) =>
        b.greatShare - a.greatShare ||
        b.times - a.times ||
        a.name.localeCompare(b.name, 'pt-BR')
    )
    .slice(0, limit)
}

// ---------------------------------------------------------------------------
// Os meses que o seletor oferece
// ---------------------------------------------------------------------------

/** Quantos meses o seletor lista, contando o corrente. */
export const LISTED_MONTHS = 12

/**
 * Os meses oferecidos, do mais recente para o mais antigo.
 *
 * Doze meses porque o ano letivo tem dez, e a direção compara "setembro deste
 * ano" com o mês passado, não com 2024. A lista não pergunta ao servidor quais
 * meses têm registro: seria uma consulta a mais para poupar uma rolagem, e um
 * mês vazio na lista responde a pergunta ("não tem nada em julho") tão bem
 * quanto a ausência dele.
 *
 * O mês aberto entra na lista mesmo fora da janela — ele pode ter vindo da
 * barra de endereço, e um seletor sem o valor que ele mostra fica em branco.
 */
export function listedMonths(
  current: MonthKey,
  today: MonthKey,
  count = LISTED_MONTHS
): MonthKey[] {
  const months: MonthKey[] = []
  const [year, index] = today.split('-').map(Number)

  for (let back = 0; back < count; back += 1) {
    const at = new Date(Date.UTC(year, index - 1 - back, 1))
    const month = `${at.getUTCFullYear()}-${String(at.getUTCMonth() + 1).padStart(2, '0')}`
    months.push(month)
  }

  if (!months.includes(current)) {
    months.push(current)
    months.sort((a, b) => b.localeCompare(a))
  }

  return months
}
