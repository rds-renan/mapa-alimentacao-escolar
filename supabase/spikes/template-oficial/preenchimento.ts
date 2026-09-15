// Preenche o modelo oficial sem redesenhá-lo.
//
// A ideia do spike: o modelo é o próprio gabarito. Em vez de recriar a tabela
// em código — o que jogaria fora bordas, larguras, fontes e o brasão —, o
// gerador **clona o bloco de quatro linhas que o modelo já traz** (as três
// refeições e a justificativa), uma vez por dia do período, e escreve o
// conteúdo dentro do XML que veio da prefeitura. Nada de formatação é
// inventado aqui.
//
// O reconhecimento do modelo é por rótulo, não por posição: a linha de
// cabeçalho é a que começa com "Dia", e cada linha do bloco é achada pelo
// rótulo que ela já imprime ("Almoço:", "Mudança no cardápio, justificativa:").
// Se a prefeitura mudar o formulário, o preenchimento falha alto — com o
// rótulo que faltou — em vez de escrever no lugar errado calado.

import {
  children,
  closePackage,
  descendants,
  firstChild,
  getAttribute,
  makeElement,
  openPackage,
  type Package,
  readXml,
  removeElement,
  setAttribute,
  textOf,
  W,
  writeXml,
  type XmlElement,
} from "./docx.ts";
import {
  ACCEPTANCE_LABELS,
  consolidateFoodItems,
  type DocumentData,
  formatDayAndMonth,
  formatFoodItem,
  type Meal,
  MEAL_LABELS,
  type MealKind,
  type MealMap,
} from "./dados.ts";

const DOCUMENT_PART = "word/document.xml";
const CORE_PROPERTIES_PART = "docProps/core.xml";
const CUSTOM_PROPERTIES_PART = "docProps/custom.xml";
const CHANGE_LABEL = "Mudança no cardápio, justificativa:";
const HEADER_LABEL = "Dia";

/** O gabarito extraído do modelo: um cabeçalho e um bloco de dia, já limpos. */
interface DayTemplate {
  header: XmlElement;
  mealRows: Map<MealKind, XmlElement>;
  changeRow: XmlElement;
  /** As quatro linhas na ordem em que aparecem no modelo. */
  order: XmlElement[];
}

export function fillOfficialTemplate(
  templateBytes: Uint8Array,
  data: DocumentData,
): Uint8Array {
  const pkg = openPackage(templateBytes);
  const xml = readXml(pkg, DOCUMENT_PART);
  const body = firstChild(xml.documentElement as XmlElement, "body");
  if (!body) throw new Error("o modelo não tem `w:body`");

  fillHeading(body, data);

  const table = firstChild(body, "tbl");
  if (!table) throw new Error("o modelo não tem tabela de mapa");

  const template = extractDayTemplate(table);
  rebuildTable(table, template, data.mealMaps);

  writeXml(pkg, DOCUMENT_PART, xml);
  stripPersonalMetadata(pkg);
  return closePackage(pkg);
}

// --- sigilo ----------------------------------------------------------------

/**
 * O modelo veio de um arquivo real e carrega, nas propriedades do pacote, o
 * nome de quem o criou e de quem o editou por último — dado pessoal que
 * viajaria em todo documento gerado, invisível no corpo mas legível em
 * qualquer leitor de metadados. Aqui essas propriedades são reescritas
 * neutras; é regra de sigilo do projeto, não preferência.
 */
