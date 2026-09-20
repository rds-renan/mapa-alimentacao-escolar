import {
  useMutation,
  useMutationState,
  useQueryClient,
} from '@tanstack/react-query'

import { supabase } from '@/lib/supabase'

import { FAILURE_MESSAGES } from './messages'

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
