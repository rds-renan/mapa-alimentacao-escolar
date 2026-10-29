import { normalizedName, type FoodItemPayload } from '@/local/day'

/*
 * O catálogo de gêneros da escola, do jeito que o registro do dia precisa
 * dele: uma lista para buscar e as unidades para sugerir.
 *
 * Mora fora de `day/` porque não é do dia — é o catálogo, e a tela de
 * manutenção (tela 4) lê pela mesma porta. O que é do dia é a folha que o
 * consulta sem tirar a merendeira do registro (decisão 7 da E3).
 */

export interface FoodItem {
  id: string
  name: string
  default_unit: string
}

/**
 * O mesmo gênero, como a tela de manutenção precisa vê-lo: com o desativado
 * junto.
 *
 * Quem registra o dia só enxerga os ativos — o desativado sumiu das sugestões
 * (CA#3 da US009) e nada mais precisa saber dele. Quem mantém o catálogo
 * precisa: desativar por engano tem de ter volta, e sem os desativados à vista
 * o erro seria irreversível pela interface.
 */
export interface CatalogItem extends FoodItem {
  active: boolean
}

/**
 * As unidades que a folha oferece ao cadastrar um gênero no meio do registro.
 *
 * A unidade é texto curto no banco e a lista **não** é fechada (decisão 8 da
 * E4) — mas quem abre o leque é a tela de manutenção do catálogo. Aqui, no
 * meio do registro, é um toque e nenhum teclado.
 *
 * São só "kg" e "un" desde a E7 (issue #175): é como vem na nota fiscal do
 * fornecedor, onde elas conferem o que recebem, e são as duas que usam.
 * Qualquer outra elas digitam no catálogo, que aceita texto livre.
 */
export const UNIT_SUGGESTIONS = ['kg', 'un'] as const

/*
 * A busca ignora acento e caixa: "feijao" acha "Feijão". Quem digita é quem
 * está com as duas mãos ocupadas na cozinha, e errar o til não pode custar o
 * resultado.
 */
function fold(text: string): string {
  return normalizedName(text)
    .normalize('NFD')
    .replace(/\p{Diacritic}/gu, '')
}

export function matchesSearch(item: FoodItem, search: string): boolean {
  return fold(item.name).includes(fold(search))
}

/** Os nomes normalizados de uma lista, como a folha os quer para marcá-los. */
export function chosenNames(items: FoodItemPayload[]): string[] {
  return items.map((item) => normalizedName(item.name))
}

/** Já está na refeição? A folha marca esses e não os oferece de novo. */
export function isAlreadyChosen(item: FoodItem, chosen: string[]): boolean {
  return chosen.includes(normalizedName(item.name))
}

/**
 * "3 kg de arroz" — a quantidade como o cartão do dia a resume.
 *
 * Sem plural desde a E7 (issue #175): a unidade sai como está no catálogo,
 * como na nota fiscal e no documento oficial. "kg" e "un" não têm plural, e o
 * "s" simples de antes daria "3 kgs".
 */
export function quantityLabel(quantity: number, unit: string | null): string {
  const one = (unit ?? '').trim()
  return one === '' ? String(quantity) : `${quantity} ${one}`
}
