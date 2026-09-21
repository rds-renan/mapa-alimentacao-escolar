import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { fireEvent, render, screen, within } from '@testing-library/react'
import { MemoryRouter } from 'react-router'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'

import App from '@/App'
import type { Profile } from '@/auth/auth-context'
import { AuthProvider } from '@/auth/auth-provider'
import { SyncProvider } from '@/local/sync-provider'
import { ThemeProvider } from '@/theme/theme-provider'

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
 * Os critérios de aceite da issue #70, um a um.
 *
 * A pergunta desta tela é a da direção: como foi o mês, sem abrir mapa nenhum.
 * Os dois casos que mais importam não são sobre desenho — são o dia não letivo
 * que traz refeições consigo (RN#2 da US017) e a ausência de qualquer caminho
 * daqui para a edição de um mapa.
 */

const SCHOOL = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'

const admin: Profile = {
  id: '11111111-1111-4111-8111-111111111111',
  name: 'Direção',
  email: 'direcao@dominio.com.br',
  role: 'admin',
  school_id: SCHOOL,
}

function mapOf(
  map_date: string,
  overrides: Partial<MealMapRow> = {}
): MealMapRow {
  return {
    map_date,
    non_school_day: false,
    note: null,
    meals_served: 300,
    locked: false,
    meal: [
      {
        type: 'morning_snack',
        description: 'Pão com leite',
        acceptance: 'great',
      },
      { type: 'lunch', description: 'Arroz com frango', acceptance: 'great' },
      { type: 'afternoon_snack', description: 'Canjica', acceptance: 'poor' },
    ],
    ...overrides,
  }
}

/** Dois dias letivos de setembro: 300 e 320 refeições, média 310. */
const SEPTEMBER: MealMapRow[] = [
  mapOf('2026-09-01'),
  mapOf('2026-09-02', { meals_served: 320 }),
]

function renderAt(at: string) {
  const queryClient = new QueryClient({
    defaultOptions: { queries: { retry: false } },
  })

  return render(
    <ThemeProvider>
      <MemoryRouter initialEntries={[at]}>
        <QueryClientProvider client={queryClient}>
          <AuthProvider>
            <SyncProvider>
              <App />
            </SyncProvider>
          </AuthProvider>
        </QueryClientProvider>
      </MemoryRouter>
    </ThemeProvider>
  )
}

/** O painel de setembro de 2026 — o mês vai no endereço, como na tela dela. */
function renderDashboard(month = '2026-09') {
  return renderAt(`/admin?mes=${month}`)
}

/** O painel chegou: até aqui o cabeçalho já está na tela e não prova nada. */
function dashboardLoaded() {
  return screen.findByRole('heading', { name: 'Aceitação por refeição' })
}

/** O cartão de número, achado pelo seu rótulo. */
function summaryCard(title: string) {
  return screen.getByText(title).parentElement as HTMLElement
}

beforeEach(() => {
  givenSignedIn(admin)
  givenMealMaps(SEPTEMBER.map((row) => ({ ...row })))
})

afterEach(() => resetSupabaseMock())

describe('os números do mês', () => {
  it('mostra o total de refeições, a média por dia letivo e os dias registrados', async () => {
    renderDashboard()
    await dashboardLoaded()

    expect(
      within(summaryCard('Refeições servidas no mês')).getByText('620')
    ).toBeVisible()
    expect(
      within(summaryCard('Média por dia letivo')).getByText('310')
    ).toBeVisible()

    /* Setembro de 2026 tem 22 dias úteis, e dois deles estão completos. */
    expect(
      within(summaryCard('Dias registrados')).getByText('2 de 22')
    ).toBeVisible()
  })

  it('não mostra média quando nenhum dia tem o número informado', async () => {
    givenMealMaps([mapOf('2026-09-01', { meals_served: null })])

    renderDashboard()
    await dashboardLoaded()

    expect(
      within(summaryCard('Média por dia letivo')).getByText('—')
    ).toBeVisible()
  })

  it('deixa o dia não letivo fora das contas, mesmo com refeições registradas', async () => {
    /*
     * RN#2 da US017. O dia abaixo foi registrado inteiro e só depois marcado
     * como não letivo — o banco preserva as refeições de propósito (decisão 1
     * da E4), então excluir "dias sem refeição" não excluiria este.
     */
    givenMealMaps([
      mapOf('2026-09-01'),
      mapOf('2026-09-02', {
        non_school_day: true,
        note: 'Feriado municipal',
        meals_served: null,
      }),
    ])

    renderDashboard()
    await dashboardLoaded()

    expect(
      within(summaryCard('Refeições servidas no mês')).getByText('300')
    ).toBeVisible()
    expect(
      within(summaryCard('Dias registrados')).getByText('1 de 21')
    ).toBeVisible()
    expect(screen.getByText(/1 não letivo/)).toBeVisible()
  })
})

describe('a aceitação por refeição', () => {
  it('mostra a distribuição de cada refeição do dia', async () => {
    renderDashboard()
    await dashboardLoaded()

    expect(screen.getByText('Lanche da manhã')).toBeVisible()
    expect(screen.getByText('Almoço')).toBeVisible()
    expect(screen.getByText('Lanche da tarde')).toBeVisible()

    /* Duas avaliações "ótimo" no lanche da manhã, nenhuma na tarde. */
    const shares = screen
      .getAllByText(/% ótimo$/)
      .map((node) => node.textContent)
    expect(shares).toEqual(['100% ótimo', '100% ótimo', '0% ótimo'])
  })

  it('diz a distribuição em palavras, e não só em cor', async () => {
    /*
     * CA#3 da issue: a paleta é legível nos dois temas, e a informação não
     * depende dela. Quem usa leitor de tela recebe a mesma contagem em texto.
     */
    renderDashboard()
    await dashboardLoaded()

    expect(
      screen.getByRole('img', {
        name: 'Lanche da tarde: 0 ótimo, 0 bom, 2 ruim, de 2 avaliações',
      })
    ).toBeInTheDocument()
  })

  it('pinta as barras com a paleta de dados da E3, não com o acento da marca', async () => {
    renderDashboard()
    await dashboardLoaded()

    const bar = screen.getByRole('img', { name: /^Lanche da manhã/ })
    const classes = [...bar.children].map((piece) => piece.className)

    expect(classes.some((name) => name.includes('bg-chart-1'))).toBe(true)
    expect(classes.some((name) => name.includes('bg-primary'))).toBe(false)
  })

  it('avisa quando o mês ainda não tem avaliação nenhuma', async () => {
    givenMealMaps([
      mapOf('2026-09-01', {
        meal: [
          { type: 'lunch', description: 'Arroz com frango', acceptance: null },
        ],
      }),
    ])

    renderDashboard()
    await dashboardLoaded()

    expect(
      screen.getByText(/Nenhuma refeição foi avaliada neste mês ainda/)
    ).toBeVisible()
  })
})

describe('as merendas mais bem aceitas', () => {
  it('ordena pelo percentual de ótimo e diz quantas vezes cada uma foi servida', async () => {
    renderDashboard()
    await dashboardLoaded()

    const ranking = within(
      screen
        .getByRole('heading', { name: 'Merendas mais bem aceitas' })
        .closest('section') as HTMLElement
    )

    const names = ranking
      .getAllByRole('listitem')
      .map((item) => item.firstElementChild?.firstElementChild?.textContent)

    expect(names).toEqual(['Arroz com frango', 'Pão com leite', 'Canjica'])
    expect(ranking.getAllByText('2 vezes no mês')).toHaveLength(3)
  })

  it('agrupa grafias que só diferem em caixa e espaço', async () => {
    givenMealMaps([
      mapOf('2026-09-01', {
        meal: [
          {
            type: 'lunch',
            description: 'Arroz com frango',
            acceptance: 'great',
          },
        ],
      }),
      mapOf('2026-09-02', {
        meal: [
          {
            type: 'lunch',
            description: 'arroz  com  frango',
            acceptance: 'great',
          },
        ],
      }),
    ])

    renderDashboard()
    await dashboardLoaded()

    expect(screen.getByText('Arroz com frango')).toBeVisible()
    expect(screen.getByText('2 vezes no mês')).toBeVisible()
  })
})

describe('a navegação entre os meses', () => {
  it('abre no mês do endereço e leva o mês escolhido de volta para ele', async () => {
    renderDashboard('2026-08')
    await dashboardLoaded()

    const picker = screen.getByRole('combobox', { name: 'Mês do painel' })
    expect(picker).toHaveTextContent('Agosto de 2026')

    fireEvent.keyDown(picker, { key: 'Enter' })
    fireEvent.click(
      await screen.findByRole('option', { name: 'Julho de 2026' })
    )

    expect(
      screen.getByRole('combobox', { name: 'Mês do painel' })
    ).toHaveTextContent('Julho de 2026')
  })
})

describe('o painel não é caminho para o mapa', () => {
  it('não oferece nenhum link para o registro de um dia', async () => {
    /*
     * RN#1 da US017: o painel é leitura agregada. A guarda de rota já barraria
     * a direção no registro; o que se confere aqui é que ela nem é convidada.
     */
    renderDashboard()
    await dashboardLoaded()

    const destinations = screen
      .getAllByRole('link')
      .map((link) => link.getAttribute('href'))

    expect(destinations).toEqual(['/admin', '/admin/gestao', '/admin/mapas'])
  })
})

describe('quando a leitura não vem', () => {
  it('diz que nada foi alterado e oferece tentar de novo', async () => {
    givenMealMapsFail()

    renderDashboard()

    expect(
      await screen.findByText(/Não deu para carregar o painel agora/)
    ).toBeVisible()
    expect(screen.getByRole('button', { name: 'Tentar de novo' })).toBeVisible()
  })

  it('explica o mês sem nenhum dia registrado', async () => {
    givenMealMaps([])

    renderDashboard()

    expect(
      await screen.findByText(/Nenhum dia foi registrado neste mês/)
    ).toBeVisible()
  })
})
