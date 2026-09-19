import { normalizedName } from '@/local/day'

import { matchesSearch, type CatalogItem } from './catalog'

/*
 * A manutenção do catálogo — tela 4 (US009) — sem nada de React.
 *
 * A tela tem um formulário só: o cartão "Novo gênero" do desenho da E3 é o
 * mesmo que edita um gênero escolhido na lista. Quem decide em que estado ele
 * está é este rascunho, e é por isso que ele mora aqui e não dentro do
 * componente: o que decide se dá para salvar, se o nome já existe e se a
 * unidade mudou é regra, e regra se testa sem montar tela.
 */

export interface FoodItemDraft {
  /** Nulo é gênero novo; preenchido é o gênero da lista sendo editado. */
  id: string | null
  name: string
  unit: string
}

export const EMPTY_DRAFT: FoodItemDraft = { id: null, name: '', unit: '' }

/** O gênero escolhido na lista, carregado no cartão. */
export function draftOf(item: CatalogItem): FoodItemDraft {
  return { id: item.id, name: item.name, unit: item.default_unit }
}

/**
 * Nome e unidade são obrigatórios (CA#1 da US009) — e é só isso que o botão
 * espera. Nada aqui culpa quem está digitando: o botão fica apagado até haver
 * o que salvar, em vez de aceitar e depois reclamar (regra 1 da linguagem da
 * E3).
 */
export function canSave(draft: FoodItemDraft): boolean {
  return draft.name.trim() !== '' && draft.unit.trim() !== ''
}

/**
 * O gênero de mesmo nome que já está no catálogo, se houver.
 *
 * O banco tem o índice único por escola e nome normalizado (decisão 8 da E4),
 * então a gravação seria recusada de qualquer jeito. Achar aqui serve para
 * dizer o que aconteceu antes de tentar — e, quando o homônimo está
 * desativado, para dizer onde ele está, que é o caso em que a recusa do
 * servidor sozinha pareceria um erro sem explicação.
 */
export function duplicateOf(
  draft: FoodItemDraft,
  items: CatalogItem[]
): CatalogItem | null {
  const name = normalizedName(draft.name)

  return (
    items.find(
      (item) => item.id !== draft.id && normalizedName(item.name) === name
    ) ?? null
  )
}

/**
 * A unidade de um gênero que já existe está sendo trocada.
 *
 * Vale um aviso na tela porque a troca alcança o passado: `meal_food_item`
 * guarda a quantidade e o gênero, e a unidade é lida do catálogo — trocar
 * "pote" por "quilo" faz um dia já registrado passar a dizer "3 quilos de
 * manteiga", e sair assim no documento do mapa que ainda não foi gerado.
 */
export function unitChanged(
  draft: FoodItemDraft,
  items: CatalogItem[]
): boolean {
  if (draft.id === null) return false

  const stored = items.find((item) => item.id === draft.id)
  return stored !== undefined && stored.default_unit !== draft.unit.trim()
}

export interface CatalogSections {
  active: CatalogItem[]
  inactive: CatalogItem[]
}

/**
 * A lista da tela: os ativos em cima, os desativados na seção recolhida do pé.
 *
 * A busca (RNF#1 da US009) corta as duas — procurar um gênero que foi
 * desativado é justamente como se descobre que ele foi desativado.
 */
export function sections(
  items: CatalogItem[],
  search: string
): CatalogSections {
  const found = items.filter((item) => matchesSearch(item, search))

  return {
    active: found.filter((item) => item.active),
    inactive: found.filter((item) => !item.active),
  }
}
