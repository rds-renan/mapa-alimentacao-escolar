import { useState } from 'react'
import { CircleAlert, LoaderCircle, Plus } from 'lucide-react'

import { FormMessage } from '@/components/form-message'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'

import {
  COOKS_MESSAGES,
  deactivateLabel,
  deactivatedLabel,
  inviteFailedLabel,
  inviteSentLabel,
  reactivateLabel,
  reactivatedLabel,
  lastAccessLabel,
  resetPasswordLabel,
  resetSentLabel,
} from './messages'
import { useCookMutations, useCooks, type CookAccess } from './queries'

/*
 * Quem pode registrar o mapa da escola (US016).
 *
 * As duas coisas que esta lista faz são de naturezas diferentes e é bom não
 * confundi-las: **cadastrar** cria uma conta onde não havia nada, e é a única
 * porta de entrada do sistema — não existe autocadastro (CA#3 da US016);
 * **desativar** tira o acesso e não tira a pessoa, porque a autoria dos mapas,
 * documentos e desbloqueios que ela deixou é parte da auditoria (decisão 2 da
 * E4).
 *
 * Nenhuma das duas pede confirmação, pela mesma razão do catálogo de gêneros:
 * as duas têm volta na própria linha, e confirmar tudo é o caminho para as
 * confirmações deixarem de ser lidas (decisão 11 da E3).
 */
export function CooksCard() {
  const cooks = useCooks()
  const { create, toggle, resetPassword } = useCookMutations()

  const [adding, setAdding] = useState(false)
  const [name, setName] = useState('')
  const [email, setEmail] = useState('')
  /** O que acabou de acontecer, dito no lugar onde aconteceu. */
  const [done, setDone] = useState<string | null>(null)

  const busy = create.isPending

  function openForm() {
    setAdding(true)
    setDone(null)
    create.reset()
  }

  function closeForm() {
    setAdding(false)
    setName('')
    setEmail('')
    create.reset()
  }

  function submit(event: React.FormEvent) {
    event.preventDefault()
    if (busy) return

    create.mutate(
      { name, email },
      {
        onSuccess: ({ cook, invited }) => {
          closeForm()
          setDone(
            invited
              ? inviteSentLabel(cook.name, cook.email)
              : inviteFailedLabel(cook.name)
          )
        },
      }
    )
  }

  function setActive(cook: CookAccess, active: boolean) {
    setDone(null)
    toggle.mutate(
      { id: cook.id, active },
      {
        onSuccess: () =>
          setDone(
            active ? reactivatedLabel(cook.name) : deactivatedLabel(cook.name)
          ),
      }
    )
  }

  function sendNewPassword(cook: CookAccess) {
    setDone(null)
    resetPassword.mutate(
      { email: cook.email, name: cook.name },
      { onSuccess: () => setDone(resetSentLabel(cook.name, cook.email)) }
    )
  }

  return (
    <section
      aria-labelledby="cooks-title"
      className="flex flex-col overflow-hidden rounded-xl border border-border bg-card"
    >
      <div className="flex flex-wrap items-center gap-3 border-b border-muted px-4 py-3.5">
        <hgroup className="flex min-w-0 flex-1 flex-col gap-0.5">
          <h2 id="cooks-title" className="text-base font-semibold">
            {COOKS_MESSAGES.title}
          </h2>
          <p className="text-xs text-muted-foreground">
            {COOKS_MESSAGES.subtitle}
          </p>
        </hgroup>

        {adding ? null : (
          <Button onClick={openForm}>
            <Plus aria-hidden="true" />
            {COOKS_MESSAGES.newTitle}
          </Button>
        )}
      </div>

      {adding ? (
        <form
          onSubmit={submit}
          aria-label={COOKS_MESSAGES.newTitle}
          className="flex flex-col gap-3 border-b border-muted bg-muted/40 px-4 py-4"
        >
          <p className="text-xs text-muted-foreground">
            {COOKS_MESSAGES.newSubtitle}
          </p>

          <div className="grid gap-3 sm:grid-cols-2">
            <div className="flex flex-col gap-1.5">
              <Label htmlFor="cook-name">{COOKS_MESSAGES.nameLabel}</Label>
              <Input
                id="cook-name"
                autoFocus
                value={name}
                placeholder={COOKS_MESSAGES.namePlaceholder}
                onChange={(event) => setName(event.target.value)}
              />
            </div>

            <div className="flex flex-col gap-1.5">
              <Label htmlFor="cook-email">{COOKS_MESSAGES.emailLabel}</Label>
              <Input
                id="cook-email"
                type="email"
                inputMode="email"
                autoComplete="off"
                value={email}
                placeholder={COOKS_MESSAGES.emailPlaceholder}
                onChange={(event) => setEmail(event.target.value)}
              />
            </div>
          </div>

          {create.isError ? (
            <FormMessage>{create.error.message}</FormMessage>
          ) : null}

          <div className="flex flex-wrap gap-2">
            <Button type="submit" disabled={busy || !filled(name, email)}>
              {busy ? (
                <LoaderCircle className="animate-spin" aria-hidden="true" />
              ) : null}
              {busy ? COOKS_MESSAGES.creating : COOKS_MESSAGES.create}
            </Button>
            <Button
              type="button"
              variant="ghost"
              disabled={busy}
              onClick={closeForm}
            >
              {COOKS_MESSAGES.cancel}
            </Button>
          </div>
        </form>
      ) : null}

      {done ? (
        <div className="border-b border-muted px-4 py-3">
          <FormMessage kind="success">{done}</FormMessage>
        </div>
      ) : null}

      {toggle.isError || resetPassword.isError ? (
        <div className="border-b border-muted px-4 py-3">
          <FormMessage>
            {toggle.isError
              ? COOKS_MESSAGES.updateFailed
              : COOKS_MESSAGES.resetFailed}
          </FormMessage>
        </div>
      ) : null}

      {cooks.isPending ? (
        <p
          role="status"
          className="flex items-center gap-2 px-4 py-6 text-sm text-muted-foreground"
        >
          <LoaderCircle className="size-4 animate-spin" aria-hidden="true" />
          {COOKS_MESSAGES.loading}
        </p>
      ) : cooks.isError ? (
        <div role="alert" className="flex flex-col gap-3 px-4 py-6">
          <p className="flex items-start gap-2 text-sm text-muted-foreground">
            <CircleAlert
              className="mt-0.5 size-4 shrink-0"
              aria-hidden="true"
            />
            {COOKS_MESSAGES.loadFailed}
          </p>
          <Button
            variant="outline"
            className="self-start"
            onClick={() => void cooks.refetch()}
          >
            {COOKS_MESSAGES.retry}
          </Button>
        </div>
      ) : cooks.data.length === 0 ? (
        <p className="px-4 py-6 text-sm text-muted-foreground">
          {COOKS_MESSAGES.empty}
        </p>
      ) : (
        <ul className="flex flex-col">
          {cooks.data.map((cook) => (
            <CookRow
              key={cook.id}
              cook={cook}
              busy={toggle.isPending || resetPassword.isPending}
              onSetActive={(active) => setActive(cook, active)}
              onResetPassword={() => sendNewPassword(cook)}
            />
          ))}
        </ul>
      )}
    </section>
  )
}

