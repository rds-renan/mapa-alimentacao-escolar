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
  elementChildren,
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
  formatPeriod,
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
  layOutSignatures(body, table);

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
  const period = data.period ?? formatPeriod(data.mealMaps);
  for (const paragraph of children(body, "p")) {
    if (!textOf(paragraph).includes("ESCOLA:")) continue;
    replaceInParagraph(paragraph, (text) =>
      text
        .replace(
          /(ESCOLA:\s*)(_+)/,
          (_m: string, label: string, gap: string) =>
            label + overwriteGap(gap, data.schoolName),
        )
        .replace(
          /(MÊS\/ANO:\s*)(_+)/,
          (_m: string, label: string, gap: string) => label + overwriteGap(gap, period),
        ));
    return;
  }
}

/**
 * Escreve o valor sobre o tracejado. O que sobra da lacuna vira **espaço**, e
 * não tracejado: linha preenchida não precisa mais do convite a preencher, e
 * o rabicho de `_` depois do nome da escola é a marca de formulário
 * preenchido às pressas que este produto existe para acabar. Em espaço, o
 * comprimento em caracteres se mantém, e o "MÊS/ANO" continua caindo mais ou
 * menos onde caía.
 */
function overwriteGap(gap: string, value: string): string {
  const filled = ` ${value} `;
  if (filled.length >= gap.length) return filled;
  return filled + " ".repeat(gap.length - filled.length);
}

/**
 * Aplica uma substituição ao texto do parágrafo tolerando texto partido entre
 * runs.
 *
 * O Word reparte um trecho em várias `w:r` por motivos que nada têm a ver com
 * formatação — uma correção, uma pausa na digitação — e o modelo oficial já
 * mostra isso: o rótulo "Lanche da tarde:" chega em quatro runs. Procurar o
 * texto dentro de cada `w:t` isolado funciona hoje para a linha da aceitação,
 * mas basta alguém reeditar o modelo para o `( ) ótimo` cair em dois pedaços e
 * a marcação parar de acontecer **sem erro nenhum** — o documento sairia
 * bonito e sem o grau de aceitação.
 *
 * Então: primeiro tenta nó a nó, que é o caso comum e preserva a formatação
 * inteira. Só quando nenhum nó casa sozinho, mas o texto do parágrafo casa, o
 * parágrafo é colapsado — o resultado vai para o primeiro `w:t` e os demais
 * esvaziam. Nesse caso a formatação que variava entre as runs se perde, e é um
 * preço que se paga de bom grado para a marcação não sumir calada.
 */
function replaceInParagraph(
  paragraph: XmlElement,
  transform: (text: string) => string,
): boolean {
  const nodes = descendants(paragraph, "t");
  if (nodes.length === 0) return false;

  let changed = false;
  for (const node of nodes) {
    const original = node.textContent ?? "";
    const replaced = transform(original);
    if (replaced === original) continue;
    node.textContent = replaced;
    changed = true;
  }
  if (changed) return true;

  const whole = nodes.map((node) => node.textContent ?? "").join("");
  const replaced = transform(whole);
  if (replaced === whole) return false;

  nodes[0].textContent = replaced;
  for (const node of nodes.slice(1)) node.textContent = "";
  return true;
}

// --- assinaturas -----------------------------------------------------------

/**
 * Centraliza cada rótulo de assinatura sob o seu traço e amarra o rodapé ao
 * último dia da tabela.
 *
 * No modelo, os dois traços e os dois rótulos — "Cozinheiro(a) responsável pelo
 * mapa" e "Diretor(a)" — foram posicionados com sequências de espaço, contadas
 * a olho. Em fonte proporcional isso nunca alinha: o "Diretor(a)" sai muito à
 * direita do traço dele. Aqui os dois parágrafos viram uma **tabela sem borda
 * de uma coluna por assinatura**, com traço e rótulo centralizados na célula.
 * Paradas de tabulação centralizadas seriam o mecanismo "certo" do Word, mas o
 * editor do Word Online não as respeita (#154): o primeiro traço caía na linha
 * de baixo e os rótulos se juntavam no meio. Tabela, todo editor desenha igual.
 *
 * O reconhecimento é pela forma, não pela posição: o parágrafo dos traços é o
 * que só tem `_` e espaço, com mais de um grupo; o dos rótulos é o próximo com
 * texto. Quantidades diferentes de traço e de rótulo fazem a função desistir
 * em silêncio de alinhar e deixar os parágrafos como estavam — é acabamento,
 * não conteúdo, e não vale falhar uma geração por causa dele. A amarração com
 * o último dia acontece de todo jeito.
 */
