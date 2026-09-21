import { useState } from 'react'
import { LoaderCircle } from 'lucide-react'

import { FormMessage } from '@/components/form-message'
import { Button } from '@/components/ui/button'
import {
  AlertDialog,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogTitle,
} from '@/components/ui/alert-dialog'
import { Label } from '@/components/ui/label'
import { Textarea } from '@/components/ui/textarea'

import { REOPEN_BODY, REOPEN_MESSAGES, reopenTitle } from './messages'

/*
 * O diálogo da reabertura (CA#1 e CA#3 da US023).
 *
 * É confirmação **e** formulário, e não por economia de tela: a justificativa é
 * o que torna a reabertura admissível, então pedi-la é a própria confirmação —
 * quem escreve o motivo já decidiu. Um "tem certeza?" antes disso seria um
 * toque a mais dizendo o que a frase seguinte já diz.
 *
 * `AlertDialog` e não `Dialog` pelo mesmo motivo dos outros dois usos: a saída
 * é sempre um dos dois botões, e não um clique distraído fora da caixa — aqui
 * isso também guarda o que a direção acabou de escrever.
 *
 * O botão de confirmar é um `submit` comum, e não o `AlertDialogAction` da
 * biblioteca: aquele fecha o diálogo ao ser tocado, e este precisa continuar
 * aberto enquanto a chamada está no ar e depois dela, se ela falhar.
 */
export function ReopenDialog({
  dayLabel,
  open,
  busy,
  failure,
  onCancel,
  onConfirm,
}: {
  /** "Sexta, 4 de setembro" — o dia de que se está falando. */
  dayLabel: string
  open: boolean
  busy: boolean
  /** A recusa do servidor, já escrita para quem vai ler. */
  failure: string | null
  onCancel(): void
  onConfirm(reason: string): void
}) {
  const [reason, setReason] = useState('')

  /*
   * Cada abertura começa em branco. A justificativa é de um dia e de uma
   * correção: reaproveitar a da vez passada é o caminho mais curto para o
   * registro permanente dizer o motivo errado.
   *
   * O ajuste é no próprio desenho, e não num efeito — o mesmo que a tela do
   * registro faz ao trocar de dia: um efeito só limparia o campo depois de ele
   * já ter aparecido por um quadro com o texto da vez passada.
   */
  const [wasOpen, setWasOpen] = useState(open)
  if (wasOpen !== open) {
    setWasOpen(open)
    if (open) setReason('')
  }

  const filled = reason.trim() !== ''

  function submit(event: React.FormEvent) {
    event.preventDefault()
    if (busy || !filled) return
    onConfirm(reason)
  }

  return (
    <AlertDialog open={open} onOpenChange={(next) => !next && onCancel()}>
      <AlertDialogContent>
        <AlertDialogTitle>{reopenTitle(dayLabel)}</AlertDialogTitle>
        <AlertDialogDescription>{REOPEN_BODY}</AlertDialogDescription>

        <form onSubmit={submit} className="flex flex-col gap-3">
          <div className="flex flex-col gap-1.5">
            <Label htmlFor="reopen-reason">{REOPEN_MESSAGES.reasonLabel}</Label>
            <Textarea
              id="reopen-reason"
              rows={3}
              autoFocus
              value={reason}
              placeholder={REOPEN_MESSAGES.reasonPlaceholder}
              onChange={(event) => setReason(event.target.value)}
            />
            <p className="text-xs text-muted-foreground">
              {REOPEN_MESSAGES.reasonHint}
            </p>
          </div>

          {failure ? <FormMessage>{failure}</FormMessage> : null}

          <div className="mt-1 flex gap-2 *:flex-1">
            <AlertDialogCancel disabled={busy} onClick={onCancel}>
              {REOPEN_MESSAGES.cancel}
            </AlertDialogCancel>
            <Button type="submit" disabled={busy || !filled}>
              {busy ? (
                <LoaderCircle className="animate-spin" aria-hidden="true" />
              ) : null}
              {busy ? REOPEN_MESSAGES.reopening : REOPEN_MESSAGES.confirm}
            </Button>
          </div>
        </form>
      </AlertDialogContent>
    </AlertDialog>
  )
}
