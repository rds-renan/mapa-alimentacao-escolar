// Gera o documento de amostra do spike.
//
//   deno task amostra --modelo=<entrada.docx> --saida=<amostra.docx>
//
// O modelo de entrada é o oficial — que mora fora do repositório — ou o
// [modelo de teste](modelo-de-teste.ts), que reproduz a estrutura sem o brasão
// e sem o nome da prefeitura. A saída também fica fora do repositório: é um
// .docx, e `.gitignore` barra .docx de propósito.

import { parseArgs } from "@std/cli/parse-args";
import { fillOfficialTemplate } from "./preenchimento.ts";
import { sampleMonth } from "./dados-ficticios.ts";

if (import.meta.main) {
  const args = parseArgs(Deno.args, { string: ["modelo", "saida"] });
  const input = args.modelo;
  const output = args.saida ?? "amostra.docx";

  if (!input) {
    console.error(
      "uso: deno task amostra --modelo=<entrada.docx> [--saida=<amostra.docx>]",
    );
    Deno.exit(2);
  }

  const data = sampleMonth();
  const filled = fillOfficialTemplate(await Deno.readFile(input), data);
  await Deno.writeFile(output, filled);

  const days = data.mealMaps.length;
  const nonSchoolDays = data.mealMaps.filter((mealMap) => !mealMap.schoolDay).length;
  console.log(
    `${output}: ${days} dias (${nonSchoolDays} não letivos), ` +
      `${(filled.byteLength / 1024).toFixed(0)} KB`,
  );
}
