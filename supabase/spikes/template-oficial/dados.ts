// O que entra no preenchimento.
//
// Os nomes seguem o schema da E4 (decisão 13): `meal_map`, `meal`,
// `menu_change`, `meal_food_item`. O conteúdo — descrição da refeição, nome do
// gênero, justificativa — é texto em português, como cadastrado.

export type MealKind = "morning_snack" | "lunch" | "afternoon_snack";

export type Acceptance = "great" | "good" | "poor";

/** Um gênero e a quantidade usada, na unidade cadastrada no catálogo. */
export interface FoodItemAmount {
  name: string;
  amount: number;
  unit: string;
}

/**
 * A troca de item na refeição. A descrição da refeição permanece fiel ao
 * cardápio previsto (achado da E4): o que a alteração guarda são os gêneros
 * efetivamente usados na troca e o motivo. No máximo uma por refeição.
 */
export interface MenuChange {
  reason: string;
  foodItems: FoodItemAmount[];
}

export interface Meal {
  kind: MealKind;
  description: string;
  acceptance: Acceptance | null;
  foodItems: FoodItemAmount[];
  change: MenuChange | null;
}

export interface MealMap {
  /** Data no formato ISO `aaaa-mm-dd`. */
  date: string;
  schoolDay: boolean;
  note: string | null;
  mealCount: number | null;
  meals: Meal[];
}

export interface DocumentData {
  schoolName: string;
  /** Rótulo do período, como sai no cabeçalho: `Agosto/2026`. */
  period: string;
  mealMaps: MealMap[];
}

// --- apresentação ----------------------------------------------------------

/** Rótulo de cada refeição no modelo oficial — é por ele que a linha é achada. */
export const MEAL_LABELS: Record<MealKind, string> = {
  morning_snack: "Lanche da manhã",
  lunch: "Almoço",
  afternoon_snack: "Lanche da tarde",
};

/** Rótulo de cada grau de aceitação, como impresso entre parênteses. */
export const ACCEPTANCE_LABELS: Record<Acceptance, string> = {
  great: "ótimo",
  good: "bom",
  poor: "ruim",
};

export function formatDayAndMonth(isoDate: string): string {
  const [, month, day] = isoDate.split("-");
  return `${day}/${month}`;
}

/** `8` vira `8`; `2.5` vira `2,5`. Vírgula decimal, sem casas à toa. */
export function formatAmount(amount: number): string {
  return String(amount).replace(".", ",");
}

export function formatFoodItem(item: FoodItemAmount): string {
  return `${item.name} — ${formatAmount(item.amount)} ${item.unit}`;
}

/**
 * Consolida os gêneros do dia inteiro: a coluna GÊNEROS UTILIZADOS é mesclada
 * no dia, mas o registro é por refeição. Gêneros de mesma unidade somam; o
 * mesmo gênero em unidades diferentes vira duas linhas, porque somar `kg` com
 * `unidade` seria inventar um número.
 */
export function consolidateFoodItems(meals: Meal[]): FoodItemAmount[] {
  const totals = new Map<string, FoodItemAmount>();
  for (const meal of meals) {
    for (const item of meal.foodItems) {
      const key = `${item.name} @ ${item.unit}`;
      const running = totals.get(key);
      if (running) running.amount += item.amount;
      else totals.set(key, { ...item });
    }
  }
  return [...totals.values()].sort((a, b) => a.name.localeCompare(b.name, "pt-BR"));
}
