import {
  MEAL_ORDER,
  newId,
  type AcceptanceLevel,
  type DayPayload,
  type MealPayload,
  type MealType,
} from '@/local/day'
import { filled, mealIsComplete } from '@/month/month'

/*
 * O dia sendo preenchido, em funções puras.
 *
 * Cada uma recebe o dia e devolve outro — nada aqui grava, envia ou desenha.
 * É de propósito: a tela do registro é um formulário grande, e a única coisa
 * difícil dele é **não perder nada** ao mexer numa parte. Com o dia inteiro
 * entrando e saindo de cada função, o que não foi tocado atravessa intacto,
 * e quem grava (a camada local) recebe sempre o dia completo — que é o que o
 * contrato de `save_meal_map` exige, já que a lista que sobe é o dia todo e
 * não um acréscimo.
 *
 * O carimbo de edição é o outro motivo: toda mudança passa por `touch`, e é
 * ele que decide a convergência entre dois aparelhos (decisão 5 da E5).
 */

export type MealState = 'complete' | 'pending' | 'empty'

export function mealOf(
  day: DayPayload,
  type: MealType
): MealPayload | undefined {
  return day.meals.find((meal) => meal.type === type)
}

/**
 * O estado da refeição, como o cartão o mostra. É a mesma regra que a visão do
 * mês usa para dizer que o dia está preenchido — uma tela não pode chamar de
 * pronta a refeição que a outra chama de pendente.
 */
export function mealState(meal: MealPayload | undefined): MealState {
  if (mealIsComplete(meal)) return 'complete'
  if (meal && (filled(meal.description) || meal.acceptance !== null)) {
    return 'pending'
  }
  return 'empty'
}

/**
 * A primeira refeição que ainda não está pronta — é nela que a tela abre.
 * Num dia vazio é o lanche da manhã; num dia que ela está completando, é onde
 * o trabalho parou. Com tudo pronto, nenhuma abre: o que ela quer ver aí é o
 * resumo dos três cartões fechados.
 */
export function firstUnfinishedMeal(day: DayPayload): MealType | null {
  return MEAL_ORDER.find((type) => !mealIsComplete(mealOf(day, type))) ?? null
}

/**
 * Quanto do dia está preenchido. São quatro partes no dia letivo — as três
 * refeições e o número de refeições —, os mesmos quatro que a visão do mês
 * confere para chamar o dia de preenchido. No dia não letivo é uma só: a
 * observação.
 */
export function dayProgress(day: DayPayload): { done: number; total: number } {
  if (day.non_school_day) {
    return { done: filled(day.note) ? 1 : 0, total: 1 }
  }

  const meals = MEAL_ORDER.filter((type) =>
    mealIsComplete(mealOf(day, type))
  ).length

  return {
    done: meals + (day.meals_served === null ? 0 : 1),
    total: MEAL_ORDER.length + 1,
  }
}

// ---------------------------------------------------------------------------
// As mudanças
// ---------------------------------------------------------------------------

/**
 * Carimba a edição com o relógio do aparelho.
 *
 * É "quando ela mexeu", não "quando chegou": um mapa preenchido na sexta sem
 * sinal e enviado no domingo precisa perder para a correção que a colega fez no
 * sábado. Toda mudança desta tela passa por aqui.
 */
export function touch(day: DayPayload): DayPayload {
  return { ...day, updated_at: new Date().toISOString() }
}

/** Mexe numa refeição, criando-a se for a primeira tecla dada nela. */
function withMeal(
  day: DayPayload,
  type: MealType,
  change: (meal: MealPayload) => MealPayload
): DayPayload {
  const existing = mealOf(day, type)

  if (existing) {
    return {
      ...day,
      meals: day.meals.map((meal) =>
        meal.type === type ? change(meal) : meal
      ),
    }
  }

  const born: MealPayload = {
    id: newId(),
    type,
    description: null,
    acceptance: null,
    food_items: [],
    menu_change: null,
  }

  return { ...day, meals: [...day.meals, change(born)] }
}

