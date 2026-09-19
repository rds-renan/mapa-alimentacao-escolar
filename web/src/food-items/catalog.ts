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
 * E4) — mas quem abre o leque é a tela de manutenção do catálogo. Aqui,
 * no meio de uma refeição, são seis toques e nenhum teclado: é o desenho da
 * tela 3b, e é o que faz o pior caso (o gênero não existe) caber em dois
 * gestos.
 */
export const UNIT_SUGGESTIONS = [
  'quilo',
  'saco',
  'pote',
  'litro',
  'lata',
  'unidade',
] as const

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
 * "3 bandejas de ovo" — a quantidade como o cartão da refeição a resume.
 *
 * O plural é o "s" simples, e é uma aproximação assumida: as seis unidades
 * sugeridas pluralizam assim, e uma unidade esquisita vinda do catálogo sai
 * com um "s" a mais em vez de sair errada de gênero. O documento oficial não
 * passa por aqui — lá o formato é "N unidade" (CA#3 da US003).
 */
export function quantityLabel(quantity: number, unit: string | null): string {
  const one = (unit ?? '').trim()
  if (one === '') return String(quantity)

  const many = quantity > 1 && !one.endsWith('s') ? `${one}s` : one
  return `${quantity} ${many}`
}
