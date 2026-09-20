import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import { MemoryRouter } from 'react-router'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'

import App from '@/App'
import { AuthProvider } from '@/auth/auth-provider'
import type { Profile } from '@/auth/auth-context'
import { SyncProvider } from '@/local/sync-provider'
import { dayKey, putStoredDay } from '@/local/store'
import { isWeekday } from '@/month/month'

vi.mock('@/lib/supabase', async () => await import('@/test/supabase-mock'))
vi.mock('@/lib/local-data', () => ({ clearLocalData: vi.fn(async () => {}) }))
vi.mock('@/lib/recovery-link', () => ({
  cameFromRecoveryLink: () => false,
  isRecoveryHash: () => false,
}))

import {
  givenGenerationFails,
  givenMealMaps,
  givenSignedIn,
  resetSupabaseMock,
  sentGenerations,
  type MealMapRow,
} from '@/test/supabase-mock'

/*
 * Os critérios de aceite da issue #66, um a um.
 *
 * O relógio é fixado em 9 de setembro de 2026, uma quarta-feira, pelo mesmo
 * motivo da visão do mês: a quebra das semanas e o mês que a tela abre saem da
 * data, e um teste que muda de resultado conforme o dia em que roda não prova
 * nada. Setembro de 2026 tem 22 dias úteis.
 */

const cook: Profile = {
  id: '22222222-2222-4222-8222-222222222222',
  name: 'Merendeira 1',
  email: 'merendeira1@dominio.com.br',
  role: 'cook',
  school_id: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
}

function meals(): MealMapRow['meal'] {
  return [
    {
      type: 'morning_snack',
      description: 'Pão com leite',
      acceptance: 'great',
    },
    { type: 'lunch', description: 'Arroz e frango', acceptance: 'good' },
    { type: 'afternoon_snack', description: 'Bolo', acceptance: 'great' },
  ]
}

/** Setembro inteiro registrado e enviado: o mês que fecha. */
function setembro(changes: Record<string, Partial<MealMapRow>> = {}) {
  const rows: MealMapRow[] = []

  for (let day = 1; day <= 30; day += 1) {
    const date = `2026-09-${String(day).padStart(2, '0')}`
    if (!isWeekday(date)) continue

    rows.push({
      map_date: date,
      non_school_day: false,
      note: null,
      meals_served: 300,
      locked: false,
      meal: meals(),
      ...changes[date],
    })
  }

  return rows
}

function renderApp(path = '/gerar?mes=2026-09') {
  const queryClient = new QueryClient({
    defaultOptions: { queries: { retry: false } },
  })

  return render(
    <MemoryRouter initialEntries={[path]}>
      <QueryClientProvider client={queryClient}>
        <AuthProvider>
          <SyncProvider>
            <App />
          </SyncProvider>
        </AuthProvider>
      </QueryClientProvider>
    </MemoryRouter>
  )
}

/**
 * Espera a lista de dias chegar. O cabeçalho aparece antes dela, então esperar
 * pelo título não prova nada — o seletor de modo só existe com os dias na mão.
 */
function screenLoaded() {
  return screen.findByRole('button', { name: 'Escolher dias' })
}

function dayRow(name: RegExp) {
  return screen.getByRole('checkbox', { name })
}

function generateButton() {
  return screen.getByRole('button', { name: /Gerar documento/ })
}

beforeEach(() => {
  resetSupabaseMock()
  localStorage.clear()
  vi.useFakeTimers({ toFake: ['Date'] })
  vi.setSystemTime(new Date('2026-09-09T12:00:00'))
  givenSignedIn(cook)
  givenMealMaps(setembro())
})

afterEach(() => {
  vi.useRealTimers()
})

describe('a porta de entrada', () => {
  it('é o botão do rodapé da visão do mês, com o mês aberto junto', async () => {
    renderApp('/')
    await screen.findByText('Andamento do mês')

    fireEvent.click(screen.getByRole('link', { name: /Gerar documento/ }))

    expect(await screenLoaded()).toBeInTheDocument()
    expect(
      screen.getByText('Escolha os mapas de setembro de 2026')
    ).toBeInTheDocument()
  })
})

describe('o atalho do mês', () => {
  it('abre com o mês inteiro marcado, sem nenhum toque (RNF#1 da US013)', async () => {
    renderApp()
    await screenLoaded()

    expect(await screen.findByText('22 mapas selecionados')).toBeInTheDocument()
    expect(generateButton()).toBeEnabled()
  })

  it('leva junto o dia já incluído em outro documento', async () => {
    // Bloqueio é sobre editar, não sobre sair de novo (CA#4 da US023).
    givenMealMaps(setembro({ '2026-09-01': { locked: true } }))
    renderApp()
    await screenLoaded()

    expect(await screen.findByText('22 mapas selecionados')).toBeInTheDocument()
    expect(dayRow(/^1 de setembro/)).toHaveAttribute('aria-checked', 'true')
  })

  it('não marca nada quando falta fechar o mês, e diz o que falta', async () => {
    givenMealMaps(setembro({ '2026-09-03': { meals_served: null } }))
    renderApp()
    await screenLoaded()

    expect(
      await screen.findByText('Ainda falta 1 dia para fechar setembro.')
    ).toBeInTheDocument()
    expect(screen.getByText('3 de setembro · pendente')).toBeInTheDocument()
    expect(screen.getByText('Nenhum mapa selecionado')).toBeInTheDocument()
    expect(generateButton()).toBeDisabled()
  })

  it('conta como buraco o dia sem registro nenhum', async () => {
    givenMealMaps(setembro().filter((row) => row.map_date !== '2026-09-21'))
    renderApp()
    await screenLoaded()

    expect(
      await screen.findByText('21 de setembro · sem registro')
    ).toBeInTheDocument()
    expect(generateButton()).toBeDisabled()
  })
})