function layOutSignatures(body: XmlElement, mapTable: XmlElement): void {
  const paragraphs = trailingParagraphs(body);
  const rulesIndex = paragraphs.findIndex(isRuleParagraph);
  if (rulesIndex < 0) return;

  const rulesParagraph = paragraphs[rulesIndex];
  const labelIndex = paragraphs.findIndex((paragraph, index) =>
    index > rulesIndex && textOf(paragraph).trim().length > 0
  );
  const footer = paragraphs.slice(0, labelIndex < 0 ? rulesIndex + 1 : labelIndex + 1);

  const rules = textOf(rulesParagraph).match(/_+/g) ?? [];
  const labels = labelIndex < 0
    ? []
    : textOf(paragraphs[labelIndex]).trim().split(/\s{2,}/);
  const aligned = rules.length >= 2 && labels.length === rules.length;

  const content = aligned
    ? [
      ...paragraphs.slice(0, rulesIndex), // o respiro
      signatureTable(
        rulesParagraph,
        paragraphs[labelIndex],
        rules,
        labels,
        footerTextWidth(mapTable),
      ),
      // Toda célula termina em parágrafo; este não pode ocupar espaço.
      emptyParagraph(rulesParagraph),
    ]
    : footer;
  for (const paragraph of footer) removeElement(paragraph);
  keepFooterWithLastDay(mapTable, content);
}

/**
 * O rodapé — o respiro de parágrafos vazios, os traços e os rótulos — não se
 * separa, e leva o último dia junto. Sem isso, num período que enche a página,
 * o respiro ficava no pé da página 1 e as assinaturas iam sozinhas para o
 * alto da página 2, coladas no cabeçalho, sem nada do mapa que elas assinam.
 *
 * Por isso o rodapé passa a ser **a última linha da tabela do mapa**: uma
 * célula sem borda, da largura da tabela, que não se parte (`cantSplit`), e a
 * última linha do último dia gruda nela como as outras linhas do dia já grudam
 * entre si. Parágrafos fora da tabela não serviriam: o Word sabe grudar a
 * última linha de uma tabela no parágrafo seguinte, mas o LibreOffice só sabe
 * grudar a tabela **inteira** — e aí ela pularia toda para a página 2.
 */
function keepFooterWithLastDay(mapTable: XmlElement, content: XmlElement[]): void {
  const lastRow = children(mapTable, "tr").at(-1);
  if (lastRow) {
    for (const cell of children(lastRow, "tc")) {
      for (const paragraph of children(cell, "p")) {
        paragraphProperty(paragraph, "keepNext");
      }
    }
  }

  const columns = gridColumns(mapTable);
  const row = makeElement(mapTable, "tr");
  addRowProperty(row, "cantSplit");
  const cell = makeElement(mapTable, "tc");
  const properties = makeElement(mapTable, "tcPr");
  properties.appendChild(widthElement(mapTable, "tcW", sum(columns)));
  const span = makeElement(mapTable, "gridSpan");
  setAttribute(span, "val", String(columns.length));
  properties.appendChild(span);
  properties.appendChild(
    noBorders(mapTable, "tcBorders", ["top", "left", "bottom", "right"]),
  );
  cell.appendChild(properties);
  for (const node of content) cell.appendChild(node);
  row.appendChild(cell);
  mapTable.appendChild(row);

  // O documento não pode terminar numa tabela: o Word exige um parágrafo
  // depois dela. Se o rodapé era o que vinha depois, entra um sem altura.
  let next = mapTable.nextSibling;
  while (next && next.nodeType !== 1) next = next.nextSibling;
  if ((next as XmlElement | null)?.localName !== "p") {
    mapTable.parentNode!.insertBefore(emptyParagraph(mapTable), next);
  }
}

