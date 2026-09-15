// Os testes rodam contra o [modelo de teste](modelo-de-teste.ts), nunca contra
// o oficial: o oficial não está no repositório, e não pode estar.
//
// O que se prova aqui é o comportamento — quantos blocos saem, o que vai em
// cada coluna, o que acontece num dia sem aula, se o nome de quem editou o
// modelo sumiu. Fidelidade visual não se prova em teste: isso é olhar o
// documento gerado a partir do arquivo oficial, e está descrito na
// documentação da etapa.

import { assert, assertEquals, assertStringIncludes, assertThrows } from "@std/assert";
import {
  children,
  closePackage,
  firstChild,
  getAttribute,
  openPackage,
  readXml,
  textOf,
  type XmlElement,
} from "./docx.ts";
import { fillOfficialTemplate } from "./preenchimento.ts";
import { buildTestTemplate } from "./modelo-de-teste.ts";
import type { DocumentData, MealMap } from "./dados.ts";

const TEMPLATE = buildTestTemplate();

function schoolDay(date: string, overrides: Partial<MealMap> = {}): MealMap {
  return {
    date,
    schoolDay: true,
    note: null,
    mealCount: 120,
    meals: [
      {
        kind: "morning_snack",
        description: "Leite com achocolatado, Biscoito",
        acceptance: "great",
        foodItems: [{ name: "Leite", amount: 10, unit: "L" }],
        change: null,
      },
      {
        kind: "lunch",
        description: "Arroz, Feijão, Carne moída",
        acceptance: "poor",
        foodItems: [{ name: "Arroz", amount: 8, unit: "kg" }],
        change: null,
      },
      {
        kind: "afternoon_snack",
        description: "Suco de laranja, Bolo",
        acceptance: null,
        foodItems: [{ name: "Arroz", amount: 2, unit: "kg" }],
        change: null,
      },
    ],
    ...overrides,
  };
}

function documentWith(mealMaps: MealMap[]): DocumentData {
  return { schoolName: "Escola Exemplo", period: "Setembro/2026", mealMaps };
}

function fill(data: DocumentData): Uint8Array {
  return fillOfficialTemplate(TEMPLATE, data);
}

function tableOf(filled: Uint8Array): XmlElement {
  const body = firstChild(
    readXml(openPackage(filled), "word/document.xml").documentElement as XmlElement,
    "body",
  )!;
  return firstChild(body, "tbl")!;
}

function rowsOf(filled: Uint8Array): XmlElement[] {
  return children(tableOf(filled), "tr");
}

function cellText(row: XmlElement, column: number): string {
  return textOf(children(row, "tc")[column]);
}

Deno.test("sai um bloco de quatro linhas por dia, sob um único cabeçalho", () => {
  const rows = rowsOf(
    fill(documentWith([schoolDay("2026-09-01"), schoolDay("2026-09-02")])),
  );

  // O modelo de teste traz o cabeçalho repetido no meio da tabela, como o
  // oficial; o resultado tem de ter um só, no alto.
  assertEquals(rows.length, 1 + 2 * 4);
  assertEquals(cellText(rows[0], 0).trim(), "Dia");
  assertEquals(cellText(rows[1], 0).trim(), "01/09");
  assertEquals(cellText(rows[5], 0).trim(), "02/09");
});

Deno.test("a escola e o período entram sobre o tracejado do cabeçalho", () => {
  const filled = fill(documentWith([schoolDay("2026-09-01")]));
  const body = firstChild(
    readXml(openPackage(filled), "word/document.xml").documentElement as XmlElement,
    "body",
  )!;
  const heading = children(body, "p").map(textOf).find((text) =>
    text.includes("ESCOLA:")
  )!;

  assertStringIncludes(heading, "ESCOLA:  Escola Exemplo ");
  assertStringIncludes(heading, "MÊS/ANO: Setembro/2026 ");
  // O tracejado sobrevive ao preenchimento: a linha não pode encolher.
  assertStringIncludes(heading, "_");
});

Deno.test("a descrição da refeição entra depois do rótulo que o modelo já traz", () => {
  const rows = rowsOf(fill(documentWith([schoolDay("2026-09-01")])));

  assertStringIncludes(
    cellText(rows[1], 1),
    "Lanche da manhã: Leite com achocolatado, Biscoito",
  );
  assertStringIncludes(cellText(rows[2], 1), "Almoço: Arroz, Feijão, Carne moída");
  assertStringIncludes(cellText(rows[3], 1), "Lanche da tarde: Suco de laranja, Bolo");
});

Deno.test("a aceitação é marcada só na opção registrada", () => {
  const rows = rowsOf(fill(documentWith([schoolDay("2026-09-01")])));

  assertStringIncludes(cellText(rows[1], 1), "(X) ótimo   ( ) bom   ( ) ruim");
  assertStringIncludes(cellText(rows[2], 1), "( ) ótimo   ( ) bom   (X) ruim");
  // Aceitação não é obrigatória: sem registro, nenhuma opção é marcada.
  assertStringIncludes(cellText(rows[3], 1), "( ) ótimo   ( ) bom   ( ) ruim");
});

