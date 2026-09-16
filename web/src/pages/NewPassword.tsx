import { useEffect, useState } from 'react'
import { ArrowLeft } from 'lucide-react'
import { Link, useNavigate } from 'react-router'

import { AUTH_MESSAGES, MINIMUM_PASSWORD_LENGTH } from '@/auth/messages'
import { useAuth } from '@/auth/useAuth'
import { EntryScreen } from '@/components/entry-screen'
import { FormMessage } from '@/components/form-message'
import { LoadingScreen } from '@/components/loading-screen'
import { PasswordInput } from '@/components/password-input'
import { Button } from '@/components/ui/button'
import { Label } from '@/components/ui/label'
import { homePathFor, ROUTES } from '@/routes'

/*
 * Onde o link do e-mail aterrissa. O que transforma o link em sessão é o
 * `detectSessionInUrl` do cliente (src/lib/supabase.ts): quando esta tela
 * aparece, a pessoa já está autenticada pelo link — por isso não há campo de
 * senha antiga aqui, e por isso o link não pode ser tratado como coisa banal.
 * Ela só se abre para a aba que veio do link, e uma vez: trocada a senha, as
 * outras sessões caem e esta tela deixa de existir.
 *
 * São dois campos, e não um: um erro de digitação num campo escondido trancaria
 * a merendeira para fora do acesso que acabou de recuperar.
 */
export function NewPassword() {
  const { loading, session, profile, recovering, setNewPassword } = useAuth()
  const navigate = useNavigate()

  const [password, setPassword] = useState('')
  const [confirmation, setConfirmation] = useState('')
  const [error, setError] = useState<string | null>(null)
  const [submitting, setSubmitting] = useState(false)
  const [done, setDone] = useState(false)

  useEffect(() => {
    if (!done) return

    // A confirmação fica um instante na tela antes de entrar: a troca de senha
    // é a única coisa que acontece aqui, e ela precisa ser vista acontecendo.
    const timer = setTimeout(() => {
      navigate(profile ? homePathFor(profile.role) : ROUTES.cookHome, {
        replace: true,
      })
    }, 1500)

    return () => clearTimeout(timer)
  }, [done, navigate, profile])

  if (loading) return <LoadingScreen />

  /*
   * A confirmação vem antes da conferência abaixo de propósito: trocada a
   * senha, esta aba deixa de ser a aba do link no mesmo instante — e sem esta
   * ordem a tela piscaria "este link não vale mais" bem depois de ter valido.
   */
  if (done) {
    return (
      <EntryScreen>
        <div className="flex flex-col gap-3.5">
          <h1 className="text-xl font-semibold">Criar uma senha nova</h1>
          <FormMessage kind="success">
            {AUTH_MESSAGES.passwordChanged}
          </FormMessage>
        </div>
      </EntryScreen>
    )
  }

  /*
   * Estar logada não basta: esta tela pertence a quem acabou de abrir o link,
   * nesta aba. Sem isso, qualquer aba com a sessão aberta — inclusive a que só
   * pediu o e-mail — viraria uma tela de trocar senha, e a senha recém-criada
   * podia ser trocada de novo logo em seguida.
   */
  if (!session || !recovering) {
    return (
      <EntryScreen>
        <div className="flex flex-col gap-3.5">
          <h1 className="text-xl font-semibold">Criar uma senha nova</h1>
          <FormMessage>{AUTH_MESSAGES.resetLinkExpired}</FormMessage>
          <Button size="lg" asChild>
            <Link to={ROUTES.forgotPassword}>Pedir outro link</Link>
          </Button>
          <Button variant="link" size="default" asChild>
            <Link to={ROUTES.signIn}>
              <ArrowLeft aria-hidden="true" />
              Voltar para o login
            </Link>
          </Button>
        </div>
      </EntryScreen>
    )
  }

  async function handleSubmit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault()

    if (password.length < MINIMUM_PASSWORD_LENGTH) {
      setError(AUTH_MESSAGES.passwordTooShort)
      return
    }

    if (password !== confirmation) {
      setError(AUTH_MESSAGES.passwordMismatch)
      return
    }

    setError(null)
    setSubmitting(true)

    const result = await setNewPassword(password)

    setSubmitting(false)
    if (result.error) {
      setError(result.error)
      return
    }
    setDone(true)
  }

  return (
    <EntryScreen>
      <div className="flex flex-col gap-3.5">
        <div className="flex flex-col gap-1.5">
          <h1 className="text-xl font-semibold">Criar uma senha nova</h1>
          <p className="text-base text-muted-foreground">
            A senha nova vale a partir de agora, neste e nos outros aparelhos.
          </p>
        </div>

        <form
          className="flex flex-col gap-3.5"
          onSubmit={handleSubmit}
          noValidate
        >
          <div className="flex flex-col gap-2">
            <Label htmlFor="password">Senha nova</Label>
            <PasswordInput
              id="password"
              name="password"
              value={password}
              onChange={(event) => setPassword(event.target.value)}
              autoComplete="new-password"
              required
              aria-invalid={error !== null}
            />
            <span className="text-xs text-muted-foreground">
              Pelo menos {MINIMUM_PASSWORD_LENGTH} caracteres.
            </span>
          </div>

          <div className="flex flex-col gap-2">
            <Label htmlFor="confirmation">Repita a senha nova</Label>
            <PasswordInput
              id="confirmation"
              name="confirmation"
              value={confirmation}
              onChange={(event) => setConfirmation(event.target.value)}
              autoComplete="new-password"
              required
              aria-invalid={error !== null}
            />
          </div>

          {error ? <FormMessage>{error}</FormMessage> : null}

          <Button
            type="submit"
            size="lg"
            className="mt-1.5"
            disabled={submitting}
          >
            {submitting ? 'Salvando…' : 'Salvar a senha nova'}
          </Button>
        </form>
      </div>
    </EntryScreen>
  )
}
