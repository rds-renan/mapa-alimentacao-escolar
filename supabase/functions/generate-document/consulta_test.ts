// O que se prova aqui é a tradução do banco para o documento: a ordem em que
// as coisas saem, o registro parcial que não vira invenção, e as duas formas
// em que o PostgREST devolve uma relação "para um".

import { assertEquals } from "@std/assert";
import { type MealMapRow, toDocumentData } from "./consulta.ts";

function row(overrides: Partial<MealMapRow> = {}): MealMapRow {
  return {
    id: "c0000001-0000-4000-8000-000000000001",
    map_date: "2026-09-01",
    non_school_day: false,
    note: null,
    meals_served: 312,
    meal: [],
    ...overrides,
  };
}

Deno.test("as refeições saem na ordem do dia, não na do banco", () => {
  const data = toDocumentData("Escola", [
    row({
      meal: [
        {
          type: "afternoon_snack",
          description: "Bolo",
          acceptance: "good",
          meal_food_item: [],
          menu_change: null,
        },
        {
          type: "morning_snack",
          description: "Leite com café",
          acceptance: "great",
          meal_food_item: [],
          menu_change: null,
        },
      ],
    }),
  ]);

  assertEquals(data.mealMaps[0].meals.map((meal) => meal.kind), [
    "morning_snack",
    "afternoon_snack",
  ]);
});

Deno.test("os dias saem em ordem cronológica, qualquer que seja a seleção", () => {
  const data = toDocumentData("Escola", [
    row({ map_date: "2026-09-10" }),
    row({ map_date: "2026-09-02" }),
    row({ map_date: "2026-09-30" }),
  ]);

  assertEquals(data.mealMaps.map((mealMap) => mealMap.date), [
    "2026-09-02",
    "2026-09-10",
    "2026-09-30",
  ]);
});

Deno.test("o gênero traz a unidade do catálogo, e a lista sai por nome", () => {
  const data = toDocumentData("Escola", [
    row({
      meal: [
        {
          type: "lunch",
          description: "Arroz e feijão",
          acceptance: null,
          meal_food_item: [
            { quantity: 2, food_item: { name: "Feijão", default_unit: "quilo" } },
            { quantity: 5, food_item: { name: "Arroz", default_unit: "quilo" } },
          ],
          menu_change: null,
        },
      ],
    }),
  ]);

  assertEquals(data.mealMaps[0].meals[0].foodItems, [
    { name: "Arroz", amount: 5, unit: "quilo" },
    { name: "Feijão", amount: 2, unit: "quilo" },
  ]);
});

Deno.test("a alteração do cardápio vem como objeto ou como lista de um", () => {
  const change = {
    reason: "Não veio o frango na entrega.",
    menu_change_food_item: [
      { quantity: 3, food_item: { name: "Ovo", default_unit: "bandeja" } },
    ],
  };
  const meal = {
    type: "lunch" as const,
    description: "Arroz, feijão e frango",
    acceptance: "good" as const,
    meal_food_item: [],
  };

  const comoObjeto = toDocumentData("Escola", [
    row({ meal: [{ ...meal, menu_change: change }] }),
  ]);
  const comoLista = toDocumentData("Escola", [
    row({ meal: [{ ...meal, menu_change: [change] }] }),
  ]);

  assertEquals(comoObjeto.mealMaps[0].meals[0].change, {
    reason: "Não veio o frango na entrega.",
    foodItems: [{ name: "Ovo", amount: 3, unit: "bandeja" }],
  });
  assertEquals(
    comoLista.mealMaps[0].meals[0].change,
    comoObjeto.mealMaps[0].meals[0].change,
  );
});

Deno.test("o registro parcial não vira invenção", () => {
  const data = toDocumentData("Escola", [
    row({
      meals_served: null,
      meal: [
        {
          type: "lunch",
          description: null,
          acceptance: null,
          meal_food_item: null,
          menu_change: null,
        },
      ],
    }),
  ]);

  const meal = data.mealMaps[0].meals[0];
  assertEquals(meal.description, "");
  assertEquals(meal.acceptance, null);
  assertEquals(meal.foodItems, []);
  assertEquals(data.mealMaps[0].mealCount, null);
});

Deno.test("o dia não letivo chega como dia sem aula, com a observação", () => {
  const data = toDocumentData("Escola", [
    row({ non_school_day: true, note: "Feriado municipal", meals_served: null }),
  ]);

  assertEquals(data.mealMaps[0].schoolDay, false);
  assertEquals(data.mealMaps[0].note, "Feriado municipal");
  assertEquals(data.mealMaps[0].mealCount, null);
});
