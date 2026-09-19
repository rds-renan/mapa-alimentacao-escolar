import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import { MemoryRouter } from 'react-router'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'

import App from '@/App'
import type { Profile } from '@/auth/auth-context'
import { AuthProvider } from '@/auth/auth-provider'
import { SyncProvider } from '@/local/sync-provider'
import { getStoredDay } from '@/local/store'

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
 * Os critérios de aceite da issue #62, um a um.
 *
 * O que se verifica aqui é sempre a mesma coisa vista de ângulos diferentes:
 * **o que ela digitou está guardado no aparelho**, na forma exata que sobe
 * para `save_meal_map`. O envio em si é assunto dos testes da fila; aqui a
 * pergunta é se a tela grava tudo, sem botão de salvar, e se não perde nada
 * pelo caminho.
 */

const cook: Profile = {
  id: '22222222-2222-4222-8222-222222222222',
  name: 'Merendeira 1',
  email: 'merendeira1@dominio.com.br',
  role: 'cook',
  school_id: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
}

const DATE = '2026-09-10'

/** Uma quinta-feira já registrada e já dentro de um documento gerado. */
const LOCKED: MealMapRow = {
  map_date: DATE,
  non_school_day: false,
  note: null,
  meals_served: 310,
  locked: true,
  meal: [
    {
      type: 'morning_snack',
      description: 'Pão com leite',
      acceptance: 'great',
    },
    { type: 'lunch', description: 'Arroz e frango', acceptance: 'good' },
    { type: 'afternoon_snack', description: 'Bolo', acceptance: 'great' },
  ],
}

