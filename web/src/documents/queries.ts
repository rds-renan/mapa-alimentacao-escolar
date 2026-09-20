import {
  useMutation,
  useMutationState,
  useQuery,
  useQueryClient,
} from '@tanstack/react-query'

import { supabase } from '@/lib/supabase'

import type { GeneratedDocumentRecord } from './generated'
import { DOCUMENT_MESSAGES, FAILURE_MESSAGES } from './messages'

/*
 * O pedido de geração do documento.
 *
 * É a primeira coisa da web a chamar uma Edge Function em vez do banco, e a
 * razão está no contrato dela: o modelo oficial mora num balde privado e não
 * passa pelo navegador (RNF#1 da US012). O que sobe daqui é só a lista de dias
 * — a escola vem do perfil de quem chamou, no servidor, como na gravação do
 * dia.
 *
 * A resposta é síncrona: o mês inteiro sai em menos de meio segundo. Mesmo
 * assim a chamada é uma mutação **com chave**, e não um `fetch` dentro da
 * tela: a chave é o que permite a qualquer tela perguntar se existe geração em
 * curso, e é ela que sustenta o CA da issue que diz que a geração sobrevive a
 * terminar com a merendeira fora da tela. A mutação vive no cliente da Query,
 * que está acima das rotas; sair da tela não a cancela.
 */

export interface GeneratedDocument {
  generated_document_id: string
  status: string
  requested_at: string
  completed_at: string | null
  expires_at: string | null
  meal_map_count: number
  period: { from: string; to: string }
  file_name: string
  download_url: string
}

export const GENERATE_DOCUMENT_KEY = ['generate-document'] as const

/**
 * A recusa, como ela chega na tela.
 *
 * A Edge Function devolve a mensagem já escrita para quem vai lê-la — a mesma
 * convenção da gravação do dia, que não deixa tradução para o cliente. O que
 * este trecho faz é apenas alcançá-la: o `supabase-js` embrulha a resposta num
 * erro e guarda o corpo em `context`, então sem isto a merendeira receberia
 * "Edge Function returned a non-2xx status code", que não é frase de ninguém.
 */
async function readFailure(cause: unknown): Promise<string> {
  const context = (cause as { context?: Response } | null)?.context

  if (context && typeof context.json === 'function') {
    try {
      const body = (await context.json()) as {
        error?: { message?: string; hint?: string | null }
      }
      const message = body.error?.message
      if (typeof message === 'string' && message !== '') {
        return [message, body.error?.hint].filter(Boolean).join(' ')
      }
    } catch {
      // Corpo que não é JSON: cai na frase da E3, logo abaixo.
    }
  }

  // Sem resposta do servidor. Na escola isso é a internet, e é o que a frase diz.
  return FAILURE_MESSAGES.network
}

async function generateDocument(
  mealMapIds: string[]
): Promise<GeneratedDocument> {
  const { data, error } = await supabase.functions.invoke<GeneratedDocument>(
    'generate-document',
    { body: { meal_map_ids: mealMapIds } }
  )

  if (error) throw new Error(await readFailure(error))
  if (!data) throw new Error(FAILURE_MESSAGES.network)

  return data
}

export function useGenerateDocument() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationKey: GENERATE_DOCUMENT_KEY,
    mutationFn: generateDocument,
    /*
     * Gerou: os mapas incluídos acabaram de ficar bloqueados, e a visão do mês
     * ainda mostra o estado de antes. Invalidar todos os meses, e não só o
     * aberto, porque a seleção pode atravessar meses.
     *
     * Fica no nível da mutação, e não na chamada: a chamada é descartada se a
     * merendeira sair da tela, e o bloqueio acontece do mesmo jeito.
     */
    onSuccess: () => {
      void queryClient.invalidateQueries({ queryKey: ['month'] })
      void queryClient.invalidateQueries({ queryKey: GENERATED_DOCUMENTS_KEY })
    },
  })
}

/**
 * Existe geração em curso agora, tenha ela sido pedida nesta tela ou não.
 *
 * É o que faz a tela reencontrar a geração quando a merendeira volta para ela
 * no meio do caminho: o observador da mutação morre com a tela, mas a mutação
 * continua no cliente da Query, que está acima das rotas.
 */
export function useGenerationInFlight(): boolean {
  const running = useMutationState({
    filters: { mutationKey: GENERATE_DOCUMENT_KEY, status: 'pending' },
  })

  return running.length > 0
}

// ---------------------------------------------------------------------------
// A lista dos documentos gerados (tela 2b, US021)
// ---------------------------------------------------------------------------

/*
 * Aqui não há Edge Function: a merendeira lê a tabela direto, e o balde
 * assina o link para ela. É o que as políticas da E4 já permitem — a leitura
 * de `generated_document` é dos dois perfis da escola, e a do objeto no balde
 * exige que o registro exista, seja desta escola, esteja disponível e ainda
 * dentro do prazo. A geração precisava do servidor porque o **modelo** oficial
 * não pode passar pelo navegador; ler o que já saiu não precisa.
 *
 * Sem filtro de escola na consulta: quem recorta é o RLS (decisão 6 da E5).
 */

const DOCUMENT_BUCKET = 'generated-documents'

const DOCX_TYPE =
  'application/vnd.openxmlformats-officedocument.wordprocessingml.document'

/*
 * O período e a quantidade de mapas são derivados da ligação, não gravados
 * (decisão 10 da E4): é `document_meal_map` que sabe quais dias entraram.
 */
const DOCUMENT_COLUMNS =
  'id, status, requested_at, completed_at, expires_at, file_path, file_name, document_meal_map (meal_map (map_date))'

