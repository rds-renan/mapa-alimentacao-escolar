import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { fireEvent, render, screen, waitFor } from '@testing-library/react'
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
  createdAccesses,
  givenCooks,
  givenCooksFail,
  givenCookWriteFails,
  givenCreateAccessFails,
  givenCurrentTemplate,
  givenPasswordEmailFails,
  givenSchool,
  givenSignedIn,
  givenTemplateRegisterFails,
  givenTemplateUploadFails,
  passwordEmails,
  removals,
  resetSupabaseMock,
  storedCooks,
  storedSchool,
  storedTemplate,
  uploads,
  type CookRow,
} from '@/test/supabase-mock'

/*
 * Os critérios de aceite da issue #68, um a um.
 *
 * A pergunta desta tela é a do papel da direção: ela cuida do que sustenta o
 * trabalho das merendeiras — quem entra, com qual modelo o documento sai e o
 * que vai no cabeçalho dele — **sem nunca entrar no fluxo do mapa**. Cada
 * bloco abaixo é um dos critérios, e o último é o que a tela não faz.
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

const COOKS: CookRow[] = [
  {
    id: '22222222-2222-4222-8222-222222222222',
    name: 'Merendeira 1',
    email: 'merendeira1@dominio.com.br',
    active: true,
    last_access: new Date().toISOString(),
  },
  {
    id: '33333333-3333-4333-8333-333333333333',
    name: 'Merendeira 2',
    email: 'merendeira2@dominio.com.br',
    active: false,
    last_access: null,
  },
]

const TEMPLATE = {
  id: 'd0000001-0000-4000-8000-000000000001',
  file_name: 'modelo-oficial.docx',
  file_path: `${SCHOOL}/modelo-oficial.docx`,
  uploaded_at: '2026-08-20T12:00:00.000Z',
}

const SCHOOL_ROW = {
  id: SCHOOL,
  name: 'Escola Municipal Exemplo',
  city: 'Município Exemplo',
  school_year: 2026,
}

function renderManagement(at = '/admin/gestao') {
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

/** A lista chegou: até aí o cabeçalho já está na tela e não prova nada. */
function cooksLoaded() {
  return screen.findByText('merendeira1@dominio.com.br')
}

function click(name: string | RegExp) {
  fireEvent.click(screen.getByRole('button', { name }))
}

function type(label: string, value: string) {
  fireEvent.change(screen.getByLabelText(label), { target: { value } })
}

/** Um .docx de mentira, que é o que o campo de arquivo entrega. */
function docx(name = 'modelo-novo.docx', bytes = 10) {
  return new File([new Uint8Array(bytes)], name, {
    type: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  })
}

function chooseFile(file: File) {
  const input = document.querySelector<HTMLInputElement>('input[type="file"]')
  if (!input) throw new Error('o campo de arquivo não está na tela')

  Object.defineProperty(input, 'files', { value: [file], configurable: true })
  fireEvent.change(input)
}

beforeEach(() => {
  givenSignedIn(admin)
  givenCooks(COOKS.map((row) => ({ ...row })))
  givenSchool({ ...SCHOOL_ROW })
  givenCurrentTemplate({ ...TEMPLATE })
})

afterEach(() => resetSupabaseMock())

