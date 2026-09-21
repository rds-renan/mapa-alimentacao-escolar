import { useMemo } from 'react'
import { useQuery } from '@tanstack/react-query'

import type { MealType } from '@/local/day'
import type { MonthKey } from '@/month/month'
import { fetchMonth, monthQueryKey } from '@/month/queries'

import {
  acceptanceByMeal,
  monthSummary,
  topMeals,
  type MealAcceptance,
  type MonthSummary,
  type TopMeal,
} from './dashboard'

/*
 * A leitura do painel (US017).
 *
 * **Uma consulta só, e ela já existia**: os dias do mês, os mesmos que a visão
 * do mês da merendeira lê. O painel não tem consulta própria, não tem view e
 * não tem função no banco — a agregação acontece aqui, no navegador, sobre as
 * vinte e poucas linhas de um mês. Uma view agregada pareceria mais séria e
 * não seria: seria uma segunda definição de "mês", livre para divergir da que
 * as telas da merendeira usam, para poupar uma soma de sessenta números.
 *
 * O teto é o RNF#1 — cinco segundos —, e o que se mede é a ida ao servidor: um
 * mês inteiro sai do Supabase em algumas centenas de milissegundos, e somar as
 * linhas depois disso é tempo de quadro de vídeo, não de espera.
 *
 * A chave da consulta é a mesma da visão do mês, de propósito: é o mesmo dado,
 * na mesma forma, e duas chaves para ele só fariam o cache guardá-lo duas
 * vezes. Ninguém abre as duas telas na mesma sessão — a direção não registra
 * mapa, e as guardas de rota garantem isso —, mas o cache não precisa saber
 * disso para estar certo.
 *
 * Nada aqui escreve. O painel é leitura agregada (RN#1 da US017), e é por isso
 * que não há uma única mutação neste arquivo.
 */

export interface DashboardData {
  summary: MonthSummary
  acceptance: Record<MealType, MealAcceptance>
  top: TopMeal[]
  /** O mês não tem dia registrado nenhum — nem letivo, nem não letivo. */
  empty: boolean
  loading: boolean
  /** Não veio do servidor. Na web isso é falta de rede (decisão 2 da E5). */
  failed: boolean
  retry(): void
}

export function useDashboard(month: MonthKey): DashboardData {
  const maps = useQuery({
    queryKey: monthQueryKey(month),
    queryFn: () => fetchMonth(month),
  })

  const days = useMemo(() => maps.data ?? [], [maps.data])

  const aggregated = useMemo(() => {
    const byDate = new Map(days.map((day) => [day.mapDate, day]))

    return {
      summary: monthSummary(month, byDate),
      acceptance: acceptanceByMeal(days),
      top: topMeals(days),
    }
  }, [month, days])

  return {
    ...aggregated,
    empty: days.length === 0,
    loading: maps.isPending,
    failed: maps.isError,
    retry: () => void maps.refetch(),
  }
}
