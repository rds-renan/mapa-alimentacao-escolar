import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'

import { supabase } from '@/lib/supabase'

import type { CatalogItem, FoodItem } from './catalog'

/*
 * A leitura e a escrita do catálogo. Sem filtro de escola: quem recorta é o
 * RLS da E4, pela escola de quem está logada (decisão 6 da E5).
 *
 * São duas leituras, e a diferença entre elas é o CA#3 da US009: quem registra
 * o dia vê só os ativos — o desativado sumiu das sugestões —, e quem mantém o
 * catálogo vê os dois, porque desativar por engano precisa ter volta.
 *
 * As duas chaves nascem da mesma raiz de propósito: invalidar `['food-items']`
 * alcança as duas, e é isso que a fila do dia já faz quando `save_meal_map`
 * cria um gênero no servidor.
 */

const COLUMNS = 'id, name, default_unit'

export const FOOD_ITEMS_QUERY_KEY = ['food-items'] as const

const ACTIVE_QUERY_KEY = [...FOOD_ITEMS_QUERY_KEY, 'active'] as const
const CATALOG_QUERY_KEY = [...FOOD_ITEMS_QUERY_KEY, 'all'] as const

async function fetchActive(): Promise<FoodItem[]> {
  const { data, error } = await supabase
    .from('food_item')
    .select(COLUMNS)
    .eq('active', true)
    .order('name')

  if (error) throw new Error(error.message)
  return data ?? []
}

async function fetchCatalog(): Promise<CatalogItem[]> {
  const { data, error } = await supabase
    .from('food_item')
    .select(`${COLUMNS}, active`)
    .order('name')

  if (error) throw new Error(error.message)
  return data ?? []
}

export function useFoodItems() {
  return useQuery({
    queryKey: ACTIVE_QUERY_KEY,
    queryFn: fetchActive,
    /*
     * O catálogo muda devagar — um gênero novo por semana, no máximo — e é
     * consultado no meio de um registro. Meia hora sem reconsultar poupa a
     * espera de quem abriu a folha para achar "Arroz" pela quinta vez.
     */
    staleTime: 30 * 60 * 1000,
  })
}

/**
 * O catálogo inteiro, para a tela de manutenção.
 *
 * Sem o `staleTime` da folha 3b: quem está nesta tela veio para mexer no
 * catálogo, e as duas merendeiras mexem nele do mesmo jeito. Meia hora de
 * atraso aqui é meia hora editando uma lista que já mudou.
 */
export function useCatalog() {
  return useQuery({ queryKey: CATALOG_QUERY_KEY, queryFn: fetchCatalog })
}

export interface SaveFoodItem {
  /** Nulo cadastra; preenchido edita o que já existe. */
  id: string | null
  name: string
  unit: string
}

/*
 * A gravação vai direto ao servidor, sem passar pela fila do aparelho. É a
 * decisão 2 da E5 aplicada: a fila existe para o mapa do dia, que é o que não
 * pode se perder; a manutenção do catálogo é tarefa ocasional, feita de
 * propósito, e quem a faz sem rede pode refazer com rede. O gênero que nasce
 * no meio de um registro — esse sim — continua subindo pela fila, dentro do
 * dia.
 */
async function saveFoodItem(
  schoolId: string,
  item: SaveFoodItem
): Promise<CatalogItem> {
  const values = { name: item.name.trim(), default_unit: item.unit.trim() }

  const query =
    item.id === null
      ? supabase.from('food_item').insert({ school_id: schoolId, ...values })
      : supabase.from('food_item').update(values).eq('id', item.id)

  const { data, error } = await query.select(`${COLUMNS}, active`).single()

  if (error) throw new Error(error.message)
  return data
}

async function setActive(id: string, active: boolean): Promise<CatalogItem> {
  const { data, error } = await supabase
    .from('food_item')
    .update({ active })
    .eq('id', id)
    .select(`${COLUMNS}, active`)
    .single()

  if (error) throw new Error(error.message)
  return data
}

/**
 * Cadastrar, editar, desativar e reativar — as quatro escritas da tela 4.
 *
 * Todas invalidam a raiz do catálogo: a folha 3b do registro lê a outra chave,
 * e o gênero desativado tem de sumir de lá sem que a merendeira precise
 * recarregar nada.
 */
export function useCatalogMutations(schoolId: string | undefined) {
  const queryClient = useQueryClient()

  const invalidate = () =>
    queryClient.invalidateQueries({ queryKey: FOOD_ITEMS_QUERY_KEY })

  const save = useMutation({
    mutationFn: (item: SaveFoodItem) => {
      // Sem perfil não há escola, e sem escola o RLS recusaria a linha de
      // qualquer jeito. A guarda de rota já garante que não se chega aqui.
      if (schoolId === undefined) throw new Error('sem escola')
      return saveFoodItem(schoolId, item)
    },
    onSuccess: invalidate,
  })

  const toggle = useMutation({
    mutationFn: ({ id, active }: { id: string; active: boolean }) =>
      setActive(id, active),
    onSuccess: invalidate,
  })

  return { save, toggle }
}
