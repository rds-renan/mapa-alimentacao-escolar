// O cliente do Supabase dentro da Edge Function.
//
// Aqui ele usa a **chave secreta**, que ignora as políticas de acesso: é este
// o único lugar do sistema onde ela existe (decisão 10 da E5). O que a protege
// é o que cada função faz com ela — validar o token de quem chamou antes de
// qualquer escrita — e as três funções do banco, que recusam quem não for o
// servidor.

import { createClient, type SupabaseClient } from "@supabase/supabase-js";

/**
 * Todas as chaves secretas que este projeto reconhece, na ordem de preferência.
 *
 * São duas gerações convivendo, e as duas valem. A CLI 2.117 injeta
 * `SUPABASE_SECRET_KEYS` — um dicionário JSON, porque o projeto pode ter mais
 * de uma chave, e a em uso é a `default`; os nomes antigos
 * (`SUPABASE_SERVICE_ROLE_KEY`, um JWT) seguem existindo ao lado. Quem chama a
 * limpeza pode apresentar qualquer uma das duas, então a comparação é contra
 * todas — reconhecer só uma faria o agendador ser recusado dependendo de onde
 * ele copiou a chave.
 */
function secretKeys(): string[] {
  const keys: string[] = [];

  const dictionary = Deno.env.get("SUPABASE_SECRET_KEYS");
  if (dictionary) {
    try {
      const parsed = JSON.parse(dictionary) as Record<string, string>;
      if (parsed.default) keys.push(parsed.default);
      for (const value of Object.values(parsed)) {
        if (typeof value === "string" && !keys.includes(value)) keys.push(value);
      }
    } catch {
      // Dicionário ilegível cai no nome antigo, logo abaixo.
    }
  }

  const legacy = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (legacy && !keys.includes(legacy)) keys.push(legacy);

  if (keys.length === 0) {
    throw new Error(
      "a chave secreta não está no ambiente (SUPABASE_SECRET_KEYS ou SUPABASE_SERVICE_ROLE_KEY)",
    );
  }
  return keys;
}

export function serviceClient(): SupabaseClient {
  const url = Deno.env.get("SUPABASE_URL");
  if (!url) throw new Error("SUPABASE_URL não está no ambiente");

  return createClient(url, secretKeys()[0], {
    // Não há sessão a persistir nem token a renovar: cada invocação nasce e
    // morre com a requisição.
    auth: { persistSession: false, autoRefreshToken: false },
  });
}

/**
 * Quem chamou é o próprio servidor? É o guarda das funções que não têm usuária
 * do outro lado — a limpeza dos vencidos é chamada pelo agendador, com a chave
 * secreta no lugar do token da sessão.
 */
export function isServiceToken(token: string): boolean {
  return secretKeys().includes(token);
}
