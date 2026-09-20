// O que passou do prazo (RN#2 da US012).
//
// Duas pendências, que são a mesma coisa vista de dois lados — geração que não
// terminou e arquivo que não devia mais existir:
//
//   * o arquivo de um documento vencido sai do balde. O registro fica, e é ele
//     que diz que os mapas do período continuam guardados (decisão 10 da E4);
//   * a geração que ficou "em processamento" além de uma hora é encerrada como
//     falha. Só chega aqui a que morreu no meio — a que termina, termina em
//     menos de um segundo.
//
// Por que apagar de verdade, e não deixar o link vencer: a política do balde
// já recusa servir o arquivo vencido, mas ele continuaria guardado para sempre
// — e o que está guardado é um documento com o brasão da prefeitura e o mapa
// de uma escola. "O sistema não mantém cópia permanente do documento" é regra
// da US012 e é a regra de sigilo do projeto.
//
// Quem chama é o agendador, com a chave secreta: não há usuária do outro lado.
// Como agendá-lo está em docs/05-web/geracao-do-documento.md.

import { isServiceToken, serviceClient } from "../_shared/cliente.ts";
import { bearer, failure, json, preflight } from "../_shared/resposta.ts";

const DOCUMENT_BUCKET = "generated-documents";

/** Uma geração parada além disto morreu no meio: nada legítimo demora tanto. */
const ABANDONED_AFTER_MS = 60 * 60 * 1000;

/** Uma página por pasta basta: a escola gera um documento por mês, não por hora. */
const PAGE = 1000;

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") return preflight();

  const token = bearer(request);
  if (!token || !isServiceToken(token)) {
    return failure(401, "Esta rotina é chamada pelo próprio servidor.");
  }

  const supabase = serviceClient();
  const removed = await removeExpiredFiles(supabase);
  const closed = await closeAbandonedGenerations(supabase);

  return json(200, { removed_files: removed, closed_generations: closed });
});

/**
 * Varre o balde, e não a tabela: o balde é quem sabe o que ainda está lá. Pela
 * tabela, cada passagem reprocessaria todo documento já gerado na história da
 * escola, e um arquivo que tivesse perdido o registro nunca seria alcançado.
 */
async function removeExpiredFiles(
  supabase: ReturnType<typeof serviceClient>,
): Promise<number> {
  const bucket = supabase.storage.from(DOCUMENT_BUCKET);

  const { data: records, error } = await supabase
    .from("generated_document")
    .select("file_path, expires_at")
    .not("file_path", "is", null)
    .returns<{ file_path: string; expires_at: string | null }[]>();
  if (error) {
    console.error("não foi possível ler os documentos gerados:", error);
    return 0;
  }
  const validUntil = new Map(records.map((row) => [row.file_path, row.expires_at]));

  // O arquivo mora em `<escola>/<documento>.docx`, então a varredura tem dois
  // níveis: as pastas das escolas e os arquivos dentro delas.
  const { data: folders, error: foldersError } = await bucket.list("", { limit: PAGE });
  if (foldersError) {
    console.error("não foi possível listar o balde:", foldersError);
    return 0;
  }

  const now = Date.now();
  const expired: string[] = [];
  for (const folder of folders ?? []) {
    const { data: files, error: filesError } = await bucket.list(folder.name, {
      limit: PAGE,
    });
    if (filesError) {
      console.error("não foi possível listar", folder.name, filesError);
      continue;
    }
    for (const file of files ?? []) {
      const path = `${folder.name}/${file.name}`;
      const until = validUntil.get(path);
      // Arquivo sem registro é sobra de uma geração que não chegou ao fim: não
      // há como servi-lo — a política do balde exige o registro —, e ele não
      // tem por que continuar guardado.
      if (until === undefined || until === null || Date.parse(until) <= now) {
        expired.push(path);
      }
    }
  }

  if (expired.length === 0) return 0;

  const { error: removeError } = await bucket.remove(expired);
  if (removeError) {
    console.error("não foi possível apagar os vencidos:", removeError);
    return 0;
  }
  return expired.length;
}

/**
 * A geração é síncrona, então "em processamento" é um estado de segundos. Se
 * ela sobreviver a uma hora, quem a abriu já não existe para encerrá-la — e um
 * registro que fica em processamento para sempre é uma promessa que a lista de
 * documentos faz à merendeira e nunca cumpre.
 */
async function closeAbandonedGenerations(
  supabase: ReturnType<typeof serviceClient>,
): Promise<number> {
  const { data: stale, error } = await supabase
    .from("generated_document")
    .select("id")
    .eq("status", "processing")
    .lt("requested_at", new Date(Date.now() - ABANDONED_AFTER_MS).toISOString())
    .returns<{ id: string }[]>();
  if (error) {
    console.error("não foi possível procurar gerações abandonadas:", error);
    return 0;
  }

  let closed = 0;
  for (const document of stale) {
    const { error: failError } = await supabase.rpc("fail_document_generation", {
      p_document_id: document.id,
    });
    if (failError) console.error("não foi possível encerrar", document.id, failError);
    else closed += 1;
  }
  return closed;
}
