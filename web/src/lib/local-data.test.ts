import { describe, expect, it, vi } from 'vitest'

import { getStoredDay } from '@/local/store'
import { createSyncEngine } from '@/local/sync'

import { clearLocalData } from './local-data'

vi.mock('@/lib/supabase', () => ({ supabase: { rpc: vi.fn() } }))

const COOK = '22222222-2222-4222-8222-222222222222'

describe('o que sair do aplicativo apaga', () => {
  it('leva junto o mapa que ainda não subiu', async () => {
    const engine = createSyncEngine(COOK)
    await engine.save({
      id: 'a0000000-0000-4000-8000-000000000001',
      map_date: '2026-09-10',
      updated_at: '2026-09-10T18:30:00-03:00',
      non_school_day: false,
      note: null,
      meals_served: 312,
      meals: [],
    })

    await clearLocalData()

    /*
     * Sair apaga tudo, inclusive o que não subiu — e apaga de verdade: a
     * conexão que a fila mantinha aberta bloquearia o apagamento, e sem
     * fechá-la antes o banco sobreviveria à saída sem ninguém perceber.
     *
     * A escolha é dela, não do sistema: quem tem mapa por enviar é avisada
     * antes pelo botão de sair.
     */
    expect(await getStoredDay(COOK, '2026-09-10')).toBeNull()
  })

  it('apaga qualquer outro banco que exista na origem', async () => {
    await new Promise<void>((resolve) => {
      const request = indexedDB.open('algum-outro-banco', 1)
      request.onsuccess = () => {
        request.result.close()
        resolve()
      }
    })

    await clearLocalData()

    const names = (await indexedDB.databases()).map((one) => one.name)
    expect(names).not.toContain('algum-outro-banco')
  })
})