describe('acessos das merendeiras', () => {
  it('lista quem tem acesso, com a situação de cada uma', async () => {
    renderManagement()
    await cooksLoaded()

    expect(screen.getByText('Ativa')).toBeVisible()
    expect(screen.getByText('Sem acesso')).toBeVisible()
    expect(screen.getByText('Nunca entrou')).toBeVisible()
  })

  it('cadastra merendeira e manda o e-mail de criar senha', async () => {
    renderManagement()
    await cooksLoaded()

    click('Cadastrar merendeira')
    type('Nome', 'Merendeira 3')
    type('E-mail', 'merendeira3@dominio.com.br')
    click('Cadastrar e enviar o convite')

    await waitFor(() => expect(createdAccesses()).toHaveLength(1))
    expect(createdAccesses()[0]).toEqual({
      name: 'Merendeira 3',
      email: 'merendeira3@dominio.com.br',
    })

    /*
     * O e-mail é o que faz a senha existir: a Edge Function cria a conta com
     * uma senha descartável que ninguém vê, e a direção nunca define senha
     * de ninguém.
     */
    expect(passwordEmails()).toEqual(['merendeira3@dominio.com.br'])
    expect(
      await screen.findByText(/O e-mail para criar a senha foi enviado/)
    ).toBeVisible()
  })

  it('diz para reenviar quando o e-mail não sai, e o acesso fica de pé', async () => {
    givenPasswordEmailFails()
    renderManagement()
    await cooksLoaded()

    click('Cadastrar merendeira')
    type('Nome', 'Merendeira 3')
    type('E-mail', 'merendeira3@dominio.com.br')
    click('Cadastrar e enviar o convite')

    expect(
      await screen.findByText(/o e-mail para criar a senha não saiu/)
    ).toBeVisible()
    expect(storedCooks()).toHaveLength(3)
  })

  it('mostra a recusa da Edge Function com a frase que ela escreveu', async () => {
    givenCreateAccessFails(
      'Este e-mail já tem um acesso desativado nesta escola.',
      409,
      'Reative o acesso na lista, em vez de cadastrar de novo.'
    )
    renderManagement()
    await cooksLoaded()

    click('Cadastrar merendeira')
    type('Nome', 'Merendeira 2')
    type('E-mail', 'merendeira2@dominio.com.br')
    click('Cadastrar e enviar o convite')

    expect(await screen.findByText(/Reative o acesso na lista/)).toBeVisible()
    // Nada de e-mail: não houve acesso criado a quem convidar.
    expect(passwordEmails()).toEqual([])
  })

  it('desativa o acesso sem apagar a pessoa', async () => {
    renderManagement()
    await cooksLoaded()

    click('Desativar o acesso de Merendeira 1')

    expect(
      await screen.findByText(/Merendeira 1 não entra mais no aplicativo/)
    ).toBeVisible()
    // A linha continua lá, desativada: é ela que sustenta a autoria dos
    // mapas, documentos e desbloqueios que a merendeira deixou.
    expect(storedCooks()).toHaveLength(2)
    expect(storedCooks()[0].active).toBe(false)
  })

  it('reativa o acesso de quem estava sem', async () => {
    renderManagement()
    await cooksLoaded()

    click('Reativar o acesso de Merendeira 2')

    expect(
      await screen.findByText('Merendeira 2 voltou a ter acesso.')
    ).toBeVisible()
    expect(storedCooks()[1].active).toBe(true)
  })

  it('reenvia o e-mail de senha para quem já tem acesso', async () => {
    renderManagement()
    await cooksLoaded()

    click('Enviar e-mail de senha nova para Merendeira 1')

    await waitFor(() =>
      expect(passwordEmails()).toEqual(['merendeira1@dominio.com.br'])
    )
  })

  it('não oferece senha nova a quem está sem acesso', async () => {
    renderManagement()
    await cooksLoaded()

    expect(
      screen.queryByRole('button', {
        name: 'Enviar e-mail de senha nova para Merendeira 2',
      })
    ).not.toBeInTheDocument()
  })

  it('avisa quando a escrita não passa, sem inventar que passou', async () => {
    givenCookWriteFails()
    renderManagement()
    await cooksLoaded()

    click('Desativar o acesso de Merendeira 1')

    expect(
      await screen.findByText(/Não deu para mudar o acesso agora/)
    ).toBeVisible()
    expect(storedCooks()[0].active).toBe(true)
  })

  it('oferece tentar de novo quando a lista não vem', async () => {
    givenCooksFail()
    renderManagement()

    expect(
      await screen.findByText(/Não deu para carregar a lista/)
    ).toBeVisible()
  })
})