describe('os outros dois modos', () => {
  it('a semana fecha sozinha, e a semana com buraco não deixa marcar', async () => {
    givenMealMaps(setembro({ '2026-09-10': { meals_served: null } }))
    renderApp()
    await screenLoaded()

    fireEvent.click(screen.getByRole('button', { name: 'Semana' }))

    const week1 = await screen.findByRole('checkbox', {
      name: 'Semana 1 · 1 a 4 de setembro',
    })
    fireEvent.click(week1)
    expect(screen.getByText('4 mapas selecionados')).toBeInTheDocument()

    expect(
      screen.getByRole('checkbox', {
        name: 'Semana 2 · 7 a 11 de setembro, falta 1 dia',
      })
    ).toBeDisabled()
  })

  it('escolher dias aceita avulsos, e recusa o que não pode entrar', async () => {
    givenMealMaps(setembro({ '2026-09-03': { meals_served: null } }))
    renderApp()
    await screenLoaded()

    fireEvent.click(screen.getByRole('button', { name: 'Escolher dias' }))

    fireEvent.click(dayRow(/^1 de setembro/))
    fireEvent.click(dayRow(/^15 de setembro/))
    expect(screen.getByText('2 mapas selecionados')).toBeInTheDocument()

    // Avulso permite buraco no meio — o que não permite é mapa pendente.
    expect(dayRow(/^3 de setembro/)).toBeDisabled()
  })
})

describe('o dia que ainda não subiu', () => {
  it('não entra no documento, e a tela oferece enviar (RN#3 da US012)', async () => {
    await putStoredDay({
      key: dayKey(cook.id, '2026-09-08'),
      userId: cook.id,
      mapDate: '2026-09-08',
      day: {
        id: '33333333-3333-4333-8333-333333333333',
        map_date: '2026-09-08',
        updated_at: '2026-09-08T18:00:00.000Z',
        non_school_day: false,
        note: null,
        meals_served: 312,
        meals: meals().map((meal, index) => ({
          id: `4444444${index}-4444-4444-8444-444444444444`,
          type: meal.type,
          description: meal.description,
          acceptance: meal.acceptance,
          food_items: [],
          menu_change: null,
        })),
      },
      attempts: 0,
      rejection: null,
      queuedAt: '2026-09-08T18:00:00.000Z',
    })

    renderApp()
    await screenLoaded()

    await waitFor(() =>
      expect(dayRow(/^8 de setembro/)).toHaveAccessibleName(
        '8 de setembro, esperando enviar'
      )
    )
    expect(screen.getByText(/ainda não subiu/)).toBeInTheDocument()
    expect(
      screen.getByRole('button', { name: 'Enviar agora' })
    ).toBeInTheDocument()
    expect(generateButton()).toBeDisabled()
  })
})

describe('sem internet', () => {
  it('explica a espera em vez de deixar o toque falhar', async () => {
    const online = vi.spyOn(navigator, 'onLine', 'get').mockReturnValue(false)

    renderApp()
    await screenLoaded()

    expect(
      await screen.findByText(/Gerar o documento precisa de internet/)
    ).toBeInTheDocument()
    expect(generateButton()).toBeDisabled()

    online.mockRestore()
  })
})

describe('a confirmação, que é a única do fluxo dela', () => {
  it('diz o período e que os mapas ficam bloqueados', async () => {
    renderApp()
    await screenLoaded()
    await screen.findByText('22 mapas selecionados')

    fireEvent.click(generateButton())

    expect(
      await screen.findByText('Gerar o documento de setembro?')
    ).toBeInTheDocument()
    expect(
      screen.getByText(/Os 22 mapas incluídos ficam bloqueados para edição/)
    ).toBeInTheDocument()
  })

  it('voltar não gera nada', async () => {
    renderApp()
    await screenLoaded()
    await screen.findByText('22 mapas selecionados')

    fireEvent.click(generateButton())
    fireEvent.click(await screen.findByRole('button', { name: 'Voltar' }))

    expect(sentGenerations()).toHaveLength(0)
  })

  it('confirmar manda os dias escolhidos e leva para os documentos gerados', async () => {
    renderApp()
    await screenLoaded()
    await screen.findByText('22 mapas selecionados')

    fireEvent.click(generateButton())
    fireEvent.click(await screen.findByRole('button', { name: 'Gerar' }))

    await waitFor(() => expect(sentGenerations()).toHaveLength(1))
    expect(sentGenerations()[0]).toHaveLength(22)
    expect(sentGenerations()[0]).toContain('map-2026-09-01')

    expect(
      await screen.findByRole('heading', { name: /Documentos gerados/ })
    ).toBeInTheDocument()
  })
})

describe('quando a geração falha', () => {
  it('diz que nada foi bloqueado e deixa tentar de novo', async () => {
    givenGenerationFails(
      'A escola ainda não tem um modelo oficial cadastrado.',
      400,
      'A direção envia o modelo na área de administração.'
    )

    renderApp()
    await screenLoaded()
    await screen.findByText('22 mapas selecionados')

    fireEvent.click(generateButton())
    fireEvent.click(await screen.findByRole('button', { name: 'Gerar' }))

    expect(
      await screen.findByText('Não deu para gerar o documento')
    ).toBeInTheDocument()
    expect(
      screen.getByText(/ainda não tem um modelo oficial cadastrado/)
    ).toBeInTheDocument()
    expect(screen.getByText(/nenhum foi bloqueado/)).toBeInTheDocument()

    fireEvent.click(screen.getByRole('button', { name: 'Tentar de novo' }))
    await waitFor(() => expect(sentGenerations()).toHaveLength(2))
  })
})
