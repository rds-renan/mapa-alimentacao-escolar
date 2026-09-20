// Do banco para o preenchimento.
//
// O que o preenchedor recebe (`DocumentData`) é o mapa como o documento o
// mostra; o que o banco guarda é o mapa como a merendeira o registrou. A
// tradução entre os dois está aqui, separada da borda HTTP de propósito: é a
// parte que tem regra e, por isso, a parte que tem teste.

import type {
  Acceptance,
  DocumentData,
  FoodItemAmount,
  Meal,
  MealKind,
  MealMap,
  MenuChange,
} from "../_shared/dados.ts";

/**
 * A ordem em que as refeições aparecem no documento. O preenchimento acha cada
 * linha pelo rótulo, então ela não decide onde a refeição cai — decide a ordem
 * das colunas que listam **várias**: os gêneros da troca e a justificativa,
 * montados na ordem desta lista.
 */
const MEAL_ORDER: MealKind[] = ["morning_snack", "lunch", "afternoon_snack"];

/** As colunas que a consulta pede, e o formato em que elas voltam. */
export const MEAL_MAP_SELECT = `
  id,
  map_date,
  non_school_day,
  note,
  meals_served,
  meal (
    type,
    description,
    acceptance,
    meal_food_item ( quantity, food_item ( name, default_unit ) ),
    menu_change (
      reason,
      menu_change_food_item ( quantity, food_item ( name, default_unit ) )
    )
  )
`;

interface FoodItemRow {
  name: string;
  default_unit: string;
}

interface UsedFoodItemRow {
  quantity: number;
  food_item: FoodItemRow | FoodItemRow[] | null;
}

interface MenuChangeRow {
  reason: string;
  menu_change_food_item: UsedFoodItemRow[] | null;
}

interface MealRow {
  type: MealKind;
  description: string | null;
  acceptance: Acceptance | null;
  meal_food_item: UsedFoodItemRow[] | null;
  menu_change: MenuChangeRow | MenuChangeRow[] | null;
}

export interface MealMapRow {
  id: string;
  map_date: string;
  non_school_day: boolean;
  note: string | null;
  meals_served: number | null;
  meal: MealRow[] | null;
}

/**
 * Uma relação "para um" volta do PostgREST como objeto quando ele reconhece a
 * unicidade, e como lista de um elemento quando não reconhece. Depender de
 * qual dos dois seria depender de uma inferência dele, e o preço de ela mudar
 * é a alteração do cardápio sumir do documento em silêncio.
 */
function one<T>(value: T | T[] | null): T | null {
  if (value === null) return null;
  return Array.isArray(value) ? value[0] ?? null : value;
}

function toFoodItems(rows: UsedFoodItemRow[] | null): FoodItemAmount[] {
  return (rows ?? [])
    .map((row) => {
      const item = one(row.food_item);
      if (!item) return null;
      return { name: item.name, amount: row.quantity, unit: item.default_unit };
    })
    .filter((item): item is FoodItemAmount => item !== null)
    // A ordem do banco não tem promessa nenhuma, e estas listas são impressas
    // como vêm. Ordenar por nome é o que faz o mesmo dia sair igual duas vezes.
    .sort((a, b) => a.name.localeCompare(b.name, "pt-BR"));
}

function toMenuChange(row: MenuChangeRow | MenuChangeRow[] | null): MenuChange | null {
  const change = one(row);
  if (!change) return null;
  return {
    reason: change.reason,
    foodItems: toFoodItems(change.menu_change_food_item),
  };
}

function toMeal(row: MealRow): Meal {
  return {
    kind: row.type,
    // Descrição ausente é o registro parcial, que as regras permitem: a
    // refeição sai com o rótulo e a escala em branco, como o formulário a mão
    // (CA#3 da US001).
    description: row.description ?? "",
    acceptance: row.acceptance,
    foodItems: toFoodItems(row.meal_food_item),
    change: toMenuChange(row.menu_change),
  };
}

function toMealMap(row: MealMapRow): MealMap {
  const meals = (row.meal ?? [])
    .filter((meal) => MEAL_ORDER.includes(meal.type))
    .sort((a, b) => MEAL_ORDER.indexOf(a.type) - MEAL_ORDER.indexOf(b.type))
    .map(toMeal);

  return {
    date: row.map_date,
    schoolDay: !row.non_school_day,
    note: row.note,
    mealCount: row.meals_served,
    meals,
  };
}

export function toDocumentData(schoolName: string, rows: MealMapRow[]): DocumentData {
  return {
    schoolName,
    // A seleção pode chegar em qualquer ordem — inclusive dias avulsos
    // (CA#1 da US013). No documento ela é sempre cronológica.
    mealMaps: [...rows]
      .sort((a, b) => a.map_date.localeCompare(b.map_date))
      .map(toMealMap),
  };
}
