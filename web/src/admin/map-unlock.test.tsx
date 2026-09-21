import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import {
  fireEvent,
  render,
  screen,
  waitFor,
  within,
} from '@testing-library/react'
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
  givenGeneratedDocuments,
  givenMapUnlocks,
  givenMapUnlocksFail,
  givenMealMaps,
  givenMealMapsFail,
  givenReopenFails,
  givenSignedIn,
  reopenRequests,
  resetSupabaseMock,
  storedMapUnlocks,
  storedMealMaps,
  type MealMapRow,
} from '@/test/supabase-mock'

/*
 * Os critérios de aceite da issue #69, um a um.
 *
 * A pergunta desta tela é a do beco: o mapa incluído em documento gerado fica
 * bloqueado, e um erro descoberto depois não tinha caminho nenhum. A direção
 * reabre com justificativa, a merendeira corrige, e nada do que já saiu deixa
 * de constar.
 *
 * O último bloco é o da tela da merendeira, e é ele que fecha o CA#2: o dia
 * reaberto volta a aceitar edição **e** aparece sinalizado, senão ela não teria
 * como achá-lo na lista do mês.
 */

const SCHOOL = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'

const admin: Profile = {
  id: '11111111-1111-4111-8111-111111111111',
  name: 'Direção',
  email: 'direcao@dominio.com.br',
  role: 'admin',
  school_id: SCHOOL,
}

const cook: Profile = {
  id: '22222222-2222-4222-8222-222222222222',
  name: 'Merendeira 1',
  email: 'merendeira1@dominio.com.br',
  role: 'cook',
  school_id: SCHOOL,
}

const THREE_MEALS: MealMapRow['meal'] = [
  { type: 'morning_snack', description: 'Pão com leite', acceptance: 'great' },
  { type: 'lunch', description: 'Arroz, feijão e frango', acceptance: 'good' },
  { type: 'afternoon_snack', description: 'Bolo e suco', acceptance: 'great' },
]

function mapOf(
  map_date: string,
  overrides: Partial<MealMapRow> = {}
): MealMapRow {
  return {
    map_date,
    non_school_day: false,
    note: null,
    meals_served: 312,
    locked: true,
    meal: THREE_MEALS,
    ...overrides,
  }
}

/** Dois meses de dias bloqueados: é o agrupamento por mês que eles provam. */
const LOCKED = [mapOf('2026-09-04'), mapOf('2026-09-11'), mapOf('2026-08-28')]

/** O documento que bloqueou os dois dias de setembro. */
const DOCUMENT = {
  id: 'doc-1',
  status: 'available' as const,
  requested_at: '2026-09-30T12:00:00.000Z',
  completed_at: '2026-09-30T12:00:01.000Z',
  expires_at: '2026-10-07T12:00:01.000Z',
  file_path: `${SCHOOL}/mapa-setembro.docx`,
  file_name: 'mapa-da-alimentacao-escolar-setembro-2026.docx',
  dates: ['2026-09-04', '2026-09-11'],
}

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

function renderMaps() {
  return renderAt('/admin/mapas')
}

/** A lista chegou: até aí o cabeçalho já está na tela e não prova nada. */
function mapsLoaded() {
  return screen.findByText('Sexta, 4 de setembro')
}

function click(name: string | RegExp) {
  fireEvent.click(screen.getByRole('button', { name }))
}

function typeReason(value: string) {
  fireEvent.change(screen.getByLabelText('Justificativa'), {
    target: { value },
  })
}

/** Abre o diálogo do dia 4 de setembro e escreve a justificativa. */
async function reopenSeptemberFourth(
  reason = 'O número de refeições saiu trocado.'
) {
  await mapsLoaded()
  click('Reabrir o mapa de Sexta, 4 de setembro')
  typeReason(reason)
}

beforeEach(() => {
  givenSignedIn(admin)
  givenMealMaps(LOCKED.map((row) => ({ ...row })))
  givenGeneratedDocuments([{ ...DOCUMENT }])
  givenMapUnlocks([])
})

afterEach(() => resetSupabaseMock())

