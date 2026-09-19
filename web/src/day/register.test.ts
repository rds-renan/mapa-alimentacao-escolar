import { describe, expect, it } from 'vitest'

import { emptyDay, type DayPayload } from '@/local/day'

import {
  dayProgress,
  firstUnfinishedMeal,
  mealOf,
  mealState,
  parseMealsServed,
  schoolDayContent,
  setAcceptance,
  setDescription,
  setMealsServed,
  setNonSchoolDay,
  setNote,
  stepMealsServed,
  touch,
} from './register'

/*
 * As regras do registro, sem tela no meio.
 *
 * O que se verifica aqui é o que a tela não pode errar de jeito nenhum: não
 * perder o que já estava escrito ao mexer numa parte, e não montar um dia que
 * o servidor recusaria.
 */

const DATE = '2026-09-10'

function dayWithMeals(): DayPayload {
  let day = emptyDay(DATE)
  day = setDescription(day, 'morning_snack', 'Pão com manteiga')
  day = setAcceptance(day, 'morning_snack', 'great')
  day = setDescription(day, 'lunch', 'Arroz, feijão e frango')
  day = setMealsServed(day, 312)
  return day
}

describe('o estado de cada refeição', () => {
  const day = dayWithMeals()

  it('é preenchida com descrição e aceitação, pendente com uma só, vazia sem nenhuma', () => {
    expect(mealState(mealOf(day, 'morning_snack'))).toBe('complete')
    expect(mealState(mealOf(day, 'lunch'))).toBe('pending')
    expect(mealState(mealOf(day, 'afternoon_snack'))).toBe('empty')
  })

  it('não conta descrição que é só espaço', () => {
    const blank = setDescription(emptyDay(DATE), 'lunch', '   ')
    expect(mealState(mealOf(blank, 'lunch'))).toBe('empty')
  })

  it('abre a tela na primeira refeição que falta', () => {
    expect(firstUnfinishedMeal(day)).toBe('lunch')
    expect(firstUnfinishedMeal(emptyDay(DATE))).toBe('morning_snack')
  })
})

describe('o andamento do dia', () => {
  it('conta as três refeições e o número de refeições', () => {
    expect(dayProgress(dayWithMeals())).toEqual({ done: 2, total: 4 })
    expect(dayProgress(emptyDay(DATE))).toEqual({ done: 0, total: 4 })
  })

  it('no dia não letivo, conta só a observação', () => {
    const marked = setNonSchoolDay(emptyDay(DATE), true)

    expect(dayProgress(marked)).toEqual({ done: 0, total: 1 })
    expect(dayProgress(setNote(marked, 'Conselho de classe'))).toEqual({
      done: 1,
      total: 1,
    })
  })
})

describe('mexer numa parte não mexe no resto', () => {
  it('cria a refeição na primeira tecla, sem tocar nas outras', () => {
    const day = setDescription(dayWithMeals(), 'afternoon_snack', 'Bolo')

    expect(day.meals).toHaveLength(3)
    expect(mealOf(day, 'morning_snack')?.description).toBe('Pão com manteiga')
    expect(mealOf(day, 'morning_snack')?.acceptance).toBe('great')
    expect(day.meals_served).toBe(312)
  })

  it('a aceitação é de uma refeição só (RN#1 da US004)', () => {
    const day = setAcceptance(dayWithMeals(), 'lunch', 'poor')

    expect(mealOf(day, 'lunch')?.acceptance).toBe('poor')
    expect(mealOf(day, 'morning_snack')?.acceptance).toBe('great')
    expect(mealOf(day, 'lunch')?.description).toBe('Arroz, feijão e frango')
  })

  it('o carimbo da edição anda a cada mudança', () => {
    const before = emptyDay(DATE)
    before.updated_at = '2026-09-10T18:00:00.000Z'

    expect(touch(before).updated_at > before.updated_at).toBe(true)
  })
})

describe('o dia não letivo', () => {
  it('tira as refeições e o número do dia que vai subir (RN#1 da US006)', () => {
    const marked = setNonSchoolDay(dayWithMeals(), true)

    expect(marked.non_school_day).toBe(true)
    expect(marked.meals).toEqual([])
    expect(marked.meals_served).toBeNull()
    expect(marked.note).toBe('')
  })

  it('devolve o que estava digitado quando ela desmarca (CA#3 da US006)', () => {
    const day = dayWithMeals()
    const kept = schoolDayContent(day)
    const marked = setNote(setNonSchoolDay(day, true), 'Conselho de classe')

    const back = setNonSchoolDay(marked, false, kept)

    expect(back.non_school_day).toBe(false)
    expect(back.note).toBeNull()
    expect(back.meals_served).toBe(312)
    expect(mealOf(back, 'morning_snack')?.description).toBe('Pão com manteiga')
  })
})

describe('o número de refeições', () => {
  it('aceita só dígitos e recusa o zero', () => {
    expect(parseMealsServed('312')).toBe(312)
    expect(parseMealsServed('3a1,2')).toBe(312)
    expect(parseMealsServed('')).toBeNull()
    expect(parseMealsServed('0')).toBeNull()
    expect(parseMealsServed('-5')).toBe(5)
  })

  it('não passa do que o banco guarda', () => {
    expect(parseMealsServed('99999')).toBe(32767)
  })

  it('anda de um em um, e abaixo de um volta a ser vazio', () => {
    expect(stepMealsServed(null, 1)).toBe(1)
    expect(stepMealsServed(312, 1)).toBe(313)
    expect(stepMealsServed(1, -1)).toBeNull()
    expect(stepMealsServed(null, -1)).toBeNull()
  })
})
