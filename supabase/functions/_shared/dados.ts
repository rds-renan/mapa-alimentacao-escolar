// O que entra no preenchimento.
//
// Os nomes seguem o schema da E4 (decisão 13): `meal_map`, `meal`,
// `menu_change`, `meal_map_food_item`. O conteúdo — descrição da refeição, nome do
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
 * A troca no cardápio do dia. A descrição da refeição permanece fiel ao
 * cardápio previsto (achado da E4): o que a alteração guarda são os gêneros
 * efetivamente usados na troca e o motivo. No máximo uma por dia (decisão 14
 * da E4).
 */
export interface MenuChange {
  reason: string;
  foodItems: FoodItemAmount[];
}

export interface Meal {
  kind: MealKind;
  description: string;
  acceptance: Acceptance | null;
}

export interface MealMap {
  /** Data no formato ISO `aaaa-mm-dd`. */
  date: string;
  schoolDay: boolean;
  note: string | null;
  mealCount: number | null;
  meals: Meal[];
  /** Os gêneros do dia, em ordem de nome. Alimentam a coluna GÊNEROS UTILIZADOS. */
  foodItems: FoodItemAmount[];
  change: MenuChange | null;
}

export interface DocumentData {
  schoolName: string;
  mealMaps: MealMap[];
  /**
   * Rótulo do campo "MÊS/ANO" do cabeçalho. Omitido, é derivado das datas
   * selecionadas — ver {@link formatPeriod}.
   */
  period?: string;
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

const MONTH_NAMES = [
  "Janeiro",
  "Fevereiro",
  "Março",
  "Abril",
  "Maio",
  "Junho",
  "Julho",
  "Agosto",
  "Setembro",
  "Outubro",
  "Novembro",
  "Dezembro",
];

export function formatDayAndMonth(isoDate: string): string {
  const [, month, day] = isoDate.split("-");
  return `${day}/${month}`;
}

/**
 * O rótulo do campo "MÊS/ANO", derivado das datas selecionadas.
 *
 * O campo do formulário pede mês e ano, mas a seleção não é obrigatoriamente
 * um mês: a merendeira pode gerar uma semana, ou dias avulsos. Nesses casos o
 * mês continua sendo a resposta certa para o campo — quais dias entraram é o
 * que a tabela mostra, dia a dia, logo abaixo. O que o campo não pode é
 * mentir, e por isso uma seleção que atravessa meses os nomeia todos.
 */
export function formatPeriod(mealMaps: MealMap[]): string {
  const months = [...new Set(mealMaps.map((mealMap) => mealMap.date.slice(0, 7)))]
    .sort();
  if (months.length === 0) return "";

  const label = (yearMonth: string) => {
    const [year, month] = yearMonth.split("-");
    return { name: MONTH_NAMES[Number(month) - 1], year };
  };

  const first = label(months[0]);
  const last = label(months[months.length - 1]);

  if (months.length === 1) return `${first.name}/${first.year}`;
  // Anos diferentes obrigam a repetir o ano dos dois lados.
  if (first.year !== last.year) {
    return `${first.name}/${first.year} a ${last.name}/${last.year}`;
  }
  // Dois meses seguidos se ligam por "e"; uma sequência maior, por "a".
  const joint = months.length === 2 ? "e" : "a";
  return `${first.name} ${joint} ${last.name}/${first.year}`;
}

/** `8` vira `8`; `2.5` vira `2,5`. Vírgula decimal, sem casas à toa. */
export function formatAmount(amount: number): string {
  return String(amount).replace(".", ",");
}

export function formatFoodItem(item: FoodItemAmount): string {
  return `${item.name} — ${formatAmount(item.amount)} ${item.unit}`;
}