describe('os dias que saíram em documento', () => {
  it('lista os bloqueados, do mais recente para o mais antigo, por mês', async () => {
    renderMaps()
    await mapsLoaded()

    expect(screen.getByText('Setembro de 2026')).toBeVisible()
    expect(screen.getByText('Agosto de 2026')).toBeVisible()

    const days = screen
      .getAllByRole('button', { name: /^Reabrir o mapa de/ })
      .map((button) => button.getAttribute('aria-label'))

    expect(days).toEqual([
      'Reabrir o mapa de Sexta, 11 de setembro',
      'Reabrir o mapa de Sexta, 4 de setembro',
      'Reabrir o mapa de Sexta, 28 de agosto',
    ])
  })

  it('diz em qual documento cada dia saiu', async () => {
    renderMaps()
    await mapsLoaded()

    expect(screen.getAllByText('No documento de 30/09/2026')).toHaveLength(2)
    // O dia de agosto não está em documento nenhum que a tela conheça.
    expect(screen.getByText('Em documento gerado')).toBeVisible()
  })

  it('não lista dia que não está bloqueado', async () => {
    givenMealMaps([mapOf('2026-09-04'), mapOf('2026-09-15', { locked: false })])
    renderMaps()
    await mapsLoaded()

    expect(screen.queryByText('Terça, 15 de setembro')).not.toBeInTheDocument()
  })

  it('não dá caminho nenhum para abrir nem editar o mapa', async () => {
    renderMaps()
    await mapsLoaded()

    /*
     * A direção reabre e nada mais (RN#1 da US023). A lista não leva ao
     * registro do dia, e foi decisão de escopo não lhe dar nem a leitura do
     * mapa: quem viu o erro foi a merendeira, e é ela que pede.
     */
    expect(
      screen.queryByRole('link', { name: /setembro/ })
    ).not.toBeInTheDocument()
    expect(screen.queryByText('Arroz, feijão e frango')).not.toBeInTheDocument()
  })

  it('quando a lista não vem, oferece tentar de novo', async () => {
    givenMealMapsFail()
    renderMaps()

    expect(await screen.findByText(/foi só a lista que não veio/)).toBeVisible()
    expect(screen.getByRole('button', { name: 'Tentar de novo' })).toBeVisible()
  })

  it('escola sem nenhum dia em documento vê o porquê', async () => {
    givenMealMaps([])
    renderMaps()

    expect(
      await screen.findByText(/Nenhum dia saiu em documento ainda/)
    ).toBeVisible()
  })
})

describe('a reabertura', () => {
  it('exige a justificativa antes de deixar reabrir', async () => {
    renderMaps()
    await mapsLoaded()

    click('Reabrir o mapa de Sexta, 4 de setembro')

    expect(
      screen.getByText('Reabrir o mapa de Sexta, 4 de setembro?')
    ).toBeVisible()
    expect(
      screen.getByRole('button', { name: 'Reabrir o mapa' })
    ).toBeDisabled()

    // Espaço em branco não é justificativa, e o banco recusaria igual.
    typeReason('   ')
    expect(
      screen.getByRole('button', { name: 'Reabrir o mapa' })
    ).toBeDisabled()

    typeReason('Erro no número de refeições.')
    expect(screen.getByRole('button', { name: 'Reabrir o mapa' })).toBeEnabled()
  })

  it('reabre o mapa e registra a justificativa', async () => {
    renderMaps()
    await reopenSeptemberFourth()

    click('Reabrir o mapa')

    expect(
      await screen.findByText(/O mapa de Sexta, 4 de setembro foi reaberto/)
    ).toBeVisible()

    expect(reopenRequests()).toEqual([
      {
        mapId: 'map-2026-09-04',
        reason: 'O número de refeições saiu trocado.',
      },
    ])

    const reopened = storedMealMaps().find(
      (row) => row.map_date === '2026-09-04'
    )
    expect(reopened?.locked).toBe(false)
  })

  it('o dia reaberto sai da lista dos bloqueados', async () => {
    renderMaps()
    await reopenSeptemberFourth()
    click('Reabrir o mapa')

    await waitFor(() =>
      expect(screen.queryByText('Sexta, 4 de setembro')).not.toBeInTheDocument()
    )
    expect(screen.getByText('Sexta, 11 de setembro')).toBeVisible()
  })

  it('a justificativa começa em branco a cada abertura', async () => {
    renderMaps()
    await reopenSeptemberFourth('Motivo do primeiro dia.')

    fireEvent.click(screen.getByRole('button', { name: 'Cancelar' }))
    click('Reabrir o mapa de Sexta, 11 de setembro')

    expect(screen.getByLabelText('Justificativa')).toHaveValue('')
  })

  it('cancelar não reabre nada', async () => {
    renderMaps()
    await reopenSeptemberFourth()

    fireEvent.click(screen.getByRole('button', { name: 'Cancelar' }))

    expect(reopenRequests()).toEqual([])
    expect(screen.getByText('Sexta, 4 de setembro')).toBeVisible()
  })

  it('recusa do banco chega com a frase que a própria função escreveu', async () => {
    givenReopenFails('Este mapa não está bloqueado.', '23514')
    renderMaps()
    await reopenSeptemberFourth()

    click('Reabrir o mapa')

    expect(
      await screen.findByText('Este mapa não está bloqueado.')
    ).toBeVisible()
    // O diálogo continua aberto, com o que ela escreveu.
    expect(screen.getByLabelText('Justificativa')).toHaveValue(
      'O número de refeições saiu trocado.'
    )
  })

  it('sem rede, diz que o mapa continua bloqueado', async () => {
    givenReopenFails('Failed to fetch')
    renderMaps()
    await reopenSeptemberFourth()

    click('Reabrir o mapa')

    expect(await screen.findByText(/O mapa continua bloqueado/)).toBeVisible()
  })
})

