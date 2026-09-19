import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'

import type { DayPayload, SaveResponse } from './day'
import { SYNC_MESSAGES } from './messages'
import { closeLocalDatabase, getStoredDay } from './store'
import { createSyncEngine, type SyncEngine } from './sync'

/*
 * A fila é o que quebra em silêncio neste produto: um mapa que não subiu não
 * reclama, e ninguém descobre até o dia da entrega do documento. Por isso a
 * decisão 11 da E5 aponta para cá o peso dos testes da etapa.
 *
 * O servidor é de mentira, mas o contrato é o de verdade: as respostas e os
 * códigos de erro daqui são os que `save_meal_map` devolve, como está descrito
 * em docs/05-web/gravacao-do-dia.md.
 */

const rpc = vi.fn()

vi.mock('@/lib/supabase', () => ({
  supabase: {
    rpc: (...args: unknown[]) => rpc(...args),
  },
}))

const COOK = '22222222-2222-4222-8222-222222222222'
const OTHER_COOK = '33333333-3333-4333-8333-333333333333'
const DATE = '2026-09-10'

function dayFor(updatedAt: string, mapDate = DATE): DayPayload {
  return {
    id: 'a0000000-0000-4000-8000-000000000001',
    map_date: mapDate,
    updated_at: updatedAt,
    non_school_day: false,
    note: null,
    meals_served: 312,
    meals: [
      {
        id: 'b0000000-0000-4000-8000-000000000001',
        type: 'morning_snack',
        description: 'Pão com manteiga e leite com achocolatado',
        acceptance: 'great',
        food_items: [
          { food_item_id: null, name: 'Pão', unit: 'quilo', quantity: 4 },
        ],
        menu_change: null,
      },
    ],
  }
}

function saved(overrides: Partial<SaveResponse> = {}) {
  const response: SaveResponse = {
    status: 'saved',
    meal_map_id: 'c0000010-0000-4000-8000-000000000010',
    sent_meal_map_id: 'a0000000-0000-4000-8000-000000000001',
    map_date: DATE,
    locked: false,
    updated_at: '2026-09-10T21:30:00+00:00',
    updated_by: COOK,
    food_items: [],
    ...overrides,
  }

  return { data: response, error: null }
}

function failure(code: string, message: string) {
  return { data: null, error: { code, message, details: '', hint: '' } }
}

/** Falha de rede: o erro chega sem código nenhum. */
function offlineFailure() {
  return {
    data: null,
    error: { code: '', message: 'Failed to fetch', details: '', hint: '' },
  }
}

function setOnline(online: boolean) {
  Object.defineProperty(navigator, 'onLine', {
    configurable: true,
    get: () => online,
  })
}

const engines: SyncEngine[] = []

function engineFor(userId = COOK): SyncEngine {
  const engine = createSyncEngine(userId)
  engines.push(engine)
  return engine
}

beforeEach(() => {
  rpc.mockReset()
  setOnline(true)
})

afterEach(() => {
  for (const engine of engines.splice(0)) engine.stop()
})

describe('o rascunho no aparelho', () => {
  it('guarda cada alteração sem botão de salvar, e sobrevive a fechar o navegador', async () => {
    const engine = engineFor()
    await engine.save(dayFor('2026-09-10T18:30:00-03:00'))

    // Fechar e reabrir o navegador: a conexão cai, o motor é outro, o disco é
    // o mesmo (CA#3 da US010).
    closeLocalDatabase()

    const reopened = engineFor()
    const draft = await reopened.load(DATE)

    expect(draft?.meals_served).toBe(312)
    expect(draft?.meals[0].description).toContain('Pão com manteiga')
  })

  it('não mostra à colega o rascunho de quem preencheu', async () => {
    await engineFor(COOK).save(dayFor('2026-09-10T18:30:00-03:00'))

    expect(await engineFor(OTHER_COOK).load(DATE)).toBeNull()
  })
})

