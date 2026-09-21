import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import { MemoryRouter } from 'react-router'
import { beforeEach, describe, expect, it, vi } from 'vitest'

import App from '@/App'
import { AuthProvider } from '@/auth/auth-provider'
import { SyncProvider } from '@/local/sync-provider'
import { ThemeProvider } from '@/theme/theme-provider'
import { dayKey, putStoredDay } from '@/local/store'
import { AUTH_MESSAGES } from '@/auth/messages'
import type { Profile } from '@/auth/auth-context'

vi.mock('@/lib/supabase', async () => await import('@/test/supabase-mock'))
vi.mock('@/lib/local-data', () => ({ clearLocalData: vi.fn(async () => {}) }))

/*
 * Se esta aba veio do link do e-mail. No navegador a resposta é o endereço que
 * abriu a aba; aqui é uma chave que cada teste liga quando precisa.
 */
const recoveryLink = vi.hoisted(() => ({ arrived: false }))
vi.mock('@/lib/recovery-link', () => ({
  cameFromRecoveryLink: () => recoveryLink.arrived,
  isRecoveryHash: (hash: string) => hash.includes('type=recovery'),
}))

import { clearLocalData } from '@/lib/local-data'
import {
  emitFromAnotherTab,
  givenAccount,
  givenProfileMissing,
  givenSignInFails,
  givenSignedIn,
  resetSupabaseMock,
  supabase,
} from '@/test/supabase-mock'

/*
 * Os critérios de aceite da issue #59, um a um. O que se verifica aqui é a
 * conveniência de interface — a tela certa para o perfil certo. O controle de
 * acesso de verdade é o RLS da E4, e quem o verifica são os testes de banco em
 * supabase/tests/.
 */

const cook: Profile = {
  id: '22222222-2222-4222-8222-222222222222',
  name: 'Merendeira 1',
  email: 'merendeira1@dominio.com.br',
  role: 'cook',
  school_id: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
}

const admin: Profile = {
  id: '11111111-1111-4111-8111-111111111111',
  name: 'Direção',
  email: 'direcao@dominio.com.br',
  role: 'admin',
  school_id: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
}

