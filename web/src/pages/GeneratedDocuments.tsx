import { useMemo } from 'react'
import {
  ArrowLeft,
  CircleAlert,
  FileText,
  Info,
  LoaderCircle,
  WifiOff,
} from 'lucide-react'
import { Link, useLocation } from 'react-router'

import { FormMessage } from '@/components/form-message'
import { Button } from '@/components/ui/button'
import { DocumentCard } from '@/documents/document-card'
import { DOCUMENT_MESSAGES, SELECTION_MESSAGES } from '@/documents/messages'
import {
  canShareFiles,
  useDocumentFile,
  useGeneratedDocuments,
  useGenerationInFlight,
} from '@/documents/queries'
import { useOnline } from '@/documents/use-online'
import { monthKeyToday } from '@/month/month'
import { ROUTES, selectMapsPath } from '@/routes'

/*
 * Os documentos gerados — telas 6 e 2b da E3 (US012, US014, US021).
 *
 * A tela existe porque a 6, sozinha, é um beco: a decisão 10 da E3 notou que
 * o documento recém-gerado ficava inalcançável assim que a merendeira saísse
 * dali, e três situações banais caem nisso. Aqui as duas são a mesma tela —
 * o recém-gerado é o primeiro cartão da lista, no lugar onde ele estará
 * amanhã também.
 *
 * **Na web, compartilhar é baixar** (decisão 9 da E5). O botão de
 * compartilhamento nativo aparece quando o navegador souber compartilhar
 * arquivo, e não quando ele disser que tem `navigator.share` — a folha do
 * Android de que fala o CA#1 da US014 é da E6. O que a estratégia de aceitação
 * institucional exige se preserva inteiro: o arquivo é o mesmo, e o envio é
 * sempre ação da merendeira (RN#1 da US014).
 *
 * Nada aqui abre mapa nenhum (RN#2 da US021): a lista é sobre o arquivo, e os
 * mapas que entraram nele estão bloqueados. O caminho para corrigir um dia é
 * a direção reabri-lo (US023), não esta tela.
 */

export function GeneratedDocuments() {
  const location = useLocation()
  const online = useOnline()
  const documents = useGeneratedDocuments()
  const generating = useGenerationInFlight()
  const file = useDocumentFile()

  /*
   * Qual documento ela acabou de gerar, se é que acabou. Vem no estado da
   * navegação, e não de uma consulta: é um fato daquela ida, não do servidor
   * — recarregar a tela amanhã não deve ressuscitar a tela 6 de hoje.
   */
  const justGenerated =
    (location.state as { justGenerated?: string } | null)?.justGenerated ?? null

  // Perguntar ao navegador uma vez: a resposta não muda enquanto a tela vive.
  const canShare = useMemo(() => canShareFiles(), [])

  const now = new Date()
  const list = documents.data ?? []

  return (
    <div className="flex min-h-dvh flex-col bg-background">
      <header className="sticky top-0 z-10 border-b border-border bg-card">
        <div className="mx-auto flex w-full max-w-screen items-center gap-1 p-2">
          <Button variant="ghost" size="icon" asChild>
            <Link to={ROUTES.cookHome} aria-label={DOCUMENT_MESSAGES.back}>
              <ArrowLeft aria-hidden="true" />
            </Link>
          </Button>

          <h1 className="flex flex-1 flex-col gap-px overflow-hidden">
            <span className="truncate text-lg font-semibold tracking-tight">
              {DOCUMENT_MESSAGES.title}
            </span>
            <span className="truncate text-xs font-normal text-muted-foreground">
              {DOCUMENT_MESSAGES.subtitle}
            </span>
          </h1>
        </div>
      </header>

      <main className="mx-auto flex w-full max-w-screen flex-1 flex-col gap-3.5 px-4 pt-3.5 pb-6">
        <p className="flex items-start gap-2 rounded-lg border border-accent-border bg-accent px-3.5 py-3 text-xs text-accent-foreground">
          <Info className="mt-px size-4 shrink-0" aria-hidden="true" />
          {DOCUMENT_MESSAGES.notice}
        </p>

        {/*
         * Sem rede não se baixa nada, e o aviso vem antes do toque — explicar
         * a espera em vez de deixar o botão falhar em silêncio (catálogo de
         * avisos da E3). A lista em si pode estar aqui: ela veio do cache.
         */}
        {online ? null : (
          <p
            role="status"
            className="flex items-start gap-2 rounded-lg border border-warning-border bg-warning-subtle px-3.5 py-3 text-xs text-warning"
          >
            <WifiOff className="mt-px size-4 shrink-0" aria-hidden="true" />
            {DOCUMENT_MESSAGES.offline}
          </p>
        )}

        {file.isError ? <FormMessage>{file.error.message}</FormMessage> : null}

        {/*
         * A geração em curso aparece mesmo tendo sido pedida em outra tela: a
         * mutação vive no cliente da Query, acima das rotas. É o que cumpre a
         * promessa do aviso do alto — "não é preciso esperar na tela".
         */}
        {generating ? (
          <p
            role="status"
            className="flex items-center gap-2 rounded-xl border border-border bg-card px-3.5 py-3.5 text-base text-muted-foreground"
          >
            <LoaderCircle className="size-4 animate-spin" aria-hidden="true" />
            {SELECTION_MESSAGES.generating}
          </p>
        ) : null}

        {documents.isPending ? (
          <p
            role="status"
            className="flex flex-1 items-center justify-center gap-2 text-base text-muted-foreground"
          >
            <LoaderCircle className="size-4 animate-spin" aria-hidden="true" />
            {DOCUMENT_MESSAGES.loading}
          </p>
        ) : documents.isError ? (
          <div
            role="alert"
            className="flex flex-1 flex-col items-center justify-center gap-3 text-center"
          >
            <CircleAlert
              className="size-6 text-muted-foreground"
              aria-hidden="true"
            />
            <p className="text-base text-muted-foreground">
              {DOCUMENT_MESSAGES.loadFailed}
            </p>
            <Button variant="outline" onClick={() => void documents.refetch()}>
              {DOCUMENT_MESSAGES.retry}
            </Button>
          </div>
        ) : list.length === 0 ? (
          <div className="flex flex-1 flex-col items-center justify-center gap-3 text-center">
            <FileText
              className="size-6 text-muted-foreground"
              aria-hidden="true"
            />
            <p className="text-base text-muted-foreground">
              {DOCUMENT_MESSAGES.empty}
              <br />
              {DOCUMENT_MESSAGES.emptyHint}
            </p>
            <Button variant="outline" asChild>
              <Link to={selectMapsPath(monthKeyToday(now))}>
                {DOCUMENT_MESSAGES.generate}
              </Link>
            </Button>
          </div>
        ) : (
          <ul
            aria-label={DOCUMENT_MESSAGES.title}
            className="flex flex-col gap-3"
          >
            {list.map((document) => (
              <DocumentCard
                key={document.id}
                document={document}
                now={now}
                justGenerated={document.id === justGenerated}
                online={online}
                busy={
                  file.isPending && file.variables?.document.id === document.id
                }
                canShare={canShare}
                onDownload={() => file.mutate({ document, action: 'download' })}
                onShare={() => file.mutate({ document, action: 'share' })}
              />
            ))}
          </ul>
        )}
      </main>
    </div>
  )
}
