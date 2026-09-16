/*
 * Esta aba chegou pelo link de senha nova?
 *
 * A pergunta parece boba e não é. A sessão do Supabase é compartilhada por
 * todas as abas do mesmo navegador, e o aviso de "entrou para trocar a senha"
 * também viaja entre elas. Sem esta pergunta, a aba onde a pessoa **pediu** a
 * senha nova virava, sozinha, uma segunda tela de trocar senha — que ninguém
 * pediu e que aceitava trocar de novo.
 *
 * A resposta é lida no carregamento do módulo, **antes** de o cliente do
 * Supabase consumir e limpar o endereço; é por isso que quem o importa
 * primeiro é o próprio módulo do cliente. E ela vale para esta aba e mais
 * nenhuma: é um fato do endereço que abriu aqui, não do estado da conta.
 */

/** O endereço traz o código de um link de senha nova? */
export function isRecoveryHash(hash: string): boolean {
  return /(^|[#&])type=recovery(&|$)/.test(hash)
}

const arrived =
  typeof window === 'undefined' ? false : isRecoveryHash(window.location.hash)

export function cameFromRecoveryLink(): boolean {
  return arrived
}