function renderApp(path = '/') {
  return render(
    <ThemeProvider>
      <MemoryRouter initialEntries={[path]}>
        {/* A visão do mês lê o mês do servidor: sem o cliente da Query ela nem
            chega a montar. O que estes testes verificam continua sendo a
            sessão — o mês é só o destino de quem entra. */}
        <QueryClientProvider client={new QueryClient()}>
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

/*
 * A tela-casa da merendeira, pelo que ela tem de próprio: o segundo dos dois
 * caminhos da visão do mês. O título da tela é o mês, e o mês muda com a data
 * em que o teste roda.
 */
const COOK_HOME = 'Gerar documento'

/**
 * Sair mora dentro do menu desde a issue #61 — é o lugar que a decisão 9 da E3
 * lhe deu. Chegar lá custa um toque a mais, e é este.
 */
async function openMenu() {
  fireEvent.click(await screen.findByRole('button', { name: 'Abrir o menu' }))
}

async function fillSignIn(email: string, password: string) {
  fireEvent.change(await screen.findByLabelText('E-mail'), {
    target: { value: email },
  })
  fireEvent.change(screen.getByLabelText('Senha'), {
    target: { value: password },
  })
  fireEvent.click(screen.getByRole('button', { name: 'Entrar' }))
}

beforeEach(() => {
  resetSupabaseMock()
  localStorage.clear()
  recoveryLink.arrived = false
})

describe('login', () => {
  it('é a única porta de entrada: sem sessão, qualquer endereço leva a ele', async () => {
    renderApp('/')

    expect(await screen.findByRole('button', { name: 'Entrar' })).toBeVisible()
    expect(screen.getByText(/O acesso é criado pela direção/)).toBeVisible()
    // Não há autocadastro (CA#3 da US016).
    expect(screen.queryByText(/criar conta/i)).not.toBeInTheDocument()
    expect(screen.queryByText(/cadastr/i)).not.toBeInTheDocument()
  })

  it('não revela qual dos dois campos errou', async () => {
    givenSignInFails({
      code: 'invalid_credentials',
      message: 'Invalid login credentials',
    })
    renderApp('/')

    await fillSignIn('merendeira1@dominio.com.br', 'senha-errada')

    const alerta = await screen.findByRole('alert')
    expect(alerta).toHaveTextContent(AUTH_MESSAGES.invalidCredentials)
    // Os dois campos marcados: marcar só um diria qual é o errado.
    expect(screen.getByLabelText('E-mail')).toHaveAttribute(
      'aria-invalid',
      'true'
    )
    expect(screen.getByLabelText('Senha')).toHaveAttribute(
      'aria-invalid',
      'true'
    )
  })

  it('marca o campo de e-mail e não deixa enviar o que não é e-mail', async () => {
    givenAccount(cook)
    renderApp('/')

    const campo = await screen.findByLabelText('E-mail')
    fireEvent.change(campo, { target: { value: 'teste' } })
    fireEvent.blur(campo)

    expect(await screen.findByRole('alert')).toHaveTextContent(
      AUTH_MESSAGES.emailInvalid
    )
    expect(campo).toHaveAttribute('aria-invalid', 'true')
    // O erro é do e-mail, e só ele é marcado: nenhum servidor foi consultado.
    expect(screen.getByLabelText('Senha')).toHaveAttribute(
      'aria-invalid',
      'false'
    )

    fireEvent.change(screen.getByLabelText('Senha'), {
      target: { value: 'mae-desenvolvimento' },
    })
    fireEvent.click(screen.getByRole('button', { name: 'Entrar' }))
    expect(supabase.auth.signInWithPassword).not.toHaveBeenCalled()
    // O foco volta para o campo que precisa de conserto.
    expect(campo).toHaveFocus()

    fireEvent.change(campo, { target: { value: 'merendeira1@dominio.com.br' } })
    expect(screen.queryByRole('alert')).not.toBeInTheDocument()
    expect(campo).toHaveAttribute('aria-invalid', 'false')
  })

  it('nunca mostra duas mensagens ao mesmo tempo', async () => {
    givenSignInFails({
      code: 'invalid_credentials',
      message: 'Invalid login credentials',
    })
    renderApp('/')

    await fillSignIn('merendeira1@dominio.com.br', 'senha-errada')
    expect(await screen.findByRole('alert')).toHaveTextContent(
      AUTH_MESSAGES.invalidCredentials
    )

    // Trocar o e-mail por um torto troca a mensagem, não acumula outra.
    const campo = screen.getByLabelText('E-mail')
    fireEvent.change(campo, { target: { value: 'teste' } })
    fireEvent.blur(campo)

    const mensagens = screen.getAllByRole('alert')
    expect(mensagens).toHaveLength(1)
    expect(mensagens[0]).toHaveTextContent(AUTH_MESSAGES.emailInvalid)
  })

  it('mostra e esconde a senha pelo olho', async () => {
    renderApp('/')

    const senha = await screen.findByLabelText('Senha')
    expect(senha).toHaveAttribute('type', 'password')

    fireEvent.click(screen.getByRole('button', { name: 'Mostrar senha' }))
    expect(senha).toHaveAttribute('type', 'text')

    fireEvent.click(screen.getByRole('button', { name: 'Ocultar senha' }))
    expect(senha).toHaveAttribute('type', 'password')
  })

  it('para de aceitar tentativa depois de muitos erros seguidos', async () => {
    givenSignInFails({
      code: 'invalid_credentials',
      message: 'Invalid login credentials',
    })
    // Quatro erros já aconteceram; o quinto é o que aciona a espera.
    localStorage.setItem(
      'mae.sign-in-attempts',
      JSON.stringify({ failures: 4, blockedUntil: 0 })
    )
    renderApp('/')

    await fillSignIn('merendeira1@dominio.com.br', 'senha-errada')

    expect(await screen.findByRole('alert')).toHaveTextContent(
      /Foram muitas tentativas seguidas/
    )
    expect(screen.getByRole('button', { name: 'Entrar' })).toBeDisabled()
  })

  it('leva a merendeira ao fluxo do mapa', async () => {
    givenAccount(cook)
    renderApp('/')

    await fillSignIn(cook.email, 'mae-desenvolvimento')

    expect(await screen.findByText(COOK_HOME)).toBeVisible()
  })
})

describe('sessão', () => {
  it('persiste: com sessão guardada, o aplicativo abre sem pedir senha', async () => {
    givenSignedIn(cook)
    renderApp('/')

    expect(await screen.findByText(COOK_HOME)).toBeVisible()
    expect(supabase.auth.signInWithPassword).not.toHaveBeenCalled()
  })

  it('encerra ao sair, e leva junto o que era local', async () => {
    givenSignedIn(cook)
    renderApp('/')

    await openMenu()
    fireEvent.click(await screen.findByRole('button', { name: /^Sair$/ }))

    expect(await screen.findByRole('button', { name: 'Entrar' })).toBeVisible()
    await waitFor(() => {
      expect(supabase.auth.signOut).toHaveBeenCalled()
      expect(clearLocalData).toHaveBeenCalled()
    })
  })

  it('avisa antes de sair quando ainda há mapa por enviar', async () => {
    /*
     * Sair apaga o que está guardado no aparelho, inclusive o que não subiu.
     * O que torna isso legítimo é ela saber antes e decidir: perder por escolha
     * dela é uma coisa, perder por decisão do sistema seria outra.
     */
    await putStoredDay({
      key: dayKey(cook.id, '2026-09-10'),
      userId: cook.id,
      mapDate: '2026-09-10',
      day: {
        id: 'a0000000-0000-4000-8000-000000000001',
        map_date: '2026-09-10',
        updated_at: '2026-09-10T18:30:00-03:00',
        non_school_day: false,
        note: null,
        meals_served: 312,
        meals: [],
      },
      attempts: 0,
      rejection: null,
      queuedAt: '2026-09-10T18:30:00-03:00',
    })

    givenSignedIn(cook)
    renderApp('/')

    await openMenu()
    fireEvent.click(await screen.findByRole('button', { name: /^Sair$/ }))

    const aviso = await screen.findByRole('alertdialog')
    expect(aviso).toHaveTextContent(
      'Ainda tem 1 dia salvo neste computador que não foi enviado.'
    )
    // Só o aviso: nada foi apagado nem a sessão encerrada ainda.
    expect(supabase.auth.signOut).not.toHaveBeenCalled()
    expect(clearLocalData).not.toHaveBeenCalled()

    fireEvent.click(screen.getByRole('button', { name: 'Sair e apagar' }))

    await waitFor(() => {
      expect(supabase.auth.signOut).toHaveBeenCalled()
      expect(clearLocalData).toHaveBeenCalled()
    })
  })

  it('deixa ficar quem mudou de ideia diante do aviso', async () => {
    await putStoredDay({
      key: dayKey(cook.id, '2026-09-10'),
      userId: cook.id,
      mapDate: '2026-09-10',
      day: {
        id: 'a0000000-0000-4000-8000-000000000001',
        map_date: '2026-09-10',
        updated_at: '2026-09-10T18:30:00-03:00',
        non_school_day: false,
        note: null,
        meals_served: 312,
        meals: [],
      },
      attempts: 0,
      rejection: null,
      queuedAt: '2026-09-10T18:30:00-03:00',
    })

    givenSignedIn(cook)
    renderApp('/')

    await openMenu()
    fireEvent.click(await screen.findByRole('button', { name: /^Sair$/ }))
    fireEvent.click(await screen.findByRole('button', { name: 'Ficar' }))

    await waitFor(() => {
      expect(screen.queryByRole('alertdialog')).toBeNull()
    })
    expect(supabase.auth.signOut).not.toHaveBeenCalled()
    expect(clearLocalData).not.toHaveBeenCalled()
  })

  it('não segura quem teve o acesso desativado pela direção', async () => {
    givenProfileMissing(cook)
    renderApp('/')

    expect(await screen.findByRole('alert')).toHaveTextContent(
      AUTH_MESSAGES.accessDisabled
    )
    expect(supabase.auth.signOut).toHaveBeenCalled()
  })
})

describe('rotas por perfil', () => {
  it('não deixa a merendeira na administração', async () => {
    givenSignedIn(cook)
    renderApp('/admin')

    expect(await screen.findByText(COOK_HOME)).toBeVisible()
    expect(
      screen.queryByRole('heading', { name: 'Painel' })
    ).not.toBeInTheDocument()
  })

  it('não deixa a direção no fluxo do mapa', async () => {
    givenSignedIn(admin)
    renderApp('/')

    // Pelo cabeçalho, e não pelo texto: "Painel" também é um destino da barra
    // lateral da direção, que a issue #68 montou.
    expect(await screen.findByRole('heading', { name: 'Painel' })).toBeVisible()
    expect(screen.queryByText(COOK_HOME)).not.toBeInTheDocument()
  })

  it('manda endereço desconhecido para a casa do perfil', async () => {
    givenSignedIn(admin)
    renderApp('/um-endereco-que-nao-existe')

    expect(await screen.findByRole('heading', { name: 'Painel' })).toBeVisible()
  })
})

describe('senha esquecida', () => {
  it('responde igual para e-mail conhecido e desconhecido', async () => {
    renderApp('/esqueci-a-senha')

    fireEvent.change(await screen.findByLabelText('E-mail'), {
      target: { value: 'nao-existe@dominio.com.br' },
    })
    fireEvent.click(screen.getByRole('button', { name: 'Enviar o link' }))

    expect(await screen.findByRole('alert')).toHaveTextContent(
      AUTH_MESSAGES.resetRequested
    )
    expect(supabase.auth.resetPasswordForEmail).toHaveBeenCalledWith(
      'nao-existe@dominio.com.br',
      expect.objectContaining({
        redirectTo: expect.stringContaining('/nova-senha'),
      })
    )
  })

  it('recusa o link que já não vale', async () => {
    recoveryLink.arrived = true
    renderApp('/nova-senha')

    expect(await screen.findByRole('alert')).toHaveTextContent(
      AUTH_MESSAGES.resetLinkExpired
    )
  })

  it('recusa senha curta demais sem ir ao servidor', async () => {
    recoveryLink.arrived = true
    givenSignedIn(cook)
    renderApp('/nova-senha')

    fireEvent.change(await screen.findByLabelText('Senha nova'), {
      target: { value: 'curta' },
    })
    fireEvent.change(screen.getByLabelText('Repita a senha nova'), {
      target: { value: 'curta' },
    })
    fireEvent.click(screen.getByRole('button', { name: 'Salvar a senha nova' }))

    expect(await screen.findByRole('alert')).toHaveTextContent(
      AUTH_MESSAGES.passwordTooShort
    )
    expect(supabase.auth.updateUser).not.toHaveBeenCalled()
  })

  it('não troca a senha quando as duas digitadas diferem', async () => {
    recoveryLink.arrived = true
    givenSignedIn(cook)
    renderApp('/nova-senha')

    fireEvent.change(await screen.findByLabelText('Senha nova'), {
      target: { value: 'senha-nova' },
    })
    fireEvent.change(screen.getByLabelText('Repita a senha nova'), {
      target: { value: 'senha-nvoa' },
    })
    fireEvent.click(screen.getByRole('button', { name: 'Salvar a senha nova' }))

    expect(await screen.findByRole('alert')).toHaveTextContent(
      AUTH_MESSAGES.passwordMismatch
    )
    expect(supabase.auth.updateUser).not.toHaveBeenCalled()
  })

  it('troca a senha e confirma na tela', async () => {
    recoveryLink.arrived = true
    givenSignedIn(cook)
    renderApp('/nova-senha')

    fireEvent.change(await screen.findByLabelText('Senha nova'), {
      target: { value: 'senha-nova' },
    })
    fireEvent.change(screen.getByLabelText('Repita a senha nova'), {
      target: { value: 'senha-nova' },
    })
    fireEvent.click(screen.getByRole('button', { name: 'Salvar a senha nova' }))

    expect(await screen.findByRole('alert')).toHaveTextContent(
      AUTH_MESSAGES.passwordChanged
    )
    expect(supabase.auth.updateUser).toHaveBeenCalledWith({
      password: 'senha-nova',
    })
    // E as outras sessões caem junto: a senha antiga não abre mais nada.
    expect(supabase.auth.signOut).toHaveBeenCalledWith({ scope: 'others' })
  })
})

/*
 * A sessão do Supabase é compartilhada por todas as abas do navegador, e o
 * aviso de recuperação viaja com ela. Estes dois casos são o bug que apareceu
 * em uso: a aba onde a pessoa pediu a senha nova virava uma segunda tela de
 * trocar senha, e aceitava trocar de novo a senha recém-criada.
 */
describe('a aba que não veio do link', () => {
  it('não vira uma segunda tela de trocar senha', async () => {
    givenSignedIn(cook)
    renderApp('/')
    expect(await screen.findByText(COOK_HOME)).toBeVisible()

    emitFromAnotherTab('PASSWORD_RECOVERY')

    expect(await screen.findByText(COOK_HOME)).toBeVisible()
    expect(screen.queryByLabelText('Senha nova')).not.toBeInTheDocument()
  })

  it('não deixa trocar a senha nem estando logada', async () => {
    givenSignedIn(cook)
    renderApp('/nova-senha')

    expect(await screen.findByRole('alert')).toHaveTextContent(
      AUTH_MESSAGES.resetLinkExpired
    )
    expect(screen.queryByLabelText('Senha nova')).not.toBeInTheDocument()
    expect(supabase.auth.updateUser).not.toHaveBeenCalled()
  })
})
