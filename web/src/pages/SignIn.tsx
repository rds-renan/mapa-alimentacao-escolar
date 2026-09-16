import { useEffect, useRef, useState } from 'react'
import { Lock } from 'lucide-react'
import { Link, Navigate, useLocation } from 'react-router'

import { isCaptchaEnabled } from '@/auth/captcha'
import { AUTH_MESSAGES, waitMessage } from '@/auth/messages'
import {
  clearAttempts,
  registerFailure,
  remainingWait,
} from '@/auth/sign-in-throttle'
import { Turnstile } from '@/auth/turnstile'
import { useAuth } from '@/auth/useAuth'
import { EntryScreen } from '@/components/entry-screen'
import { FormMessage } from '@/components/form-message'
import { LoadingScreen } from '@/components/loading-screen'
import { PasswordInput } from '@/components/password-input'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { isValidEmail } from '@/lib/email'
import { homePathFor, ROUTES } from '@/routes'

/*
 * Tela 1 da E3: a única porta de entrada. Não há autocadastro — o acesso é
 * criado pela direção (CA#3 da US016), e é isso que o rodapé explica para
 * quem chegar aqui sem conta e ficar procurando o botão de cadastrar.
 */

export function SignIn() {
  const { loading, session, profile, recovering, notice, signIn } = useAuth()
  const location = useLocation()

  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState<string | null>(null)
  // O formato do e-mail é problema do campo, e some do caminho do resto.
  const [emailInvalid, setEmailInvalid] = useState(false)
  const emailField = useRef<HTMLInputElement>(null)
  const [submitting, setSubmitting] = useState(false)
  const [waitLeft, setWaitLeft] = useState(() => remainingWait())
  const [captchaToken, setCaptchaToken] = useState<string | null>(null)
  // O código do desafio vale uma vez só: a cada recusa, o widget é remontado.
  const [captchaRound, setCaptchaRound] = useState(0)

  const waiting = waitLeft > 0

  useEffect(() => {
    if (!waiting) return

    // O tempo que falta é recontado do relógio, e não descontado de um número
    // guardado: assim recarregar a página não zera a espera.
    const timer = setInterval(() => setWaitLeft(remainingWait()), 1000)
    return () => clearInterval(timer)
  }, [waiting])

  if (recovering) return <Navigate to={ROUTES.newPassword} replace />

  if (loading && session) return <LoadingScreen />

  if (session && profile) {
    // De volta ao que ela tentou abrir antes de o login aparecer; na falta
    // disso, a casa do perfil dela.
    const from = (location.state as { from?: string } | null)?.from
    return <Navigate to={from ?? homePathFor(profile.role)} replace />
  }

  async function handleSubmit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault()

    if (!isValidEmail(email)) {
      /*
       * Trava aqui: já se sabe que não é e-mail, e mandar assim traria de
       * volta o erro de senha — que não é o problema, e ainda contaria como
       * tentativa errada no freio.
       */
      setEmailInvalid(true)
      setError(null)
      emailField.current?.focus()
      return
    }

    const stillWaiting = remainingWait()
    if (stillWaiting > 0) {
      setWaitLeft(stillWaiting)
      setError(waitMessage(stillWaiting))
      return
    }

    setError(null)
    setSubmitting(true)

    const result = await signIn(email, password, captchaToken)

    setSubmitting(false)
    setCaptchaToken(null)
    setCaptchaRound((round) => round + 1)

    if (!result.error) {
      clearAttempts()
      return
    }

    // Só erro de credencial conta para o freio. Falha de rede não é tentativa
    // de adivinhar senha, e trancar quem está sem sinal seria punir o lugar.
    if (result.error !== AUTH_MESSAGES.invalidCredentials) {
      setError(result.error)
      return
    }

    const wait = registerFailure()
    if (wait > 0) {
      setWaitLeft(wait)
      setError(waitMessage(wait))
      return
    }

    setError(result.error)
  }

  return (
    <EntryScreen
      footer={
        <p className="flex items-center justify-center gap-2 text-xs text-muted-foreground">
          <Lock className="size-3.5" aria-hidden="true" />O acesso é criado pela
          direção da escola
        </p>
      }
    >
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
              // Mexeu no e-mail: a marca sai, e a resposta do servidor sobre o
              // e-mail anterior também. Nunca há duas mensagens na tela.
              setEmailInvalid(false)
              setError(null)
            }}
            /*
             * Ao sair do campo, e não a cada tecla: ninguém quer ser corrigido
             * no meio da digitação de um e-mail que ainda não terminou.
             */
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

        <div className="flex flex-col gap-2">
          <Label htmlFor="password">Senha</Label>
          <PasswordInput
            id="password"
            name="password"
            value={password}
            onChange={(event) => setPassword(event.target.value)}
            autoComplete="current-password"
            required
            /*
             * O erro marca os dois campos: marcar só um diria qual dos dois
             * está certo.
             */
            aria-invalid={error !== null}
          />
        </div>

        {isCaptchaEnabled() ? (
          <Turnstile key={captchaRound} onToken={setCaptchaToken} />
        ) : null}

        {error ? <FormMessage>{error}</FormMessage> : null}
        {!error && notice ? <FormMessage>{notice}</FormMessage> : null}

        <Button
          type="submit"
          size="lg"
          className="mt-1.5"
          disabled={submitting || waiting}
        >
          {submitting ? 'Entrando…' : 'Entrar'}
        </Button>

        <Button variant="link" size="default" asChild>
          <Link to={ROUTES.forgotPassword}>Esqueci minha senha</Link>
        </Button>
      </form>
    </EntryScreen>
  )
}
