/*
 * A conferência da forma do e-mail: alguma coisa, arroba, domínio, ponto e o
 * fim do domínio. Não existe validação que prove que um endereço recebe
 * mensagem — só mandando se descobre —, então isto não serve para recusar
 * ninguém: serve para o campo avisar que espera um e-mail, e não qualquer
 * coisa. É pouco o bastante para não implicar com endereço de formato incomum.
 */
const FORMATO = /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/

export function isValidEmail(value: string): boolean {
  return FORMATO.test(value.trim())
}
