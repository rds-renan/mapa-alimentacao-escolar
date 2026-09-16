/*
 * A guarda contra robôs, ligada por configuração. A chave do site é pública —
 * ela aparece no HTML por construção —, e quem valida o desafio é o Supabase,
 * com a chave secreta que só ele tem. Sem chave configurada, a guarda não
 * existe: é assim que o desenvolvimento local e os testes rodam sem depender
 * de rede externa, e é assim que a produção a ganha sem tocar em código.
 *
 * Como ligar está em docs/05-web/autenticacao-e-sessao.md.
 */
export const TURNSTILE_SITE_KEY = import.meta.env.VITE_TURNSTILE_SITE_KEY ?? ''

export function isCaptchaEnabled(): boolean {
  return TURNSTILE_SITE_KEY.length > 0
}
