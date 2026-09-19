import { describe, expect, it } from 'vitest'

import { canBeSent, emptyDay, type DayPayload } from '@/local/day'

import {
  addFoodItem,
  dayProgress,
  firstUnfinishedMeal,
  mealOf,
  mealState,
  menuChangeIsComplete,
  menuChangeIsEmpty,
  parseMealsServed,
  parseQuantity,
  removeFoodItem,
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

// ---------------------------------------------------------------------------
// Os gêneros utilizados e a alteração do cardápio (issue #63)
// ---------------------------------------------------------------------------

const RICE = { food_item_id: 'rice', name: 'Arroz', unit: 'quilo' }
const EGG = { food_item_id: null, name: 'Ovo', unit: 'bandeja' }

describe('os gêneros de uma refeição', () => {
  it('entram com a quantidade em 1 e com a unidade do catálogo', () => {
    const day = addFoodItem(emptyDay(DATE), 'lunch', 'meal', RICE)
    const [item] = mealOf(day, 'lunch')?.food_items ?? []

    expect(item).toEqual({ ...RICE, quantity: 1 })
  })

  it('não entram duas vezes, nem voltam para 1 quando ela repete o gesto', () => {
    let day = addFoodItem(emptyDay(DATE), 'lunch', 'meal', RICE)
    day = setFoodItemQuantity(day, 'lunch', 'meal', 'arroz', 4)
    // O mesmo gênero, com a caixa e o espaço que o servidor normalizaria.
    day = addFoodItem(day, 'lunch', 'meal', { ...RICE, name: ' ARROZ ' })

    expect(mealOf(day, 'lunch')?.food_items).toEqual([{ ...RICE, quantity: 4 }])
  })

  it('andam de um em um, e o "−" de quem está em 1 tira o gênero', () => {
    let day = addFoodItem(emptyDay(DATE), 'lunch', 'meal', RICE)
    day = stepFoodItemQuantity(day, 'lunch', 'meal', 'arroz', 1)
    expect(mealOf(day, 'lunch')?.food_items[0].quantity).toBe(2)

    day = stepFoodItemQuantity(day, 'lunch', 'meal', 'arroz', -1)
    expect(mealOf(day, 'lunch')?.food_items[0].quantity).toBe(1)

    day = stepFoodItemQuantity(day, 'lunch', 'meal', 'arroz', -1)
    expect(mealOf(day, 'lunch')?.food_items).toEqual([])
  })

  it('não passam do que o banco guarda, e não descem abaixo de 1', () => {
    let day = addFoodItem(emptyDay(DATE), 'lunch', 'meal', RICE)
    day = setFoodItemQuantity(day, 'lunch', 'meal', 'arroz', 99_999)
    expect(mealOf(day, 'lunch')?.food_items[0].quantity).toBe(32_767)

    day = setFoodItemQuantity(day, 'lunch', 'meal', 'arroz', 0)
    expect(mealOf(day, 'lunch')?.food_items[0].quantity).toBe(1)
  })

  it('aceitam só dígitos no campo da quantidade', () => {
    expect(parseQuantity('4')).toBe(4)
    expect(parseQuantity('4,5')).toBe(45)
    expect(parseQuantity('')).toBeNull()
    expect(parseQuantity('0')).toBeNull()
  })

  it('não se misturam com os da troca: são duas listas', () => {
    let day = addFoodItem(emptyDay(DATE), 'lunch', 'meal', RICE)
    day = addFoodItem(day, 'lunch', 'menu_change', EGG)

    expect(mealOf(day, 'lunch')?.food_items).toHaveLength(1)
    expect(mealOf(day, 'lunch')?.menu_change?.food_items).toHaveLength(1)
    expect(mealOf(day, 'lunch')?.food_items[0].name).toBe('Arroz')
  })

  it('não mexem na descrição nem na aceitação da refeição (CA#3 da US002)', () => {
    let day = dayWithMeals()
    day = addFoodItem(day, 'morning_snack', 'menu_change', EGG)
    day = setMenuChangeReason(day, 'morning_snack', 'Não veio o pão.')

    const meal = mealOf(day, 'morning_snack')
    expect(meal?.description).toBe('Pão com manteiga')
    expect(meal?.acceptance).toBe('great')
  })
})

describe('a alteração do cardápio', () => {
  it('nasce do primeiro gesto, mesmo antes de ter motivo', () => {
    const day = addFoodItem(emptyDay(DATE), 'lunch', 'menu_change', EGG)
    const change = mealOf(day, 'lunch')?.menu_change

    expect(change?.reason).toBe('')
    expect(change?.food_items).toEqual([{ ...EGG, quantity: 1 }])
  })

  it('é uma só por refeição (RN#2 da US002)', () => {
    let day = addFoodItem(emptyDay(DATE), 'lunch', 'menu_change', EGG)
    const born = mealOf(day, 'lunch')?.menu_change?.id
    day = addFoodItem(day, 'lunch', 'menu_change', RICE)

    expect(mealOf(day, 'lunch')?.menu_change?.id).toBe(born)
    expect(mealOf(day, 'lunch')?.menu_change?.food_items).toHaveLength(2)
  })

  it('só está inteira com gênero e motivo', () => {
    let day = addFoodItem(emptyDay(DATE), 'lunch', 'menu_change', EGG)
    expect(
      menuChangeIsComplete(mealOf(day, 'lunch')?.menu_change ?? null)
    ).toBe(false)

    day = setMenuChangeReason(day, 'lunch', '   ')
    expect(
      menuChangeIsComplete(mealOf(day, 'lunch')?.menu_change ?? null)
    ).toBe(false)

    day = setMenuChangeReason(day, 'lunch', 'Não veio o frango.')
    expect(
      menuChangeIsComplete(mealOf(day, 'lunch')?.menu_change ?? null)
    ).toBe(true)
  })

  it('aberta e fechada sem nada dentro é vazia, e sai do dia', () => {
    let day = setMenuChangeReason(emptyDay(DATE), 'lunch', '')
    expect(menuChangeIsEmpty(mealOf(day, 'lunch')?.menu_change ?? null)).toBe(
      true
    )

    day = setMenuChange(day, 'lunch', null)
    expect(mealOf(day, 'lunch')?.menu_change).toBeNull()
  })

  it('volta ao que era quando ela cancela', () => {
    let day = addFoodItem(emptyDay(DATE), 'lunch', 'menu_change', EGG)
    day = setMenuChangeReason(day, 'lunch', 'Não veio o frango.')
    const before = mealOf(day, 'lunch')?.menu_change ?? null

    day = setMenuChangeReason(day, 'lunch', 'outra coisa')
    day = removeFoodItem(day, 'lunch', 'menu_change', 'ovo')
    day = setMenuChange(day, 'lunch', before)

    expect(mealOf(day, 'lunch')?.menu_change).toEqual(before)
  })
})

describe('o que a fila deixa subir', () => {
  it('segura o dia enquanto a alteração não tem motivo nem gênero', () => {
    let day = addFoodItem(emptyDay(DATE), 'lunch', 'menu_change', EGG)
    expect(canBeSent(day)).toBe(false)

    day = setMenuChangeReason(day, 'lunch', 'Não veio o frango.')
    expect(canBeSent(day)).toBe(true)

    day = removeFoodItem(day, 'lunch', 'menu_change', 'ovo')
    expect(canBeSent(day)).toBe(false)
  })

  it('deixa subir a refeição com gêneros e sem alteração nenhuma', () => {
    const day = addFoodItem(emptyDay(DATE), 'lunch', 'meal', RICE)
    expect(canBeSent(day)).toBe(true)
  })

  it('segura o gênero a nascer que ficou sem unidade', () => {
    const day = addFoodItem(emptyDay(DATE), 'lunch', 'meal', {
      food_item_id: null,
      name: 'Feijão preto',
      unit: null,
    })

    expect(canBeSent(day)).toBe(false)
  })
})
