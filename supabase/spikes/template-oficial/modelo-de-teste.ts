// Um modelo com a mesma estrutura do oficial, sem nada que seja da prefeitura.
//
// O modelo oficial não entra no repositório — tem brasão, nome da prefeitura e
// um mapa real preenchido. Sem um substituto, ninguém consegue rodar o spike
// nem testá-lo na integração contínua. Este arquivo constrói, do zero, um
// .docx que reproduz o que importa para o preenchimento:
//
//   - a mesma tabela de cinco colunas, com os mesmos rótulos;
//   - o mesmo bloco de quatro linhas por dia (três refeições e a justificativa);
//   - a mesma mescla vertical nas colunas do dia, dos gêneros, das alterações
//     e do número de refeições;
//   - os mesmos dois vícios do original: altura de linha travada em `exact` e
//     cabeçalho copiado no meio da tabela.
//
// O que ele não reproduz é a aparência — bordas, sombreado, brasão, fontes.
// Fidelidade visual só se prova contra o arquivo oficial de verdade.

import { zipSync } from "fflate";

const W = "http://schemas.openxmlformats.org/wordprocessingml/2006/main";

const encode = (xml: string): Uint8Array => new TextEncoder().encode(xml);

const COLUMN_WIDTHS = [546, 5657, 4536, 4111, 1276];
const HEADER_LABELS = [
  "Dia",
  "CARDÁPIO REALIZADO",
  "GÊNEROS UTILIZADOS",
  "Em caso de alterações no cardápio, descreva os gêneros utilizados e as quantidades abaixo:",
  "Número de refeições:",
];
const MEAL_LABELS = ["Lanche da manhã:", "Almoço:", "Lanche da tarde:"];
const ACCEPTANCE_LINE = "Grau de aceitação:      ( ) ótimo   ( ) bom   ( ) ruim";
const CHANGE_LABEL = "Mudança no cardápio, justificativa:";

/** Dias de exemplo, só para o modelo nascer com blocos como o oficial. */
const SAMPLE_DAYS = ["01/01", "02/01"];

export function buildTestTemplate(): Uint8Array {
  return zipSync({
    "[Content_Types].xml": encode(contentTypes()),
    "_rels/.rels": encode(packageRelationships()),
    "docProps/core.xml": encode(coreProperties()),
    "word/document.xml": encode(documentPart()),
  });
}

function documentPart(): string {
  const rows = [headerRow()];
  SAMPLE_DAYS.forEach((day, index) => {
    // O original repete o cabeçalho no meio da tabela; o modelo de teste
    // também, para o preenchimento ter de lidar com isso.
    if (index === 1) rows.push(headerRow());
    rows.push(...dayBlock(day));
  });

  return xmlDeclaration() +
    `<w:document xmlns:w="${W}"><w:body>` +
    paragraph("MAPA DA ALIMENTAÇÃO ESCOLAR") +
    paragraph(
      "ESCOLA: ___________________________________________________________" +
        "      MÊS/ANO:_____________________________",
    ) +
    `<w:tbl>${tableProperties()}${rows.join("")}</w:tbl>` +
    paragraph("") +
    '<w:sectPr><w:pgSz w:orient="landscape" w:w="16838" w:h="11906"/>' +
    '<w:pgMar w:left="284" w:right="284" w:top="720" w:bottom="720"' +
    ' w:header="426" w:footer="0" w:gutter="0"/></w:sectPr>' +
    "</w:body></w:document>";
}

function tableProperties(): string {
  return '<w:tblPr><w:tblW w:w="16126" w:type="dxa"/><w:tblLayout w:type="fixed"/></w:tblPr>' +
    "<w:tblGrid>" +
    COLUMN_WIDTHS.map((width) => `<w:gridCol w:w="${width}"/>`).join("") +
    "</w:tblGrid>";
}

function headerRow(): string {
  const cells = HEADER_LABELS.map((label, index) =>
    cell(index, [paragraph(label)], { merge: null })
  );
  return row(679, cells.join(""));
}

