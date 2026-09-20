// O acesso de uma merendeira nasce aqui (US016).
//
// Por que uma Edge Function, e não mais um insert da tela: o acesso começa em
// `auth.users`, e essa tabela não é do nosso schema — quem escreve nela é a
// API de administração do Supabase, que só a chave secreta abre. O
// autocadastro está desligado no projeto de propósito (CA#3 da US016), então
// não existe caminho pelo navegador: ou a conta nasce com a chave secreta, ou
// não nasce.
//
// O caminho, na ordem:
//
//   1. quem chamou é uma direção ativa?
//   2. o nome e o e-mail vieram, e o e-mail já tem acesso nesta escola?
//   3. cria a conta no serviço de autenticação
//   4. cria a linha de `profile`, que é o que o aplicativo enxerga
//
// Se o 4 falhar, o 3 é desfeito: uma conta em `auth.users` sem perfil é um
// acesso invisível para a direção e sem tela nenhuma para quem entrar com ele.
//
// A **senha não nasce aqui**. A conta é criada com uma senha aleatória que
// ninguém vê, e quem manda o e-mail de criar senha é a própria tela, logo
// depois, pelo mesmo caminho do "Esqueci minha senha" (issue #59). São dois
// motivos: a direção nunca fica sabendo a senha de ninguém, e o botão
// "Redefinir senha" da mesma tela usa exatamente essa chamada — uma regra só,
// num lugar só.

import { serviceClient } from "../_shared/cliente.ts";
import { bearer, failure, fromDatabase, json, preflight } from "../_shared/resposta.ts";

interface NewAccess {
  name: string;
  email: string;
}

/** O que a tela manda. O resto — escola, papel — vem de quem chamou. */
function readNewAccess(body: unknown): NewAccess | null {
  if (typeof body !== "object" || body === null) return null;

  const { name, email } = body as Record<string, unknown>;
  if (typeof name !== "string" || typeof email !== "string") return null;

  const trimmed = { name: name.trim(), email: email.trim().toLowerCase() };
  if (trimmed.name === "" || trimmed.email === "") return null;
  // Conferência de forma, não de existência: quem sabe se o endereço existe é
  // o e-mail que a tela manda em seguida, ao chegar ou não.
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(trimmed.email)) return null;

  return trimmed;
}

/**
 * A senha com que a conta nasce.
 *
 * Ela existe porque o serviço de autenticação pede uma, e é descartada sem
 * nunca sair daqui — não é devolvida, não é registrada e não chega a e-mail
 * nenhum. Quem define a senha de verdade é a merendeira, no link que ela
 * recebe. Aleatória do gerador criptográfico para que a conta não fique
 * aberta por uma senha adivinhável enquanto o e-mail não chega.
 */
function throwawayPassword(): string {
  return `${crypto.randomUUID()}${crypto.randomUUID()}`;
}

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") return preflight();
  if (request.method !== "POST") {
    return failure(405, "Este endereço só aceita POST.");
  }

  const token = bearer(request);
  if (!token) return failure(401, "Entre de novo para cadastrar a merendeira.");

  const supabase = serviceClient();

  const { data: authenticated, error: authError } = await supabase.auth.getUser(token);
  if (authError || !authenticated.user) {
    return failure(401, "Entre de novo para cadastrar a merendeira.");
  }

  let wanted: NewAccess | null = null;
  try {
    wanted = readNewAccess(await request.json());
  } catch {
    wanted = null;
  }
  if (!wanted) {
    return failure(400, "Preencha o nome e um e-mail válido.");
  }

  // Cadastrar acesso é da direção (US016). A conferência é aqui porque este é
  // o único guarda que existe: daqui para a frente tudo roda com a chave
  // secreta, que passa por cima das políticas do banco.
  const { data: caller, error: callerError } = await supabase
    .from("profile")
    .select("id, school_id, role, active")
    .eq("id", authenticated.user.id)
    .maybeSingle();

  if (callerError) return fromDatabase(callerError);
  if (!caller || !caller.active || caller.role !== "admin") {
    return failure(403, "Só a direção cadastra merendeira.");
  }

  // O e-mail já é de alguém? A coluna `email` de `profile` é única no sistema
  // inteiro, e o insert lá embaixo recusaria de qualquer jeito — mas com uma
  // violação de chave, que não é frase que a direção possa ler. E, quando a
  // pessoa está nesta escola e desativada, o caminho não é cadastrar de novo:
  // é reativar, que é o que preserva a autoria dos registros dela (CA#2).
  const { data: existing, error: existingError } = await supabase
    .from("profile")
    .select("school_id, active")
    .eq("email", wanted.email)
    .maybeSingle();

  if (existingError) return fromDatabase(existingError);
  if (existing) {
    return failure(
      409,
      existing.school_id === caller.school_id && !existing.active
        ? "Este e-mail já tem um acesso desativado nesta escola."
        : "Este e-mail já tem acesso ao sistema.",
      existing.school_id === caller.school_id && !existing.active
        ? "Reative o acesso na lista, em vez de cadastrar de novo."
        : undefined,
    );
  }

  const { data: created, error: createError } = await supabase.auth.admin.createUser({
    email: wanted.email,
    password: throwawayPassword(),
    // Já confirmado: quem criou o acesso foi a direção, na escola, e não há
    // um "confirme seu e-mail" a pedir de quem não pediu conta nenhuma. O
    // e-mail ainda assim precisa funcionar — é por ele que a senha é criada.
    email_confirm: true,
  });

  if (createError || !created.user) {
    console.error("não foi possível criar a conta:", createError);
    return failure(
      createError?.code === "email_exists" ? 409 : 502,
      createError?.code === "email_exists"
        ? "Este e-mail já tem acesso ao sistema."
        : "Não foi possível criar o acesso agora. Tente de novo.",
    );
  }

  const { data: profile, error: profileError } = await supabase
    .from("profile")
    .insert({
      id: created.user.id,
      school_id: caller.school_id,
      name: wanted.name,
      email: wanted.email,
      role: "cook",
    })
    .select("id, name, email, active, last_access")
    .single();

  if (profileError) {
    // Desfaz o passo 3. Sem isto sobraria uma conta capaz de autenticar e
    // incapaz de ver qualquer coisa — e o e-mail dela ficaria ocupado para
    // sempre, porque a tela não teria como saber que ela existe.
    const { error: undoError } = await supabase.auth.admin.deleteUser(created.user.id);
    if (undoError) {
      console.error("conta órfã em auth.users:", created.user.id, undoError);
    }

    return fromDatabase(profileError);
  }

  return json(201, profile);
});
