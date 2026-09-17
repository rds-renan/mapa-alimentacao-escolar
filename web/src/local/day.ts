import type { Database } from '@/lib/database.types'

/*
 * O dia como ele sobe.
 *
 * Esta forma não é uma invenção do cliente: é, campo por campo, o payload de
 * `save_meal_map` descrito em docs/05-web/gravacao-do-dia.md. O rascunho local
 * guarda exatamente isto, e é essa igualdade que torna a fila simples — enviar
 * é pegar o rascunho e mandar, sem tradução no meio que possa divergir do
 * contrato do servidor.
 *
 * Por isso os nomes aqui são os do banco, em snake_case, e não os do
 * TypeScript: quem manda na forma é a função do servidor.
 */

export type MealType = Database['public']['Enums']['meal_type']
export type AcceptanceLevel = Database['public']['Enums']['acceptance_level']

export interface FoodItemPayload {
  /** O gênero do catálogo, quando ele já existe. Nulo é gênero a nascer. */
  food_item_id: string | null
  name: string
  /** Só é exigido pelo servidor quando o gênero vai nascer. */
  unit: string | null
  quantity: number
}

export interface MenuChangePayload {
  id: string
  reason: string
  food_items: FoodItemPayload[]
}

export interface MealPayload {
  id: string
  type: MealType
  /** O cardápio previsto — continua sendo ele mesmo quando houve troca. */
  description: string | null
  acceptance: AcceptanceLevel | null
  food_items: FoodItemPayload[]
  menu_change: MenuChangePayload | null
}

export interface DayPayload {
  /** UUID gerado no aparelho. O servidor pode devolver outro, e vale o dele. */
  id: string
  /** A data do dia, em AAAA-MM-DD. É ela que identifica o dia. */
  map_date: string
  /** Quando a merendeira mexeu, no relógio do aparelho — não quando chegou. */
  updated_at: string
  non_school_day: boolean
  note: string | null
  meals_served: number | null
  meals: MealPayload[]
}

/** O que `save_meal_map` devolve. O contrato inteiro está na doc da gravação. */
export interface SaveResponse {
  status: 'saved' | 'superseded'
  meal_map_id: string
  sent_meal_map_id: string | null
  map_date: string
  locked: boolean
  updated_at: string
  updated_by: string | null
  food_items: {
    sent_id: string | null
    id: string
    name: string
    unit: string
    created: boolean
  }[]
}

export function newId(): string {
  return crypto.randomUUID()
}

/** Um dia em branco, pronto para a primeira tecla. */
export function emptyDay(mapDate: string): DayPayload {
  return {
    id: newId(),
    map_date: mapDate,
    updated_at: new Date().toISOString(),
    non_school_day: false,
    note: null,
    meals_served: null,
    meals: [],
  }
}

/*
 * A mesma normalização que o servidor usa para decidir se dois nomes são o
 * mesmo gênero. Aqui ela serve só para adotar o identificador que voltou; se
 * errar, o pior que acontece é o servidor resolver pelo nome de novo no envio
 * seguinte.
 */
function normalizedName(name: string): string {
  return name.trim().toLowerCase().replace(/\s+/g, ' ')
}

/*
 * Adota o que o servidor devolveu.
 *
 * O contrato é explícito: o cliente precisa assumir o `meal_map_id` e os
 * identificadores de gênero que voltaram, porque são eles que fazem o próximo
 * envio encontrar o registro em vez de tentar criá-lo de novo. Dois aparelhos
 * podem ter criado o mesmo dia offline, cada um com o seu UUID — quem vale é o
 * que já estava no servidor.
 */
export function adoptServerIds(
  day: DayPayload,
  response: SaveResponse
): DayPayload {
  const bySentId = new Map<string, string>()
  const byName = new Map<string, string>()

  for (const item of response.food_items) {
    if (item.sent_id) bySentId.set(item.sent_id, item.id)
    // O gênero que nasceu agora não tem `sent_id`: o nome é o que o liga à
    // linha que o aparelho mandou.
    byName.set(normalizedName(item.name), item.id)
  }

  const adoptItem = (item: FoodItemPayload): FoodItemPayload => {
    const resolved =
      (item.food_item_id ? bySentId.get(item.food_item_id) : undefined) ??
      byName.get(normalizedName(item.name))

    return resolved ? { ...item, food_item_id: resolved } : item
  }

  return {
    ...day,
    id: response.meal_map_id,
    meals: day.meals.map((meal) => ({
      ...meal,
      food_items: meal.food_items.map(adoptItem),
      menu_change: meal.menu_change
        ? {
            ...meal.menu_change,
            food_items: meal.menu_change.food_items.map(adoptItem),
          }
        : null,
    })),
  }
}
