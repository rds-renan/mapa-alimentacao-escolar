import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import { MemoryRouter } from 'react-router'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'

import App from '@/App'
import { AuthProvider } from '@/auth/auth-provider'
import type { Profile } from '@/auth/auth-context'
import { SyncProvider } from '@/local/sync-provider'
import { dayKey, putStoredDay } from '@/local/store'

vi.mock('@/lib/supabase', async () => await import('@/test/supabase-mock'))
vi.mock('@/lib/local-data', () => ({ clearLocalData: vi.fn(async () => {}) }))
vi.mock('@/lib/recovery-link', () => ({
  cameFromRecoveryLink: () => false,
  isRecoveryHash: () => false,
}))

import {
  givenMealMaps,
  givenMealMapsFail,
  givenSignedIn,
  resetSupabaseMock,
  type MealMapRow,
} from '@/test/supabase-mock'

/*
 * Os critérios de aceite da issue #61, um a um.
 *
 * O relógio é fixado em 9 de setembro de 2026, uma quarta-feira: o mês que a
 * tela abre, o destaque de "hoje" e a quebra das semanas dependem todos da
 * data, e um teste que muda de resultado conforme o dia em que roda não prova
 * nada.
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

const SETEMBRO: MealMapRow[] = [
  // Terça, já dentro de um documento gerado.
  {
    map_date: '2026-09-01',
    non_school_day: false,
    note: null,
    meals_served: 310,
    locked: true,
    meal: meals(),
  },
  // Quarta, pronta.
  {
    map_date: '2026-09-02',
    non_school_day: false,
    note: null,
    meals_served: 305,
    locked: false,
    meal: meals(),
  },
  // Quinta, faltando o lanche da tarde.
  {
    map_date: '2026-09-03',
    non_school_day: false,
    note: null,
    meals_served: 308,
    locked: false,
    meal: meals().filter((meal) => meal.type !== 'afternoon_snack'),
  },
  // Sexta, dia não letivo.
  {
    map_date: '2026-09-04',
    non_school_day: true,
    note: 'Conselho de classe',
    meals_served: null,
    locked: false,
    meal: [],
  },
]

function renderApp(path = '/') {
  /*
   * Um cliente por caso, sem retentativa: o que se verifica aqui é a tela, e
   * as três tentativas do cliente de produção só fariam o teste da falha
   * esperar por elas.
   */
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

/*
 * Espera o mês estar carregado. O cabeçalho aparece antes da resposta do
 * servidor — é ele que segura a tela enquanto a lista não vem —, então esperar
 * pelo título do mês não prova que os dias chegaram. O cartão de andamento só
 * existe depois deles.
 */
function monthLoaded() {
  return screen.findByText('Andamento do mês')
}

/** A etiqueta de estado de um dia, achada pela linha que o leitor de tela lê. */
function badgeOf(name: RegExp): HTMLElement {
  const row = screen.getByRole('link', { name })
  const badge = row.querySelector<HTMLElement>('[data-slot="day-badge"]')
  if (!badge) throw new Error(`A linha de ${String(name)} não tem etiqueta.`)
  return badge
}

beforeEach(() => {
  resetSupabaseMock()
  localStorage.clear()
  // Só a data é de mentira; os temporizadores da fila continuam reais.
  vi.useFakeTimers({ toFake: ['Date'] })
  vi.setSystemTime(new Date('2026-09-09T12:00:00'))
  givenSignedIn(cook)
  givenMealMaps(SETEMBRO)
})

afterEach(() => {
  vi.useRealTimers()
})

