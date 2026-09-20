import { useRef, useState } from 'react'
import { Download, FileText, LoaderCircle, Upload } from 'lucide-react'

import { FormMessage } from '@/components/form-message'
import { Button } from '@/components/ui/button'

import { TEMPLATE_MESSAGES, templateReplacedLabel } from './messages'
import {
  templateRejection,
  useCurrentTemplate,
  useReplaceTemplate,
  useTemplateDownload,
} from './queries'

/*
 * O modelo oficial do documento (US015).
 *
 * O arquivo mora num balde privado e nunca é público (CA#3 da US015, RNF#1 da
 * US012): é a mesma regra de sigilo que o projeto inteiro segue, e aqui ela é
 * literal — o que está guardado é o documento com o símbolo da prefeitura.
 * Quem o lê para preencher é a Edge Function da geração, no servidor; o
 * navegador da direção só o envia e, se quiser conferir, o baixa por um link
 * assinado que vale um minuto.
 *
 * Trocar o modelo é uma operação do banco, e não duas do navegador: existe
 * sempre exatamente um vigente (RN#1 da US015), e a função
 * `replace_document_template` é o que impede a escola de ficar sem nenhum
 * entre uma chamada e outra.
 *
 * O arquivo é aceito como veio. Ele é o mesmo documento reeditado semana a
 * semana por quem não cuida do layout, e a cada volta uma linha se desloca —
 * não há versão limpa a manter, e não é este sistema que vai normalizá-lo.
 */
export function TemplateCard({ schoolId }: { schoolId: string | undefined }) {
  const template = useCurrentTemplate()
  const replace = useReplaceTemplate(schoolId)
  const download = useTemplateDownload()

  const fileInput = useRef<HTMLInputElement>(null)
  const [rejection, setRejection] = useState<string | null>(null)
  const [done, setDone] = useState(false)

  function chooseFile() {
    setRejection(null)
    setDone(false)
    replace.reset()
    fileInput.current?.click()
  }

  function send(event: React.ChangeEvent<HTMLInputElement>) {
    const file = event.target.files?.[0]
    // Limpa o campo antes de qualquer coisa: sem isso, escolher o mesmo
    // arquivo de novo depois de um erro não dispara evento nenhum.
    event.target.value = ''
    if (!file) return

    const refused = templateRejection(file)
    if (refused) {
      setRejection(refused)
      return
    }

    replace.mutate(file, { onSuccess: () => setDone(true) })
  }

  const current = template.data ?? null
  const busy = replace.isPending

  return (
    <section
      aria-labelledby="template-title"
      className="flex flex-col gap-3.5 rounded-xl border border-border bg-card p-4"
    >
      <hgroup className="flex flex-col gap-0.5">
        <h2 id="template-title" className="text-base font-semibold">
          {TEMPLATE_MESSAGES.title}
        </h2>
        <p className="text-xs text-muted-foreground">
          {TEMPLATE_MESSAGES.subtitle}
        </p>
      </hgroup>

      {template.isPending ? (
        <p
          role="status"
          className="flex items-center gap-2 py-2 text-sm text-muted-foreground"
        >
          <LoaderCircle className="size-4 animate-spin" aria-hidden="true" />
          {TEMPLATE_MESSAGES.loading}
        </p>
      ) : template.isError ? (
        <div role="alert" className="flex flex-col items-start gap-3">
          <FormMessage>{TEMPLATE_MESSAGES.loadFailed}</FormMessage>
          <Button variant="outline" onClick={() => void template.refetch()}>
            {TEMPLATE_MESSAGES.retry}
          </Button>
        </div>
      ) : current ? (
        <div className="flex items-center gap-3 rounded-lg border border-border px-3.5 py-3">
          <span className="flex size-10 shrink-0 items-center justify-center rounded-lg bg-accent text-primary">
            <FileText className="size-5" aria-hidden="true" />
          </span>
          <div className="flex min-w-0 flex-col">
            <span className="truncate text-sm font-medium">
              {current.file_name}
            </span>
            <span className="text-xs text-muted-foreground">
              {templateReplacedLabel(current.uploaded_at)}
            </span>
          </div>
        </div>
      ) : (
        /*
         * Sem modelo não há documento: a função do banco recusa a geração, e
         * a merendeira receberia a recusa sem ter como resolvê-la. Quem
         * resolve é quem está lendo esta tela.
         */
        <FormMessage>{TEMPLATE_MESSAGES.none}</FormMessage>
      )}

      {rejection ? <FormMessage>{rejection}</FormMessage> : null}
      {replace.isError ? (
        <FormMessage>{replace.error.message}</FormMessage>
      ) : null}
      {done ? (
        <FormMessage kind="success">{TEMPLATE_MESSAGES.replaced}</FormMessage>
      ) : null}

      <div className="flex flex-wrap gap-2">
        <input
          ref={fileInput}
          type="file"
          accept=".docx"
          className="hidden"
          onChange={send}
        />

        <Button variant="outline" disabled={busy} onClick={chooseFile}>
          {busy ? (
            <LoaderCircle className="animate-spin" aria-hidden="true" />
          ) : (
            <Upload aria-hidden="true" />
          )}
          {busy
            ? TEMPLATE_MESSAGES.sending
            : current
              ? TEMPLATE_MESSAGES.replace
              : TEMPLATE_MESSAGES.upload}
        </Button>

        {current ? (
          <Button
            variant="outline"
            disabled={download.isPending}
            onClick={() => download.mutate(current)}
          >
            <Download aria-hidden="true" />
            {TEMPLATE_MESSAGES.download}
          </Button>
        ) : null}
      </div>

      {download.isError ? (
        <FormMessage>{TEMPLATE_MESSAGES.downloadFailed}</FormMessage>
      ) : null}

      <p className="text-2xs text-muted-foreground">
        {TEMPLATE_MESSAGES.privacy}
      </p>
    </section>
  )
}