function filled(name: string, email: string): boolean {
  return name.trim() !== '' && email.trim() !== ''
}

/** Uma merendeira: quem é, se entra, quando entrou e o que fazer com isso. */
function CookRow({
  cook,
  busy,
  onSetActive,
  onResetPassword,
}: {
  cook: CookAccess
  busy: boolean
  onSetActive(active: boolean): void
  onResetPassword(): void
}) {
  return (
    <li className="flex flex-wrap items-center gap-x-3 gap-y-1.5 border-b border-muted px-4 py-3 last:border-b-0">
      <div className="flex min-w-0 flex-1 basis-48 flex-col">
        <span className="truncate text-sm font-medium">{cook.name}</span>
        <span className="truncate text-xs text-muted-foreground">
          {cook.email}
        </span>
      </div>

      <span
        className={
          cook.active
            ? 'shrink-0 rounded-full border border-success-border bg-success-subtle px-2.5 py-0.5 text-2xs font-medium text-success'
            : 'shrink-0 rounded-full border border-border bg-muted px-2.5 py-0.5 text-2xs font-medium text-muted-foreground'
        }
      >
        {cook.active ? COOKS_MESSAGES.active : COOKS_MESSAGES.inactive}
      </span>

      <span className="shrink-0 text-xs text-muted-foreground">
        {lastAccessLabel(cook.last_access)}
      </span>

      <div className="flex shrink-0 gap-1">
        {/*
         * Redefinir senha só faz sentido para quem entra: o e-mail levaria a
         * merendeira desativada a criar uma senha que não abre nada.
         */}
        {cook.active ? (
          <Button
            variant="ghost"
            size="sm"
            disabled={busy}
            aria-label={resetPasswordLabel(cook.name)}
            onClick={onResetPassword}
          >
            {COOKS_MESSAGES.resetPassword}
          </Button>
        ) : null}

        <Button
          variant={cook.active ? 'ghost' : 'outline'}
          size="sm"
          disabled={busy}
          aria-label={
            cook.active
              ? deactivateLabel(cook.name)
              : reactivateLabel(cook.name)
          }
          className={
            cook.active ? 'text-destructive hover:text-destructive' : ''
          }
          onClick={() => onSetActive(!cook.active)}
        >
          {cook.active ? COOKS_MESSAGES.deactivate : COOKS_MESSAGES.reactivate}
        </Button>
      </div>
    </li>
  )
}