describe('a fila de envio', () => {
  it('sobe o dia inteiro numa chamada e só então o tira do aparelho', async () => {
    rpc.mockResolvedValueOnce(saved())

    const engine = engineFor()
    await engine.save(dayFor('2026-09-10T18:30:00-03:00'))
    await engine.flush()

    expect(rpc).toHaveBeenCalledTimes(1)
    expect(rpc.mock.calls[0][0]).toBe('save_meal_map')
    expect(rpc.mock.calls[0][1]).toEqual({
      payload: dayFor('2026-09-10T18:30:00-03:00'),
    })

    // Confirmado no servidor, e só aí, o dia deixa de ocupar o aparelho
    // (RN#1 da US011).
    expect(await getStoredDay(COOK, DATE)).toBeNull()
    expect(engine.getState().pending).toBe(0)
    expect(engine.getState().days[DATE].message).toBe(SYNC_MESSAGES.sent)
  })

  it('reenvia com a mesma carga, e o dia entregue não vira registro duplicado', async () => {
    // A rede caiu entre a gravação e a confirmação: o aparelho reenvia sem
    // saber se chegou.
    rpc.mockResolvedValueOnce(offlineFailure()).mockResolvedValueOnce(saved())

    const engine = engineFor()
    await engine.save(dayFor('2026-09-10T18:30:00-03:00'))

    await engine.flush()
    expect(engine.getState().days[DATE].message).toBe(SYNC_MESSAGES.failed)
    expect(await getStoredDay(COOK, DATE)).not.toBeNull()

    await engine.flush()

    // A carga é idêntica, com o mesmo carimbo de edição — é isso que faz o
    // servidor reescrever o mesmo dia em vez de criar um segundo.
    expect(rpc).toHaveBeenCalledTimes(2)
    expect(rpc.mock.calls[1][1]).toEqual(rpc.mock.calls[0][1])
    expect(await getStoredDay(COOK, DATE)).toBeNull()
  })

  it('não tenta enviar sem rede, e a faixa diz que está salvo no aparelho', async () => {
    setOnline(false)

    const engine = engineFor()
    engine.start()
    await engine.save(dayFor('2026-09-10T18:30:00-03:00'))
    await engine.flush()

    expect(rpc).not.toHaveBeenCalled()
    expect(engine.getState().days[DATE].message).toBe(SYNC_MESSAGES.pending)
  })

  it('reenvia sozinha quando a rede volta, sem a usuária pedir', async () => {
    setOnline(false)
    rpc.mockResolvedValue(saved())

    const engine = engineFor()
    engine.start()
    await engine.save(dayFor('2026-09-10T18:30:00-03:00'))
    await engine.flush()
    expect(rpc).not.toHaveBeenCalled()

    // O navegador avisa que a internet voltou. Ninguém tocou em nada
    // (CA#1 da US011).
    setOnline(true)
    window.dispatchEvent(new Event('online'))
    await engine.flush()

    expect(rpc).toHaveBeenCalledTimes(1)
    expect(await getStoredDay(COOK, DATE)).toBeNull()
  })

  it('adota o identificador que o servidor devolveu, e não descarta a tecla que veio no meio', async () => {
    const engine = engineFor()

    /*
     * Ela continuou digitando enquanto o envio estava no ar. O dia confirmado
     * não é mais o que está no aparelho: o que fica guardado é o mais novo — já
     * com o mapa e o gênero que o servidor criou, para o próximo envio achar o
     * registro em vez de tentar criá-lo de novo.
     */
    rpc.mockImplementationOnce(async () => {
      await engine.save(dayFor('2026-09-10T18:35:00-03:00'))
      return saved({
        food_items: [
          {
            sent_id: null,
            id: '5005748a-0000-4000-8000-000000000001',
            name: 'Pão',
            unit: 'quilo',
            created: true,
          },
        ],
      })
    })

    await engine.save(dayFor('2026-09-10T18:30:00-03:00'))
    await engine.flush()

    const stored = await getStoredDay(COOK, DATE)
    expect(stored?.day.updated_at).toBe('2026-09-10T18:35:00-03:00')
    expect(stored?.day.id).toBe('c0000010-0000-4000-8000-000000000010')
    expect(stored?.day.meals[0].food_items[0].food_item_id).toBe(
      '5005748a-0000-4000-8000-000000000001'
    )
  })
})

describe('a convergência entre aparelhos', () => {
  it('sinaliza o conflito e nunca o resolve em silêncio', async () => {
    rpc.mockResolvedValueOnce({
      data: {
        status: 'superseded',
        meal_map_id: 'c0000010-0000-4000-8000-000000000010',
        sent_meal_map_id: 'a0000000-0000-4000-8000-000000000001',
        map_date: DATE,
        locked: false,
        updated_at: '2026-09-11T10:00:00+00:00',
        updated_by: OTHER_COOK,
        food_items: [],
      },
      error: null,
    })

    const engine = engineFor()
    await engine.save(dayFor('2026-09-10T18:30:00-03:00'))
    await engine.flush()

    const [conflict] = engine.getState().conflicts
    expect(conflict.mapDate).toBe(DATE)
    expect(conflict.message).toContain('10/09')
    expect(conflict.message).toContain('outro aparelho')
    expect(conflict.updatedAt).toBe('2026-09-11T10:00:00+00:00')

    // Prevalece a edição mais recente: o dia sai do aparelho e a tela passa a
    // ler o do servidor. O que não acontece é sair calado.
    expect(await getStoredDay(COOK, DATE)).toBeNull()

    engine.dismissConflict(DATE)
    expect(engine.getState().conflicts).toHaveLength(0)
  })

  it('avisa do conflito sem descartar a tecla que veio durante o envio', async () => {
    const engine = engineFor()

    rpc
      .mockImplementationOnce(async () => {
        await engine.save(dayFor('2026-09-10T19:00:00-03:00'))
        return {
          data: {
            status: 'superseded',
            meal_map_id: 'c0000010-0000-4000-8000-000000000010',
            sent_meal_map_id: 'a0000000-0000-4000-8000-000000000001',
            map_date: DATE,
            locked: false,
            updated_at: '2026-09-10T18:45:00-03:00',
            updated_by: OTHER_COOK,
            food_items: [],
          },
          error: null,
        }
      })
      .mockResolvedValueOnce(saved())

    await engine.save(dayFor('2026-09-10T18:30:00-03:00'))
    await engine.flush()

    // Quem perdeu a convergência foi a edição de 18:30, que era a que estava
    // subindo. A de 19:00 é mais nova que a do outro aparelho e ainda tem de
    // subir — apagá-la junto seria perder o que ela acabou de digitar.
    expect(engine.getState().conflicts).toHaveLength(1)
    const stored = await getStoredDay(COOK, DATE)
    expect(stored?.day.updated_at).toBe('2026-09-10T19:00:00-03:00')

    await engine.flush()
    expect(await getStoredDay(COOK, DATE)).toBeNull()
  })
})

