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

vi.mock('@/lib/supabase', async () => await import('@/test/supabase-mock'))
vi.mock('@/lib/local-data', () => ({ clearLocalData: vi.fn(async () => {}) }))
vi.mock('@/lib/recovery-link', () => ({
  cameFromRecoveryLink: () => false,
  isRecoveryHash: () => false,
}))

import {
  givenFoodItems,
  givenFoodItemsFail,
  givenFoodItemWriteFails,
  givenMealMaps,
  givenSignedIn,
  resetSupabaseMock,
  storedFoodItems,
  type MealMapRow,
} from '@/test/supabase-mock'

/*
 * Os critérios de aceite da issue #64, um a um.
 *
 * A pergunta desta tela é sempre a mesma: **a unidade de cada gênero continua
 * uma só**, porque é ela que mantém as quantidades comparáveis entre os dias e
 * entre as duas merendeiras (US009). Listar, cadastrar, editar e desativar são
 * quatro maneiras de responder a isso.
 */

const cook: Profile = {
  id: '22222222-2222-4222-8222-222222222222',
  name: 'Merendeira 1',
  email: 'merendeira1@dominio.com.br',
  role: 'cook',
  school_id: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
}

const CATALOGO = [
  { id: 'food-arroz', name: 'Arroz', default_unit: 'quilo' },
  { id: 'food-feijao', name: 'Feijão carioca', default_unit: 'quilo' },
  { id: 'food-manteiga', name: 'Manteiga', default_unit: 'pote' },
]