function stripPersonalMetadata(pkg: Package): void {
  const encoder = new TextEncoder();
  if (pkg[CORE_PROPERTIES_PART]) {
    pkg[CORE_PROPERTIES_PART] = encoder.encode(
      '<?xml version="1.0" encoding="UTF-8"?>' +
        "<cp:coreProperties" +
        ' xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties"' +
        ' xmlns:dc="http://purl.org/dc/elements/1.1/">' +
        "<dc:creator>Mapa da Alimentação Escolar</dc:creator>" +
        "<cp:lastModifiedBy>Mapa da Alimentação Escolar</cp:lastModifiedBy>" +
        "<dc:title>Mapa da Alimentação Escolar</dc:title>" +
        "</cp:coreProperties>",
    );
  }
  if (pkg[CUSTOM_PROPERTIES_PART]) {
    // As propriedades personalizadas são rastros do editor de origem. O
    // arquivo continua no pacote, vazio: tirá-lo exigiria mexer no
    // `[Content_Types].xml` e nas relações, sem ganho nenhum.
    pkg[CUSTOM_PROPERTIES_PART] = encoder.encode(
      '<?xml version="1.0" encoding="UTF-8"?>' +
        '<Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/custom-properties"' +
        ' xmlns:vt="http://schemas.openxmlformats.org/officeDocument/2006/docPropsVTypes"/>',
    );
  }
}

// --- cabeçalho do documento ------------------------------------------------

/**
 * A linha "ESCOLA: ____ MÊS/ANO:____" é preenchida por cima da lacuna: o valor
 * entra e o que sobra do tracejado continua lá, do mesmo comprimento em
 * caracteres, para a linha não encolher.
 */
function fillHeading(body: XmlElement, data: DocumentData): void {
  for (const paragraph of children(body, "p")) {
    const text = textOf(paragraph);
    if (!text.includes("ESCOLA:")) continue;
    for (const node of descendants(paragraph, "t")) {
      const original = node.textContent ?? "";
      if (!original.includes("ESCOLA:")) continue;
      node.textContent = original
        .replace(
          /(ESCOLA:\s*)(_+)/,
          (_m: string, label: string, gap: string) =>
            label + overwriteGap(gap, data.schoolName),
        )
        .replace(
          /(MÊS\/ANO:\s*)(_+)/,
          (_m: string, label: string, gap: string) =>
            label + overwriteGap(gap, data.period),
        );
    }
    return;
  }
}

/** Escreve o valor sobre o tracejado, preservando o comprimento da lacuna. */
function overwriteGap(gap: string, value: string): string {
  const filled = ` ${value} `;
  if (filled.length >= gap.length) return filled;
  return filled + "_".repeat(gap.length - filled.length);
}

// --- leitura do gabarito ---------------------------------------------------

function extractDayTemplate(table: XmlElement): DayTemplate {
  const rows = children(table, "tr");
  const headerIndex = rows.findIndex((row) => firstCellText(row) === HEADER_LABEL);
  if (headerIndex < 0) {
    throw new Error(`o modelo não tem linha de cabeçalho ("${HEADER_LABEL}")`);
  }

  const blockStart = rows.findIndex((row, index) =>
    index > headerIndex && startsDayBlock(row)
  );
  if (blockStart < 0) {
    throw new Error("o modelo não tem bloco de dia (célula do dia mesclada)");
  }

  const block: XmlElement[] = [rows[blockStart]];
  for (let i = blockStart + 1; i < rows.length; i++) {
    if (startsDayBlock(rows[i]) || firstCellText(rows[i]) === HEADER_LABEL) break;
    block.push(rows[i]);
  }

  const header = rows[headerIndex].cloneNode(true) as XmlElement;
  const clones = block.map((row) => row.cloneNode(true) as XmlElement);

  const mealRows = new Map<MealKind, XmlElement>();
  let changeRow: XmlElement | null = null;
  for (const row of clones) {
    const label = menuCellText(row);
    const kind = (Object.keys(MEAL_LABELS) as MealKind[]).find((k) =>
      label.startsWith(MEAL_LABELS[k])
    );
    if (kind) mealRows.set(kind, row);
    else if (label.startsWith(CHANGE_LABEL)) changeRow = row;
  }

  const missing = (Object.keys(MEAL_LABELS) as MealKind[]).filter((k) =>
    !mealRows.has(k)
  );
  if (missing.length > 0) {
    throw new Error(
      `o modelo não traz a linha de ${missing.map((k) => MEAL_LABELS[k]).join(", ")}`,
    );
  }
  if (!changeRow) throw new Error(`o modelo não traz a linha "${CHANGE_LABEL}"`);

  prepareHeaderRow(header);
  // Todas as linhas do bloco, menos a última, grudam na seguinte: é assim que
  // o dia inteiro atravessa a quebra de página junto, em vez de deixar a
  // justificativa órfã no alto da página com a célula do dia vazia.
  clones.forEach((row, index) => prepareBodyRow(row, index < clones.length - 1));

  return { header, mealRows, changeRow, order: clones };
}

