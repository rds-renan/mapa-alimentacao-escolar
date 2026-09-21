import { describe, expect, it } from 'vitest'

import type { AcceptanceLevel } from '@/local/day'
import type { DayRecord } from '@/month/month'

import {
  acceptanceByMeal,
  listedMonths,
  monthSummary,
  normalizeMeal,
  topMeals,
} from './dashboard'

/*
 * A agregação do painel, sem tela no meio (US017).
 *
 * O que estes casos protegem é a aritmética que a direção não tem como
 * conferir: ela olha "312" e acredita. O caso mais importante do arquivo é o
 * do dia não letivo — o banco **preserva** as refeições de um dia marcado como
 * não letivo (decisão 1 da E4), então um painel que filtrasse "dias sem
 * refeição" contaria um dia que não houve, e ninguém perceberia.
 */

function dayOf(mapDate: string, overrides: Partial<DayRecord> = {}): DayRecord {
  return {
    id: `map-${mapDate}`,
    mapDate,
    nonSchoolDay: false,
    note: null,
    mealsServed: 300,
    locked: false,
    reopened: false,
    pendingUpload: false,
    meals: mealsOf('great', 'good', 'poor'),
    ...overrides,
  }
}

function mealsOf(
  morning: AcceptanceLevel | null,
  lunch: AcceptanceLevel | null,
  afternoon: AcceptanceLevel | null
): DayRecord['meals'] {
  return [
    {
      type: 'morning_snack',
      description: 'Pão com leite',
      acceptance: morning,
    },
    { type: 'lunch', description: 'Arroz com frango', acceptance: lunch },
    {
      type: 'afternoon_snack',
      description: 'Bolo e suco',
      acceptance: afternoon,
    },
  ]
}

function byDate(days: DayRecord[]) {
  return new Map(days.map((day) => [day.mapDate, day]))
}

describe('os números do mês', () => {
  it('soma as refeições servidas e divide pelos dias com o número informado', () => {
    const days = [
      dayOf('2026-09-01', { mealsServed: 300 }),
      dayOf('2026-09-02', { mealsServed: 320 }),
      /* Dia registrado sem o número: não entra na soma nem no divisor. */
      dayOf('2026-09-03', { mealsServed: null }),
    ]

    const summary = monthSummary('2026-09', byDate(days))

    expect(summary.mealsServed).toBe(620)
    expect(summary.daysCounted).toBe(2)
    expect(summary.averagePerDay).toBe(310)
  })

  it('não inventa média quando nenhum dia tem o número', () => {
    const summary = monthSummary('2026-09', byDate([]))

    expect(summary.mealsServed).toBe(0)
    expect(summary.averagePerDay).toBeNull()
  })

  it('conta os dias prontos contra os dias letivos do mês', () => {
    /*
     * Setembro de 2026 tem 22 dias úteis. Dois completos, um deles já em
     * documento (que para a direção é pronto do mesmo jeito) e um não letivo.
     */
    const days = [
      dayOf('2026-09-01'),
      dayOf('2026-09-02', { locked: true }),
      dayOf('2026-09-03', {
        nonSchoolDay: true,
        note: 'Feriado municipal',
        mealsServed: null,
      }),
      dayOf('2026-09-04', { meals: mealsOf('great', null, null) }),
    ]

    const summary = monthSummary('2026-09', byDate(days))

    expect(summary.schoolDays).toBe(21)
    expect(summary.registered).toBe(2)
    expect(summary.pending).toBe(1)
    expect(summary.empty).toBe(18)
    expect(summary.nonSchoolDays).toBe(1)
  })

  it('exclui o dia não letivo pelo atributo, ainda que ele tenha refeições', () => {
    /*
     * RN#2 da US017. O dia não letivo abaixo tem as três refeições avaliadas e
     * um número de refeições — é exatamente o que sobra quando a merendeira
     * registra o dia e depois descobre que não houve aula. O banco guarda tudo
     * de propósito, para que desmarcar devolva o que estava lá.
     */
    const days = [
      dayOf('2026-09-01', { mealsServed: 300 }),
      dayOf('2026-09-02', {
        nonSchoolDay: true,
        note: 'Ponto facultativo',
        mealsServed: 999,
      }),
    ]

    const summary = monthSummary('2026-09', byDate(days))

    expect(summary.mealsServed).toBe(300)
    expect(summary.daysCounted).toBe(1)
    expect(summary.averagePerDay).toBe(300)
  })
})

