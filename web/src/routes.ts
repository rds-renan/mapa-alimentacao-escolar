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
  /** A seleção de mapas e o pedido de geração: a tela 5 da E3. */
  selectMaps: '/gerar',
  /** O documento recém-gerado e a lista dos que ainda estão no ar: telas 6 e 2b. */
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
 * O caminho da seleção de mapas, com o mês aberto junto: `/gerar?mes=2026-09`.
 *
 * O mês vai no endereço pelo mesmo motivo que vai na visão do mês — a tela 5
 * não tem navegação de mês (a E3 não a desenhou com uma), então o mês de onde
 * ela veio é a única coisa que diz quais dias mostrar.
 */
export function selectMapsPath(month: string): string {
  return `${ROUTES.selectMaps}?${MONTH_PARAM}=${month}`
}

/**
 * O mês aberto na visão do mês vai na barra de endereço, e não só na memória
 * da tela: recarregar com F5 — que na web acontece — não pode jogá-la de volta
 * no mês de hoje quando ela estava conferindo o mês passado.
 */
export const MONTH_PARAM = 'mes'
