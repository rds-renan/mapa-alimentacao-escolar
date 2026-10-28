import { describe, expect, it } from 'vitest'

import {
  adoptServerIds,
  canBeSent,
  upgradeDay,
  type DayPayload,
  type SaveResponse,
} from './day'

/*
 * O contrato da gravação é explícito: o cliente precisa adotar os
 * identificadores que voltaram, porque são eles que fazem o próximo envio
 * encontrar o registro em vez de tentar criá-lo de novo.
 */

const day: DayPayload = {
  id: 'a0000000-0000-4000-8000-000000000001',
  map_date: '2026-09-10',
  updated_at: '2026-09-10T18:30:00-03:00',
  non_school_day: false,
  note: null,
  meals_served: 312,
  meals: [
    {
      id: 'b0000000-0000-4000-8000-000000000001',
      type: 'lunch',
      description: 'Arroz, feijão e frango',
      acceptance: 'good',
    },
  ],
  food_items: [
    // Um do catálogo, com o identificador que o aparelho inventou...
    {
      food_item_id: 'd0000000-0000-4000-8000-000000000001',
      name: 'Arroz',
      unit: 'quilo',
      quantity: 5,
    },
    // ...e um que vai nascer no servidor, que só tem nome.
    { food_item_id: null, name: ' ovo ', unit: 'bandeja', quantity: 3 },
  ],
  menu_change: {
    id: 'e0000000-0000-4000-8000-000000000001',
    reason: 'Não veio o frango na entrega da semana.',
    food_items: [
      { food_item_id: null, name: 'Ovo', unit: 'bandeja', quantity: 3 },
    ],
  },
}

const response: SaveResponse = {
  status: 'saved',
  // O dia já existia no servidor, criado pelo outro aparelho: vale o dele.
  meal_map_id: 'c0000010-0000-4000-8000-000000000010',
  sent_meal_map_id: 'a0000000-0000-4000-8000-000000000001',
  map_date: '2026-09-10',
  locked: false,
  updated_at: '2026-09-10T21:30:00+00:00',
  updated_by: '22222222-2222-4222-8222-222222222222',
  food_items: [
    {
      sent_id: 'd0000000-0000-4000-8000-000000000001',
      id: 'f0000000-0000-4000-8000-000000000009',
      name: 'Arroz',
      unit: 'quilo',
      created: false,
    },
    {
      sent_id: null,
      id: 'f0000000-0000-4000-8000-000000000010',
      name: 'Ovo',
      unit: 'bandeja',
      created: true,
    },
  ],
}

describe('adotar o que o servidor devolveu', () => {
  const adopted = adoptServerIds(day, response)

  it('troca o identificador do mapa pelo que valeu', () => {
    expect(adopted.id).toBe('c0000010-0000-4000-8000-000000000010')
  })

  it('troca o identificador do gênero que o aparelho tinha inventado', () => {
    expect(adopted.food_items[0].food_item_id).toBe(
      'f0000000-0000-4000-8000-000000000009'
    )
  })

  it('acha pelo nome o gênero que acabou de nascer, mesmo com caixa e espaços diferentes', () => {
    expect(adopted.food_items[1].food_item_id).toBe(
      'f0000000-0000-4000-8000-000000000010'
    )
    expect(adopted.menu_change?.food_items[0].food_item_id).toBe(
      'f0000000-0000-4000-8000-000000000010'
    )
  })

  it('não mexe no resto do dia', () => {
    expect(adopted.meals_served).toBe(312)
    expect(adopted.updated_at).toBe('2026-09-10T18:30:00-03:00')
    expect(adopted.menu_change?.reason).toBe(
      'Não veio o frango na entrega da semana.'
    )
  })
})

/*
 * A pergunta que a fila faz antes de tentar: o servidor aceitaria este dia?
 * Ela existe para que o meio do caminho — o dia não letivo cuja observação ela
 * ainda não escreveu — fique guardado no aparelho em vez de voltar recusado.
 */
