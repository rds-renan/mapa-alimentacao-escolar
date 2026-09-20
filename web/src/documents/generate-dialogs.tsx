import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogTitle,
} from '@/components/ui/alert-dialog'

import {
  confirmBody,
  confirmTitle,
  CONFIRM_MESSAGES,
  FAILURE_MESSAGES,
} from './messages'

/*
 * Os dois diálogos da geração.
 *
 * O primeiro é **a única confirmação do fluxo da merendeira** (decisão da E3).
 * Ele existe porque o bloqueio dos mapas é irreversível para ela — desfazer
 * passa a ser assunto da direção, com justificativa (US023). Confirmar tudo é
 * o caminho mais curto para ela deixar de ler as confirmações, e é por isso que
 * esta é a única.
 *
 * O segundo obedece à regra de linguagem da E3: o erro diz primeiro o que
 * **não** se perdeu. Aqui isso não é gentileza — é informação operacional, e é
 * verdade verificável: o bloqueio dos mapas acontece junto com a publicação do
 * documento, então geração que falhou não bloqueou nada.
 */

export function ConfirmGenerationDialog({
  open,
  period,
  count,
  onCancel,
  onConfirm,
}: {
  open: boolean
  /** O período em português: "setembro", "agosto e setembro". */
  period: string
  count: number
  onCancel(): void
  onConfirm(): void
}) {
  return (
    <AlertDialog open={open} onOpenChange={(next) => !next && onCancel()}>
      <AlertDialogContent>
        <AlertDialogTitle>{confirmTitle(period)}</AlertDialogTitle>
        <AlertDialogDescription>{confirmBody(count)}</AlertDialogDescription>

        <AlertDialogFooter>
          <AlertDialogCancel onClick={onCancel}>
            {CONFIRM_MESSAGES.cancel}
          </AlertDialogCancel>
          <AlertDialogAction onClick={onConfirm}>
            {CONFIRM_MESSAGES.confirm}
          </AlertDialogAction>
        </AlertDialogFooter>
      </AlertDialogContent>
    </AlertDialog>
  )
}

export function GenerationFailureDialog({
  open,
  message,
  onClose,
  onRetry,
}: {
  open: boolean
  /** A frase do servidor, quando a recusa tem explicação própria. */
  message: string
  onClose(): void
  onRetry(): void
}) {
  /*
   * A frase da rede já afirma que nada foi bloqueado; a do servidor, não. A
   * linha só é acrescentada quando falta, para não dizer duas vezes a mesma
   * coisa a quem já leu.
   */
  const reassures = message.includes('bloquead')

  return (
    <AlertDialog open={open} onOpenChange={(next) => !next && onClose()}>
      <AlertDialogContent>
        <AlertDialogTitle>{FAILURE_MESSAGES.title}</AlertDialogTitle>
        <AlertDialogDescription>
          {message}
          {reassures ? null : <> {FAILURE_MESSAGES.nothingLocked}</>}
        </AlertDialogDescription>

        <AlertDialogFooter>
          <AlertDialogCancel onClick={onClose}>
            {FAILURE_MESSAGES.close}
          </AlertDialogCancel>
          <AlertDialogAction onClick={onRetry}>
            {FAILURE_MESSAGES.retry}
          </AlertDialogAction>
        </AlertDialogFooter>
      </AlertDialogContent>
    </AlertDialog>
  )
}
