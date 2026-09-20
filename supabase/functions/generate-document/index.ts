// A geração do documento oficial (US012, US013).
//
// A merendeira escolhe os dias e recebe um documento só, no modelo da
// prefeitura, por link temporário. Tudo acontece no servidor porque é aqui que
// o modelo oficial pode ser lido — ele mora num balde privado e não passa pelo
// navegador (RNF#1 da US012).
//
// O caminho, na ordem:
//
//   1. quem chamou é uma merendeira ativa desta escola?
//   2. `start_document_generation` valida o pedido e registra a geração
//   3. lê os mapas e o modelo vigente
//   4. preenche o modelo (o preenchedor é o do spike, em _shared/)
//   5. guarda o arquivo no balde privado
//   6. `complete_document_generation` publica e bloqueia os mapas incluídos
//   7. devolve o link assinado, com a validade que o banco carimbou
//
// Qualquer tropeço entre o 3 e o 6 encerra a geração como falha, e nenhum mapa
// é bloqueado — não houve documento, não há o que bloquear.
//
// A resposta é síncrona: o mês inteiro levou 336 ms no spike, contra os 30
// segundos do RNF#2. A situação "em processamento" continua existindo no
// registro porque é ela que sustenta o caminho da falha, não porque a
// merendeira vá esperar por ela.

import { fillOfficialTemplate } from "../_shared/preenchimento.ts";
import { serviceClient } from "../_shared/cliente.ts";
import { bearer, failure, fromDatabase, json, preflight } from "../_shared/resposta.ts";
import { MEAL_MAP_SELECT, type MealMapRow, toDocumentData } from "./consulta.ts";
import { documentFileName } from "./nome-do-arquivo.ts";

const TEMPLATE_BUCKET = "document-templates";
const DOCUMENT_BUCKET = "generated-documents";
const DOCX_TYPE =
  "application/vnd.openxmlformats-officedocument.wordprocessingml.document";

interface GeneratedDocument {
  id: string;
  school_id: string;
  document_template_id: string;
  status: string;
  requested_at: string;
  completed_at: string | null;
  expires_at: string | null;
  file_name: string | null;
}

