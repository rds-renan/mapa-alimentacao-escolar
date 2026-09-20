import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'

import { sendPasswordEmail } from '@/auth/password-email'
import { supabase } from '@/lib/supabase'

import { COOKS_MESSAGES, SCHOOL_MESSAGES, TEMPLATE_MESSAGES } from './messages'

/*
 * A leitura e a escrita da gestão (US015, US016).
 *
 * Sem filtro de escola em lugar nenhum: quem recorta é o RLS da E4, pela
 * escola de quem está logada (decisão 6 da E5). As políticas que sustentam
 * este arquivo já estavam de pé desde lá — `school_update`,
 * `profile_admin_insert`, `profile_admin_update` e as do balde do modelo —,
 * e o que a E5 acrescentou foi só o que o navegador não conseguia fazer
 * sozinho: a Edge Function que cria a conta e a função que troca o modelo
 * vigente sem deixar a escola sem modelo no meio do caminho.
 *
 * Nada daqui passa pela fila do aparelho, pelo mesmo motivo do catálogo de
 * gêneros (decisão 2 da E5): a fila existe para o mapa do dia, que é o que não
 * pode se perder. Gestão é tarefa ocasional, feita de propósito, e quem a faz
 * sem rede refaz com rede.
 */

// ---------------------------------------------------------------------------
// Merendeiras
// ---------------------------------------------------------------------------

export interface CookAccess {
  id: string
  name: string
  email: string
  active: boolean
  last_access: string | null
}

export const COOKS_QUERY_KEY = ['admin', 'cooks'] as const

async function fetchCooks(): Promise<CookAccess[]> {
  /*
   * Só as merendeiras. A direção não aparece na própria lista — e não é
   * economia de linha: o gatilho da E4 recusa que ela mexa no próprio papel ou
   * no próprio acesso, porque a escola tem uma direção só e uma direção que se
   * desativa tranca a gestão para fora do aplicativo. Mostrar a linha seria
   * oferecer botões que o banco recusa.
   */
  const { data, error } = await supabase
    .from('profile')
    .select('id, name, email, active, last_access')
    .eq('role', 'cook')
    .order('name')

  if (error) throw new Error(error.message)
  return data ?? []
}

export function useCooks() {
  return useQuery({ queryKey: COOKS_QUERY_KEY, queryFn: fetchCooks })
}

export interface NewCook {
  name: string
  email: string
}

/**
 * O resultado de cadastrar, que tem dois desfechos bons.
 *
 * O acesso é criado pela Edge Function e o convite sai daqui, em duas
 * chamadas: é possível a conta existir e o e-mail não sair. Não é falha do
 * cadastro — é o convite que falta, e reenviá-lo é o botão "Redefinir senha"
 * da linha dela. A tela precisa saber a diferença para dizer a frase certa.
 */
export interface CookCreated {
  cook: CookAccess
  invited: boolean
}

async function createCook(wanted: NewCook): Promise<CookCreated> {
  const { data, error } = await supabase.functions.invoke<CookAccess>(
    'create-access',
    { body: { name: wanted.name.trim(), email: wanted.email.trim() } }
  )

  if (error) throw new Error(await readFailure(error))
  if (!data) throw new Error(COOKS_MESSAGES.createFailed)

  const emailError = await sendPasswordEmail(data.email)

  return { cook: data, invited: emailError === null }
}

/**
 * A recusa da Edge Function, como ela chega na tela.
 *
 * A função devolve a mensagem já escrita para quem vai lê-la — mesma
 * convenção da geração do documento. Sem alcançá-la dentro do `context`, a
 * direção receberia "Edge Function returned a non-2xx status code".
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
      // Corpo que não é JSON: cai na frase de sempre, logo abaixo.
    }
  }

  return COOKS_MESSAGES.createFailed
}

async function setCookActive(id: string, active: boolean): Promise<CookAccess> {
  /*
   * Desativar é `active = false`, e nunca um delete: a linha é o que sustenta
   * a autoria dos mapas, dos documentos e dos desbloqueios que ela deixou
   * (decisão 2 da E4). Não há política de delete em `profile`, então nem por
   * engano isso acontece pelo navegador.
   */
  const { data, error } = await supabase
    .from('profile')
    .update({ active })
    .eq('id', id)
    .select('id, name, email, active, last_access')
    .single()

  if (error) throw new Error(error.message)
  return data
}

async function resetCookPassword(email: string): Promise<void> {
  const error = await sendPasswordEmail(email)
  if (error) throw new Error(COOKS_MESSAGES.resetFailed)
}

/** Cadastrar, desativar, reativar e reenviar a senha — as escritas da lista. */
export function useCookMutations() {
  const queryClient = useQueryClient()

  const invalidate = () =>
    queryClient.invalidateQueries({ queryKey: COOKS_QUERY_KEY })

  const create = useMutation({
    mutationFn: createCook,
    onSuccess: invalidate,
  })

  const toggle = useMutation({
    mutationFn: ({ id, active }: { id: string; active: boolean }) =>
      setCookActive(id, active),
    onSuccess: invalidate,
  })

  const resetPassword = useMutation({
    mutationFn: ({ email }: { email: string; name: string }) =>
      resetCookPassword(email),
  })

  return { create, toggle, resetPassword }
}

// ---------------------------------------------------------------------------
// Dados da escola
// ---------------------------------------------------------------------------

