import { describe, expect, it } from 'vitest'

import type { DayPayload } from '@/local/day'

import {
  dayState,
  daySummary,
  groupIntoWeeks,
  listedDays,
  mergeDays,
  monthLabel,
  monthProgress,
  monthRange,
  recordFromDraft,
  shiftMonth,
  type DayRecord,
} from './month'

/*
 * O domínio do mês, que é onde mora a decisão 4 da E4: só o bloqueio vem
 * gravado, o resto é derivado. Testar isto sem React é de propósito — o que
 * pode estar errado nesta tela é a regra, não o desenho.
 */

function day(overrides: Partial<DayRecord> = {}): DayRecord {
  return {
    id: 'map-2026-09-10',
    mapDate: '2026-09-10',
    nonSchoolDay: false,
    note: null,
    mealsServed: null,
    locked: false,
    reopened: false,
    meals: [],
    pendingUpload: false,
    ...overrides,
  }
}

const THREE_MEALS: DayRecord['meals'] = [
  { type: 'morning_snack', description: 'Pão com leite', acceptance: 'great' },
  { type: 'lunch', description: 'Arroz, feijão e frango', acceptance: 'good' },
  { type: 'afternoon_snack', description: 'Bolo e suco', acceptance: 'great' },
]

describe('estados do dia', () => {
  it('sem registro é vazio', () => {
    expect(dayState(undefined)).toBe('empty')
  })

  it('registro que existe mas em que ninguém escreveu nada também é vazio', () => {
    expect(dayState(day())).toBe('empty')
  })

  it('as três refeições e o número de refeições fazem o dia completo', () => {
    expect(dayState(day({ meals: THREE_MEALS, mealsServed: 310 }))).toBe(
      'complete'
    )
  })

  it('falta a aceitação de uma refeição e o dia continua pendente (CA#3 da US004)', () => {
    const meals = THREE_MEALS.map((meal) =>
      meal.type === 'lunch' ? { ...meal, acceptance: null } : meal
    )

    expect(dayState(day({ meals, mealsServed: 310 }))).toBe('pending')
  })

  it('falta o número de refeições e o dia continua pendente', () => {
    expect(dayState(day({ meals: THREE_MEALS }))).toBe('pending')
  })

  it('dia não letivo é o seu próprio estado, e não um dia pendente', () => {
    expect(
      dayState(day({ nonSchoolDay: true, note: 'Conselho de classe' }))
    ).toBe('non_school')
  })

  it('o bloqueio vem na frente: é o único estado que muda o que ela pode fazer', () => {
    expect(
      dayState(day({ meals: THREE_MEALS, mealsServed: 310, locked: true }))
    ).toBe('locked')
    expect(
      dayState(day({ nonSchoolDay: true, note: 'Feriado', locked: true }))
    ).toBe('locked')
  })
})

describe('a linha de apoio de cada dia', () => {
  it('diz o que o dia tem quando ele está pronto', () => {
    expect(daySummary(day({ meals: THREE_MEALS, mealsServed: 310 }))).toBe(
      '3 refeições · 310 servidas'
    )
  })

  it('nomeia a refeição que falta, no singular', () => {
    const meals = THREE_MEALS.filter((meal) => meal.type !== 'afternoon_snack')

    expect(daySummary(day({ meals, mealsServed: 310 }))).toBe(
      'falta o lanche da tarde'
    )
  })

  it('junta o que falta quando é mais de uma coisa', () => {
    const meals = THREE_MEALS.filter((meal) => meal.type === 'morning_snack')

    expect(daySummary(day({ meals }))).toBe(
      'faltam o almoço, o lanche da tarde e o número de refeições'
    )
  })

  it('resume as três refeições numa expressão só quando nenhuma foi feita', () => {
    expect(daySummary(day({ mealsServed: 310 }))).toBe(
      'faltam as três refeições'
    )
  })

  it('mostra a observação do dia não letivo', () => {
    expect(
      daySummary(day({ nonSchoolDay: true, note: 'Conselho de classe' }))
    ).toBe('Conselho de classe')
  })

  it('marca o dia de hoje, que é o que ela abre nove vezes em dez', () => {
    expect(daySummary(undefined, { isToday: true })).toBe('Hoje · Sem registro')
  })
})

