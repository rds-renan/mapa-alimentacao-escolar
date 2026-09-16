import type { UserRole } from '@/auth/auth-context'

/*
 * Os caminhos das telas. Ficam em português porque aparecem na barra de
 * endereço: são texto de interface, e a fronteira da decisão 13 da E4 põe o
 * inglês nos identificadores e o português no que a merendeira lê.
 *
 * Quem serve estes caminhos em produção é o Worker da Cloudflare, com
 * `not_found_handling: single-page-application` no wrangler.jsonc — é o que
 * mantém de pé uma rota recarregada com F5.
 */
export const ROUTES = {
  signIn: '/entrar',
  forgotPassword: '/esqueci-a-senha',
  newPassword: '/nova-senha',
  /** A tela-casa da merendeira: a visão do mês (issue #61). */
  cookHome: '/',
  /** A tela-casa da direção: o painel gerencial (issue #70). */
  adminHome: '/admin',
} as const

/** Onde cada perfil aterrissa ao entrar. São dois fluxos, não um com menus a mais. */
export function homePathFor(role: UserRole): string {
  return role === 'admin' ? ROUTES.adminHome : ROUTES.cookHome
}