describe('a aceitação por refeição', () => {
  it('conta cada grau na refeição a que ele pertence', () => {
    const days = [
      dayOf('2026-09-01', { meals: mealsOf('great', 'good', 'great') }),
      dayOf('2026-09-02', { meals: mealsOf('great', 'poor', 'poor') }),
    ]

    const acceptance = acceptanceByMeal(days)

    expect(acceptance.morning_snack.counts).toEqual({
      great: 2,
      good: 0,
      poor: 0,
    })
    expect(acceptance.lunch.counts).toEqual({ great: 0, good: 1, poor: 1 })
    expect(acceptance.morning_snack.shares.great).toBe(100)
    expect(acceptance.lunch.shares.good).toBe(50)
  })

  it('ignora a refeição sem avaliação em vez de contá-la como ruim', () => {
    const days = [dayOf('2026-09-01', { meals: mealsOf('great', null, null) })]

    const acceptance = acceptanceByMeal(days)

    expect(acceptance.morning_snack.rated).toBe(1)
    expect(acceptance.lunch.rated).toBe(0)
    expect(acceptance.lunch.shares).toEqual({ great: 0, good: 0, poor: 0 })
  })

  it('deixa a fatia exata, sem arredondar a largura da barra', () => {
    /* Três avaliações: um terço não cabe em número inteiro. */
    const days = [dayOf('2026-09-01', { meals: mealsOf('great', null, null) })]
    days.push(dayOf('2026-09-02', { meals: mealsOf('good', null, null) }))
    days.push(dayOf('2026-09-03', { meals: mealsOf('poor', null, null) }))

    const { shares } = acceptanceByMeal(days).morning_snack
    const total = shares.great + shares.good + shares.poor

    expect(total).toBeCloseTo(100)
    expect(shares.great).toBeCloseTo(33.33, 1)
  })

  it('não conta as refeições de um dia não letivo', () => {
    const days = [
      dayOf('2026-09-01', { meals: mealsOf('great', 'great', 'great') }),
      dayOf('2026-09-02', {
        nonSchoolDay: true,
        note: 'Feriado',
        mealsServed: null,
        meals: mealsOf('poor', 'poor', 'poor'),
      }),
    ]

    const acceptance = acceptanceByMeal(days)

    expect(acceptance.lunch.counts).toEqual({ great: 1, good: 0, poor: 0 })
  })
})

describe('as merendas mais bem aceitas', () => {
  it('agrupa pela descrição normalizada e ordena pela fatia de ótimo', () => {
    const days = [
      dayOf('2026-09-01', {
        meals: [
          {
            type: 'morning_snack',
            description: 'Arroz com frango',
            acceptance: 'great',
          },
          {
            type: 'lunch',
            description: 'Sopa de legumes',
            acceptance: 'poor',
          },
          {
            type: 'afternoon_snack',
            description: 'Canjica',
            acceptance: 'great',
          },
        ],
      }),
      dayOf('2026-09-02', {
        meals: [
          /* Mesma merenda, outra grafia: espaço repetido e caixa diferente. */
          {
            type: 'morning_snack',
            description: 'arroz  com  frango',
            acceptance: 'great',
          },
          {
            type: 'lunch',
            description: 'Sopa de legumes',
            acceptance: 'great',
          },
          { type: 'afternoon_snack', description: null, acceptance: 'great' },
        ],
      }),
    ]

    const top = topMeals(days)

    expect(top.map((meal) => [meal.name, meal.times, meal.greatShare])).toEqual(
      [
        /* 100% de duas vezes vem antes de 100% de uma: o desempate é a repetição. */
        ['Arroz com frango', 2, 100],
        ['Canjica', 1, 100],
        ['Sopa de legumes', 2, 50],
      ]
    )
  })

  it('só conta a merenda avaliada, e nunca a de um dia não letivo', () => {
    const days = [
      dayOf('2026-09-01', {
        meals: [
          {
            type: 'morning_snack',
            description: 'Pão com leite',
            acceptance: null,
          },
          { type: 'lunch', description: 'Feijoada', acceptance: 'great' },
          { type: 'afternoon_snack', description: null, acceptance: null },
        ],
      }),
      dayOf('2026-09-02', {
        nonSchoolDay: true,
        note: 'Feriado',
        mealsServed: null,
        meals: [
          { type: 'lunch', description: 'Feijoada', acceptance: 'poor' },
        ] as DayRecord['meals'],
      }),
    ]

    const top = topMeals(days)

    expect(top).toEqual([
      { name: 'Feijoada', times: 1, great: 1, greatShare: 100 },
    ])
  })

  it('mostra no máximo o número de merendas pedido', () => {
    const days = Array.from({ length: 8 }, (_, index) =>
      dayOf(`2026-09-0${index + 1}`, {
        meals: [
          {
            type: 'lunch',
            description: `Merenda ${index}`,
            acceptance: 'great',
          },
        ] as DayRecord['meals'],
      })
    )

    expect(topMeals(days)).toHaveLength(5)
  })

  it('normaliza como o banco normaliza o nome de um gênero', () => {
    expect(normalizeMeal('  Arroz   COM  frango ')).toBe('arroz com frango')
  })
})

describe('os meses do seletor', () => {
  it('lista doze meses, do mais recente para o mais antigo', () => {
    const months = listedMonths('2026-09', '2026-09')

    expect(months).toHaveLength(12)
    expect(months[0]).toBe('2026-09')
    expect(months[11]).toBe('2025-10')
  })

  it('inclui o mês aberto quando ele veio de fora da janela', () => {
    /* O mês pode chegar pela barra de endereço, e o seletor não pode ficar vazio. */
    const months = listedMonths('2024-03', '2026-09')

    expect(months).toContain('2024-03')
    expect(months).toHaveLength(13)
  })
})