function renderCatalog() {
  const queryClient = new QueryClient({
    defaultOptions: { queries: { retry: false } },
  })

  return render(
    <MemoryRouter initialEntries={['/generos']}>
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

/** A lista chegou: antes disso o cabeçalho já está na tela, e não prova nada. */
function catalogLoaded() {
  return screen.findByRole('button', { name: 'Editar Arroz' })
}

function typeName(value: string) {
  fireEvent.change(screen.getByLabelText('Nome'), { target: { value } })
}

function typeUnit(value: string) {
  fireEvent.change(screen.getByLabelText('Unidade padrão'), {
    target: { value },
  })
}

function click(name: string | RegExp) {
  fireEvent.click(screen.getByRole('button', { name }))
}

/**
 * "Arroz (quilo)" para cada linha da lista de trabalho, na ordem da tela.
 *
 * Só a de cima: os desativados têm a sua própria seção, e é a diferença entre
 * as duas que importa aqui.
 */
function listed(): string[] {
  const list = screen.getByRole('region', { name: 'No catálogo' })

  return within(list)
    .queryAllByRole('button', { name: /^Editar / })
    .map((row) => {
      const [name, unit] = Array.from(row.querySelectorAll('span'))
      return `${name?.textContent} (${unit?.textContent})`
    })
}

/** O mesmo, para a seção recolhida do pé. */
function listedInactive(): string[] {
  const list = screen.getByRole('region', { name: /^Desativados/ })

  return within(list)
    .queryAllByRole('button', { name: /^Editar / })
    .map((row) => {
      const [name, unit] = Array.from(row.querySelectorAll('span'))
      return `${name?.textContent} (${unit?.textContent})`
    })
}

beforeEach(() => {
  resetSupabaseMock()
  givenSignedIn(cook)
  givenMealMaps([])
  givenFoodItems(CATALOGO)
})

afterEach(() => {
  resetSupabaseMock()
})

describe('a lista do catálogo', () => {
  it('mostra cada gênero com a sua unidade padrão', async () => {
    renderCatalog()
    await catalogLoaded()

    expect(listed()).toEqual([
      'Arroz (quilo)',
      'Feijão carioca (quilo)',
      'Manteiga (pote)',
    ])
  })

  it('busca por nome sem cobrar o acento', async () => {
    renderCatalog()
    await catalogLoaded()

    fireEvent.change(screen.getByLabelText('Buscar gênero'), {
      target: { value: 'feijao' },
    })

    expect(listed()).toEqual(['Feijão carioca (quilo)'])
  })

  it('diz que a lista não veio sem tirar o cadastro da tela', async () => {
    givenFoodItemsFail()
    renderCatalog()

    expect(await screen.findByRole('alert')).toHaveTextContent(
      /Não deu para carregar o catálogo/
    )
    // O cartão continua de pé: o que falhou foi a leitura.
    expect(screen.getByLabelText('Nome')).toBeInTheDocument()
  })
})

describe('cadastrar um gênero', () => {
  it('entra no catálogo com a unidade escolhida na sugestão', async () => {
    renderCatalog()
    await catalogLoaded()

    typeName('Óleo de soja')
    click('lata')
    click('Adicionar ao catálogo')

    expect(await screen.findByRole('alert')).toHaveTextContent(
      'Óleo de soja entrou no catálogo.'
    )
    await waitFor(() => {
      expect(listed()).toContain('Óleo de soja (lata)')
    })

    expect(storedFoodItems()).toContainEqual(
      expect.objectContaining({ name: 'Óleo de soja', default_unit: 'lata' })
    )
  })

  it('aceita a unidade que a cozinha usa, fora das seis sugeridas', async () => {
    renderCatalog()
    await catalogLoaded()

    typeName('Ovo')
    typeUnit('bandeja')
    click('Adicionar ao catálogo')

    await waitFor(() => {
      expect(listed()).toContain('Ovo (bandeja)')
    })
  })

  it('não deixa salvar sem nome ou sem unidade', async () => {
    renderCatalog()
    await catalogLoaded()

    const add = screen.getByRole('button', { name: 'Adicionar ao catálogo' })
    expect(add).toBeDisabled()

    typeName('Ovo')
    expect(add).toBeDisabled()

    typeUnit('bandeja')
    expect(add).toBeEnabled()
  })

  it('avisa que o nome já está no catálogo em vez de deixar duplicar', async () => {
    renderCatalog()
    await catalogLoaded()

    typeName('arroz')
    typeUnit('quilo')

    expect(screen.getByRole('alert')).toHaveTextContent(
      'Arroz já está no catálogo.'
    )
    expect(
      screen.getByRole('button', { name: 'Adicionar ao catálogo' })
    ).toBeDisabled()
  })

  it('guarda o que ela escreveu quando a gravação não passa', async () => {
    givenFoodItemWriteFails()
    renderCatalog()
    await catalogLoaded()

    typeName('Ovo')
    typeUnit('bandeja')
    click('Adicionar ao catálogo')

    expect(await screen.findByRole('alert')).toHaveTextContent(
      /Não deu para salvar agora/
    )
    expect(screen.getByLabelText('Nome')).toHaveValue('Ovo')
    expect(screen.getByLabelText('Unidade padrão')).toHaveValue('bandeja')
  })
})

describe('editar um gênero', () => {
  it('carrega o gênero da lista no mesmo cartão e salva o nome novo', async () => {
    renderCatalog()
    await catalogLoaded()

    click('Editar Manteiga')

    expect(screen.getByText('Editar gênero')).toBeInTheDocument()
    expect(screen.getByLabelText('Nome')).toHaveValue('Manteiga')
    expect(screen.getByLabelText('Unidade padrão')).toHaveValue('pote')

    typeName('Manteiga com sal')
    click('Salvar')

    await waitFor(() => {
      expect(listed()).toContain('Manteiga com sal (pote)')
    })
    // O cartão volta a ser o de cadastro: a edição terminou.
    expect(screen.getByText('Novo gênero')).toBeInTheDocument()
  })

  it('avisa que trocar a unidade alcança os dias já registrados', async () => {
    renderCatalog()
    await catalogLoaded()

    click('Editar Manteiga')
    expect(
      screen.queryByText(/Mudar a unidade muda também/)
    ).not.toBeInTheDocument()

    typeUnit('quilo')

    expect(screen.getByText(/Mudar a unidade muda também/)).toBeInTheDocument()
  })

  it('desiste da edição sem mexer no gênero', async () => {
    renderCatalog()
    await catalogLoaded()

    click('Editar Manteiga')
    typeName('Margarina')
    click('Cancelar a edição')

    expect(screen.getByText('Novo gênero')).toBeInTheDocument()
    expect(screen.getByLabelText('Nome')).toHaveValue('')
    expect(listed()).toContain('Manteiga (pote)')
  })
})

describe('desativar um gênero', () => {
  it('tira das sugestões, mostra entre os desativados e deixa reativar', async () => {
    renderCatalog()
    await catalogLoaded()

    click('Editar Manteiga')
    click('Desativar')

    expect(await screen.findByRole('alert')).toHaveTextContent(
      'Manteiga saiu das sugestões. Os dias que já o usaram continuam como estão.'
    )

    // Ela some da lista de trabalho e aparece na seção de baixo, já aberta.
    await waitFor(() => {
      expect(listedInactive()).toEqual(['Manteiga (pote)'])
    })
    expect(listed()).toEqual(['Arroz (quilo)', 'Feijão carioca (quilo)'])

    click('Editar Manteiga')
    click('Reativar')

    await waitFor(() => {
      expect(listed()).toContain('Manteiga (pote)')
    })
    expect(
      screen.queryByRole('region', { name: /^Desativados/ })
    ).not.toBeInTheDocument()
  })

  it('diz onde está o homônimo desativado em vez de recusar sem explicação', async () => {
    givenFoodItems([
      ...CATALOGO.slice(0, 2),
      {
        id: 'food-manteiga',
        name: 'Manteiga',
        default_unit: 'pote',
        active: false,
      },
    ])
    renderCatalog()
    await catalogLoaded()

    typeName('Manteiga')
    typeUnit('pote')

    expect(screen.getByRole('alert')).toHaveTextContent(
      'Manteiga já está no catálogo, entre os desativados. Reative para usar de novo.'
    )
  })
})

describe('o gênero desativado, visto do registro do dia', () => {
  /** Uma quinta-feira em que a manteiga já foi usada, antes de ser desativada. */
  const DIA: MealMapRow = {
    map_date: '2026-09-10',
    non_school_day: false,
    note: null,
    meals_served: 310,
    locked: false,
    meal: [
      {
        type: 'morning_snack',
        description: 'Pão com manteiga',
        acceptance: 'great',
        food_items: [
          {
            food_item_id: 'food-manteiga',
            name: 'Manteiga',
            default_unit: 'pote',
            quantity: 2,
          },
        ],
      },
    ],
  }

  it('continua no dia que já o usou e some da folha de escolher', async () => {
    givenMealMaps([DIA])
    givenFoodItems([
      { id: 'food-arroz', name: 'Arroz', default_unit: 'quilo' },
      {
        id: 'food-manteiga',
        name: 'Manteiga',
        default_unit: 'pote',
        active: false,
      },
    ])

    const queryClient = new QueryClient({
      defaultOptions: { queries: { retry: false } },
    })

    render(
      <MemoryRouter initialEntries={['/dia/2026-09-10']}>
        <QueryClientProvider client={queryClient}>
          <AuthProvider>
            <SyncProvider>
              <App />
            </SyncProvider>
          </AuthProvider>
        </QueryClientProvider>
      </MemoryRouter>
    )

    // O cartão abre com o que já estava lá.
    fireEvent.click(
      await screen.findByRole('button', { name: /^Lanche da manhã/ })
    )

    // O gênero desativado continua no dia que já o usou (CA#3 da US009), com a
    // sua unidade — é a unidade que faz a quantidade querer dizer alguma coisa.
    expect(
      screen.getByLabelText('Quantidade de Manteiga, em pote')
    ).toHaveValue('2')

    // E não é mais oferecido a um registro novo: sumiu das sugestões.
    fireEvent.click(screen.getByRole('button', { name: 'Adicionar gênero' }))

    const sheet = within(await screen.findByRole('dialog'))
    expect(await sheet.findByText('Arroz')).toBeInTheDocument()
    expect(sheet.queryByText('Manteiga')).not.toBeInTheDocument()
  })
})
