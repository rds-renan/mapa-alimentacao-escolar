import { describe, expect, it } from 'vitest'

import {
  adoptServerIds,
  canBeSent,
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
    },
  ],
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
    expect(adopted.meals[0].food_items[0].food_item_id).toBe(
      'f0000000-0000-4000-8000-000000000009'
    )
  })

  it('acha pelo nome o gênero que acabou de nascer, mesmo com caixa e espaços diferentes', () => {
    expect(adopted.meals[0].food_items[1].food_item_id).toBe(
      'f0000000-0000-4000-8000-000000000010'
    )
    expect(adopted.meals[0].menu_change?.food_items[0].food_item_id).toBe(
      'f0000000-0000-4000-8000-000000000010'
    )
  })

  it('não mexe no resto do dia', () => {
    expect(adopted.meals_served).toBe(312)
    expect(adopted.updated_at).toBe('2026-09-10T18:30:00-03:00')
    expect(adopted.meals[0].menu_change?.reason).toBe(
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
})