function firstCellText(row: XmlElement): string {
  return textOf(children(row, "tc")[0]).trim();
}

/** A coluna CARDÁPIO REALIZADO, onde mora o rótulo que identifica a linha. */
function menuCellText(row: XmlElement): string {
  return textOf(children(row, "tc")[1] ?? children(row, "tc")[0]).trim();
}

/** Uma linha abre bloco de dia quando a célula do dia começa a mescla vertical. */
function startsDayBlock(row: XmlElement): boolean {
  const properties = firstChild(children(row, "tc")[0], "tcPr");
  const merge = properties ? firstChild(properties, "vMerge") : null;
  return merge !== null && (getAttribute(merge, "val") ?? "continue") === "restart";
}

// --- normalização ----------------------------------------------------------
//
// O modelo que a escola usa hoje é um mapa preenchido à mão: cada linha tem
// altura travada (`hRule="exact"`, ajustada a olho para aquela semana) e o
// cabeçalho foi copiado no meio da tabela para cair certo na quebra de página.
// Nenhuma das duas coisas sobrevive a um mês inteiro gerado — texto maior que a
// altura travada some sem aviso, e o cabeçalho copiado cai em lugar aleatório.
// A normalização troca as duas por equivalentes que o Word calcula sozinho.

function prepareHeaderRow(row: XmlElement): void {
  relaxRowHeight(row);
  addRowProperty(row, "tblHeader"); // repete o cabeçalho a cada página
  addRowProperty(row, "cantSplit");
}

function prepareBodyRow(row: XmlElement, keepWithNext: boolean): void {
  relaxRowHeight(row);
  addRowProperty(row, "cantSplit"); // uma linha não se parte entre páginas
  if (!keepWithNext) return;
  for (const cell of children(row, "tc")) {
    for (const paragraph of children(cell, "p")) {
      addParagraphProperty(paragraph, "keepNext");
    }
  }
}

/** `exact` vira `atLeast`: a altura do modelo vira piso, não teto. */
function relaxRowHeight(row: XmlElement): void {
  const height = rowHeight(row);
  if (height) setAttribute(height, "hRule", "atLeast");
}

/** Deixa a linha encolher até o conteúdo — usado no dia sem refeição. */
function collapseRowHeight(row: XmlElement): void {
  const height = rowHeight(row);
  if (height) setAttribute(height, "val", "0");
}

function rowHeight(row: XmlElement): XmlElement | null {
  const properties = firstChild(row, "trPr");
  return properties ? firstChild(properties, "trHeight") : null;
}

function addRowProperty(row: XmlElement, local: string): void {
  let properties = firstChild(row, "trPr");
  if (!properties) {
    properties = makeElement(row, "trPr");
    row.insertBefore(properties, row.firstChild);
  }
  if (firstChild(properties, local)) return;
  properties.appendChild(makeElement(row, local));
}

/**
 * `w:pPr` é uma sequência de ordem normativa: o que vier fora de lugar faz o
 * Word recusar o arquivo. `w:keepNext` entra logo depois de `w:pStyle`.
 */
function addParagraphProperty(paragraph: XmlElement, local: string): void {
  let properties = firstChild(paragraph, "pPr");
  if (!properties) {
    properties = makeElement(paragraph, "pPr");
    paragraph.insertBefore(properties, paragraph.firstChild);
  }
  if (firstChild(properties, local)) return;
  const style = firstChild(properties, "pStyle");
  const created = makeElement(paragraph, local);
  if (style) properties.insertBefore(created, style.nextSibling);
  else properties.insertBefore(created, properties.firstChild);
}