/** Os parágrafos que vêm depois da tabela — o rodapé de assinaturas. */
function trailingParagraphs(body: XmlElement): XmlElement[] {
  const all = elementChildren(body);
  const tableIndex = all.findIndex((node) => node.localName === "tbl");
  if (tableIndex < 0) return [];
  return all.slice(tableIndex + 1).filter((node) => node.localName === "p");
}

/** Um parágrafo de traços não tem nada além de `_` e espaço. */
function isRuleParagraph(paragraph: XmlElement): boolean {
  const text = textOf(paragraph);
  return text.includes("__") && /^[\s_]+$/.test(text);
}

function gridColumns(table: XmlElement): number[] {
  const grid = firstChild(table, "tblGrid");
  return (grid ? children(grid, "gridCol") : [])
    .map((column) => Number(getAttribute(column, "w") ?? 0) || 0);
}

function sum(values: number[]): number {
  return values.reduce((total, value) => total + value, 0);
}

/**
 * A largura onde cabe texto na célula do rodapé: a da tabela menos as margens
 * internas da célula, que o modelo declara em `w:tblCellMar` (108 twips de
 * cada lado, o padrão do Word, se não declarar).
 */
function footerTextWidth(mapTable: XmlElement): number {
  const properties = firstChild(mapTable, "tblPr");
  const margins = properties ? firstChild(properties, "tblCellMar") : null;
  const margin = (side: string) => {
    const el = margins ? firstChild(margins, side) : null;
    const value = el ? Number(getAttribute(el, "w")) : NaN;
    return Number.isFinite(value) ? value : 108;
  };
  return sum(gridColumns(mapTable)) - margin("left") - margin("right");
}

function widthElement(reference: XmlElement, local: string, width: number): XmlElement {
  const element = makeElement(reference, local);
  setAttribute(element, "w", String(width));
  setAttribute(element, "type", "dxa");
  return element;
}

function noBorders(reference: XmlElement, local: string, sides: string[]): XmlElement {
  const borders = makeElement(reference, local);
  for (const side of sides) {
    const border = makeElement(reference, side);
    setAttribute(border, "val", "nil");
    borders.appendChild(border);
  }
  return borders;
}

/** Um parágrafo vazio de altura desprezível, para fechar célula ou documento. */
function emptyParagraph(reference: XmlElement): XmlElement {
  const paragraph = makeElement(reference, "p");
  const spacing = paragraphProperty(paragraph, "spacing");
  setAttribute(spacing, "before", "0");
  setAttribute(spacing, "after", "0");
  setAttribute(spacing, "line", "20");
  setAttribute(spacing, "lineRule", "exact");
  const mark = paragraphProperty(paragraph, "rPr");
  const size = makeElement(reference, "sz");
  setAttribute(size, "val", "2");
  mark.appendChild(size);
  return paragraph;
}

/**
 * A tabela das assinaturas: uma linha, uma coluna por assinatura, todas da
 * mesma largura, sem borda. Cada célula leva o traço e, embaixo, o rótulo,
 * centralizados — com o espaçamento e a fonte que os dois parágrafos tinham no
 * modelo.
 */
