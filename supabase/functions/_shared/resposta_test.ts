import { assertEquals } from "@std/assert";

import { json, preflight } from "./resposta.ts";

// O que a supabase-js manda em toda chamada a uma Edge Function. Se um deles
// ficar fora do pré-voo, o navegador barra a chamada antes de ela sair — e a
// tela vê uma falha de rede, não um erro.
const SENT_BY_THE_CLIENT = ["authorization", "apikey", "content-type", "x-client-info"];

function allowedHeaders(response: Response): string[] {
  return (response.headers.get("Access-Control-Allow-Headers") ?? "")
    .split(",")
    .map((header) => header.trim().toLowerCase());
}

Deno.test("o pré-voo libera todo cabeçalho que a supabase-js manda", () => {
  const allowed = allowedHeaders(preflight());
  for (const header of SENT_BY_THE_CLIENT) {
    assertEquals(allowed.includes(header), true, `${header} fora do pré-voo`);
  }
});

Deno.test("a resposta leva o mesmo CORS do pré-voo", () => {
  assertEquals(allowedHeaders(json(200, {})), allowedHeaders(preflight()));
});

Deno.test("as funções só atendem POST", () => {
  assertEquals(
    preflight().headers.get("Access-Control-Allow-Methods"),
    "POST, OPTIONS",
  );
});