describe('o dia em condição de subir', () => {
  const schoolDay: DayPayload = { ...day }

  it('deixa passar o dia letivo, completo ou pela metade', () => {
    expect(canBeSent(schoolDay)).toBe(true)
    expect(canBeSent({ ...schoolDay, meals: [], meals_served: null })).toBe(
      true
    )
  })

  it('segura o dia não letivo enquanto não há o motivo', () => {
    const marked: DayPayload = {
      ...schoolDay,
      non_school_day: true,
      meals: [],
      meals_served: null,
      food_items: [],
      menu_change: null,
      note: '',
    }

    expect(canBeSent(marked)).toBe(false)
    expect(canBeSent({ ...marked, note: '   ' })).toBe(false)
    expect(canBeSent({ ...marked, note: 'Conselho de classe' })).toBe(true)
  })

  it('segura o dia não letivo que ainda carrega refeições', () => {
    expect(
      canBeSent({
        ...schoolDay,
        non_school_day: true,
        note: 'Conselho de classe',
      })
    ).toBe(false)
  })

  it('segura o dia não letivo que ainda carrega gêneros', () => {
    expect(
      canBeSent({
        ...schoolDay,
        non_school_day: true,
        note: 'Conselho de classe',
        meals: [],
        meals_served: null,
        menu_change: null,
      })
    ).toBe(false)
  })

  it('segura a alteração sem motivo ou sem gênero', () => {
    const change = schoolDay.menu_change!
    expect(
      canBeSent({ ...schoolDay, menu_change: { ...change, reason: ' ' } })
    ).toBe(false)
    expect(
      canBeSent({ ...schoolDay, menu_change: { ...change, food_items: [] } })
    ).toBe(false)
  })
})

/*
 * O rascunho e a fila guardados antes da decisão 14 da E4 trazem os gêneros
 * dentro de cada refeição. A conversão é a mesma junção da migration: nada se
 * perde, e o que se repete soma.
 */
describe('o dia guardado no formato antigo', () => {
  const legacy = {
    id: 'a0000000-0000-4000-8000-000000000002',
    map_date: '2026-10-01',
    updated_at: '2026-10-01T18:30:00-03:00',
    non_school_day: false,
    note: null,
    meals_served: 90,
    meals: [
      {
        id: 'm2',
        type: 'lunch',
        description: 'Arroz e frango',
        acceptance: 'good',
        food_items: [
          { food_item_id: 'arroz', name: 'Arroz', unit: 'kg', quantity: 3 },
        ],
        menu_change: {
          id: 'c-almoco',
          reason: 'Faltou frango',
          food_items: [
            { food_item_id: 'ovo', name: 'Ovo', unit: 'un', quantity: 10 },
            { food_item_id: 'suco', name: 'Suco', unit: 'L', quantity: 1 },
          ],
        },
      },
      {
        id: 'm1',
        type: 'morning_snack',
        description: 'Leite',
        acceptance: 'great',
        food_items: [
          { food_item_id: 'leite', name: 'Leite', unit: 'L', quantity: 1 },
          { food_item_id: null, name: ' arroz ', unit: 'kg', quantity: 2 },
        ],
        menu_change: {
          id: 'c-manha',
          reason: 'Faltou leite',
          food_items: [
            { food_item_id: 'suco', name: 'Suco', unit: 'L', quantity: 2 },
          ],
        },
      },
    ],
  } as unknown as DayPayload

  const upgraded = upgradeDay(legacy)

  it('tira os gêneros e a alteração de dentro das refeições', () => {
    expect(upgraded.meals).toEqual([
      {
        id: 'm2',
        type: 'lunch',
        description: 'Arroz e frango',
        acceptance: 'good',
      },
      {
        id: 'm1',
        type: 'morning_snack',
        description: 'Leite',
        acceptance: 'great',
      },
    ])
  })

  it('soma o mesmo gênero que estava em duas refeições', () => {
    expect(
      upgraded.food_items.map((item) => [item.name, item.quantity])
    ).toEqual([
      ['Leite', 1],
      ['Arroz', 5],
    ])
  })

  it('junta as alterações na ordem das refeições, somando os gêneros', () => {
    expect(upgraded.menu_change?.id).toBe('c-manha')
    expect(upgraded.menu_change?.reason).toBe('Faltou leite / Faltou frango')
    expect(
      upgraded.menu_change?.food_items.map((item) => [item.name, item.quantity])
    ).toEqual([
      ['Suco', 3],
      ['Ovo', 10],
    ])
  })

  it('não mexe no carimbo, que é o que a fila compara ao confirmar', () => {
    expect(upgraded.updated_at).toBe(legacy.updated_at)
  })

  it('deixa intacto o dia que já está no formato novo', () => {
    expect(upgradeDay(day)).toBe(day)
  })
})
