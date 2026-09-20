// O nome com que o documento chega no aparelho de quem recebe.
//
// Ele não é detalhe: o arquivo sai daqui e vai para o WhatsApp da secretaria,
// onde vive ao lado de dezenas de outros. O que hoje chega lá tem nome de
// arquivo reencaminhado ("2.MAPA-escola integral -Agosto-Semana 4.docx"), e o
// que o sistema manda pode dizer o que é sem que ninguém precise abrir.

import { formatPeriod, type MealMap } from "../_shared/dados.ts";

/**
 * Sem acento e sem espaço, de propósito: o nome viaja em cabeçalho HTTP, passa
 * por aplicativo de mensagem e termina no sistema de arquivos de um celular
 * que não é nosso. O que sobrevive a esse caminho inteiro é ASCII.
 */
function slug(text: string): string {
  return text
    .normalize("NFD")
    .replace(/[̀-ͯ]/g, "")
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "");
}

export function documentFileName(mealMaps: MealMap[]): string {
  const period = slug(formatPeriod(mealMaps));
  const base = "mapa-da-alimentacao-escolar";
  return period ? `${base}-${period}.docx` : `${base}.docx`;
}