describe('modelo oficial', () => {
  it('mostra o modelo vigente e avisa que ele é privado', async () => {
    renderManagement()

    expect(await screen.findByText('modelo-oficial.docx')).toBeVisible()
    expect(screen.getByText(/não aparece para as merendeiras/)).toBeVisible()
  })

  it('envia a versão nova para a pasta da escola e a torna vigente', async () => {
    renderManagement()
    await screen.findByText('modelo-oficial.docx')

    chooseFile(docx())

    expect(
      await screen.findByText(/O modelo novo passou a valer/)
    ).toBeVisible()

    expect(uploads()).toHaveLength(1)
    expect(uploads()[0].bucket).toBe('document-templates')
    // Cada versão é um arquivo próprio: sobrescrever um `modelo.docx` só
    // deixaria a tabela apontando para o arquivo errado (decisão 11 da E4).
    expect(uploads()[0].path.startsWith(`${SCHOOL}/`)).toBe(true)
    expect(uploads()[0].path).not.toBe(TEMPLATE.file_path)

    expect(storedTemplate()?.file_name).toBe('modelo-novo.docx')
  })

  it('recusa arquivo que não é .docx sem chegar ao balde', async () => {
    renderManagement()
    await screen.findByText('modelo-oficial.docx')

    chooseFile(
      new File([new Uint8Array(4)], 'modelo.pdf', {
        type: 'application/pdf',
      })
    )

    expect(await screen.findByText(/tem de ser um arquivo .docx/)).toBeVisible()
    expect(uploads()).toEqual([])
  })

  it('apaga o arquivo que subiu quando o registro não passa', async () => {
    givenTemplateRegisterFails()
    renderManagement()
    await screen.findByText('modelo-oficial.docx')

    chooseFile(docx())

    expect(await screen.findByText(/continua valendo/)).toBeVisible()
    await waitFor(() => expect(removals()).toHaveLength(1))
    expect(removals()[0]).toBe(uploads()[0].path)
  })

  it('não troca nada quando o arquivo não sobe', async () => {
    givenTemplateUploadFails()
    renderManagement()
    await screen.findByText('modelo-oficial.docx')

    chooseFile(docx())

    expect(await screen.findByText(/continua valendo/)).toBeVisible()
    expect(storedTemplate()?.file_name).toBe('modelo-oficial.docx')
  })

  it('avisa quando a escola ainda não tem modelo', async () => {
    givenCurrentTemplate(null)
    renderManagement()

    expect(
      await screen.findByText(/ainda não tem um modelo oficial/)
    ).toBeVisible()
  })
})

describe('dados da escola', () => {
  it('edita o nome e o que mais entra no cabeçalho do documento', async () => {
    renderManagement()
    await screen.findByDisplayValue('Escola Municipal Exemplo')

    type('Nome da escola', 'Escola Municipal Nova')
    click('Salvar alterações')

    expect(
      await screen.findByText(/Os dados da escola foram salvos/)
    ).toBeVisible()
    expect(storedSchool()?.name).toBe('Escola Municipal Nova')
  })

  it('não deixa salvar com o nome em branco', async () => {
    renderManagement()
    await screen.findByDisplayValue('Escola Municipal Exemplo')

    type('Nome da escola', '   ')

    expect(screen.getByText(/Preencha o nome, o município/)).toBeVisible()
    expect(
      screen.getByRole('button', { name: 'Salvar alterações' })
    ).toBeDisabled()
  })
})

describe('a direção fora do fluxo do mapa', () => {
  it('não oferece caminho nenhum para registrar mapa', async () => {
    renderManagement()
    await cooksLoaded()

    /*
     * A navegação da direção tem três destinos, e nenhum deles registra mapa.
     * "Mapas" é o da issue #69: ele reabre um dia bloqueado, e quem corrige
     * continua sendo a merendeira.
     */
    expect(
      screen.queryByRole('link', { name: /Documentos gerados/ })
    ).not.toBeInTheDocument()
    expect(
      screen.queryByRole('link', { name: /Gerenciar gêneros/ })
    ).not.toBeInTheDocument()
    expect(screen.getAllByRole('link').map((link) => link.textContent)).toEqual(
      ['Painel', 'Gestão', 'Mapas']
    )
  })

  it('devolve a merendeira para a casa dela se ela tentar a gestão', async () => {
    resetSupabaseMock()
    givenSignedIn(cook)
    renderManagement()

    // A visão do mês, que é a casa dela — a guarda de rota a trouxe de volta.
    expect(await screen.findByText('Gerar documento')).toBeVisible()
    expect(screen.queryByText('Merendeiras')).not.toBeInTheDocument()
  })
})

describe('o tema na barra da direção (US024)', () => {
  it('deixa a direção escolher o tema no pé da barra lateral', async () => {
    // Aparelho sem preferência guardada, que é onde a escolha começa.
    localStorage.removeItem('mae.theme')
    document.documentElement.classList.remove('dark')

    renderManagement()
    await cooksLoaded()

    /*
     * A direção não tem menu — os dois fluxos são separados (RN#1 da US020) —,
     * então a barra lateral é o canto onde a escolha cabe.
     */
    expect(screen.getByRole('radio', { name: 'Sistema' })).toBeChecked()

    fireEvent.click(screen.getByRole('radio', { name: 'Escuro' }))

    expect(document.documentElement.classList.contains('dark')).toBe(true)
    expect(localStorage.getItem('mae.theme')).toBe('dark')
  })
})
