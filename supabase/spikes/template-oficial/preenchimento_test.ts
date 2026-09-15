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
  writeXml,
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
  return { schoolName: "Escola Exemplo", mealMaps };
}

function headingOf(filled: Uint8Array): string {
  const body = firstChild(
    readXml(openPackage(filled), "word/document.xml").documentElement as XmlElement,
    "body",
  )!;
  return children(body, "p").map(textOf).find((text) => text.includes("ESCOLA:"))!;
}

function fill(data: DocumentData, template: Uint8Array = TEMPLATE): Uint8Array {
  return fillOfficialTemplate(template, data);
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

Deno.test("a escola e o período entram na lacuna do cabeçalho, sem sobra de tracejado", () => {
  const heading = headingOf(fill(documentWith([schoolDay("2026-09-01")])));

  assertStringIncludes(heading, "ESCOLA:  Escola Exemplo ");
  assertStringIncludes(heading, "MÊS/ANO: Setembro/2026 ");

  // Lacuna preenchida não fica com rabicho: nada de "Escola Exemplo ______".
  assertEquals(/Escola Exemplo\s*_/.test(heading), false);
  assertEquals(/Setembro\/2026\s*_/.test(heading), false);
  // Mas o comprimento se mantém, para o "MÊS/ANO" não andar pela linha.
  assert(heading.length > "ESCOLA:  Escola Exemplo  MÊS/ANO: Setembro/2026 ".length);
});

Deno.test("cada rótulo de assinatura se apoia na parada do seu traço", () => {
  const body = firstChild(
    readXml(
      openPackage(fill(documentWith([schoolDay("2026-09-01")]))),
      "word/document.xml",
    ).documentElement as XmlElement,
    "body",
  )!;
  const paragraphs = children(body, "p");
  const rules = paragraphs.find((p) =>
    /^[\s_]+$/.test(textOf(p)) && textOf(p).includes("__")
  )!;
  const labels = paragraphs.find((p) => textOf(p).includes("Diretor(a)"))!;

  // Duas paradas centralizadas, nos centros das duas metades da largura útil:
  // a página tem 16838 twips e 284 de margem de cada lado.
  const stopsOf = (paragraph: XmlElement) =>
    children(firstChild(paragraph, "pPr")!, "tabs").flatMap((tabs) =>
      children(tabs, "tab").map((
        tab,
      ) => [getAttribute(tab, "val"), getAttribute(tab, "pos")])
    );
  const expected = [["center", "4068"], ["center", "12203"]];
  assertEquals(stopsOf(rules), expected);
  assertEquals(stopsOf(labels), expected);

  // E cada parte passa a ser precedida da sua tabulação, em vez de espaços.
  assertEquals(children(labels, "r").length, 2);
  for (const run of children(labels, "r")) assert(firstChild(run, "tab") !== null);
  assertStringIncludes(textOf(labels), "Cozinheiro(a) responsável pelo mapa");
  assertEquals(textOf(labels).includes("   "), false);
});

Deno.test("o período do cabeçalho sai das datas, mesmo em seleção avulsa", () => {
  // Dias soltos continuam sendo de setembro: quais entraram é o que a tabela
  // mostra logo abaixo, dia a dia.
  const scattered = [schoolDay("2026-09-03"), schoolDay("2026-09-17")];
  assertStringIncludes(
    headingOf(fill(documentWith(scattered))),
    "MÊS/ANO: Setembro/2026 ",
  );

  const twoMonths = [schoolDay("2026-08-31"), schoolDay("2026-09-01")];
  assertStringIncludes(
    headingOf(fill(documentWith(twoMonths))),
    "MÊS/ANO: Agosto e Setembro/2026 ",
  );

  const acrossYears = [schoolDay("2026-12-18"), schoolDay("2027-02-02")];
  assertStringIncludes(
    headingOf(fill(documentWith(acrossYears))),
    "MÊS/ANO: Dezembro/2026 a Fevereiro/2027 ",
  );
});

Deno.test("um período informado à mão prevalece sobre o derivado", () => {
  const data = { ...documentWith([schoolDay("2026-09-01")]), period: "Semana 1" };
  assertStringIncludes(headingOf(fill(data)), "MÊS/ANO: Semana 1 ");
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

Deno.test("a aceitação é marcada mesmo com a linha partida entre runs", () => {
  // O Word reparte texto em várias runs sem motivo de formatação — no modelo
  // oficial o rótulo "Lanche da tarde:" já chega em quatro. Se isso acontecer
  // com a linha da aceitação, a marcação não pode simplesmente deixar de sair.
  const split = splitAcceptanceLine(TEMPLATE);
  const rows = rowsOf(fill(documentWith([schoolDay("2026-09-01")]), split));

  assertStringIncludes(cellText(rows[1], 1), "(X) ótimo");
  assertStringIncludes(cellText(rows[2], 1), "(X) ruim");
});

Deno.test("período sem mapa nenhum sai só com o cabeçalho", () => {
  const rows = rowsOf(fill(documentWith([])));
  assertEquals(rows.length, 1);
  assertEquals(cellText(rows[0], 0).trim(), "Dia");
});

Deno.test("dia letivo com refeição faltando não inventa conteúdo", () => {
  // Registro parcial é permitido: a merendeira pode ter lançado só o almoço.
  const day = schoolDay("2026-09-01");
  day.meals = day.meals.filter((meal) => meal.kind === "lunch");

  const rows = rowsOf(fill(documentWith([day])));
  assertStringIncludes(cellText(rows[2], 1), "Almoço: Arroz, Feijão, Carne moída");

  // A refeição ausente sai como o formulário em branco: o rótulo, a escala de
  // aceitação sem marca, e nenhuma descrição inventada. O dia é letivo — só
  // não foi registrado —, e quem receber ainda pode completar à mão.
  const missing = cellText(rows[1], 1);
  assertStringIncludes(missing, "Lanche da manhã:");
  assertStringIncludes(missing, "( ) ótimo   ( ) bom   ( ) ruim");
  assertEquals(missing.includes("Leite"), false);
  assertStringIncludes(cellText(rows[3], 1), "Lanche da tarde:");
});

Deno.test("duas refeições alteradas no mesmo dia aparecem separadas", () => {
  const day = schoolDay("2026-09-01");
  day.meals[0].change = {
    reason: "o leite azedou",
    foodItems: [{ name: "Suco", amount: 8, unit: "L" }],
  };
  day.meals[1].change = {
    reason: "o frango não chegou",
    foodItems: [{ name: "Ovo", amount: 120, unit: "unidade" }],
  };

  const rows = rowsOf(fill(documentWith([day])));
  const changes = cellText(rows[1], 3);
  assertStringIncludes(changes, "Lanche da manhã:");
  assertStringIncludes(changes, "Suco — 8 L");
  assertStringIncludes(changes, "Almoço:");
  assertStringIncludes(changes, "Ovo — 120 unidade");

  const reasons = cellText(rows[4], 1);
  assertStringIncludes(reasons, "Lanche da manhã: o leite azedou");
  assertStringIncludes(reasons, "Almoço: o frango não chegou");
});

Deno.test("um dia deslocado no modelo não contamina o documento inteiro", () => {
  // O modelo circula sendo reeditado, e a cada edição alguém desloca uma linha.
  // Caindo no primeiro dia, ele não pode virar o gabarito de todos os outros.
  const dented = dentFirstBlock(TEMPLATE);
  const rows = rowsOf(fill(documentWith([schoolDay("2026-09-01")]), dented));

  assertEquals(rows.length, 1 + 4, "o bloco íntegro de outro dia é que vale");
  assertStringIncludes(cellText(rows[2], 1), "Almoço: Arroz, Feijão, Carne moída");
  assertStringIncludes(cellText(rows[4], 1), "Mudança no cardápio, justificativa:");
});

Deno.test("modelo sem os rótulos esperados falha dizendo o que faltou", () => {
  const broken = withoutLabel(TEMPLATE, "Almoço:");
  const error = assertThrows(() => fillOfficialTemplate(broken, documentWith([])));
  assertStringIncludes((error as Error).message, "Almoço");
});

/**
 * Reparte a linha da aceitação em três runs, no meio do `( ) ótimo` e do
 * `( ) ruim`, como o Word faz sozinho ao longo das edições de um documento.
 */
function splitAcceptanceLine(template: Uint8Array): Uint8Array {
  const pkg = openPackage(template);
  const xml = new TextDecoder().decode(pkg["word/document.xml"]);
  const style =
    '<w:rPr><w:rFonts w:ascii="Arial" w:hAnsi="Arial"/><w:b/><w:sz w:val="20"/></w:rPr>';
  const broken = xml.replaceAll(
    "Grau de aceitação:      ( ) ótimo   ( ) bom   ( ) ruim",
    "Grau de aceitação:      (</w:t></w:r>" +
      `<w:r>${style}<w:t xml:space="preserve"> ) ótimo   ( ) bom   (</w:t></w:r>` +
      `<w:r>${style}<w:t xml:space="preserve"> ) ruim`,
  );
  pkg["word/document.xml"] = new TextEncoder().encode(broken);
  return closePackage(pkg);
}

/**
 * Descaracteriza o modelo trocando um rótulo em **todos** os blocos — é o
 * formulário que mudou, não um deslize de edição num dia só.
 */
function withoutLabel(template: Uint8Array, label: string): Uint8Array {
  const pkg = openPackage(template);
  const xml = new TextDecoder().decode(pkg["word/document.xml"]);
  pkg["word/document.xml"] = new TextEncoder().encode(
    xml.replaceAll(label, "Refeição:"),
  );
  return closePackage(pkg);
}

/** Duplica uma linha dentro do primeiro bloco: o deslize de quem reedita o arquivo. */
function dentFirstBlock(template: Uint8Array): Uint8Array {
  const pkg = openPackage(template);
  const xml = readXml(pkg, "word/document.xml");
  const body = firstChild(xml.documentElement as XmlElement, "body")!;
  const rows = children(firstChild(body, "tbl")!, "tr");
  const lunch = rows[2];
  lunch.parentNode!.insertBefore(lunch.cloneNode(true), lunch);
  writeXml(pkg, "word/document.xml", xml);
  return closePackage(pkg);
}
