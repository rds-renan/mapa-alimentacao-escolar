// O que as duas funções têm em comum na borda HTTP: a resposta em JSON, o
// cabeçalho de CORS e a tradução de um erro do banco em código de situação.

/**
 * A web é servida de outro endereço que não o do Supabase, então toda chamada
 * passa por CORS. O `*` é o que o `Authorization` permite: a autorização vem
 * do token que a própria chamada leva, não de cookie de sessão — não há o que
 * um site de terceiro consiga fazer aqui sem ter o token da merendeira.
 */
const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

export function preflight(): Response {
  return new Response(null, { status: 204, headers: CORS });
}

export function json(status: number, body: unknown): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS, "content-type": "application/json; charset=utf-8" },
  });
}

/**
 * O erro que chega na tela. A mensagem já é a que a merendeira pode ler — a
 * mesma convenção da gravação do dia, que não deixa tradução para o cliente.
 */
export function failure(status: number, message: string, hint?: string): Response {
  return json(status, { error: { message, hint: hint ?? null } });
}

/** O `Bearer <token>` do cabeçalho, ou nada. */
export function bearer(request: Request): string | null {
  const header = request.headers.get("Authorization") ?? "";
  const [scheme, token] = header.split(" ");
  if (scheme?.toLowerCase() !== "bearer" || !token) return null;
  return token;
}

interface PostgresError {
  code?: string;
  message?: string;
  hint?: string | null;
}

/**
 * Traduz o erro de uma função do banco em resposta HTTP, com a mesma tabela
 * que a gravação do dia usa: `42501` é permissão, `23514` é regra do produto,
 * e o resto é defeito nosso — que não vira mensagem, vira registro no log.
 */
export function fromDatabase(error: PostgresError): Response {
  if (error.code === "42501") {
    return failure(403, error.message ?? "Sem permissão.", error.hint ?? undefined);
  }
  if (error.code === "23514") {
    return failure(400, error.message ?? "Pedido inválido.", error.hint ?? undefined);
  }
  console.error("erro inesperado do banco", error);
  return failure(500, "Não foi possível falar com o banco. Tente de novo.");
}