// --- montagem da tabela ----------------------------------------------------

function rebuildTable(
  table: XmlElement,
  template: DayTemplate,
  mealMaps: MealMap[],
): void {
  for (const row of children(table, "tr")) removeElement(row);

  table.appendChild(template.header.cloneNode(true));
  for (const mealMap of mealMaps) {
    for (const row of buildDayRows(template, mealMap)) table.appendChild(row);
  }
}

function buildDayRows(template: DayTemplate, mealMap: MealMap): XmlElement[] {
  const rows = template.order.map((row) => row.cloneNode(true) as XmlElement);
  const byPrototype = new Map(template.order.map((row, index) => [row, rows[index]]));

  const first = rows[0];
  setCellLines(cellAt(first, 0), [formatDayAndMonth(mealMap.date)]);
  setCellLines(cellAt(first, 2), dayFoodItemLines(mealMap));
  setCellLines(cellAt(first, 3), dayChangeLines(mealMap));
  setCellLines(cellAt(first, 4), [mealCountText(mealMap)]);

  for (const kind of Object.keys(MEAL_LABELS) as MealKind[]) {
    const row = byPrototype.get(template.mealRows.get(kind)!)!;
    fillMealRow(row, mealMap, mealMap.meals.find((meal) => meal.kind === kind) ?? null);
  }

  fillChangeRow(byPrototype.get(template.changeRow)!, mealMap);
  return rows;
}

function fillMealRow(row: XmlElement, mealMap: MealMap, meal: Meal | null): void {
  const cell = cellAt(row, 1);
  const paragraphs = children(cell, "p");
  const menuParagraph = paragraphs[0];
  const acceptanceParagraph = paragraphs[1];

  if (!mealMap.schoolDay) {
    // Dia não letivo não tem refeição: a observação ocupa a primeira linha do
    // bloco e as outras duas ficam em branco, como quando é escrito à mão. As
    // linhas vazias encolhem — senão o dia sem aula ocuparia, em branco, a
    // mesma meia página de um dia cheio.
    const isFirstMealRow = menuCellText(row).startsWith(MEAL_LABELS.morning_snack);
    writeAfterLabel(menuParagraph, isFirstMealRow ? nonSchoolDayText(mealMap) : "", {
      keepLabel: false,
    });
    if (acceptanceParagraph) removeElement(acceptanceParagraph);
    dropExtraParagraphs(cell, 1);
    if (!isFirstMealRow) collapseRowHeight(row);
    return;
  }

  writeAfterLabel(menuParagraph, meal?.description ?? "", { keepLabel: true });
  if (acceptanceParagraph) {
    markAcceptance(acceptanceParagraph, meal?.acceptance ?? null);
  }
  dropExtraParagraphs(cell, acceptanceParagraph ? 2 : 1);
}

function fillChangeRow(row: XmlElement, mealMap: MealMap): void {
  const cell = cellAt(row, 1);
  const paragraph = children(cell, "p")[0];
  const reasons = mealMap.meals
    .filter((meal) => meal.change !== null)
    .map((meal) => `${MEAL_LABELS[meal.kind]}: ${meal.change!.reason}`);
  writeAfterLabel(paragraph, reasons.join("; "), { keepLabel: true });
  dropExtraParagraphs(cell, 1);
}

function nonSchoolDayText(mealMap: MealMap): string {
  const note = mealMap.note?.trim();
  return note ? `DIA NÃO LETIVO: ${note}` : "DIA NÃO LETIVO";
}

function mealCountText(mealMap: MealMap): string {
  if (!mealMap.schoolDay) return "—";
  return mealMap.mealCount === null ? "" : String(mealMap.mealCount);
}

function dayFoodItemLines(mealMap: MealMap): string[] {
  if (!mealMap.schoolDay) return [];
  return consolidateFoodItems(mealMap.meals).map(formatFoodItem);
}