function renderDay(date = DATE) {
  const queryClient = new QueryClient({
    defaultOptions: { queries: { retry: false } },
  })

  return render(
    <MemoryRouter initialEntries={[`/dia/${date}`]}>
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
 * Espera a tela abrir. O cabeçalho aparece antes da resposta do servidor —
 * é ele que segura a tela enquanto o dia não vem —, então esperar pelo título
 * não prova que dá para digitar.
 */
function dayLoaded() {
  return screen.findByText('Dia não letivo')
}

/** O dia como está guardado no aparelho agora. */
function storedDay() {
  return getStoredDay(cook.id, DATE)
}

function openCard(name: string) {
  fireEvent.click(screen.getByRole('button', { name: new RegExp(`^${name}`) }))
}

function typeDescription(value: string) {
  fireEvent.change(screen.getByLabelText('Cardápio realizado'), {
    target: { value },
  })
}

beforeEach(() => {
  resetSupabaseMock()
  givenSignedIn(cook)
  givenMealMaps([])
})

afterEach(() => {
  resetSupabaseMock()
})

describe('o registro de um dia comum', () => {
  it('grava cada tecla no aparelho, sem botão de salvar', async () => {
    renderDay()
    await dayLoaded()

    // O lanche da manhã já abre: é a primeira refeição que falta.
    typeDescription('Pão com manteiga e leite com achocolatado')
    fireEvent.click(screen.getByRole('button', { name: 'Ótimo' }))

    await waitFor(async () => {
      const stored = await storedDay()
      expect(stored?.day.meals[0].description).toBe(
        'Pão com manteiga e leite com achocolatado'
      )
      expect(stored?.day.meals[0].acceptance).toBe('great')
    })

    expect(
      screen.queryByRole('button', { name: /salvar/i })
    ).not.toBeInTheDocument()
    expect(screen.getByText(/Salva sozinho/)).toBeInTheDocument()
  })

  it('leva as três refeições e o número do dia numa carga só', async () => {
    renderDay()
    await dayLoaded()

    typeDescription('Pão com manteiga')
    fireEvent.click(screen.getByRole('button', { name: 'Ótimo' }))

    openCard('Almoço')
    typeDescription('Arroz, feijão e frango')
    fireEvent.click(screen.getByRole('button', { name: 'Bom' }))

    openCard('Lanche da tarde')
    typeDescription('Bolo de fubá')
    fireEvent.click(screen.getByRole('button', { name: 'Ruim' }))

    fireEvent.change(screen.getByLabelText('Refeições servidas no dia'), {
      target: { value: '312' },
    })

    await waitFor(async () => {
      const day = (await storedDay())?.day
      expect(day?.meals).toHaveLength(3)
      expect(day?.meals_served).toBe(312)
      expect(day?.map_date).toBe(DATE)
    })
  })

  it('aceita o registro parcial: gêneros e quantidades não obrigam a nada', async () => {
    renderDay()
    await dayLoaded()

    typeDescription('Pão com manteiga')

    await waitFor(async () => {
      const day = (await storedDay())?.day
      expect(day?.meals[0].acceptance).toBeNull()
      expect(day?.meals[0].food_items).toEqual([])
      expect(day?.meals_served).toBeNull()
    })
  })
})

describe('a aceitação', () => {
  it('é um toque em um de três botões, sem digitar nada (US004)', async () => {
    renderDay()
    await dayLoaded()

    const great = screen.getByRole('button', { name: 'Ótimo' })
    const good = screen.getByRole('button', { name: 'Bom' })
    const poor = screen.getByRole('button', { name: 'Ruim' })

    expect(great).toHaveAttribute('aria-pressed', 'false')

    fireEvent.click(good)

    expect(good).toHaveAttribute('aria-pressed', 'true')
    expect(great).toHaveAttribute('aria-pressed', 'false')
    expect(poor).toHaveAttribute('aria-pressed', 'false')

    await waitFor(async () =>
      expect((await storedDay())?.day.meals[0].acceptance).toBe('good')
    )
  })
})

describe('o número de refeições', () => {
  it('é um campo numérico único do dia (US005)', async () => {
    renderDay()
    await dayLoaded()

    const field = screen.getByLabelText('Refeições servidas no dia')
    expect(field).toHaveAttribute('inputmode', 'numeric')

    fireEvent.change(field, { target: { value: '31a2' } })

    await waitFor(async () =>
      expect((await storedDay())?.day.meals_served).toBe(312)
    )
    expect(field).toHaveValue('312')

    fireEvent.click(screen.getByRole('button', { name: 'Uma refeição a mais' }))
    await waitFor(() => expect(field).toHaveValue('313'))
  })
})

describe('o dia não letivo', () => {
  it('recolhe as refeições e pede o motivo (CA#1 e CA#2 da US006)', async () => {
    renderDay()
    await dayLoaded()

    typeDescription('Pão com manteiga')
    fireEvent.click(screen.getByRole('switch'))

    expect(
      screen.queryByLabelText('Cardápio realizado')
    ).not.toBeInTheDocument()
    expect(screen.getByLabelText('Observação')).toBeInTheDocument()
    expect(screen.getByText(/Escreva o motivo/)).toBeInTheDocument()

    /*
     * Enquanto o motivo não existe, o dia fica guardado e não sobe: o servidor
     * recusaria, e a faixa diria "ainda não deu para enviar" para quem não fez
     * nada de errado.
     */
    await waitFor(async () => {
      const day = (await storedDay())?.day
      expect(day?.non_school_day).toBe(true)
      expect(day?.meals).toEqual([])
    })

    fireEvent.change(screen.getByLabelText('Observação'), {
      target: { value: 'Conselho de classe' },
    })

    await waitFor(async () =>
      expect((await storedDay())?.day.note).toBe('Conselho de classe')
    )
    expect(screen.queryByText(/Escreva o motivo/)).not.toBeInTheDocument()
  })

  it('devolve o que já estava digitado quando ela desmarca (CA#3 da US006)', async () => {
    renderDay()
    await dayLoaded()

    typeDescription('Pão com manteiga')
    fireEvent.click(screen.getByRole('button', { name: 'Ótimo' }))
    fireEvent.change(screen.getByLabelText('Refeições servidas no dia'), {
      target: { value: '312' },
    })

    fireEvent.click(screen.getByRole('switch'))
    await screen.findByLabelText('Observação')

    fireEvent.click(screen.getByRole('switch'))

    expect(await screen.findByLabelText('Cardápio realizado')).toHaveValue(
      'Pão com manteiga'
    )
    expect(screen.getByLabelText('Refeições servidas no dia')).toHaveValue(
      '312'
    )

    await waitFor(async () => {
      const day = (await storedDay())?.day
      expect(day?.non_school_day).toBe(false)
      expect(day?.meals[0].acceptance).toBe('great')
      expect(day?.meals_served).toBe(312)
    })
  })
})

describe('o dia que já saiu em documento', () => {
  it('abre para consulta, dizendo por quê (CA#2 da US007)', async () => {
    givenMealMaps([LOCKED])
    renderDay()
    await dayLoaded()

    expect(
      await screen.findByText(/já está em um documento gerado/)
    ).toBeInTheDocument()

    // Com as três refeições prontas nenhum cartão abre sozinho; quem quer
    // conferir o detalhe abre o cartão, como num dia qualquer.
    openCard('Lanche da manhã')

    expect(screen.getByRole('switch')).toBeDisabled()
    expect(screen.getByLabelText('Refeições servidas no dia')).toBeDisabled()
    expect(screen.getByLabelText('Cardápio realizado')).toBeDisabled()
    expect(screen.getByRole('button', { name: 'Ótimo' })).toBeDisabled()
  })

  it('mostra o que foi registrado, e não uma tela vazia', async () => {
    givenMealMaps([LOCKED])
    renderDay()
    await dayLoaded()

    // Fechados, os cartões já dizem o que foi servido em cada refeição.
    expect(await screen.findByText('Arroz e frango')).toBeInTheDocument()

    openCard('Lanche da manhã')
    await waitFor(() =>
      expect(screen.getByLabelText('Cardápio realizado')).toHaveValue(
        'Pão com leite'
      )
    )
    expect(screen.getByLabelText('Refeições servidas no dia')).toHaveValue(
      '310'
    )
  })
})

describe('quando o dia não vem do servidor', () => {
  it('não deixa escrever por cima do que não foi lido, e oferece tentar de novo', async () => {
    givenMealMapsFail()
    renderDay()

    expect(
      await screen.findByText(/foi só a leitura que não veio/)
    ).toBeInTheDocument()
    expect(
      screen.getByRole('button', { name: 'Tentar de novo' })
    ).toBeInTheDocument()
    expect(
      screen.queryByLabelText('Cardápio realizado')
    ).not.toBeInTheDocument()
  })
})

describe('a navegação do cabeçalho', () => {
  it('anda entre dias e volta para o mês', async () => {
    renderDay()
    await dayLoaded()

    expect(
      screen.getByRole('link', { name: 'Voltar para a visão do mês' })
    ).toHaveAttribute('href', '/?mes=2026-09')

    fireEvent.click(
      screen.getByRole('button', { name: /^Próximo dia, 11 de setembro/ })
    )

    expect(await screen.findByText('Sexta, 11 de setembro')).toBeInTheDocument()
  })
})
