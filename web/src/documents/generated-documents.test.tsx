import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import { MemoryRouter } from 'react-router'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'

import App from '@/App'
import { AuthProvider } from '@/auth/auth-provider'
import type { Profile } from '@/auth/auth-context'
import { SyncProvider } from '@/local/sync-provider'

vi.mock('@/lib/supabase', async () => await import('@/test/supabase-mock'))
vi.mock('@/lib/local-data', () => ({ clearLocalData: vi.fn(async () => {}) }))
vi.mock('@/lib/recovery-link', () => ({
  cameFromRecoveryLink: () => false,
  isRecoveryHash: () => false,
}))

import {
  givenGeneratedDocuments,
  givenGeneratedDocumentsFail,
  givenSignedIn,
  givenSignedUrlFails,
  resetSupabaseMock,
  signedUrls,
  type GeneratedDocumentRow,
} from '@/test/supabase-mock'

/*
 * Os critérios de aceite da issue #67, um a um.
 *
 * O relógio é fixado em 9 de setembro de 2026 pelo mesmo motivo das outras
 * telas: a situação de cada documento é a comparação entre o prazo que o
 * banco carimbou e o dia de hoje, e um teste que mudasse de resultado
 * conforme a hora em que roda não provaria nada.
 */

const cook: Profile = {
  id: '22222222-2222-4222-8222-222222222222',
  name: 'Merendeira 1',
  email: 'merendeira1@dominio.com.br',
  role: 'cook',
  school_id: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
}

/** O documento do começo de setembro, no ar e com folga. */
function disponivel(
  changes: Partial<GeneratedDocumentRow> = {}
): GeneratedDocumentRow {
  return {
    id: 'doc-1',
    status: 'available',
    requested_at: '2026-09-07T17:32:00',
    completed_at: '2026-09-07T17:32:00',
    expires_at: '2026-09-14T17:32:00',
    file_path: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa/doc-1.docx',
    file_name: 'mapa-da-alimentacao-escolar-setembro-2026.docx',
    dates: ['2026-09-01', '2026-09-02', '2026-09-03'],
    ...changes,
  }
}