/**
 * As últimas gerações, e não a história inteira.
 *
 * O registro é permanente de propósito (decisão 10 da E4), então a tabela só
 * cresce; a tela, não. Vinte cobre bem mais de um ano de uso — a escola gera
 * um documento por mês, mais as regerações de correção —, e o que cai fora
 * disso já não é "voltar ao documento que acabei de gerar", que é do que esta
 * tela trata.
 */
const RECENT = 20

/** O link assinado vale o tempo de a merendeira tocar no botão, não mais. */
const LINK_SECONDS = 60

interface DocumentRow {
  id: string
  status: 'processing' | 'available' | 'failed'
  requested_at: string
  completed_at: string | null
  expires_at: string | null
  file_path: string | null
  file_name: string | null
  document_meal_map: { meal_map: { map_date: string } | null }[]
}

export const GENERATED_DOCUMENTS_KEY = ['generated-documents'] as const

async function fetchGeneratedDocuments(): Promise<GeneratedDocumentRecord[]> {
  const { data, error } = await supabase
    .from('generated_document')
    .select(DOCUMENT_COLUMNS)
    .order('requested_at', { ascending: false })
    .limit(RECENT)

  if (error) throw new Error(error.message)

  return ((data ?? []) as unknown as DocumentRow[]).map((row) => ({
    id: row.id,
    status: row.status,
    requestedAt: row.requested_at,
    completedAt: row.completed_at,
    expiresAt: row.expires_at,
    filePath: row.file_path,
    fileName: row.file_name,
    dates: row.document_meal_map
      .map((link) => link.meal_map?.map_date)
      .filter((date): date is string => typeof date === 'string')
      .sort(),
  }))
}

export function useGeneratedDocuments() {
  return useQuery({
    queryKey: GENERATED_DOCUMENTS_KEY,
    queryFn: fetchGeneratedDocuments,
  })
}

// ---------------------------------------------------------------------------
// Baixar e compartilhar, que na web são a mesma coisa vista de dois lados
// ---------------------------------------------------------------------------

/**
 * O navegador sabe compartilhar **arquivo**.
 *
 * Não basta existir `navigator.share`: no computador da secretaria ele pode
 * existir e recusar arquivos, e aí o botão prometeria o que não entrega. A
 * pergunta se faz com um arquivo de mentira do mesmo tipo, que é a única
 * forma de perguntar (decisão 9 da E5).
 */
export function canShareFiles(): boolean {
  if (typeof navigator === 'undefined') return false
  if (typeof navigator.share !== 'function') return false
  if (typeof navigator.canShare !== 'function') return false

  try {
    const probe = new File([new Uint8Array(1)], 'mapa.docx', {
      type: DOCX_TYPE,
    })
    return navigator.canShare({ files: [probe] })
  } catch {
    return false
  }
}

async function signedUrl(document: GeneratedDocumentRecord): Promise<string> {
  if (!document.filePath || !document.fileName) {
    throw new Error(DOCUMENT_MESSAGES.linkFailed)
  }

  /*
   * O nome vai no link, e é o balde que o devolve no cabeçalho: é o que faz o
   * arquivo chegar como "mapa-da-alimentacao-escolar-setembro-2026.docx" e não
   * como o identificador que ele tem no balde. O nome é o que a geração
   * gravou — recalculá-lo aqui seria uma segunda regra, livre para divergir.
   */
  const { data, error } = await supabase.storage
    .from(DOCUMENT_BUCKET)
    .createSignedUrl(document.filePath, LINK_SECONDS, {
      download: document.fileName,
    })

  if (error || !data) throw new Error(DOCUMENT_MESSAGES.linkFailed)
  return data.signedUrl
}

/** O link assinado já vem com "anexo" no cabeçalho: abrir é baixar. */
function saveToDevice(url: string, fileName: string) {
  const anchor = window.document.createElement('a')
  anchor.href = url
  anchor.download = fileName
  anchor.rel = 'noopener'

  window.document.body.append(anchor)
  anchor.click()
  anchor.remove()
}

/** Quem cancela a folha de compartilhamento não errou nada. */
function cancelled(cause: unknown): boolean {
  return cause instanceof Error && cause.name === 'AbortError'
}

async function shareFile(url: string, fileName: string) {
  const response = await fetch(url)
  if (!response.ok) throw new Error(DOCUMENT_MESSAGES.linkFailed)

  const file = new File([await response.blob()], fileName, { type: DOCX_TYPE })

  /*
   * O navegador pode mudar de ideia diante do arquivo de verdade — tamanho,
   * tipo, o que for. Aí o caminho não é um erro: é baixar, que é o que esta
   * web promete (decisão 9 da E5).
   */
  if (!navigator.canShare?.({ files: [file] })) {
    saveToDevice(url, fileName)
    return
  }

  try {
    await navigator.share({ files: [file], title: fileName })
  } catch (cause) {
    if (!cancelled(cause)) throw cause
  }
}

export interface DocumentFileRequest {
  document: GeneratedDocumentRecord
  action: 'download' | 'share'
}

/**
 * Pegar o arquivo: assina o link e entrega, baixando ou compartilhando.
 *
 * É uma mutação, e não uma consulta, porque o link é de uso único e de
 * duração curta — guardá-lo em cache seria guardar algo que vence em um
 * minuto. O que se cacheia é o registro; o link se pede na hora do toque.
 */
export function useDocumentFile() {
  return useMutation({
    mutationFn: async ({ document, action }: DocumentFileRequest) => {
      const url = await signedUrl(document)
      const fileName = document.fileName as string

      if (action === 'share') await shareFile(url, fileName)
      else saveToDevice(url, fileName)
    },
  })
}
