import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'

import { supabase } from '@/lib/supabase'

import { ADMIN_MESSAGES, REOPEN_MESSAGES } from './messages'

/*
 * A leitura e a escrita da tela Mapas (US023).
 *
 * **Esta issue não tem migration**, e é o fato mais importante do arquivo: a
 * E4 já havia posto a porta no banco — `unlock_meal_map()` exige direção,
 * exige justificativa, grava a linha em `meal_map_unlock` e desbloqueia o mapa
 * na mesma transação — e o que faltava era quem a abrisse. Nada aqui reimplementa
 * essas regras, porque elas não estão aqui: reimplementá-las no navegador
 * criaria uma segunda régua, livre para divergir da que decide de verdade.
 *
 * Sem filtro de escola em lugar nenhum: quem recorta é o RLS (decisão 6 da E5).
 * O histórico é legível pelos dois perfis e não tem política de escrita — quem
 * grava é a função, e é assim que ele é permanente (RNF#1 da US023).
 */

// ---------------------------------------------------------------------------
// Os dias que saíram em documento
// ---------------------------------------------------------------------------

/*
 * O documento vem junto, e em dois níveis: é dele que a linha tira o "no
 * documento de 30/09" — a informação que explica o bloqueio a quem está
 * olhando. Um mapa pode estar em mais de um documento (a regeração depois de
 * uma correção), então o que a tela mostra é o mais recente.
 */
const LOCKED_MAPS_COLUMNS =
  'id, map_date, document_meal_map (generated_document (id, requested_at, completed_at))'

/**
 * Quantos dias bloqueados a lista mostra.
 *
 * Uma escola bloqueia cerca de vinte dias por mês, e a correção aparece dias
 * depois da geração — não meses. Sessenta cobre o trimestre corrente e o
 * anterior, e a tela diz que o corte existe em vez de parecer completa.
 */
export const RECENT_LOCKED = 60

export interface LockedMap {
  id: string
  mapDate: string
  /** Quando saiu o documento mais recente que o inclui. Nulo se não se sabe. */
  generatedAt: string | null
}

export const LOCKED_MAPS_QUERY_KEY = ['admin', 'locked-maps'] as const

interface LockedMapRow {
  id: string
  map_date: string
  document_meal_map: {
    generated_document: {
      id: string
      requested_at: string
      completed_at: string | null
    } | null
  }[]
}

/** A geração mais recente entre as que incluem o mapa. */
function latestGeneration(row: LockedMapRow): string | null {
  const stamps = row.document_meal_map
    .map((link) => link.generated_document)
    .filter((document): document is NonNullable<typeof document> => !!document)
    .map((document) => document.completed_at ?? document.requested_at)
    .sort()

  return stamps.length === 0 ? null : stamps[stamps.length - 1]
}

async function fetchLockedMaps(): Promise<LockedMap[]> {
  const { data, error } = await supabase
    .from('meal_map')
    .select(LOCKED_MAPS_COLUMNS)
    .eq('locked', true)
    .order('map_date', { ascending: false })
    .limit(RECENT_LOCKED)

  if (error) throw new Error(error.message)

  return ((data ?? []) as unknown as LockedMapRow[]).map((row) => ({
    id: row.id,
    mapDate: row.map_date,
    generatedAt: latestGeneration(row),
  }))
}

export function useLockedMaps() {
  return useQuery({
    queryKey: LOCKED_MAPS_QUERY_KEY,
    queryFn: fetchLockedMaps,
  })
}

// ---------------------------------------------------------------------------
// O histórico de reaberturas
// ---------------------------------------------------------------------------

const UNLOCKS_COLUMNS =
  'id, unlocked_at, reason, meal_map (map_date), profile (name)'

/**
 * Quantas reaberturas a tela mostra.
 *
 * O registro é permanente e a tabela só cresce; a tela, não — é o mesmo corte
 * da lista de documentos gerados, e pelo mesmo motivo. Cinquenta reaberturas é
 * muito mais do que uma escola que corrige mapa "raramente" vai acumular na
 * vida útil do sistema.
 */
const RECENT_UNLOCKS = 50

export interface MapUnlock {
  id: string
  mapDate: string
  unlockedAt: string
  unlockedBy: string
  reason: string
}

export const UNLOCKS_QUERY_KEY = ['admin', 'map-unlocks'] as const

interface UnlockRow {
  id: string
  unlocked_at: string
  reason: string
  meal_map: { map_date: string } | null
  profile: { name: string } | null
}

async function fetchUnlocks(): Promise<MapUnlock[]> {
  const { data, error } = await supabase
    .from('meal_map_unlock')
    .select(UNLOCKS_COLUMNS)
    .order('unlocked_at', { ascending: false })
    .limit(RECENT_UNLOCKS)

  if (error) throw new Error(error.message)

  return ((data ?? []) as unknown as UnlockRow[]).map((row) => ({
    id: row.id,
    mapDate: row.meal_map?.map_date ?? '',
    unlockedAt: row.unlocked_at,
    /*
     * Quem reabriu continua na lista mesmo depois de perder o acesso: a linha
     * de `profile` nunca é apagada, e é justamente para a autoria não evaporar
     * (decisão 2 da E4). O nome vazio é só a defesa contra um vínculo que o
     * RLS não devolveu.
     */
    unlockedBy: row.profile?.name ?? ADMIN_MESSAGES.role,
    reason: row.reason,
  }))
}

export function useMapUnlocks() {
  return useQuery({ queryKey: UNLOCKS_QUERY_KEY, queryFn: fetchUnlocks })
}

// ---------------------------------------------------------------------------
// Reabrir
// ---------------------------------------------------------------------------

export interface ReopenRequest {
  mapId: string
  reason: string
}

/**
 * A recusa, como ela chega na tela.
 *
 * A função do banco escreve as frases dela em português e para quem vai lê-las
 * — "A reabertura precisa de uma justificativa.", "Este mapa não está
 * bloqueado." —, então o que a tela faz é entregá-las, e não traduzi-las. O que
 * separa os dois casos é o código: erro do Postgres tem um; rede que não chegou
 * a virar resposta, não — e aí vale a frase escrita para a internet da escola.
 */
function refusal(error: { code?: string; message: string }): string {
  return error.code && error.message ? error.message : REOPEN_MESSAGES.failed
}

export function useReopenMap() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: async ({ mapId, reason }: ReopenRequest) => {
      const { data, error } = await supabase
        .rpc('unlock_meal_map', {
          map_id: mapId,
          unlock_reason: reason.trim(),
        })
        .single()

      if (error) throw new Error(refusal(error))
      return data
    },
    /*
     * Reabriu: o dia sai da lista dos bloqueados e entra no histórico. As duas
     * leituras mudaram na mesma chamada, e as duas estão na tela.
     */
    onSuccess: () => {
      void queryClient.invalidateQueries({ queryKey: LOCKED_MAPS_QUERY_KEY })
      void queryClient.invalidateQueries({ queryKey: UNLOCKS_QUERY_KEY })
    },
  })
}