describe('os dias que a tela lista', () => {
  it('lista só de segunda a sexta: fim de semana não é pendência (RN#1 da US008)', () => {
    const days = listedDays('2026-09', new Set())

    expect(days).toHaveLength(22)
    expect(days).toContain('2026-09-01')
    // 5 e 6 de setembro de 2026 são sábado e domingo.
    expect(days).not.toContain('2026-09-05')
    expect(days).not.toContain('2026-09-06')
  })

  it('traz o fim de semana que tem registro, para ele não ficar inalcançável', () => {
    const days = listedDays('2026-09', new Set(['2026-09-05']))

    expect(days).toContain('2026-09-05')
    expect(days).not.toContain('2026-09-06')
  })

  it('quebra as semanas na segunda-feira, e não a cada sete dias', () => {
    const weeks = groupIntoWeeks(listedDays('2026-09', new Set()))

    // Setembro de 2026 começa numa terça: a primeira semana tem 4 dias.
    expect(weeks[0].days).toEqual([
      '2026-09-01',
      '2026-09-02',
      '2026-09-03',
      '2026-09-04',
    ])
    expect(weeks[0].label).toBe('Semana 1 · 1 a 4 de setembro')
    expect(weeks[1].days[0]).toBe('2026-09-07')
  })
})

describe('o andamento do mês', () => {
  it('conta os dias prontos e tira os não letivos do total', () => {
    const days = listedDays('2026-09', new Set())
    const byDate = new Map<string, DayRecord>([
      [
        '2026-09-01',
        day({
          mapDate: '2026-09-01',
          meals: THREE_MEALS,
          mealsServed: 310,
          locked: true,
        }),
      ],
      [
        '2026-09-02',
        day({ mapDate: '2026-09-02', meals: THREE_MEALS, mealsServed: 305 }),
      ],
      ['2026-09-03', day({ mapDate: '2026-09-03', meals: THREE_MEALS })],
      [
        '2026-09-04',
        day({ mapDate: '2026-09-04', nonSchoolDay: true, note: 'Conselho' }),
      ],
    ])

    const progress = monthProgress(days, byDate)

    expect(progress.schoolDays).toBe(21)
    expect(progress.done).toBe(2)
    expect(progress.counts).toEqual({
      locked: 1,
      complete: 1,
      pending: 1,
      non_school: 1,
      empty: 18,
    })
  })
})

describe('o mês em si', () => {
  it('nomeia o mês como ela o lê', () => {
    expect(monthLabel('2026-09')).toBe('Setembro de 2026')
  })

  it('anda de mês virando o ano', () => {
    expect(shiftMonth('2026-01', -1)).toBe('2025-12')
    expect(shiftMonth('2026-12', 1)).toBe('2027-01')
  })

  it('fecha o recorte no último dia, inclusive em fevereiro bissexto', () => {
    expect(monthRange('2026-09')).toEqual({
      first: '2026-09-01',
      last: '2026-09-30',
    })
    expect(monthRange('2028-02').last).toBe('2028-02-29')
  })
})

describe('o rascunho do aparelho e a linha do servidor', () => {
  const draft: DayPayload = {
    id: '11111111-1111-4111-8111-111111111111',
    map_date: '2026-09-10',
    updated_at: '2026-09-10T18:00:00.000Z',
    non_school_day: false,
    note: null,
    meals_served: 310,
    meals: THREE_MEALS.map((meal, index) => ({
      id: `2222222${index}-2222-4222-8222-222222222222`,
      type: meal.type,
      description: meal.description,
      acceptance: meal.acceptance,
      food_items: [],
      menu_change: null,
    })),
  }

  it('o rascunho prevalece: é ele que ainda não foi confirmado', () => {
    const byDate = mergeDays(
      [day({ mapDate: '2026-09-10' })],
      [recordFromDraft(draft)]
    )

    expect(dayState(byDate.get('2026-09-10'))).toBe('complete')
    expect(byDate.get('2026-09-10')?.pendingUpload).toBe(true)
  })

  it('mas o bloqueio continua vindo do servidor, que é quem o conhece', () => {
    const byDate = mergeDays(
      [day({ mapDate: '2026-09-10', locked: true })],
      [recordFromDraft(draft)]
    )

    expect(dayState(byDate.get('2026-09-10'))).toBe('locked')
  })
})
