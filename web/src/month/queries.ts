import { useEffect, useRef, useState } from 'react'
import { useQuery, useQueryClient } from '@tanstack/react-query'

import { supabase } from '@/lib/supabase'
import { useSync } from '@/local/useSync'

import {
  mergeDays,
  monthRange,
  recordFromDraft,
  type DayRecord,
  type MonthKey,
} from './month'

/*
 * De onde vêm os dias do mês.
 *
 * São duas origens e elas não se misturam, que é a fronteira da decisão 4 da
 * E5: o servidor é assunto da TanStack Query; o que ainda não subiu é assunto
 * da camada local. Esta é a primeira tela do projeto que lê do servidor, e
 * portanto onde a Query entra.
 */

/** O que o servidor precisa devolver para a tela decidir o estado de cada dia. */
const MONTH_COLUMNS =
  'map_date, non_school_day, note, meals_served, locked, meal (type, description, acceptance)'

export function monthQueryKey(month: MonthKey) {
  return ['month', month] as const
}

async function fetchMonth(month: MonthKey): Promise<DayRecord[]> {
  const { first, last } = monthRange(month)

  /*
   * Sem filtro de escola: quem recorta é o RLS da E4, pela escola de quem está
   * logada. Repetir o recorte aqui daria a impressão de que é ele que protege
   * — e não é (decisão 6 da E5).
   */
  const { data, error } = await supabase
    .from('meal_map')
    .select(MONTH_COLUMNS)
    .gte('map_date', first)
    .lte('map_date', last)
    .order('map_date')

  if (error) throw new Error(error.message)

  return (data ?? []).map((row) => ({
    mapDate: row.map_date,
    nonSchoolDay: row.non_school_day,
    note: row.note,
    mealsServed: row.meals_served,
    locked: row.locked,
    meals: row.meal.map((meal) => ({
      type: meal.type,
      description: meal.description,
      acceptance: meal.acceptance,
    })),
    pendingUpload: false,
  }))
}

/** Os rascunhos do mês, relidos do aparelho sempre que a fila se mexe. */
function useMonthDrafts(month: MonthKey): DayRecord[] {
  const { state, pendingDays } = useSync()
  const [drafts, setDrafts] = useState<DayRecord[]>([])

  /*
   * `state.days` muda a cada gravação e `state.pending` a cada confirmação:
   * juntos, são exatamente os dois momentos em que o que está no aparelho
   * deixa de ser o que esta tela mostra.
   */
  const touched = state.days
  const pending = state.pending

  useEffect(() => {
    let active = true

    void pendingDays(month).then((days) => {
      if (active) setDrafts(days.map(recordFromDraft))
    })

    return () => {
      active = false
    }
  }, [month, pendingDays, touched, pending])

  return drafts
}

export interface MonthData {
  byDate: Map<string, DayRecord>
  loading: boolean
  /** A lista não veio do servidor. Na web isso é falta de rede (decisão 2 da E5). */
  failed: boolean
  /** Dias guardados no aparelho, esperando envio — o que a falha não levou. */
  pending: number
  retry(): void
}

export function useMonth(month: MonthKey): MonthData {
  const queryClient = useQueryClient()
  const { state } = useSync()
  const drafts = useMonthDrafts(month)

  const maps = useQuery({
    queryKey: monthQueryKey(month),
    queryFn: () => fetchMonth(month),
  })

  /*
   * A fila confirmou alguma coisa: o que o servidor tem agora é diferente do
   * que esta tela leu. Invalidar todos os meses, e não só o aberto, porque a
   * fila pode ter subido um dia de outro mês enquanto ela olhava este.
   */
  const settled = useRef(state.pending)
  useEffect(() => {
    if (state.pending < settled.current) {
      void queryClient.invalidateQueries({ queryKey: ['month'] })
    }
    settled.current = state.pending
  }, [state.pending, queryClient])

  return {
    byDate: mergeDays(maps.data ?? [], drafts),
    loading: maps.isPending,
    failed: maps.isError,
    pending: state.pending,
    retry: () => void maps.refetch(),
  }
}
