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
  /** A tela-casa da merendeira: a visão do mês. */
  cookHome: '/',
  /** O registro de um dia (issue #62). A data vai no caminho, em AAAA-MM-DD. */
  dayRegister: '/dia/:mapDate',
  /** Os documentos ainda dentro da janela de 7 dias (issue #67). */
  generatedDocuments: '/documentos',
  /** A manutenção do catálogo de gêneros: a tela 4 da E3. */
  foodItems: '/generos',
  /** A tela-casa da direção: o painel gerencial (issue #70). */
  adminHome: '/admin',
} as const

/** Onde cada perfil aterrissa ao entrar. São dois fluxos, não um com menus a mais. */
export function homePathFor(role: UserRole): string {
  return role === 'admin' ? ROUTES.adminHome : ROUTES.cookHome
}

/** O caminho do registro de um dia: `/dia/2026-09-10`. */
export function dayPath(mapDate: string): string {
  return `/dia/${mapDate}`
}

/**
 * O mês aberto na visão do mês vai na barra de endereço, e não só na memória
 * da tela: recarregar com F5 — que na web acontece — não pode jogá-la de volta
 * no mês de hoje quando ela estava conferindo o mês passado.
 */
export const MONTH_PARAM = 'mes'