describe('o histórico de reaberturas', () => {
  it('mostra de qual dia, por quem, quando e por quê', async () => {
    givenMapUnlocks([
      {
        id: 'unlock-1',
        map_date: '2026-09-04',
        unlocked_at: '2026-10-02T17:32:00.000Z',
        unlocked_by: 'Direção',
        reason: 'O número de refeições do dia saiu trocado.',
      },
    ])

    renderMaps()

    expect(
      await screen.findByText(/Reaberto por Direção em 02\/10\/2026/)
    ).toBeVisible()
    expect(
      screen.getByText(/O número de refeições do dia saiu trocado/)
    ).toBeVisible()
  })

  it('a reabertura que acabou de acontecer entra no histórico', async () => {
    renderMaps()
    await reopenSeptemberFourth('Segunda correção do mês.')
    click('Reabrir o mapa')

    /*
     * Dentro do cartão do histórico, e não em qualquer lugar da tela: a mesma
     * frase acabou de ser digitada no diálogo, e procurá-la solta encontraria o
     * campo, não o registro.
     */
    await waitFor(() => {
      const history = screen.getByRole('region', { name: 'Reaberturas' })
      expect(within(history).getByText(/Segunda correção do mês/)).toBeVisible()
    })

    expect(storedMapUnlocks()).toHaveLength(1)
  })

  it('escola que nunca reabriu mapa vê o histórico vazio', async () => {
    renderMaps()

    expect(
      await screen.findByText('Nenhum mapa foi reaberto até agora.')
    ).toBeVisible()
  })

  it('quando o histórico não vem, diz que ele não se perdeu', async () => {
    givenMapUnlocksFail()
    renderMaps()

    expect(
      await screen.findByText(
        /Ele não se perde — foi só a leitura que não veio/
      )
    ).toBeVisible()
  })
})

describe('o dia reaberto, na tela da merendeira', () => {
  beforeEach(() => {
    resetSupabaseMock()
    givenSignedIn(cook)
  })

  it('volta a aceitar edição e diz que foi reaberto', async () => {
    givenMealMaps([
      mapOf('2026-09-04', {
        id: 'map-2026-09-04',
        locked: false,
        unlocks: [
          { unlocked_at: '2026-10-02T17:32:00.000Z', reason: 'Refeições.' },
        ],
      }),
    ])

    renderAt('/dia/2026-09-04')

    expect(
      await screen.findByText(/A direção reabriu este dia para correção/)
    ).toBeVisible()

    /*
     * Esperar o cartão, e não só a faixa: a faixa aparece assim que o servidor
     * responde, e o dia só é desenhado quando o rascunho do aparelho termina de
     * ser lido. Sem esta espera, as afirmações abaixo passariam por o dia ainda
     * não estar na tela — o contrário do que elas querem dizer. Aqui passava e
     * na CI, mais lenta, não.
     */
    expect(
      await screen.findByRole('switch', { name: /Dia não letivo/ })
    ).toBeEnabled()

    /*
     * A justificativa fica na área da direção: aqui ela não aparece, por
     * decisão de escopo — o texto é prestação de contas, não recado.
     */
    expect(screen.queryByText(/Refeições\./)).not.toBeInTheDocument()
    expect(screen.queryByText(/abre só para consulta/)).not.toBeInTheDocument()
  })

  it('aparece sinalizado na visão do mês, sem deixar de ser o que é', async () => {
    givenMealMaps([
      mapOf('2026-09-04', {
        locked: false,
        unlocks: [
          { unlocked_at: '2026-10-02T17:32:00.000Z', reason: 'Refeições.' },
        ],
      }),
    ])

    renderAt('/?mes=2026-09')

    /*
     * Reaberto **e** preenchido: o sinal acompanha o estado do dia, não o
     * substitui — e é o estado que continua contando no andamento do mês.
     */
    const row = await screen.findByRole('link', {
      name: /4 de setembro, preenchido, reaberto para correção/,
    })
    expect(row).toBeVisible()
    expect(row.querySelector('[data-slot="reopened-badge"]')).not.toBeNull()
    expect(row.querySelector('[data-state="complete"]')).not.toBeNull()
  })

  it('o dia que voltou para um documento é bloqueado, e não reaberto', async () => {
    givenMealMaps([
      mapOf('2026-09-04', {
        locked: true,
        unlocks: [
          { unlocked_at: '2026-10-02T17:32:00.000Z', reason: 'Refeições.' },
        ],
      }),
    ])

    renderAt('/?mes=2026-09')

    const row = await screen.findByRole('link', {
      name: /4 de setembro, no documento/,
    })
    expect(row.querySelector('[data-slot="reopened-badge"]')).toBeNull()
  })
})
