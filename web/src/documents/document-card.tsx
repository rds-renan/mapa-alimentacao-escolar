import {
  CircleAlert,
  CircleCheck,
  CircleOff,
  Clock,
  Download,
  FileText,
  LoaderCircle,
  Lock,
  Share2,
} from 'lucide-react'

import { Button } from '@/components/ui/button'

import {
  availabilityOf,
  daysLeft,
  documentSummary,
  downloadable,
  expiryLabel,
  periodTitle,
  type DocumentAvailability,
  type GeneratedDocumentRecord,
} from './generated'
import {
  actionLabel,
  availabilityLabel,
  DOCUMENT_MESSAGES,
  lockedNotice,
} from './messages'

/*
 * Um documento na lista — o cartão da tela 2b, e, quando é o recém-gerado, a
 * tela 6 inteira dentro dele.
 *
 * A situação aparece em cor **e** ícone, como o estado do dia na visão do mês
 * (RNF#1 da US008): "Fora do ar" e "Não saiu" são os dois cinzas que precisam
 * se separar sem depender da cor, e quem os separa é o ícone.
 */

const APPEARANCE: Record<
  DocumentAvailability,
  { icon: typeof Clock; className: string }
> = {
  processing: {
    icon: LoaderCircle,
    className: 'border-accent-border bg-accent text-accent-foreground',
  },
  available: {
    icon: CircleCheck,
    className: 'border-success-border bg-success-subtle text-success',
  },
  expiring: {
    icon: Clock,
    className: 'border-warning-border bg-warning-subtle text-warning',
  },
  expired: {
    icon: CircleOff,
    className: 'border-border bg-muted text-muted-foreground',
  },
  failed: {
    icon: CircleAlert,
    className:
      'border-destructive-border bg-destructive-subtle text-destructive',
  },
}

export interface DocumentCardProps {
  document: GeneratedDocumentRecord
  /** O relógio de quem está olhando. Vem de fora para o teste poder pará-lo. */
  now: Date
  /** Este é o documento que ela acabou de gerar: o cartão vira a tela 6. */
  justGenerated: boolean
  online: boolean
  /** Um link deste documento está sendo assinado agora. */
  busy: boolean
  /** O navegador sabe compartilhar arquivo (decisão 9 da E5). */
  canShare: boolean
  onDownload(): void
  onShare(): void
}

export function DocumentCard({
  document,
  now,
  justGenerated,
  online,
  busy,
  canShare,
  onDownload,
  onShare,
}: DocumentCardProps) {
  const availability = availabilityOf(document, now)
  const { icon: Icon, className } = APPEARANCE[availability]
  const period = periodTitle(document.dates)
  const open = downloadable(availability)

  return (
    <li
      data-slot="document-card"
      data-availability={availability}
      className={`flex flex-col gap-2.5 rounded-xl border bg-card p-3.5 ${
        justGenerated ? 'border-success-border' : 'border-border'
      }`}
    >
      {/*
       * O cabeçalho da tela 6, e só no recém-gerado: a confirmação de que
       * saiu. Na lista de amanhã ele seria ruído — o documento está ali, e a
       * etiqueta já diz que está disponível.
       */}
      {justGenerated ? (
        <p className="flex items-center gap-2 text-base font-semibold text-success">
          <CircleCheck className="size-4.5 shrink-0" aria-hidden="true" />
          {DOCUMENT_MESSAGES.justGenerated}
        </p>
      ) : null}

      <div className="flex items-start gap-2.5">
        <div className="flex min-w-0 flex-1 flex-col gap-0.5">
          <span
            className={`text-lg font-semibold ${
              open || availability === 'processing'
                ? ''
                : 'text-muted-foreground'
            }`}
          >
            {period}
          </span>
          <span className="text-xs text-muted-foreground">
            {documentSummary(document, now)}
          </span>
        </div>

        <span
          className={`inline-flex shrink-0 items-center gap-1.5 rounded-full border px-2.5 py-1 text-2xs font-medium whitespace-nowrap ${className}`}
        >
          <Icon
            className={`size-3.5 ${availability === 'processing' ? 'animate-spin' : ''}`}
            aria-hidden="true"
          />
          {availabilityLabel(availability, daysLeft(document, now))}
        </span>
      </div>

      {/*
       * O prazo por extenso só quando ainda há folga: quando o cartão já diz
       * "Sai amanhã", repeti-lo embaixo é dizer duas vezes a mesma coisa.
       */}
      {availability === 'available' ? (
        <span className="text-xs text-muted-foreground">
          {expiryLabel(document)}
        </span>
      ) : null}

      {availability === 'processing' ? (
        <span className="text-xs text-muted-foreground">
          {DOCUMENT_MESSAGES.processingNote}
        </span>
      ) : null}

      {availability === 'expired' ? (
        <span className="text-xs text-muted-foreground">
          {DOCUMENT_MESSAGES.expiredNote}
        </span>
      ) : null}

      {availability === 'failed' ? (
        <span className="text-xs text-muted-foreground">
          {DOCUMENT_MESSAGES.failedNote}
        </span>
      ) : null}

      {justGenerated && document.fileName ? (
        <p className="flex items-center gap-2.5 rounded-lg bg-muted px-3 py-2.5">
          <FileText
            className="size-4.5 shrink-0 text-muted-foreground"
            aria-hidden="true"
          />
          <span className="truncate text-xs font-medium">
            {document.fileName}
          </span>
        </p>
      ) : null}

      {open ? (
        <div className="flex flex-col gap-2">
          {canShare ? (
            <Button
              variant={justGenerated ? 'default' : 'outline'}
              size="lg"
              disabled={!online || busy}
              aria-label={actionLabel(DOCUMENT_MESSAGES.share, period)}
              onClick={onShare}
            >
              {busy ? (
                <LoaderCircle className="animate-spin" aria-hidden="true" />
              ) : (
                <Share2 aria-hidden="true" />
              )}
              {DOCUMENT_MESSAGES.share}
            </Button>
          ) : null}

          <Button
            variant={justGenerated && !canShare ? 'default' : 'outline'}
            size="lg"
            disabled={!online || busy}
            aria-label={actionLabel(DOCUMENT_MESSAGES.download, period)}
            onClick={onDownload}
          >
            {busy && !canShare ? (
              <LoaderCircle className="animate-spin" aria-hidden="true" />
            ) : (
              <Download aria-hidden="true" />
            )}
            {DOCUMENT_MESSAGES.download}
          </Button>
        </div>
      ) : null}

      {/*
       * O bloqueio, dito uma vez, no momento em que acontece. É a consequência
       * irreversível da geração (RN#1 da US007) e a única coisa da tela 6 que
       * a lista não teria como mostrar depois.
       */}
      {justGenerated ? (
        <>
          <p className="flex items-start gap-2 rounded-lg border border-warning-border bg-warning-subtle px-3 py-2.5 text-xs text-warning">
            <Lock className="mt-px size-4 shrink-0" aria-hidden="true" />
            {lockedNotice(document.dates.length)}
          </p>
          <p className="flex items-start gap-2 rounded-lg bg-muted px-3 py-2.5 text-xs text-muted-foreground">
            <Clock className="mt-px size-4 shrink-0" aria-hidden="true" />
            {DOCUMENT_MESSAGES.expireNote}
          </p>
        </>
      ) : null}
    </li>
  )
}