describe('as recusas do servidor', () => {
  it('para de insistir no que não se resolve reenviando, sem jogar o dia fora', async () => {
    rpc.mockResolvedValue(
      failure('23514', 'A quantidade de "Pão" precisa ser maior que zero.')
    )

    const engine = engineFor()
    await engine.save(dayFor('2026-09-10T18:30:00-03:00'))
    await engine.flush()
    await engine.flush()

    // Uma tentativa só: reenviar daria exatamente o mesmo erro.
    expect(rpc).toHaveBeenCalledTimes(1)

    // Mas o que ela digitou continua no aparelho, esperando a correção.
    expect(await getStoredDay(COOK, DATE)).not.toBeNull()

    const day = engine.getState().days[DATE]
    expect(day.message).toBe(SYNC_MESSAGES.failed)
    expect(day.detail).toBe('A quantidade de "Pão" precisa ser maior que zero.')
  })

  it('volta a tentar assim que ela corrige', async () => {
    rpc
      .mockResolvedValueOnce(
        failure('23514', 'A quantidade precisa ser maior que zero.')
      )
      .mockResolvedValueOnce(saved())

    const engine = engineFor()
    await engine.save(dayFor('2026-09-10T18:30:00-03:00'))
    await engine.flush()

    await engine.save(dayFor('2026-09-10T18:40:00-03:00'))
    await engine.flush()

    expect(rpc).toHaveBeenCalledTimes(2)
    expect(await getStoredDay(COOK, DATE)).toBeNull()
  })

  it('continua na fila quando dois aparelhos criam o mesmo dia no mesmo instante', async () => {
    rpc
      .mockResolvedValueOnce(
        failure('40001', 'Outro aparelho gravou este dia neste instante.')
      )
      .mockResolvedValueOnce(saved())

    const engine = engineFor()
    await engine.save(dayFor('2026-09-10T18:30:00-03:00'))
    await engine.flush()

    expect(await getStoredDay(COOK, DATE)).not.toBeNull()

    await engine.flush()
    expect(rpc).toHaveBeenCalledTimes(2)
    expect(await getStoredDay(COOK, DATE)).toBeNull()
  })
})

/*
 * O meio do caminho do dia não letivo: ela marcou a alternância e ainda está
 * indo escrever o motivo. O servidor recusaria isso (23514), e a faixa diria
 * "ainda não deu para enviar" para quem não fez nada de errado — então a fila
 * guarda e espera.
 */
describe('o dia que ainda não pode subir', () => {
  function nonSchoolDay(note: string): DayPayload {
    return {
      ...dayFor('2026-09-10T18:30:00-03:00'),
      non_school_day: true,
      note,
      meals: [],
      meals_served: null,
    }
  }

  it('guarda no aparelho o dia não letivo sem observação, e não o envia', async () => {
    const engine = engineFor()
    await engine.save(nonSchoolDay(''))
    await engine.flush()

    expect(rpc).not.toHaveBeenCalled()
    expect((await engine.load(DATE))?.non_school_day).toBe(true)
    expect(engine.getState().pending).toBe(1)
    expect(engine.getState().days[DATE].message).toBe(SYNC_MESSAGES.pending)
  })

  it('sobe assim que o motivo existe', async () => {
    rpc.mockResolvedValueOnce(saved())

    const engine = engineFor()
    await engine.save(nonSchoolDay(''))
    await engine.flush()
    await engine.save(nonSchoolDay('Conselho de classe'))
    await engine.flush()

    expect(rpc).toHaveBeenCalledTimes(1)
    expect(await getStoredDay(COOK, DATE)).toBeNull()
  })
})
