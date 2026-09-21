import { useEffect, useMemo, useRef } from 'react'
import { useQuery, useQueryClient } from '@tanstack/react-query'

import { FOOD_ITEMS_QUERY_KEY } from '@/food-items/queries'
import { supabase } from '@/lib/supabase'
import {
  emptyDay,
  type DayPayload,
  type FoodItemPayload,
  type MealPayload,
} from '@/local/day'
import type { DaySyncState } from '@/local/sync'
import { useDayDraft } from '@/local/useDayDraft'
import { useSync } from '@/local/useSync'

import { touch } from './register'

/*
 * De onde vem o dia que a tela abre.
 *
 * São as mesmas duas origens da visão do mês, com a mesma fronteira (decisão 4
 * da E5): o rascunho guardado no aparelho, quando existe, e o servidor quando
 * não existe. Vale o rascunho — ele só está guardado enquanto o servidor não
 * confirmou, então é mais novo por construção.
 *
 * A consulta traz o dia **inteiro**, com os gêneros e a alteração do cardápio
 * dentro: o que sobe em `save_meal_map` é o dia todo, e o que não vier deixa
 * de existir — ler pela metade faria uma correção de descrição apagar em
 * silêncio os gêneros que a colega registrou.
 */

/*
 * Numa linha só, e sem juntar pedaços com `+`: os tipos da consulta saem do
 * texto literal do `select`, e um texto montado vira `string` — aí a resposta
 * inteira perde o tipo e volta como erro genérico.
 */
const DAY_COLUMNS =
  'id, map_date, updated_at, non_school_day, note, meals_served, locked, meal_map_unlock (unlocked_at), meal (id, type, description, acceptance, meal_food_item (food_item_id, quantity, food_item (name, default_unit)), menu_change (id, reason, menu_change_food_item (food_item_id, quantity, food_item (name, default_unit))))'

export function dayQueryKey(mapDate: string) {
  return ['day', mapDate] as const
}

/** O dia como o servidor o tem, mais os dois fatos que só ele conhece. */
interface ServerDay {
  day: DayPayload
  locked: boolean
  /** Reaberto pela direção e ainda fora de documento (CA#2 da US023). */
  reopened: boolean
}

/** Uma linha de gênero, do jeito que o payload a quer: com nome e unidade. */
function itemFromRow(row: {
  food_item_id: string
  quantity: number
  food_item: { name: string; default_unit: string } | null
}): FoodItemPayload {
  return {
    food_item_id: row.food_item_id,
    name: row.food_item?.name ?? '',
    unit: row.food_item?.default_unit ?? null,
    quantity: row.quantity,
  }
}

async function fetchDay(mapDate: string): Promise<ServerDay | null> {
  /*
   * Sem filtro de escola: quem recorta é o RLS da E4, pela escola de quem está
   * logada. Repetir o recorte aqui daria a impressão de que é ele que protege
   * — e não é (decisão 6 da E5).
   */
  const { data, error } = await supabase
    .from('meal_map')
    .select(DAY_COLUMNS)
    .eq('map_date', mapDate)
    .maybeSingle()

  if (error) throw new Error(error.message)
  if (!data) return null

  const meals: MealPayload[] = data.meal.map((meal) => ({
    id: meal.id,
    type: meal.type,
    description: meal.description,
    acceptance: meal.acceptance,
    food_items: meal.meal_food_item.map(itemFromRow),
    menu_change: meal.menu_change
      ? {
          id: meal.menu_change.id,
          reason: meal.menu_change.reason,
          food_items: meal.menu_change.menu_change_food_item.map(itemFromRow),
        }
      : null,
  }))

  return {
    locked: data.locked,
    reopened: !data.locked && data.meal_map_unlock.length > 0,
    day: {
      id: data.id,
      map_date: data.map_date,
      updated_at: data.updated_at,
      non_school_day: data.non_school_day,
      note: data.note,
      meals_served: data.meals_served,
      meals,
    },
  }
}

export interface DayData {
  /** O dia em edição. Nulo enquanto carrega, ou quando a leitura falhou. */
  day: DayPayload | null
  /** Já saiu em documento gerado: a tela abre só para consulta (RN#1 da US007). */
  locked: boolean
  /**
   * A direção reabriu este dia para correção (CA#2 da US023).
   *
   * É a leitura do servidor que sabe disso, e não o rascunho: a reabertura
   * acontece em outro navegador, e enquanto a leitura não vier a tela não tem
   * como saber dela. Não muda o que ela pode fazer — o dia reaberto é um dia
   * comum, editável —, muda o que ela precisa saber ao abri-lo.
   */
  reopened: boolean
  loading: boolean
  /** Nem o servidor respondeu nem há rascunho — não há dia para editar. */
  failed: boolean
  status: DaySyncState | null
  retry(): void
  /** Grava a mudança no aparelho. É o autosave: não existe botão de salvar. */
  change(day: DayPayload): void
}

export function useDay(mapDate: string): DayData {
  const queryClient = useQueryClient()
  const { state } = useSync()
  const {
    draft,
    loading: draftLoading,
    status,
    update,
    reload,
  } = useDayDraft(mapDate)

  const server = useQuery({
    queryKey: dayQueryKey(mapDate),
    queryFn: () => fetchDay(mapDate),
  })

  /*
   * A fila confirmou alguma coisa: o que o servidor tem agora é diferente do
   * que esta tela leu. Invalidar todos os dias, e não só o aberto, porque a
   * fila pode ter subido outro dia enquanto ela olhava este.
   *
   * O catálogo vai junto: o gênero cadastrado no meio do registro só nasce
   * quando o dia sobe (`save_meal_map` cria o que ainda não existir), e sem
   * isto ele ficaria fora da busca da folha até a próxima meia hora.
   */
  const settled = useRef(state.pending)
  useEffect(() => {
    if (state.pending < settled.current) {
      void queryClient.invalidateQueries({ queryKey: ['day'] })
      void queryClient.invalidateQueries({ queryKey: FOOD_ITEMS_QUERY_KEY })
    }
    settled.current = state.pending
  }, [state.pending, queryClient])

  /*
   * A edição dela perdeu a convergência: o rascunho saiu do aparelho e o que
   * vale é o dia do servidor. A tela ainda está com o texto antigo na mão, e
   * "confira se está como você deixou" só faz sentido depois de reler os dois
   * lados. O aviso de que isso aconteceu é do `ConflictNotice`.
   */
  const conflictAt =
    state.conflicts.find((one) => one.mapDate === mapDate)?.updatedAt ?? null

  useEffect(() => {
    if (!conflictAt) return
    reload()
    void queryClient.invalidateQueries({ queryKey: dayQueryKey(mapDate) })
  }, [conflictAt, mapDate, reload, queryClient])

  /*
   * O dia que o servidor não tem é um dia em branco — e ele nasce uma vez só:
   * refazê-lo a cada desenho da tela trocaria o identificador do mapa no meio
   * da digitação.
   */
  const fromServer = useMemo(() => {
    if (server.data) return server.data.day
    return server.isSuccess ? emptyDay(mapDate) : null
  }, [server.data, server.isSuccess, mapDate])

  return {
    day: draft ?? fromServer,
    locked: server.data?.locked ?? false,
    reopened: server.data?.reopened ?? false,
    loading: draftLoading || (draft === null && server.isPending),
    failed: !draftLoading && draft === null && server.isError,
    status,
    retry: () => void server.refetch(),
    change: (day) => void update(touch(day)),
  }
}
