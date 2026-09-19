import { useQuery } from '@tanstack/react-query'

import { supabase } from '@/lib/supabase'

import type { FoodItem } from './catalog'

/*
 * A leitura do catálogo. Sem filtro de escola: quem recorta é o RLS da E4,
 * pela escola de quem está logada (decisão 6 da E5).
 *
 * Só os ativos: o gênero desativado some das sugestões e continua nos
 * registros que já o usaram (CA#3 da US009).
 */

export const FOOD_ITEMS_QUERY_KEY = ['food-items'] as const

async function fetchFoodItems(): Promise<FoodItem[]> {
  const { data, error } = await supabase
    .from('food_item')
    .select('id, name, default_unit')
    .eq('active', true)
    .order('name')

  if (error) throw new Error(error.message)
  return data ?? []
}

export function useFoodItems() {
  return useQuery({
    queryKey: FOOD_ITEMS_QUERY_KEY,
    queryFn: fetchFoodItems,
    /*
     * O catálogo muda devagar — um gênero novo por semana, no máximo — e é
     * consultado no meio de um registro. Meia hora sem reconsultar poupa a
     * espera de quem abriu a folha para achar "Arroz" pela quinta vez.
     */
    staleTime: 30 * 60 * 1000,
  })
}