function signatureTable(
  rulesParagraph: XmlElement,
  labelParagraph: XmlElement,
  rules: string[],
  labels: string[],
  width: number,
): XmlElement {
  const columnWidth = Math.floor(width / rules.length);
  const table = makeElement(rulesParagraph, "tbl");

  // A ordem dentro de `w:tblPr` é normativa: largura, alinhamento, bordas, layout.
  const properties = makeElement(table, "tblPr");
  properties.appendChild(widthElement(table, "tblW", columnWidth * rules.length));
  const alignment = makeElement(table, "jc");
  setAttribute(alignment, "val", "center");
  properties.appendChild(alignment);
  properties.appendChild(
    noBorders(table, "tblBorders", [
      "top",
      "left",
      "bottom",
      "right",
      "insideH",
      "insideV",
    ]),
  );
  const layout = makeElement(table, "tblLayout");
  setAttribute(layout, "type", "fixed");
  properties.appendChild(layout);
  table.appendChild(properties);

  const grid = makeElement(table, "tblGrid");
  for (const _rule of rules) {
    const column = makeElement(table, "gridCol");
    setAttribute(column, "w", String(columnWidth));
    grid.appendChild(column);
  }
  table.appendChild(grid);

  const row = makeElement(table, "tr");
  rules.forEach((rule, index) => {
    const cell = makeElement(table, "tc");
    const cellProperties = makeElement(table, "tcPr");
    cellProperties.appendChild(widthElement(table, "tcW", columnWidth));
    cell.appendChild(cellProperties);
    cell.appendChild(centeredCopy(rulesParagraph, rule));
    cell.appendChild(centeredCopy(labelParagraph, labels[index]));
    row.appendChild(cell);
  });
  table.appendChild(row);
  return table;
}

/**
 * Uma cópia do parágrafo com só `text`, centralizada. O `w:pPr` (estilo e
 * espaçamento) e o `w:rPr` da primeira run vêm do modelo; recuo e tabulação,
 * que serviam para posicionar na página, não fazem sentido dentro da célula.
 */
function centeredCopy(paragraph: XmlElement, text: string): XmlElement {
  const style = firstChild(children(paragraph, "r")[0] ?? paragraph, "rPr");
  const copy = makeElement(paragraph, "p");
  const properties = firstChild(paragraph, "pPr");
  if (properties) copy.appendChild(properties.cloneNode(true));

  for (const local of ["tabs", "ind"]) {
    const existing = firstChild(firstChild(copy, "pPr") ?? copy, local);
    if (existing) removeElement(existing);
  }
  setAttribute(paragraphProperty(copy, "jc"), "val", "center");

  copy.appendChild(makeRun(copy, style, text));
  return copy;
}

// --- leitura do gabarito ---------------------------------------------------