function renderApp(path: string | { pathname: string; state?: unknown }) {
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

/** Os cartões da lista, na ordem em que aparecem. */
function cards() {
  return document.querySelectorAll('[data-slot="document-card"]')
}

/**
 * O clique no link de download, sem sair navegando: no jsdom não há para onde
 * ir, e o que interessa conferir é o endereço que ele levava.
 */
let clicked: string[] = []

beforeEach(() => {
  resetSupabaseMock()
  localStorage.clear()
  vi.useFakeTimers({ toFake: ['Date'] })
  vi.setSystemTime(new Date('2026-09-09T14:32:00'))
  givenSignedIn(cook)

  clicked = []
  vi.spyOn(HTMLAnchorElement.prototype, 'click').mockImplementation(function (
    this: HTMLAnchorElement
  ) {
    clicked.push(this.href)
  })
})

afterEach(() => {
  vi.useRealTimers()
  vi.restoreAllMocks()
  /*
   * O gerente de rede da TanStack Query é um só para o arquivo inteiro e
   * guarda o último evento que viu. Sem devolvê-lo ao ar aqui, o teste que
   * derruba a internet deixaria os seguintes com as consultas paradas.
   */
  fireEvent(window, new Event('online'))
})

describe('a lista', () => {
  it('mostra período, quantos mapas, quando saiu e quando sai do ar', async () => {
    givenGeneratedDocuments([disponivel()])
    renderApp('/documentos')

    await screen.findByText('1 a 3 de setembro')
    expect(
      screen.getByText('3 mapas · gerado em 7 de setembro')
    ).toBeInTheDocument()
    expect(screen.getByText('Disponível')).toBeInTheDocument()
    expect(screen.getByText('Sai do ar em 14 de setembro')).toBeInTheDocument()
  })

  it('avisa o que está para sair, e ainda deixa baixar', async () => {
    givenGeneratedDocuments([disponivel({ expires_at: '2026-09-10T08:00:00' })])
    renderApp('/documentos')

    await screen.findByText('Sai amanhã')
    expect(
      screen.getByRole('button', {
        name: 'Baixar o documento de 1 a 3 de setembro',
      })
    ).toBeEnabled()
  })

  it('vem do mais novo para o mais velho, que é o que diz qual vale', async () => {
    givenGeneratedDocuments([
      disponivel({
        id: 'doc-2',
        requested_at: '2026-09-09T09:00:00',
        completed_at: '2026-09-09T09:00:00',
        expires_at: '2026-09-16T09:00:00',
      }),
      disponivel(),
    ])
    renderApp('/documentos')

    await waitFor(() => expect(cards()).toHaveLength(2))
    const shown = cards()
    expect(shown[0]).toHaveTextContent('gerado hoje, 9h00')
    expect(shown[1]).toHaveTextContent('gerado em 7 de setembro')
  })

  it('não abre mapa nenhum: nada aqui leva para o registro do dia', async () => {
    givenGeneratedDocuments([disponivel()])
    renderApp('/documentos')

    await screen.findByText('1 a 3 de setembro')
    for (const link of screen.getAllByRole('link')) {
      expect(link.getAttribute('href')).not.toMatch(/^\/dia\//)
    }
  })

  it('sem documento nenhum, aponta para onde se gera o primeiro', async () => {
    givenGeneratedDocuments([])
    renderApp('/documentos')

    await screen.findByText(/ainda não gerou nenhum documento/)
    expect(
      screen.getByRole('link', { name: 'Gerar documento' })
    ).toHaveAttribute('href', '/gerar?mes=2026-09')
  })

  it('quando não vem, diz primeiro o que não se perdeu', async () => {
    givenGeneratedDocumentsFail()
    renderApp('/documentos')

    const alert = await screen.findByRole('alert')
    expect(alert).toHaveTextContent('continuam guardados')
    expect(
      screen.getByRole('button', { name: 'Tentar de novo' })
    ).toBeInTheDocument()
  })
})

describe('o documento fora da janela', () => {
  it('aparece como indisponível, sem botão e sem susto (CA#3 da US021)', async () => {
    givenGeneratedDocuments([disponivel({ expires_at: '2026-09-08T17:32:00' })])
    renderApp('/documentos')

    await screen.findByText('Fora do ar')
    expect(
      screen.getByText('Os mapas desse período continuam guardados.')
    ).toBeInTheDocument()
    expect(screen.queryByRole('button', { name: /Baixar/ })).toBeNull()
  })

  it('a geração que falhou fica à vista, dizendo que nada foi bloqueado', async () => {
    givenGeneratedDocuments([
      disponivel({
        status: 'failed',
        expires_at: null,
        file_path: null,
        file_name: null,
      }),
    ])
    renderApp('/documentos')

    await screen.findByText('Não saiu')
    expect(screen.getByText(/Nenhum mapa foi bloqueado/)).toBeInTheDocument()
    expect(screen.queryByRole('button', { name: /Baixar/ })).toBeNull()
  })
})

describe('baixar', () => {
  it('assina o link do arquivo e o entrega com o nome que a geração gravou', async () => {
    givenGeneratedDocuments([disponivel()])
    renderApp('/documentos')

    fireEvent.click(
      await screen.findByRole('button', {
        name: 'Baixar o documento de 1 a 3 de setembro',
      })
    )

    await waitFor(() => expect(signedUrls()).toHaveLength(1))
    expect(signedUrls()[0]).toMatchObject({
      path: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa/doc-1.docx',
      download: 'mapa-da-alimentacao-escolar-setembro-2026.docx',
    })
    await waitFor(() => expect(clicked).toHaveLength(1))
    expect(clicked[0]).toContain('doc-1.docx')
  })

  it('quando o link não sai, diz que o arquivo continua no ar', async () => {
    givenGeneratedDocuments([disponivel()])
    givenSignedUrlFails()
    renderApp('/documentos')

    fireEvent.click(
      await screen.findByRole('button', {
        name: 'Baixar o documento de 1 a 3 de setembro',
      })
    )

    const alert = await screen.findByRole('alert')
    expect(alert).toHaveTextContent('Ele continua no ar')
    expect(clicked).toHaveLength(0)
  })

  /*
   * A rede cai com a lista já na tela, que é o caso que existe: sem rede
   * desde o começo, a própria lista não chega — a web não promete navegar
   * offline (decisão 2 da E5).
   */
  it('sem internet, a espera é explicada e o botão não engana', async () => {
    givenGeneratedDocuments([disponivel()])
    renderApp('/documentos')
    await screen.findByText('1 a 3 de setembro')

    vi.spyOn(navigator, 'onLine', 'get').mockReturnValue(false)
    fireEvent(window, new Event('offline'))

    await screen.findByText(/Baixar o documento precisa de internet/)
    expect(
      screen.getByRole('button', {
        name: 'Baixar o documento de 1 a 3 de setembro',
      })
    ).toBeDisabled()
  })
})

describe('compartilhar', () => {
  it('não aparece no navegador que não compartilha arquivo', async () => {
    givenGeneratedDocuments([disponivel()])
    renderApp('/documentos')

    await screen.findByText('1 a 3 de setembro')
    expect(screen.queryByRole('button', { name: /Compartilhar/ })).toBeNull()
    expect(screen.getByRole('button', { name: /Baixar/ })).toBeInTheDocument()
  })

  it('aparece quando o navegador expõe a API, e manda o arquivo (CA#2 da US021)', async () => {
    const share = vi.fn(async () => {})
    Object.defineProperty(navigator, 'share', {
      value: share,
      configurable: true,
    })
    Object.defineProperty(navigator, 'canShare', {
      value: () => true,
      configurable: true,
    })
    vi.stubGlobal(
      'fetch',
      vi.fn(async () => ({ ok: true, blob: async () => new Blob(['docx']) }))
    )

    givenGeneratedDocuments([disponivel()])
    renderApp('/documentos')

    fireEvent.click(
      await screen.findByRole('button', {
        name: 'Compartilhar o documento de 1 a 3 de setembro',
      })
    )

    await waitFor(() => expect(share).toHaveBeenCalledTimes(1))
    const [{ files }] = share.mock.calls[0] as unknown as [{ files: File[] }]
    expect(files[0].name).toBe('mapa-da-alimentacao-escolar-setembro-2026.docx')
    // Compartilhou: não baixou também.
    expect(clicked).toHaveLength(0)

    vi.unstubAllGlobals()
    Reflect.deleteProperty(navigator, 'share')
    Reflect.deleteProperty(navigator, 'canShare')
  })
})

describe('o documento recém-gerado', () => {
  it('abre como a tela 6: confirma, nomeia o arquivo e avisa do bloqueio', async () => {
    givenGeneratedDocuments([disponivel()])
    renderApp({ pathname: '/documentos', state: { justGenerated: 'doc-1' } })

    await screen.findByText('Documento gerado')
    expect(
      screen.getByText('mapa-da-alimentacao-escolar-setembro-2026.docx')
    ).toBeInTheDocument()
    expect(
      screen.getByText(/Os 3 mapas incluídos ficaram bloqueados/)
    ).toBeInTheDocument()
    expect(
      screen.getByRole('button', {
        name: 'Baixar o documento de 1 a 3 de setembro',
      })
    ).toBeEnabled()
  })

  it('chegando pelo menu, é a lista e nada mais', async () => {
    givenGeneratedDocuments([disponivel()])
    renderApp('/documentos')

    await screen.findByText('1 a 3 de setembro')
    expect(screen.queryByText('Documento gerado')).toBeNull()
    expect(screen.queryByText(/ficaram bloqueados/)).toBeNull()
  })
})