Deno.test("os gêneros do dia são consolidados numa coluna só", () => {
  const rows = rowsOf(fill(documentWith([schoolDay("2026-09-01")])));
  const items = cellText(rows[1], 2);

  // Arroz aparece em duas refeições, 8 kg e 2 kg, e sai somado uma vez só.
  assertStringIncludes(items, "Arroz — 10 kg");
  assertStringIncludes(items, "Leite — 10 L");
  assertEquals(items.split("Arroz").length - 1, 1);
});

Deno.test("o mesmo gênero em unidades diferentes não é somado", () => {
  const day = schoolDay("2026-09-01");
  day.meals[0].foodItems = [{ name: "Ovo", amount: 2, unit: "kg" }];
  day.meals[1].foodItems = [{ name: "Ovo", amount: 30, unit: "unidade" }];

  const items = cellText(rowsOf(fill(documentWith([day])))[1], 2);
  assertStringIncludes(items, "Ovo — 2 kg");
  assertStringIncludes(items, "Ovo — 30 unidade");
});

Deno.test("a alteração aparece na coluna própria e a justificativa na última linha", () => {
  const day = schoolDay("2026-09-01");
  day.meals[1].change = {
    reason: "o frango não chegou na entrega",
    foodItems: [{ name: "Ovo", amount: 120, unit: "unidade" }],
  };

  const rows = rowsOf(fill(documentWith([day])));
  assertStringIncludes(cellText(rows[1], 3), "Almoço:");
  assertStringIncludes(cellText(rows[1], 3), "Ovo — 120 unidade");
  assertStringIncludes(cellText(rows[4], 1), "Almoço: o frango não chegou na entrega");
  // A descrição da refeição continua fiel ao cardápio previsto (achado da E4).
  assertStringIncludes(cellText(rows[2], 1), "Almoço: Arroz, Feijão, Carne moída");
});

Deno.test("dia não letivo traz a observação e dispensa o número de refeições", () => {
  const rows = rowsOf(fill(documentWith([
    {
      date: "2026-09-07",
      schoolDay: false,
      note: "Feriado",
      mealCount: null,
      meals: [],
    },
  ])));

  assertStringIncludes(cellText(rows[1], 1), "DIA NÃO LETIVO: Feriado");
  assertEquals(cellText(rows[1], 4).trim(), "—");
  assertEquals(cellText(rows[1], 2).trim(), "");
  assertEquals(cellText(rows[2], 1).trim(), "");
});

Deno.test("dia sem contagem registrada fica em branco, não zerado", () => {
  const rows = rowsOf(
    fill(documentWith([schoolDay("2026-09-01", { mealCount: null })])),
  );
  assertEquals(cellText(rows[1], 4).trim(), "");
});

Deno.test("as alturas travadas viram mínimos e o cabeçalho passa a repetir", () => {
  const rows = rowsOf(fill(documentWith([schoolDay("2026-09-01")])));

  for (const row of rows) {
    const properties = firstChild(row, "trPr")!;
    const height = firstChild(properties, "trHeight");
    if (height) assertEquals(getAttribute(height, "hRule"), "atLeast");
  }
  assert(firstChild(firstChild(rows[0], "trPr")!, "tblHeader") !== null);
});

Deno.test("as três primeiras linhas do dia grudam na seguinte", () => {
  const rows = rowsOf(fill(documentWith([schoolDay("2026-09-01")])));
  const keepsNext = (row: XmlElement) =>
    children(row, "tc").every((cell) =>
      children(cell, "p").every((p) =>
        firstChild(firstChild(p, "pPr")!, "keepNext") !== null
      )
    );

  assert(keepsNext(rows[1]) && keepsNext(rows[2]) && keepsNext(rows[3]));
  assert(!keepsNext(rows[4]), "a última linha do dia não gruda na do dia seguinte");
});

Deno.test("o nome de quem mexeu no modelo não sobrevive ao preenchimento", () => {
  const pkg = openPackage(fill(documentWith([schoolDay("2026-09-01")])));
  const core = new TextDecoder().decode(pkg["docProps/core.xml"]);

  assertEquals(core.includes("Fulana de Tal"), false);
  assertEquals(core.includes("Beltrana de Tal"), false);
  assertStringIncludes(core, "Mapa da Alimentação Escolar");
});

Deno.test("modelo sem os rótulos esperados falha dizendo o que faltou", () => {
  const broken = withoutLabel(TEMPLATE, "Almoço:");
  const error = assertThrows(() => fillOfficialTemplate(broken, documentWith([])));
  assertStringIncludes((error as Error).message, "Almoço");
});

/** Descaracteriza o modelo trocando um rótulo, para testar o reconhecimento. */
function withoutLabel(template: Uint8Array, label: string): Uint8Array {
  const pkg = openPackage(template);
  const xml = new TextDecoder().decode(pkg["word/document.xml"]);
  pkg["word/document.xml"] = new TextEncoder().encode(xml.replace(label, "Refeição:"));
  return closePackage(pkg);
}
