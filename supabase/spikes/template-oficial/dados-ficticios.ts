// Dados inventados para a amostra do spike.
//
// Nada aqui vem da escola: os cardápios são plausíveis, não são os reais, e a
// escola é fictícia. O que interessa é o formato — um mês inteiro, que é o caso
// típico da prestação de contas, com os casos que mexem no layout: dia não
// letivo, refeição sem aceitação registrada, alteração de cardápio com gêneros,
// dia sem número de refeições e descrição longa o bastante para estourar a
// altura que o modelo trazia travada.

import type { DocumentData, Meal, MealMap } from "./dados.ts";

const MORNING_SNACKS = [
  "Leite com achocolatado, Biscoito de maisena",
  "Chocolate quente, Pão com margarina, Banana",
  "Café com leite, Biscoito de gergelim, Mamão",
  "Vitamina de banana com aveia, Pão com requeijão",
  "Iogurte natural, Bolo de fubá, Maçã",
];

const LUNCHES = [
  "Arroz, Feijão, Carne moída com legumes, Salada de alface e tomate",
  "Arroz, Feijão, Frango assado com batata, Repolho refogado",
  "Arroz, Feijão, Sopa de legumes (macarrão, cenoura, chuchu, couve, ovo cozido e queijo ralado por cima)",
  "Arroz, Feijão, Peixe ensopado, Aipim cozido, Salada de beterraba",
  "Arroz, Feijão, Macarrão com molho de frango, Farofa de couve",
];

const AFTERNOON_SNACKS = [
  "Café com leite, Pão com molho de carne desfiada, Pêra",
  "Suco de laranja, Biscoito Maria, Melancia",
  "Batida de maçã, Pão com requeijão, Banana",
  "Leite caramelado com canela, Bolo de cenoura",
  "Iogurte, Mix de frutas da estação",
];

const STAPLES = [
  { name: "Arroz", amount: 8, unit: "kg" },
  { name: "Feijão", amount: 5, unit: "kg" },
  { name: "Óleo", amount: 1, unit: "L" },
];

/** Dias do mês sem aula, com o motivo que vai para a observação. */
const NON_SCHOOL_DAYS: Record<number, string> = {
  7: "Feriado — Independência",
  21: "Conselho de classe",
};

/** Dias com troca de item, com o motivo e o que entrou no lugar. */
const CHANGES: Record<number, { reason: string; items: typeof STAPLES }> = {
  9: {
    reason: "o frango não chegou na entrega da semana",
    items: [
      { name: "Ovo", amount: 120, unit: "unidade" },
      { name: "Batata", amount: 6, unit: "kg" },
    ],
  },
  23: {
    reason: "a fruta prevista chegou madura demais e foi trocada",
    items: [{ name: "Banana", amount: 9, unit: "kg" }],
  },
};

export function sampleMonth(): DocumentData {
  const year = 2026;
  const month = 9;
  const mealMaps: MealMap[] = [];

  for (let day = 1; day <= 30; day++) {
    const weekday = new Date(Date.UTC(year, month - 1, day)).getUTCDay();
    if (weekday === 0 || weekday === 6) continue; // fim de semana não tem mapa
    mealMaps.push(buildMealMap(year, month, day));
  }

  return {
    schoolName: "Escola Municipal de Turno Integral Exemplo",
    period: "Setembro/2026",
    mealMaps,
  };
}

function buildMealMap(year: number, month: number, day: number): MealMap {
  const date = `${year}-${pad(month)}-${pad(day)}`;
  const note = NON_SCHOOL_DAYS[day];
  if (note) {
    return { date, schoolDay: false, note, mealCount: null, meals: [] };
  }

  const rotation = day % 5;
  const change = CHANGES[day];

  const meals: Meal[] = [
    {
      kind: "morning_snack",
      description: MORNING_SNACKS[rotation],
      // Um dia sem aceitação registrada: o campo não é obrigatório.
      acceptance: day === 15 ? null : pick(day, 0),
      foodItems: [
        { name: "Leite", amount: 12, unit: "L" },
        { name: "Açúcar", amount: 2, unit: "kg" },
      ],
      change: null,
    },
    {
      kind: "lunch",
      description: LUNCHES[rotation],
      acceptance: pick(day, 1),
      foodItems: [...STAPLES.map((item) => ({ ...item }))],
      change: change ? { reason: change.reason, foodItems: change.items } : null,
    },
    {
      kind: "afternoon_snack",
      description: AFTERNOON_SNACKS[rotation],
      acceptance: pick(day, 2),
      foodItems: [
        { name: "Pão", amount: 140, unit: "unidade" },
        { name: "Fruta da estação", amount: 10, unit: "kg" },
      ],
      change: null,
    },
  ];

  return {
    date,
    schoolDay: true,
    note: null,
    // Um dia sem contagem: o registro pode ficar parcial.
    mealCount: day === 11 ? null : 130 + ((day * 7) % 25),
    meals,
  };
}

function pick(day: number, offset: number): Meal["acceptance"] {
  return (["great", "good", "great", "poor"] as const)[(day + offset) % 4];
}

function pad(value: number): string {
  return String(value).padStart(2, "0");
}