function extractDayTemplate(table: XmlElement): DayTemplate {
  const rows = children(table, "tr");
  const headerIndex = rows.findIndex((row) => firstCellText(row) === HEADER_LABEL);
  if (headerIndex < 0) {
    throw new Error(`o modelo não tem linha de cabeçalho ("${HEADER_LABEL}")`);
  }

  const blocks = collectDayBlocks(rows, headerIndex);
  if (blocks.length === 0) {
    throw new Error("o modelo não tem bloco de dia (célula do dia mesclada)");
  }

  // Não é o primeiro bloco que serve de gabarito, e sim o primeiro **íntegro**.
  // O modelo é um arquivo só, que circula sendo reeditado a cada semana, e a
  // cada edição alguém desloca uma linha sem reparar. Se esse deslize cair
  // justamente no primeiro dia — uma linha duplicada, por exemplo —, tomar
  // aquele bloco como gabarito propagaria o defeito para todos os dias do
  // documento. Os outros dias do modelo servem de segunda opinião: basta um
  // deles estar inteiro.
  const block = blocks.find(isIntactBlock) ?? blocks[0];

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

/** Todos os blocos de dia do modelo, cada um da linha que abre a mescla até a próxima. */
function collectDayBlocks(rows: XmlElement[], headerIndex: number): XmlElement[][] {
  const blocks: XmlElement[][] = [];
  let current: XmlElement[] | null = null;

  for (const row of rows.slice(headerIndex + 1)) {
    if (startsDayBlock(row)) {
      current = [row];
      blocks.push(current);
    } else if (firstCellText(row) === HEADER_LABEL) {
      current = null; // cabeçalho repetido no meio: o bloco anterior acabou
    } else {
      current?.push(row);
    }
  }
  return blocks;
}

/**
 * Um bloco está íntegro quando traz **exatamente uma** linha de cada refeição e
 * uma de justificativa. Linha a mais de uma refeição que já apareceu é o sinal
 * do deslize de edição; linha que não corresponde a rótulo nenhum é tolerada,
 * porque pode ser algo que a prefeitura acrescentou de propósito.
 */
function isIntactBlock(block: XmlElement[]): boolean {
  const roles = block.map(rowRole);
  const expected = [...Object.keys(MEAL_LABELS), "change"];
  return expected.every((role) => roles.filter((found) => found === role).length === 1);
}

/** Qual papel a linha tem no bloco, pelo rótulo que ela imprime. */
function rowRole(row: XmlElement): string {
  const label = menuCellText(row);
  const kind = (Object.keys(MEAL_LABELS) as MealKind[]).find((k) =>
    label.startsWith(MEAL_LABELS[k])
  );
  if (kind) return kind;
  return label.startsWith(CHANGE_LABEL) ? "change" : "unknown";
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
      paragraphProperty(paragraph, "keepNext");
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
 * `w:pPr` é uma sequência de ordem normativa, e o que vier fora de lugar faz o
 * Word recusar o arquivo inteiro. Esta é a ordem na parte do schema que
 * interessa aqui — o que o modelo usa, mais o que o preenchimento acrescenta.
 */
const PARAGRAPH_PROPERTY_ORDER = [
  "pStyle",
  "keepNext",
  "keepLines",
  "pageBreakBefore",
  "widowControl",
  "numPr",
  "pBdr",
  "shd",
  "tabs",
  "suppressAutoHyphens",
  "snapToGrid",
  "spacing",
  "ind",
  "contextualSpacing",
  "jc",
  "textDirection",
  "textAlignment",
  "outlineLvl",
  "rPr",
];

/** Cria (ou devolve) um `w:<local>` no `w:pPr`, no lugar que o schema manda. */
function paragraphProperty(paragraph: XmlElement, local: string): XmlElement {
  let properties = firstChild(paragraph, "pPr");
  if (!properties) {
    properties = makeElement(paragraph, "pPr");
    paragraph.insertBefore(properties, paragraph.firstChild);
  }
  const existing = firstChild(properties, local);
  if (existing) return existing;

  const position = PARAGRAPH_PROPERTY_ORDER.indexOf(local);
  const successor = elementChildren(properties).find((sibling) => {
    const index = PARAGRAPH_PROPERTY_ORDER.indexOf(sibling.localName ?? "");
    return index > position;
  });

  const created = makeElement(paragraph, local);
  if (successor) properties.insertBefore(created, successor);
  else properties.appendChild(created);
  return created;
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
  run.appendChild(makeText(owner, text));
  return run;
}

/** Um `w:t` que não come os espaços das pontas. */
function makeText(owner: XmlElement, text: string): XmlElement {
  const node = makeElement(owner, "t");
  node.setAttribute("xml:space", "preserve");
  node.appendChild(owner.ownerDocument!.createTextNode(text));
  return node;
}

/**
 * Marca o grau de aceitação na linha que o modelo já imprime, trocando `( )`
 * por `(X)` só na opção registrada. O espaçamento original fica intacto —
 * reescrever a linha inteira seria recriar formatação que já existe.
 */
function markAcceptance(paragraph: XmlElement, acceptance: Meal["acceptance"]): void {
  // Sem registro, a linha fica como o modelo a imprime: nenhuma opção marcada.
  if (!acceptance) return;
  const option = new RegExp(`\\(\\s*\\)(\\s*${ACCEPTANCE_LABELS[acceptance]})`, "i");
  replaceInParagraph(paragraph, (text) => text.replace(option, "(X)$1"));
}

function dropExtraParagraphs(cell: XmlElement, keep: number): void {
  for (const paragraph of children(cell, "p").slice(keep)) removeElement(paragraph);
}

export { W };