describe('visão do mês', () => {
  it('abre no mês de hoje e conta os dias letivos', async () => {
    renderApp()
    await monthLoaded()

    expect(screen.getByText('Setembro de 2026')).toBeInTheDocument()
    // 22 dias úteis em setembro de 2026, menos o conselho de classe.
    expect(screen.getByText('21 dias letivos')).toBeInTheDocument()
  })

  it('identifica o estado de cada dia por cor e por ícone, nunca só por cor', async () => {
    renderApp()
    await monthLoaded()

    const estados: [RegExp, string][] = [
      [/^1 de setembro/, 'locked'],
      [/^2 de setembro/, 'complete'],
      [/^3 de setembro/, 'pending'],
      [/^4 de setembro/, 'non_school'],
      [/^7 de setembro/, 'empty'],
    ]

    for (const [dia, estado] of estados) {
      const badge = badgeOf(dia)
      expect(badge.dataset.state).toBe(estado)
      // A cor vem da classe; o ícone tem de estar lá junto (RNF#1 da US008).
      expect(badge.querySelector('svg')).not.toBeNull()
    }
  })

  it('diz o que falta no dia pendente, com todas as letras', async () => {
    renderApp()

    expect(
      await screen.findByText('falta o lanche da tarde')
    ).toBeInTheDocument()
    expect(screen.getByText('Conselho de classe')).toBeInTheDocument()
    expect(screen.getByText('3 refeições · 305 servidas')).toBeInTheDocument()
  })

  it('não lista o fim de semana, que não é pendência', async () => {
    renderApp()
    await monthLoaded()

    // 5 e 6 de setembro de 2026 são sábado e domingo.
    expect(screen.queryByRole('link', { name: /^5 de setembro/ })).toBeNull()
    expect(screen.queryByRole('link', { name: /^6 de setembro/ })).toBeNull()
  })

  it('resume o andamento do mês', async () => {
    renderApp()
    await monthLoaded()

    expect(screen.getByText('2 de 21 dias')).toBeInTheDocument()
    expect(
      screen.getByText(
        '1 preenchido · 1 pendente · 1 não letivo · 1 no documento · 18 vazios'
      )
    ).toBeInTheDocument()
  })

  it('navega entre os meses', async () => {
    renderApp()
    await monthLoaded()

    fireEvent.click(screen.getByRole('button', { name: 'Mês anterior' }))
    expect(await screen.findByText('Agosto de 2026')).toBeInTheDocument()

    fireEvent.click(screen.getByRole('button', { name: 'Próximo mês' }))
    fireEvent.click(screen.getByRole('button', { name: 'Próximo mês' }))
    expect(await screen.findByText('Outubro de 2026')).toBeInTheDocument()
  })

  it('abre o mês que está no endereço, para o F5 não jogá-la de volta em hoje', async () => {
    renderApp('/?mes=2026-05')
    await monthLoaded()

    expect(screen.getByText('Maio de 2026')).toBeInTheDocument()
  })

  it('tocar num dia abre o registro daquele dia', async () => {
    renderApp()
    await monthLoaded()

    fireEvent.click(screen.getByRole('link', { name: /^3 de setembro/ }))

    expect(await screen.findByText('Quinta, 3 de setembro')).toBeInTheDocument()
  })

  it('o dia bloqueado também abre: ele é somente leitura, não inalcançável', async () => {
    renderApp()
    await monthLoaded()

    fireEvent.click(screen.getByRole('link', { name: /^1 de setembro/ }))

    /*
     * Os dois `findBy` são dois momentos, e não um: o título sai do endereço e
     * aparece antes da resposta do servidor, enquanto o bloqueio só o servidor
     * conhece. Conferir a faixa sem esperar passa numa máquina folgada e falha
     * numa ocupada — foi o que a CI pegou.
     */
    expect(await screen.findByText('Terça, 1 de setembro')).toBeInTheDocument()
    expect(await screen.findByText(/abre só para consulta/)).toBeInTheDocument()
  })
})

describe('o dia que ainda está no aparelho', () => {
  it('aparece preenchido na lista antes mesmo de subir', async () => {
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
    await monthLoaded()

    await waitFor(() =>
      expect(badgeOf(/^8 de setembro/).dataset.state).toBe('complete')
    )
  })
})

describe('quando a lista não vem', () => {
  it('diz que o que ela registrou continua guardado, e oferece tentar de novo', async () => {
    givenMealMapsFail()
    renderApp()

    expect(
      await screen.findByText(/foi só a lista que não veio/)
    ).toBeInTheDocument()
    expect(
      screen.getByRole('button', { name: 'Tentar de novo' })
    ).toBeInTheDocument()
  })
})

describe('menu do aplicativo', () => {
  it('está a um toque da tela inicial e reúne o que não é fluxo diário', async () => {
    renderApp()
    await monthLoaded()

    fireEvent.click(screen.getByRole('button', { name: 'Abrir o menu' }))

    expect(
      await screen.findByRole('link', { name: 'Documentos gerados' })
    ).toBeInTheDocument()
    expect(
      screen.getByRole('link', { name: 'Gerenciar gêneros' })
    ).toBeInTheDocument()
    expect(screen.getByText('Tema escuro')).toBeInTheDocument()
    expect(screen.getByRole('button', { name: 'Sair' })).toBeInTheDocument()
    expect(screen.getByText(cook.email)).toBeInTheDocument()
  })

  it('não dá acesso a nada da direção (RN#1 da US020)', async () => {
    renderApp()
    await monthLoaded()

    fireEvent.click(screen.getByRole('button', { name: 'Abrir o menu' }))
    await screen.findByRole('link', { name: 'Documentos gerados' })

    for (const link of screen.getAllByRole('link')) {
      expect(link.getAttribute('href')).not.toContain('/admin')
    }
  })

  it('leva ao catálogo de gêneros', async () => {
    renderApp()
    await monthLoaded()

    fireEvent.click(screen.getByRole('button', { name: 'Abrir o menu' }))
    fireEvent.click(
      await screen.findByRole('link', { name: 'Gerenciar gêneros' })
    )

    expect(await screen.findByText('Gerenciar gêneros')).toBeInTheDocument()
  })
})
