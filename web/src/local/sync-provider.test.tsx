import { QueryClientProvider, useQuery } from '@tanstack/react-query'
import { act, fireEvent, render, screen, waitFor } from '@testing-library/react'
import { beforeEach, describe, expect, it, vi } from 'vitest'

import type { Profile } from '@/auth/auth-context'
import { createQueryClient } from '@/lib/query-client'

import { ConflictNotice } from './conflict-notice'
import { emptyDay } from './day'
import { SyncBanner } from './sync-banner'
import { SyncProvider } from './sync-provider'
import { useDayDraft } from './useDayDraft'
import { useSync } from './useSync'

/*
 * O vínculo com o React: a fila vive acima das rotas, a tela do dia grava por
 * um gancho e a faixa reflete o que a fila está fazendo. É o caminho que as
 * issues #61 e #62 vão usar, exercitado aqui inteiro.
 */

const rpc = vi.fn()

vi.mock('@/lib/supabase', () => ({
  supabase: { rpc: (...args: unknown[]) => rpc(...args) },
}))

const profile: Profile = {
  id: '22222222-2222-4222-8222-222222222222',
  name: 'Merendeira 1',
  email: 'merendeira1@dominio.com.br',
  role: 'cook',
  school_id: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
}

vi.mock('@/auth/useAuth', () => ({ useAuth: () => ({ profile }) }))

const DATE = '2026-09-10'

/** O mínimo da tela do dia: um campo que grava e a faixa que conta o que houve. */
function DayScreen() {
  const { draft, loading, status, update } = useDayDraft(DATE)
  const { flush } = useSync()

  return (
    <>
      <ConflictNotice />
      <SyncBanner status={status} />
      <button
        onClick={() => void update({ ...emptyDay(DATE), meals_served: 312 })}
      >
        Registrar 312 refeições
      </button>
      <button onClick={() => void flush()}>Enviar agora</button>
      {/* <output> tem papel "status" por padrão e disputaria com a faixa. */}
      <p>
        {loading
          ? 'Lendo o aparelho'
          : `Rascunho: ${draft?.meals_served ?? 'nenhum'}`}
      </p>
    </>
  )
}

/*
 * A tela do mês, reduzida ao que interessa aqui: uma consulta ao servidor que
 * conta quantas vezes foi lida. Ela entra e sai da árvore, que é o ponto do
 * último teste deste arquivo.
 */
const readMonth = vi.fn(async () => `leitura ${readMonth.mock.calls.length}`)

function MonthScreen() {
  const { data } = useQuery({
    queryKey: ['month', '2026-09'],
    queryFn: readMonth,
  })
  return <p>Mês: {data ?? 'carregando'}</p>
}

/*
 * O `QueryClientProvider` está aqui porque está no aplicativo: a fila vive
 * dentro dele (ver `main.tsx`), e é de lá que ela avisa o cache do servidor
 * quando um dia sobe. E o cliente é o **de verdade**, e não um de teste com os
 * padrões da biblioteca: o que faz o dia recém-enviado poder aparecer velho na
 * tela é justamente o `staleTime` de meio minuto que ele configura.
 */
function renderScreen(month = false) {
  const client = createQueryClient()

  const tree = (showMonth: boolean) => (
    <QueryClientProvider client={client}>
      <SyncProvider>
        <DayScreen />
        {showMonth ? <MonthScreen /> : null}
      </SyncProvider>
    </QueryClientProvider>
  )

  const rendered = render(tree(month))
  return {
    ...rendered,
    showMonth: (showMonth: boolean) => rendered.rerender(tree(showMonth)),
  }
}

beforeEach(() => {
  rpc.mockReset()
  readMonth.mockClear()
})