/** O identificador dos dias pedidos, como a web os manda. */
function readMealMapIds(body: unknown): string[] | null {
  if (typeof body !== "object" || body === null) return null;
  const ids = (body as Record<string, unknown>).meal_map_ids;
  if (!Array.isArray(ids) || ids.length === 0) return null;
  if (ids.some((id) => typeof id !== "string" || id.length === 0)) return null;
  return ids as string[];
}

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") return preflight();
  if (request.method !== "POST") {
    return failure(405, "Este endereço só aceita POST.");
  }

  const token = bearer(request);
  if (!token) return failure(401, "Entre de novo para gerar o documento.");

  const supabase = serviceClient();

  const { data: authenticated, error: authError } = await supabase.auth.getUser(token);
  if (authError || !authenticated.user) {
    return failure(401, "Entre de novo para gerar o documento.");
  }

  let mealMapIds: string[] | null = null;
  try {
    mealMapIds = readMealMapIds(await request.json());
  } catch {
    mealMapIds = null;
  }
  if (!mealMapIds) {
    return failure(400, "Selecione ao menos um dia para gerar o documento.");
  }

  // O perfil diz a escola e o papel. A função do banco confere os dois de
  // novo, e é lá que a regra vale — aqui é só para a recusa chegar com a
  // resposta certa antes de abrir uma geração que seria descartada.
  const { data: profile, error: profileError } = await supabase
    .from("profile")
    .select("id, school_id, role, active")
    .eq("id", authenticated.user.id)
    .maybeSingle();

  if (profileError) return fromDatabase(profileError);
  if (!profile || !profile.active || profile.role !== "cook") {
    return failure(403, "Só a merendeira gera o documento do mapa.");
  }

  const { data: opened, error: openError } = await supabase
    .rpc("start_document_generation", {
      p_school_id: profile.school_id,
      p_requested_by: profile.id,
      p_meal_map_ids: mealMapIds,
    })
    .single<GeneratedDocument>();

  if (openError) return fromDatabase(openError);

  try {
    const filled = await generate(supabase, opened, profile.school_id, mealMapIds);
    const filePath = `${profile.school_id}/${opened.id}.docx`;

    const { error: uploadError } = await supabase.storage
      .from(DOCUMENT_BUCKET)
      .upload(filePath, filled.bytes, { contentType: DOCX_TYPE, upsert: true });
    if (uploadError) throw uploadError;

    const { data: published, error: completeError } = await supabase
      .rpc("complete_document_generation", {
        p_document_id: opened.id,
        p_file_path: filePath,
        p_file_name: filled.fileName,
      })
      .single<GeneratedDocument>();
    if (completeError) throw completeError;

    // A validade é a que o banco carimbou; o link só a acompanha. Fossem dois
    // prazos, um deles envelheceria sozinho — e o que decide se o arquivo
    // ainda pode ser servido é o do banco, que a política do balde lê.
    const seconds = Math.max(
      1,
      Math.floor((Date.parse(published.expires_at!) - Date.now()) / 1000),
    );
    const { data: link, error: linkError } = await supabase.storage
      .from(DOCUMENT_BUCKET)
      .createSignedUrl(filePath, seconds, { download: filled.fileName });
    if (linkError) throw linkError;

    return json(200, {
      generated_document_id: published.id,
      status: published.status,
      requested_at: published.requested_at,
      completed_at: published.completed_at,
      expires_at: published.expires_at,
      meal_map_count: filled.dayCount,
      period: filled.period,
      file_name: published.file_name,
      download_url: link.signedUrl,
    });
  } catch (cause) {
    // A falha fica registrada, e é ela que a lista de documentos mostra à
    // merendeira no lugar do arquivo que não apareceu (decisão 10 da E4).
    console.error("geração", opened.id, "falhou:", cause);
    const { error: failError } = await supabase.rpc("fail_document_generation", {
      p_document_id: opened.id,
    });
    if (failError) console.error("não foi possível registrar a falha:", failError);

    return failure(
      500,
      "Não foi possível gerar o documento agora.",
      "Os registros do período continuam guardados. Tente de novo em instantes.",
    );
  }
});

interface FilledDocument {
  bytes: Uint8Array;
  fileName: string;
  dayCount: number;
  period: { from: string; to: string };
}

/** Lê o que entra no documento, preenche o modelo vigente e devolve o pacote. */
async function generate(
  supabase: ReturnType<typeof serviceClient>,
  document: GeneratedDocument,
  schoolId: string,
  mealMapIds: string[],
): Promise<FilledDocument> {
  const school = await supabase
    .from("school")
    .select("name")
    .eq("id", schoolId)
    .single<{ name: string }>();
  if (school.error) throw school.error;

  const maps = await supabase
    .from("meal_map")
    .select(MEAL_MAP_SELECT)
    .in("id", mealMapIds)
    .returns<MealMapRow[]>();
  if (maps.error) throw maps.error;

  // O modelo é o que a geração registrou, e não "o vigente agora": entre o
  // pedido e o preenchimento a direção pode ter trocado o arquivo, e o
  // documento tem de sair com o modelo que o seu registro diz (decisão 11).
  const template = await supabase
    .from("document_template")
    .select("file_path")
    .eq("id", document.document_template_id)
    .single<{ file_path: string }>();
  if (template.error) throw template.error;

  const file = await supabase.storage
    .from(TEMPLATE_BUCKET)
    .download(template.data.file_path);
  if (file.error) throw file.error;

  const data = toDocumentData(school.data.name, maps.data);
  const bytes = fillOfficialTemplate(
    new Uint8Array(await file.data.arrayBuffer()),
    data,
  );

  const dates = data.mealMaps.map((mealMap) => mealMap.date);
  return {
    bytes,
    fileName: documentFileName(data.mealMaps),
    dayCount: data.mealMaps.length,
    period: { from: dates[0], to: dates[dates.length - 1] },
  };
}
