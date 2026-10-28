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
  /** Os gêneros utilizados no dia — do dia, não da refeição (decisão 14 da E4). */
  food_items: FoodItemPayload[]
  /** A alteração do cardápio, no máximo uma por dia. */
  menu_change: MenuChangePayload | null
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

/**
 * As três refeições do dia letivo, na ordem em que acontecem (RN#1 da US001).
 * Mora aqui, junto do tipo, porque é a ordem do dia — a tela do registro
 * desenha os cartões por ela e a visão do mês confere o que falta pela mesma.
 */
export const MEAL_ORDER: MealType[] = [
  'morning_snack',
  'lunch',
  'afternoon_snack',
]

/**
 * O dia está em condição de subir?
 *
 * Não é validação de formulário — é a pergunta de se o servidor aceitaria este
 * payload. A tela grava cada tecla no aparelho (CA#2 da US010), e a fila leva
 * só o que não vai voltar recusado: entre marcar "dia não letivo" e escrever o
 * motivo passam alguns segundos, e nesse intervalo o dia está guardado, não
 * debaixo de uma faixa dizendo que não deu para enviar.
 *
 * São duas dobras, e as duas têm a mesma forma: o meio do caminho de um
 * preenchimento que o servidor só aceita inteiro. A do dia não letivo exige a
 * observação e proíbe refeições e gêneros; a da alteração do cardápio exige o
 * motivo e ao menos um gênero. Todas estão na tabela de erros da gravação do
 * dia.
 *
 * A refeição em si nunca impede o envio — descrição e aceitação nulas são o
 * registro parcial, de propósito (CA#3 da US001).
 */
export function canBeSent(day: DayPayload): boolean {
  if (day.non_school_day) {
    return (
      notBlank(day.note) &&
      day.meals.length === 0 &&
      day.food_items.length === 0 &&
      day.menu_change === null
    )
  }

  if (!day.food_items.every(itemCanBeSent)) return false
  if (!day.menu_change) return true

  return (
    notBlank(day.menu_change.reason) &&
    day.menu_change.food_items.length > 0 &&
    day.menu_change.food_items.every(itemCanBeSent)
  )
}

function notBlank(text: string | null): boolean {
  return text !== null && text.trim() !== ''
}

/*
 * A quantidade é inteira e maior que zero (RN#1 da US003), e o gênero que
 * ainda não está no catálogo precisa da unidade com que vai nascer — o
 * catálogo manda na unidade de quem já existe, e não aceita item sem ela.
 */
function itemCanBeSent(item: FoodItemPayload): boolean {
  if (!Number.isInteger(item.quantity) || item.quantity <= 0) return false

  return item.food_item_id !== null || notBlank(item.unit)
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
    food_items: [],
    menu_change: null,
  }
}

/*
 * A mesma normalização que o servidor usa para decidir se dois nomes são o
 * mesmo gênero. Serve para adotar o identificador que voltou — se errar, o
 * pior que acontece é o servidor resolver pelo nome de novo no envio seguinte
 * — e para a tela não pôr o mesmo gênero duas vezes na mesma lista, que é
 * exatamente o que o servidor fundiria numa linha só.
 */
export function normalizedName(name: string): string {
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
    food_items: day.food_items.map(adoptItem),
    menu_change: day.menu_change
      ? {
          ...day.menu_change,
          food_items: day.menu_change.food_items.map(adoptItem),
        }
      : null,
  }
}

/** O dia como era guardado antes da decisão 14: os gêneros em cada refeição. */
interface LegacyMeal extends MealPayload {
  food_items?: FoodItemPayload[]
  menu_change?: MenuChangePayload | null
}

/*
 * Soma por nome normalizado, que é como o servidor decide que dois gêneros
 * são o mesmo; a unidade é do catálogo, então somar é sempre somar a mesma
 * coisa. Entre as duas linhas, fica a que já conhece o gênero do catálogo.
 */
function sumByName(items: FoodItemPayload[]): FoodItemPayload[] {
  const byName = new Map<string, FoodItemPayload>()
  for (const item of items) {
    const key = normalizedName(item.name)
    const running = byName.get(key)
    if (!running) {
      byName.set(key, item)
      continue
    }
    const kept = running.food_item_id ? running : item
    byName.set(key, { ...kept, quantity: running.quantity + item.quantity })
  }
  return [...byName.values()]
}

/**
 * Traz para o formato de hoje um dia guardado no aparelho antes da decisão 14
 * da E4 — rascunho ou fila. É a mesma junção da migration
 * `20261028120000_generos_do_dia.sql`: os gêneros das refeições viram os do
 * dia, somando o que se repete, e as alterações viram uma, com as
 * justificativas na ordem das refeições. O dia que já está no formato novo
 * atravessa intacto.
 */
export function upgradeDay(stored: DayPayload): DayPayload {
  const meals = stored.meals as LegacyMeal[]
  const legacy = meals.some(
    (meal) => meal.food_items !== undefined || meal.menu_change !== undefined
  )
  if (!legacy && stored.food_items !== undefined) return stored

  const ordered = [...meals].sort(
    (a, b) => MEAL_ORDER.indexOf(a.type) - MEAL_ORDER.indexOf(b.type)
  )
  const changes = ordered
    .map((meal) => meal.menu_change ?? null)
    .filter((change): change is MenuChangePayload => change !== null)

  return {
    ...stored,
    meals: meals.map(({ id, type, description, acceptance }) => ({
      id,
      type,
      description,
      acceptance,
    })),
    food_items: sumByName([
      ...(stored.food_items ?? []),
      ...ordered.flatMap((meal) => meal.food_items ?? []),
    ]),
    menu_change:
      changes.length === 0
        ? (stored.menu_change ?? null)
        : {
            id: changes[0].id,
            reason: changes
              .map((change) => change.reason.trim())
              .filter((reason) => reason !== '')
              .join(' / '),
            food_items: sumByName(changes.flatMap((c) => c.food_items)),
          },
  }
}