function dayChangeLines(mealMap: MealMap): string[] {
  const lines: string[] = [];
  for (const meal of mealMap.meals) {
    if (!meal.change) continue;
    lines.push(`${MEAL_LABELS[meal.kind]}:`);
    for (const item of meal.change.foodItems) lines.push(formatFoodItem(item));
  }
  return lines;
}

// --- escrita dentro das células --------------------------------------------

function cellAt(row: XmlElement, index: number): XmlElement {
  const cell = children(row, "tc")[index];
  if (!cell) throw new Error(`o modelo não tem a coluna ${index + 1}`);
  return cell;
}

/**
 * Escreve o texto no primeiro parágrafo da célula, uma linha por `w:br`, e
 * descarta os demais parágrafos — no modelo eles são só espaçamento, e a
 * altura agora é calculada.
 */
function setCellLines(cell: XmlElement, lines: string[]): void {
  const paragraph = children(cell, "p")[0];
  if (!paragraph) return;
  writeAfterLabel(paragraph, "", { keepLabel: false });
  if (lines.length > 0) appendLines(paragraph, lines);
  dropExtraParagraphs(cell, 1);
}

/**
 * Substitui o conteúdo do parágrafo preservando a formatação que o modelo já
 * tem. Com `keepLabel`, a primeira `w:r` — o rótulo impresso, "Almoço:" — fica
 * onde está e o texto entra depois dela; sem, o parágrafo inteiro é reescrito.
 * Em ambos os casos o `w:rPr` reaproveitado é o do próprio modelo.
 */
function writeAfterLabel(
  paragraph: XmlElement,
  text: string,
  options: { keepLabel: boolean },
): void {
  const runs = children(paragraph, "r");
  const template = runs[0] ?? null;
  const style = template ? firstChild(template, "rPr") : null;

  const keep = options.keepLabel && template !== null;
  for (const run of runs.slice(keep ? 1 : 0)) removeElement(run);
  if (!keep && template) {
    // Sem rótulo a manter, a primeira `w:r` vira carcaça de formatação vazia.
    for (const node of descendants(template, "t")) removeElement(node);
    for (const node of descendants(template, "br")) removeElement(node);
    paragraph.appendChild(template);
  }

  if (text.length === 0) return;
  paragraph.appendChild(makeRun(paragraph, style, keep ? ` ${text}` : text));
}

function appendLines(paragraph: XmlElement, lines: string[]): void {
  const style = firstChild(children(paragraph, "r")[0] ?? paragraph, "rPr");
  lines.forEach((line, index) => {
    const run = makeRun(paragraph, style, line);
    if (index > 0) run.insertBefore(makeElement(paragraph, "br"), run.firstChild);
    paragraph.appendChild(run);
  });
}

function makeRun(
  owner: XmlElement,
  style: XmlElement | null,
  text: string,
): XmlElement {
  const run = makeElement(owner, "r");
  if (style) run.appendChild(style.cloneNode(true));
  const node = makeElement(owner, "t");
  node.setAttribute("xml:space", "preserve");
  node.appendChild(owner.ownerDocument!.createTextNode(text));
  run.appendChild(node);
  return run;
}

/**
 * Marca o grau de aceitação na linha que o modelo já imprime, trocando `( )`
 * por `(X)` só na opção registrada. O espaçamento original fica intacto —
 * reescrever a linha inteira seria recriar formatação que já existe.
 */
function markAcceptance(paragraph: XmlElement, acceptance: Meal["acceptance"]): void {
  const label = acceptance ? ACCEPTANCE_LABELS[acceptance] : null;
  for (const node of descendants(paragraph, "t")) {
    const text = node.textContent ?? "";
    if (!text.includes("(")) continue;
    node.textContent = label
      ? text.replace(new RegExp(`\\(\\s*\\)(\\s*${label})`, "i"), "(X)$1")
      : text;
  }
}

function dropExtraParagraphs(cell: XmlElement, keep: number): void {
  for (const paragraph of children(cell, "p").slice(keep)) removeElement(paragraph);
}

export { W };
