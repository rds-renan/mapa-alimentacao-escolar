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
import { getStoredDay } from '@/local/store'
import { SyncProvider } from '@/local/sync-provider'
import { ThemeProvider } from '@/theme/theme-provider'

vi.mock('@/lib/supabase', async () => await import('@/test/supabase-mock'))
vi.mock('@/lib/local-data', () => ({ clearLocalData: vi.fn(async () => {}) }))
vi.mock('@/lib/recovery-link', () => ({
  cameFromRecoveryLink: () => false,
  isRecoveryHash: () => false,
}))

import {
  givenFoodItems,
  givenFoodItemsFail,
  givenMealMaps,
  givenSignedIn,
  resetSupabaseMock,
  type MealMapRow,
} from '@/test/supabase-mock'

/*
 * Os critérios de aceite da issue #63, um a um: os gêneros utilizados e a
 * alteração do cardápio (telas 3a e 3b).
 *
 * A pergunta é sempre a mesma das outras telas — **o que ela registrou está
 * guardado no aparelho, na forma exata que sobe para `save_meal_map`** —, com
 * uma a mais, que é o que esta issue trouxe: o que ainda não está inteiro
 * **não sobe**, e fica guardado até ficar.
 */

const cook: Profile = {
  id: '22222222-2222-4222-8222-222222222222',
  name: 'Merendeira 1',
  email: 'merendeira1@dominio.com.br',
  role: 'cook',
  school_id: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
}

/*
 * Um dia diferente por caso.
 *
 * A gravação no aparelho é assíncrona e não termina junto com o caso: a
 * última tecla de um teste pode chegar ao disco já com o banco do teste
 * seguinte no lugar. Datas distintas tiram o acaso do caminho — e são de
 * graça, porque a data é o que identifica o dia.
 */
let caseNumber = 0
let DATE = ''

const CATALOG = [
  { id: 'rice', name: 'Arroz', default_unit: 'quilo' },
  { id: 'beans', name: 'Feijão carioca', default_unit: 'quilo' },
  { id: 'milk', name: 'Leite em pó', default_unit: 'saco' },
]

/** Um dia que já voltou do servidor com a troca registrada. */
function withChange(): MealMapRow {
  return {
    map_date: DATE,
    non_school_day: false,
    note: null,
    meals_served: 312,
    locked: false,
    meal: [
      {
        type: 'lunch',
        description: 'Arroz, feijão e frango',
        acceptance: 'good',
      },
    ],
    menu_change: {
      id: 'change-1',
      reason: 'Não veio o frango na entrega da semana.',
      food_items: [
        {
          food_item_id: 'egg',
          name: 'Ovo',
          default_unit: 'bandeja',
          quantity: 3,
        },
      ],
    },
  }
}