export function setDescription(
  day: DayPayload,
  type: MealType,
  description: string
): DayPayload {
  return withMeal(day, type, (meal) => ({ ...meal, description }))
}

export function setAcceptance(
  day: DayPayload,
  type: MealType,
  acceptance: AcceptanceLevel
): DayPayload {
  return withMeal(day, type, (meal) => ({ ...meal, acceptance }))
}

/**
 * O número de refeições do dia, único para as três (RN#1 da US005). Campo
 * vazio é nulo e não zero: o registro pode ficar parcial de propósito, e o
 * servidor recusa zero — refeição servida a ninguém não é um número, é a
 * ausência dele.
 */
export function setMealsServed(
  day: DayPayload,
  mealsServed: number | null
): DayPayload {
  return { ...day, meals_served: mealsServed }
}

/**
 * O teto do número de refeições: `meals_served` é um `smallint` no banco.
 * Cortar aqui evita o dia que ela preencheu voltar recusado por um dedo que
 * ficou preso na tecla.
 */
const MAX_MEALS_SERVED = 32_767

/**
 * O que ela digitou, virando número.
 *
 * Só dígitos entram: nada de sinal, ponto ou vírgula (CA#2 da US005). Campo
 * vazio é nulo — o registro parcial é legítimo —, e zero também: o banco só
 * aceita `meals_served` maior que zero, e "nenhuma refeição servida" é a
 * ausência do número, não o número zero.
 */
export function parseMealsServed(text: string): number | null {
  const digits = text.replace(/\D/g, '')
  if (digits === '') return null

  const value = Math.min(Number(digits), MAX_MEALS_SERVED)
  return value === 0 ? null : value
}

/** Um a mais, um a menos. Do vazio, o "+" começa em 1; abaixo de 1 não há. */
export function stepMealsServed(
  value: number | null,
  delta: number
): number | null {
  const next = (value ?? 0) + delta
  if (next < 1) return null
  return Math.min(next, MAX_MEALS_SERVED)
}

export function setNote(day: DayPayload, note: string): DayPayload {
  return { ...day, note }
}

/** O que só existe no dia letivo, guardado para voltar se ela desmarcar. */
export interface SchoolDayContent {
  meals: MealPayload[]
  mealsServed: number | null
}

export const NOTHING_TO_RESTORE: SchoolDayContent = {
  meals: [],
  mealsServed: null,
}

export function schoolDayContent(day: DayPayload): SchoolDayContent {
  return { meals: day.meals, mealsServed: day.meals_served }
}

/**
 * Liga e desliga o dia não letivo.
 *
 * Um dia é letivo ou não letivo, nunca os dois (RN#1 da US006) — e o servidor
 * leva isso à letra: dia não letivo com refeição é recusado, e o número de
 * refeições é descartado. Por isso marcar tira os dois do dia que vai subir, e
 * não só da tela.
 *
 * O que estava digitado volta quando ela desmarca, porque quem chama guardou o
 * conteúdo e o devolve aqui (CA#3 da US006). A devolução é da sessão: uma vez
 * gravado como não letivo, o dia não tem mais refeições em lugar nenhum — nem
 * aqui, nem no servidor.
 */
export function setNonSchoolDay(
  day: DayPayload,
  nonSchoolDay: boolean,
  restored: SchoolDayContent = NOTHING_TO_RESTORE
): DayPayload {
  if (nonSchoolDay) {
    return {
      ...day,
      non_school_day: true,
      meals: [],
      meals_served: null,
      // Vazia, e não nula: o campo da observação já está na tela esperando o
      // motivo, e é ele que falta para o dia poder subir.
      note: day.note ?? '',
    }
  }

  return {
    ...day,
    non_school_day: false,
    note: null,
    meals: restored.meals,
    meals_served: restored.mealsServed,
  }
}
