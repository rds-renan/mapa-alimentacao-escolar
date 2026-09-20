import { assertEquals } from "@std/assert";
import { documentFileName } from "./nome-do-arquivo.ts";
import type { MealMap } from "../_shared/dados.ts";

function day(date: string): MealMap {
  return { date, schoolDay: true, note: null, mealCount: null, meals: [] };
}

Deno.test("o mês vira o nome do arquivo, sem acento e sem espaço", () => {
  assertEquals(
    documentFileName([day("2026-09-01"), day("2026-09-30")]),
    "mapa-da-alimentacao-escolar-setembro-2026.docx",
  );
  assertEquals(
    documentFileName([day("2026-03-02")]),
    "mapa-da-alimentacao-escolar-marco-2026.docx",
  );
});

Deno.test("a seleção que atravessa meses os nomeia no arquivo também", () => {
  assertEquals(
    documentFileName([day("2026-08-31"), day("2026-09-01")]),
    "mapa-da-alimentacao-escolar-agosto-e-setembro-2026.docx",
  );
  assertEquals(
    documentFileName([day("2026-12-20"), day("2027-02-10")]),
    "mapa-da-alimentacao-escolar-dezembro-2026-a-fevereiro-2027.docx",
  );
});

Deno.test("sem dia nenhum, o nome não fica com o traço pendurado", () => {
  assertEquals(documentFileName([]), "mapa-da-alimentacao-escolar.docx");
});