function renderDay() {
  const queryClient = new QueryClient({
    defaultOptions: { queries: { retry: false } },
  })

  return render(
    <ThemeProvider>
      <MemoryRouter initialEntries={[`/dia/${DATE}`]}>
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

function dayLoaded() {
  return screen.findByText('Dia não letivo')
}

function storedDay() {
  return getStoredDay(cook.id, DATE)
}

function openCard(name: string) {
  fireEvent.click(screen.getByRole('button', { name: new RegExp(`^${name}`) }))
}

/** O almoço que está guardado no aparelho agora. */
async function storedLunch() {
  const day = (await storedDay())?.day
  return day?.meals.find((meal) => meal.type === 'lunch')
}

/** O dia guardado no aparelho: é nele que moram os gêneros e a alteração. */
async function storedContent() {
  return (await storedDay())?.day
}

/**
 * Abre a folha 3b a partir do cartão aberto, marca gêneros do catálogo e
 * adiciona todos.
 */
async function chooseFromCatalog(...names: string[]) {
  fireEvent.click(screen.getByRole('button', { name: /Adicionar gênero/ }))
  const sheet = await screen.findByRole('dialog')
  for (const name of names) {
    fireEvent.click(
      await within(sheet).findByRole('checkbox', { name: new RegExp(name) })
    )
  }
  fireEvent.click(within(sheet).getByRole('button', { name: /^Adicionar \d/ }))
}

beforeEach(() => {
  caseNumber += 1
  DATE = `2026-09-${String(caseNumber).padStart(2, '0')}`
  resetSupabaseMock()
  givenSignedIn(cook)
  givenMealMaps([])
  givenFoodItems(CATALOG)
})

afterEach(() => {
  resetSupabaseMock()
})

describe('os gêneros utilizados', () => {
  it('ficam num cartão do dia, fora das refeições (decisão 14 da E4)', async () => {
    renderDay()
    await dayLoaded()

    const card = screen.getByRole('region', { name: 'Gêneros do dia' })
    expect(within(card).getByText('Vazio')).toBeVisible()

    await chooseFromCatalog('Arroz')

    expect(await within(card).findByText('Preenchido')).toBeVisible()
    await waitFor(async () => expect((await storedLunch()) ?? null).toBeNull())
  })

  it('são escolhidos sem sair da tela do registro (decisão 7 da E3)', async () => {
    renderDay()
    await dayLoaded()
    openCard('Almoço')

    await chooseFromCatalog('Arroz')

    // A tela do dia continua ali, com o cartão aberto onde ela o deixou.
    expect(screen.getByLabelText('Cardápio previsto')).toBeInTheDocument()

    await waitFor(async () => {
      expect((await storedContent())?.food_items).toEqual([
        {
          food_item_id: 'rice',
          name: 'Arroz',
          unit: 'quilo',
          quantity: 1,
        },
      ])
    })
  })

  it('entram vários de uma vez, na ordem em que ela marcou (issue #173)', async () => {
    renderDay()
    await dayLoaded()
    await chooseFromCatalog('Arroz')

    fireEvent.click(screen.getByRole('button', { name: /Adicionar gênero/ }))
    const sheet = await screen.findByRole('dialog')
    const add = () => within(sheet).getByRole('button', { name: /^Adicionar/ })
    expect(add()).toHaveTextContent('Adicionar ao dia')
    expect(add()).toBeDisabled()

    // O que já está no dia vem marcado e não se mexe.
    const rice = within(sheet).getByRole('checkbox', { name: /Arroz/ })
    expect(rice).toBeChecked()
    expect(rice).toBeDisabled()

    fireEvent.click(within(sheet).getByRole('checkbox', { name: /Leite/ }))
    fireEvent.click(within(sheet).getByRole('checkbox', { name: /Feijão/ }))
    expect(add()).toHaveTextContent('Adicionar 2 gêneros')

    // Tocar de novo desmarca.
    fireEvent.click(within(sheet).getByRole('checkbox', { name: /Feijão/ }))
    expect(add()).toHaveTextContent('Adicionar 1 gênero')
    fireEvent.click(within(sheet).getByRole('checkbox', { name: /Feijão/ }))

    fireEvent.click(add())

    await waitFor(async () => {
      expect(
        (await storedContent())?.food_items.map((item) => item.name)
      ).toEqual(['Arroz', 'Leite em pó', 'Feijão carioca'])
    })
  })

  it('andam em inteiros, na unidade do catálogo, com teclado numérico (US003)', async () => {
    renderDay()
    await dayLoaded()
    openCard('Almoço')
    await chooseFromCatalog('Arroz')

    const quantity = await screen.findByLabelText(
      'Quantidade de Arroz, em quilo'
    )
    expect(quantity).toHaveAttribute('inputmode', 'numeric')

    fireEvent.click(screen.getByRole('button', { name: 'Um a mais de Arroz' }))
    await waitFor(async () =>
      expect((await storedContent())?.food_items[0].quantity).toBe(2)
    )

    fireEvent.change(quantity, { target: { value: '4a,5' } })
    await waitFor(async () =>
      expect((await storedContent())?.food_items[0].quantity).toBe(45)
    )
  })

  it('saem da lista pelo "−" de quem está em 1', async () => {
    renderDay()
    await dayLoaded()
    openCard('Almoço')
    await chooseFromCatalog('Arroz')

    fireEvent.click(
      await screen.findByRole('button', { name: 'Tirar Arroz da lista' })
    )

    await waitFor(async () =>
      expect((await storedContent())?.food_items).toEqual([])
    )
  })

  it('aceitam um gênero novo, cadastrado no próprio fluxo (CA#2 da US009)', async () => {
    renderDay()
    await dayLoaded()
    openCard('Almoço')

    fireEvent.click(screen.getByRole('button', { name: /Adicionar gênero/ }))
    const sheet = await screen.findByRole('dialog')

    fireEvent.change(within(sheet).getByLabelText('Buscar gênero'), {
      target: { value: 'Feijão preto' },
    })
    // Não está no catálogo: o cadastro embaixo já vem com o nome buscado.
    expect(within(sheet).getByText(/Nenhum gênero com esse nome/)).toBeVisible()
    expect(within(sheet).getByLabelText('Nome do gênero')).toHaveValue(
      'Feijão preto'
    )

    fireEvent.click(within(sheet).getByRole('button', { name: 'un' }))
    fireEvent.click(within(sheet).getByRole('button', { name: 'Cadastrar' }))

    // Cadastrado, ele fica marcado na folha, e o cadastro volta ao começo.
    expect(
      within(sheet).getByRole('checkbox', { name: /Feijão preto/ })
    ).toBeChecked()
    expect(within(sheet).getByLabelText('Nome do gênero')).toHaveValue('')
    fireEvent.click(
      within(sheet).getByRole('button', { name: 'Adicionar 1 gênero' })
    )

    await waitFor(async () => {
      expect((await storedContent())?.food_items).toEqual([
        {
          food_item_id: null,
          name: 'Feijão preto',
          unit: 'un',
          quantity: 1,
        },
      ])
    })
  })

  it('deixam cadastrar mesmo quando o catálogo não veio', async () => {
    givenFoodItemsFail()
    renderDay()
    await dayLoaded()
    openCard('Almoço')

    fireEvent.click(screen.getByRole('button', { name: /Adicionar gênero/ }))
    const sheet = await screen.findByRole('dialog')

    expect(
      await within(sheet).findByText(/Não deu para carregar o catálogo/)
    ).toBeVisible()
    expect(
      within(sheet).getByRole('button', { name: 'Cadastrar' })
    ).toBeInTheDocument()
  })

  it('acham no catálogo sem exigir o acento certo (RNF#1 da US009)', async () => {
    renderDay()
    await dayLoaded()
    openCard('Almoço')

    fireEvent.click(screen.getByRole('button', { name: /Adicionar gênero/ }))
    const sheet = await screen.findByRole('dialog')
    fireEvent.change(within(sheet).getByLabelText('Buscar gênero'), {
      target: { value: 'feijao' },
    })

    expect(
      within(sheet).getByRole('checkbox', { name: /Feijão carioca/ })
    ).toBeInTheDocument()
    expect(
      within(sheet).queryByRole('checkbox', { name: /Arroz/ })
    ).not.toBeInTheDocument()
  })
})

describe('a alteração do cardápio', () => {
  it('não mexe na refeição, que continua sendo o cardápio previsto', async () => {
    renderDay()
    await dayLoaded()
    openCard('Almoço')

    fireEvent.change(screen.getByLabelText('Cardápio previsto'), {
      target: { value: 'Arroz, feijão e frango' },
    })
    fireEvent.click(screen.getByRole('button', { name: 'Bom' }))

    fireEvent.click(
      screen.getByRole('button', { name: 'Alteração do cardápio' })
    )
    const dialog = await screen.findByRole('dialog')
    expect(
      within(dialog).getByText(/continuam registradas como o cardápio previsto/)
    ).toBeVisible()

    await chooseFromCatalogInside(dialog, 'Arroz')
    fireEvent.change(within(dialog).getByLabelText('Motivo'), {
      target: { value: 'Não veio o frango na entrega.' },
    })
    fireEvent.click(
      within(dialog).getByRole('button', { name: 'Confirmar alteração' })
    )

    await waitFor(async () => {
      const lunch = await storedLunch()
      expect(lunch?.description).toBe('Arroz, feijão e frango')
      expect(lunch?.acceptance).toBe('good')
      const day = await storedContent()
      expect(day?.menu_change?.reason).toBe('Não veio o frango na entrega.')
      expect(day?.menu_change?.food_items).toHaveLength(1)
    })
  })

  it('é uma só por dia: o botão vira o resumo do que foi registrado', async () => {
    givenMealMaps([withChange()])
    renderDay()
    await dayLoaded()
    openCard('Almoço')

    expect(await screen.findByText('3 bandeja de ovo')).toBeInTheDocument()
    expect(
      screen.getByText('Não veio o frango na entrega da semana.')
    ).toBeInTheDocument()
    // Registrada a alteração, o botão que a abriria some: ela é uma só.
    expect(
      screen.queryByRole('button', { name: 'Alteração do cardápio' })
    ).not.toBeInTheDocument()
  })

  it('sugere os motivos frequentes e deixa escrever o próprio (RNF#1 da US002)', async () => {
    renderDay()
    await dayLoaded()
    openCard('Almoço')
    fireEvent.click(
      screen.getByRole('button', { name: 'Alteração do cardápio' })
    )

    const dialog = await screen.findByRole('dialog')
    fireEvent.click(
      within(dialog).getByRole('button', {
        name: 'Falta de entrega do fornecedor',
      })
    )
    expect(within(dialog).getByLabelText('Motivo')).toHaveValue(
      'Falta de entrega do fornecedor'
    )

    fireEvent.change(within(dialog).getByLabelText('Motivo'), {
      target: { value: 'O caminhão não chegou.' },
    })
    expect(within(dialog).getByLabelText('Motivo')).toHaveValue(
      'O caminhão não chegou.'
    )
  })

  it('fica guardada no aparelho enquanto falta o motivo, e diz o que falta', async () => {
    renderDay()
    await dayLoaded()
    openCard('Almoço')
    fireEvent.click(
      screen.getByRole('button', { name: 'Alteração do cardápio' })
    )

    const dialog = await screen.findByRole('dialog')
    await chooseFromCatalogInside(dialog, 'Arroz')

    expect(
      await within(dialog).findByText(
        'Escreva o motivo para esta alteração entrar no mapa.'
      )
    ).toBeVisible()

    await waitFor(async () => {
      const record = await storedDay()
      expect(record?.day.menu_change?.food_items).toHaveLength(1)
      // Guardado, e não enviado: a fila não tenta o que voltaria recusado.
      expect(record?.attempts).toBe(0)
    })
  })

  it('cancelar devolve a alteração que estava registrada', async () => {
    givenMealMaps([withChange()])
    renderDay()
    await dayLoaded()
    openCard('Almoço')

    fireEvent.click(await screen.findByText('3 bandeja de ovo'))
    const dialog = await screen.findByRole('dialog')

    fireEvent.change(within(dialog).getByLabelText('Motivo'), {
      target: { value: 'outra coisa' },
    })
    fireEvent.click(within(dialog).getByRole('button', { name: 'Cancelar' }))

    await waitFor(async () =>
      expect((await storedContent())?.menu_change?.reason).toBe(
        'Não veio o frango na entrega da semana.'
      )
    )
  })

  it('sai do dia quando ela a remove', async () => {
    givenMealMaps([withChange()])
    renderDay()
    await dayLoaded()
    openCard('Almoço')

    fireEvent.click(await screen.findByText('3 bandeja de ovo'))
    const dialog = await screen.findByRole('dialog')
    fireEvent.click(
      within(dialog).getByRole('button', { name: 'Remover a alteração' })
    )

    await waitFor(async () =>
      expect((await storedContent())?.menu_change).toBeNull()
    )
    expect(
      await screen.findByRole('button', { name: 'Alteração do cardápio' })
    ).toBeInTheDocument()
  })

  it('aberta e fechada sem nada dentro não vira registro nenhum', async () => {
    renderDay()
    await dayLoaded()
    openCard('Almoço')
    fireEvent.click(
      screen.getByRole('button', { name: 'Alteração do cardápio' })
    )

    const dialog = await screen.findByRole('dialog')
    fireEvent.click(
      within(dialog).getByRole('button', { name: 'Confirmar alteração' })
    )

    await waitFor(() =>
      expect(
        screen.getByRole('button', { name: 'Alteração do cardápio' })
      ).toBeInTheDocument()
    )
    expect((await storedContent())?.menu_change ?? null).toBeNull()
  })
})

/** A folha 3b, quando quem a abre é a tela 3a — que já é um diálogo. */
async function chooseFromCatalogInside(dialog: HTMLElement, name: string) {
  fireEvent.click(
    within(dialog).getByRole('button', { name: /Adicionar gênero/ })
  )
  const sheets = await screen.findAllByRole('dialog')
  const sheet = sheets[sheets.length - 1]
  fireEvent.click(
    await within(sheet).findByRole('checkbox', { name: new RegExp(name) })
  )
  fireEvent.click(within(sheet).getByRole('button', { name: /^Adicionar \d/ }))
}