export interface School {
  id: string
  name: string
  city: string
  school_year: number
}

export const SCHOOL_QUERY_KEY = ['admin', 'school'] as const

async function fetchSchool(): Promise<School | null> {
  // Uma linha só: a política `school_select` da E4 já devolve apenas a escola
  // de quem está logada.
  const { data, error } = await supabase
    .from('school')
    .select('id, name, city, school_year')
    .maybeSingle()

  if (error) throw new Error(error.message)
  return data
}

export function useSchool() {
  return useQuery({ queryKey: SCHOOL_QUERY_KEY, queryFn: fetchSchool })
}

export function useSaveSchool() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: async (school: School) => {
      const { data, error } = await supabase
        .from('school')
        .update({
          name: school.name.trim(),
          city: school.city.trim(),
          school_year: school.school_year,
        })
        .eq('id', school.id)
        .select('id, name, city, school_year')
        .single()

      if (error) throw new Error(SCHOOL_MESSAGES.saveFailed)
      return data
    },
    onSuccess: (saved) => queryClient.setQueryData(SCHOOL_QUERY_KEY, saved),
  })
}

// ---------------------------------------------------------------------------
// Modelo oficial
// ---------------------------------------------------------------------------

const TEMPLATE_BUCKET = 'document-templates'

export const DOCX_TYPE =
  'application/vnd.openxmlformats-officedocument.wordprocessingml.document'

/** O modelo oficial é um documento de texto, não um acervo: 20 MB é folgado. */
const MAX_TEMPLATE_BYTES = 20 * 1024 * 1024

/** O link assinado vale o tempo de a direção tocar no botão, não mais. */
const LINK_SECONDS = 60

export interface DocumentTemplate {
  id: string
  file_name: string
  file_path: string
  uploaded_at: string
}

export const TEMPLATE_QUERY_KEY = ['admin', 'document-template'] as const

async function fetchCurrentTemplate(): Promise<DocumentTemplate | null> {
  const { data, error } = await supabase
    .from('document_template')
    .select('id, file_name, file_path, uploaded_at')
    .eq('is_current', true)
    .maybeSingle()

  if (error) throw new Error(error.message)
  return data
}

export function useCurrentTemplate() {
  return useQuery({
    queryKey: TEMPLATE_QUERY_KEY,
    queryFn: fetchCurrentTemplate,
  })
}

/** O arquivo é mesmo um .docx? A extensão manda: o tipo vem vazio às vezes. */
export function templateRejection(file: File): string | null {
  if (!file.name.toLowerCase().endsWith('.docx')) {
    return TEMPLATE_MESSAGES.wrongType
  }
  if (file.size > MAX_TEMPLATE_BYTES) return TEMPLATE_MESSAGES.tooLarge
  return null
}

/**
 * Enviar uma versão nova do modelo.
 *
 * Cada versão é um arquivo próprio no balde, em `<escola>/<identificador>.docx`
 * — e não um `modelo.docx` sobrescrito a cada troca. A tabela guarda as
 * versões anteriores para saber com qual modelo cada documento saiu (decisão
 * 11 da E4), e isso só vale de verdade enquanto o arquivo daquela versão
 * existir.
 *
 * O registro é a última coisa a acontecer: enquanto ele não muda, o modelo
 * vigente continua sendo o antigo, e uma falha no meio do envio não deixa a
 * escola sem documento. O arquivo que sobra de uma falha é apagado aqui mesmo.
 */
export function useReplaceTemplate(schoolId: string | undefined) {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: async (file: File): Promise<DocumentTemplate> => {
      if (schoolId === undefined) throw new Error('sem escola')

      const rejection = templateRejection(file)
      if (rejection) throw new Error(rejection)

      const path = `${schoolId}/${crypto.randomUUID()}.docx`

      const { error: uploadError } = await supabase.storage
        .from(TEMPLATE_BUCKET)
        .upload(path, file, { contentType: DOCX_TYPE })

      if (uploadError) throw new Error(TEMPLATE_MESSAGES.uploadFailed)

      const { data, error } = await supabase
        .rpc('replace_document_template', {
          p_file_name: file.name,
          p_file_path: path,
        })
        .single()

      if (error) {
        // O arquivo subiu e não virou versão nenhuma: sem isto ele ficaria no
        // balde para sempre, e o que está guardado ali é documento oficial com
        // brasão de prefeitura.
        await supabase.storage.from(TEMPLATE_BUCKET).remove([path])
        throw new Error(TEMPLATE_MESSAGES.uploadFailed)
      }

      return data
    },
    onSuccess: () =>
      queryClient.invalidateQueries({ queryKey: TEMPLATE_QUERY_KEY }),
  })
}

/** Baixar o modelo vigente: o link é de uso único e vale um minuto. */
export function useTemplateDownload() {
  return useMutation({
    mutationFn: async (template: DocumentTemplate) => {
      const { data, error } = await supabase.storage
        .from(TEMPLATE_BUCKET)
        .createSignedUrl(template.file_path, LINK_SECONDS, {
          download: template.file_name,
        })

      if (error || !data) throw new Error(TEMPLATE_MESSAGES.downloadFailed)

      const anchor = window.document.createElement('a')
      anchor.href = data.signedUrl
      anchor.download = template.file_name
      anchor.rel = 'noopener'

      window.document.body.append(anchor)
      anchor.click()
      anchor.remove()
    },
  })
}
