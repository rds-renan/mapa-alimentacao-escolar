import { useRef, useState } from 'react'
import { ArrowLeft } from 'lucide-react'
import { Link } from 'react-router'

import { isCaptchaEnabled } from '@/auth/captcha'
import { AUTH_MESSAGES } from '@/auth/messages'
import { Turnstile } from '@/auth/turnstile'
import { useAuth } from '@/auth/useAuth'
import { EntryScreen } from '@/components/entry-screen'
import { FormMessage } from '@/components/form-message'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { isValidEmail } from '@/lib/email'
import { ROUTES } from '@/routes'

/*
 * Pedido de senha nova. Não veio das entrevistas nem do desenho da E3 como
 * tela — veio do link "Esqueci minha senha" que a tela 1 sempre teve e que
 * nenhuma história descrevia; a origem está registrada em
 * docs/05-web/autenticacao-e-sessao.md.
 *
 * A resposta é a mesma para e-mail conhecido e desconhecido, pelo mesmo motivo
 * do erro de login: dizer "este e-mail não tem acesso" entregaria quem tem.
 */
export function ForgotPassword() {
  const { requestPasswordReset } = useAuth()

  const [email, setEmail] = useState('')
  const [error, setError] = useState<string | null>(null)
  const [sent, setSent] = useState(false)
  const [submitting, setSubmitting] = useState(false)
  const [captchaToken, setCaptchaToken] = useState<string | null>(null)
  const [captchaRound, setCaptchaRound] = useState(0)
  const [emailInvalid, setEmailInvalid] = useState(false)
  const emailField = useRef<HTMLInputElement>(null)

  async function handleSubmit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault()

    if (!isValidEmail(email)) {
      setEmailInvalid(true)
      setError(null)
      emailField.current?.focus()
      return
    }

    setError(null)
    setSubmitting(true)

    const result = await requestPasswordReset(email, captchaToken)

    setSubmitting(false)
    setCaptchaToken(null)
    setCaptchaRound((round) => round + 1)

    if (result.error) {
      setError(result.error)
      return
    }
    setSent(true)
  }

  return (
    <EntryScreen>
      <div className="flex flex-col gap-3.5">
        <div className="flex flex-col gap-1.5">
          <h1 className="text-xl font-semibold">Esqueci minha senha</h1>
          <p className="text-base text-muted-foreground">
            Informe o e-mail do seu acesso. Enviamos um link para você criar uma
            senha nova.
          </p>
        </div>

        {sent ? (
          <FormMessage kind="success">
            {AUTH_MESSAGES.resetRequested}
          </FormMessage>
        ) : (
          <form
            className="flex flex-col gap-3.5"
            onSubmit={handleSubmit}
            noValidate
          >
            <div className="flex flex-col gap-2">
              <Label htmlFor="email">E-mail</Label>
              <Input
                id="email"
                type="email"
                name="email"
                ref={emailField}
                value={email}
                onChange={(event) => {
                  setEmail(event.target.value)
                  setEmailInvalid(false)
                  if (error) setError(null)
                }}
                onBlur={(event) => {
                  const escrito = event.target.value.trim()
                  if (escrito.length > 0 && !isValidEmail(escrito)) {
                    setEmailInvalid(true)
                    setError(null)
                  }
                }}
                autoComplete="username"
                inputMode="email"
                autoCapitalize="none"
                spellCheck={false}
                required
                aria-describedby={emailInvalid ? 'email-error' : undefined}
                aria-invalid={emailInvalid || error !== null}
              />
              {emailInvalid ? (
                <FormMessage id="email-error">
                  {AUTH_MESSAGES.emailInvalid}
                </FormMessage>
              ) : null}
            </div>

            {isCaptchaEnabled() ? (
              <Turnstile key={captchaRound} onToken={setCaptchaToken} />
            ) : null}

            {error ? <FormMessage>{error}</FormMessage> : null}

            <Button
              type="submit"
              size="lg"
              className="mt-1.5"
              disabled={submitting}
            >
              {submitting ? 'Enviando…' : 'Enviar o link'}
            </Button>
          </form>
        )}

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