describe('a fila ligada à tela', () => {
  it('não diz nada sobre o dia antes da primeira tecla', async () => {
    renderScreen()

    await waitFor(() => {
      expect(screen.getByText('Rascunho: nenhum')).toBeInTheDocument()
    })
    expect(screen.queryByRole('status')).toBeNull()
  })

  it('não deixa a leitura do disco apagar a tecla dada enquanto ela acontecia', async () => {
    rpc.mockResolvedValue({
      data: null,
      error: { code: '', message: 'Failed to fetch', details: '', hint: '' },
    })

    renderScreen()

    // Ela digita no primeiro quadro, antes de a leitura do aparelho terminar.
    // A resposta atrasada traz "não há rascunho" — e não pode cair por cima.
    fireEvent.click(screen.getByText('Registrar 312 refeições'))

    await act(async () => {
      await new Promise((resolve) => setTimeout(resolve, 30))
    })

    expect(screen.getByText('Rascunho: 312')).toBeInTheDocument()
  })

  it('grava sem botão de salvar e conta os dois estados, na ordem', async () => {
    rpc.mockResolvedValue({
      data: {
        status: 'saved',
        meal_map_id: 'c0000010-0000-4000-8000-000000000010',
        sent_meal_map_id: null,
        map_date: DATE,
        locked: false,
        updated_at: '2026-09-10T21:30:00+00:00',
        updated_by: profile.id,
        food_items: [],
      },
      error: null,
    })

    renderScreen()
    await waitFor(() => screen.getByText('Rascunho: nenhum'))

    fireEvent.click(screen.getByText('Registrar 312 refeições'))

    await waitFor(() => {
      expect(screen.getByRole('status')).toHaveTextContent(
        'Salvo no aparelho. Envia sozinho quando houver internet.'
      )
    })
    expect(screen.getByText('Rascunho: 312')).toBeInTheDocument()

    fireEvent.click(screen.getByText('Enviar agora'))

    await waitFor(() => {
      expect(screen.getByRole('status')).toHaveTextContent(
        'Enviado. Este mapa já está disponível para gerar o documento.'
      )
    })
  })

  it('mostra o conflito à usuária, e só o tira quando ela diz que leu', async () => {
    rpc.mockResolvedValue({
      data: {
        status: 'superseded',
        meal_map_id: 'c0000010-0000-4000-8000-000000000010',
        sent_meal_map_id: null,
        map_date: DATE,
        locked: false,
        updated_at: '2026-09-11T10:00:00+00:00',
        updated_by: '33333333-3333-4333-8333-333333333333',
        food_items: [],
      },
      error: null,
    })

    renderScreen()
    await waitFor(() => screen.getByText('Rascunho: nenhum'))

    fireEvent.click(screen.getByText('Registrar 312 refeições'))
    await waitFor(() => screen.getByRole('status'))
    fireEvent.click(screen.getByText('Enviar agora'))

    const notice = await screen.findByRole('alert')
    expect(notice).toHaveTextContent('registrado em outro aparelho')

    fireEvent.click(screen.getByText('Entendi'))
    await waitFor(() => {
      expect(screen.queryByRole('alert')).toBeNull()
    })
  })

  /*
   * O defeito que o teste de ponta a ponta do caminho crítico (issue #72)
   * encontrou: a fila confirma o dia com a merendeira na tela **do dia**, e o
   * aviso ao cache morava dentro da visão do mês — que não estava montada para
   * ouvi-lo. Voltando ao mês dentro do meio minuto de `staleTime`, ela via como
   * vazio o dia que tinha acabado de registrar.
   */
  it('avisa a consulta do mês mesmo com a tela do mês fechada', async () => {
    rpc.mockResolvedValue({
      data: {
        status: 'saved',
        meal_map_id: 'c0000010-0000-4000-8000-000000000010',
        sent_meal_map_id: null,
        map_date: DATE,
        locked: false,
        updated_at: '2026-09-10T21:30:00+00:00',
        updated_by: profile.id,
        food_items: [],
      },
      error: null,
    })

    // Ela abre o mês, que lê do servidor…
    const { showMonth } = renderScreen(true)
    await waitFor(() => expect(readMonth).toHaveBeenCalledTimes(1))

    // …entra no dia, registra e o dia sobe.
    showMonth(false)
    await waitFor(() => screen.getByText('Rascunho: nenhum'))
    fireEvent.click(screen.getByText('Registrar 312 refeições'))
    await waitFor(() => screen.getByRole('status'))
    fireEvent.click(screen.getByText('Enviar agora'))
    await waitFor(() => {
      expect(screen.getByRole('status')).toHaveTextContent('Enviado.')
    })

    // De volta ao mês, a lista é lida de novo: o que está no servidor mudou.
    showMonth(true)
    await waitFor(() => expect(readMonth).toHaveBeenCalledTimes(2))
  })
})