function dayBlock(day: string): string[] {
  const rows: string[] = [];

  MEAL_LABELS.forEach((label, index) => {
    const first = index === 0;
    const menu = paragraph(label) + paragraph(ACCEPTANCE_LINE) +
      // O original enche a primeira linha do bloco de parágrafos vazios, para
      // empurrar a altura. O preenchimento tem de saber descartá-los.
      (first ? paragraph("").repeat(4) : paragraph(""));
    rows.push(
      row(
        first ? 1012 : 997,
        [
          cell(0, [paragraph(first ? day : "")], {
            merge: first ? "restart" : "continue",
          }),
          cell(1, [menu], { merge: null }),
          cell(2, [paragraph("")], { merge: first ? "restart" : "continue" }),
          cell(3, [paragraph("")], { merge: first ? "restart" : "continue" }),
          cell(4, [paragraph("")], { merge: first ? "restart" : "continue" }),
        ].join(""),
      ),
    );
  });

  rows.push(
    row(
      669,
      [
        cell(0, [paragraph("")], { merge: "continue" }),
        cell(1, [paragraph(CHANGE_LABEL)], { merge: null }),
        cell(2, [paragraph("")], { merge: "continue" }),
        cell(3, [paragraph("")], { merge: "continue" }),
        cell(4, [paragraph("")], { merge: "continue" }),
      ].join(""),
      "atLeast",
    ),
  );

  return rows;
}

function row(height: number, cells: string, rule = "exact"): string {
  return `<w:tr><w:trPr><w:trHeight w:val="${height}" w:hRule="${rule}"/></w:trPr>${cells}</w:tr>`;
}

function cell(
  index: number,
  content: string[],
  options: { merge: "restart" | "continue" | null },
): string {
  const merge = options.merge ? `<w:vMerge w:val="${options.merge}"/>` : "";
  return `<w:tc><w:tcPr><w:tcW w:w="${
    COLUMN_WIDTHS[index]
  }" w:type="dxa"/>${merge}</w:tcPr>` +
    content.join("") +
    "</w:tc>";
}

function paragraph(text: string): string {
  const run = text.length > 0
    ? `<w:r><w:rPr><w:rFonts w:ascii="Arial" w:hAnsi="Arial"/><w:b/><w:sz w:val="20"/></w:rPr>` +
      `<w:t xml:space="preserve">${escapeXml(text)}</w:t></w:r>`
    : `<w:r><w:rPr><w:rFonts w:ascii="Arial" w:hAnsi="Arial"/><w:b/><w:sz w:val="20"/></w:rPr></w:r>`;
  return `<w:p><w:pPr><w:pStyle w:val="Normal"/></w:pPr>${run}</w:p>`;
}

function contentTypes(): string {
  return xmlDeclaration() +
    '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">' +
    '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>' +
    '<Default Extension="xml" ContentType="application/xml"/>' +
    '<Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>' +
    '<Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>' +
    "</Types>";
}

function packageRelationships(): string {
  return xmlDeclaration() +
    '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">' +
    '<Relationship Id="rId1" Target="word/document.xml"' +
    ' Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument"/>' +
    '<Relationship Id="rId2" Target="docProps/core.xml"' +
    ' Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties"/>' +
    "</Relationships>";
}

/** Nasce com nome de gente, como o oficial — é o que a limpeza tem de apagar. */
function coreProperties(): string {
  return xmlDeclaration() +
    '<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties"' +
    ' xmlns:dc="http://purl.org/dc/elements/1.1/">' +
    "<dc:creator>Fulana de Tal</dc:creator>" +
    "<cp:lastModifiedBy>Beltrana de Tal</cp:lastModifiedBy>" +
    "</cp:coreProperties>";
}

function xmlDeclaration(): string {
  return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>';
}

function escapeXml(text: string): string {
  return text
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;");
}

if (import.meta.main) {
  const output = Deno.args[0] ?? "modelo-de-teste.docx";
  await Deno.writeFile(output, buildTestTemplate());
  console.log(output);
}
