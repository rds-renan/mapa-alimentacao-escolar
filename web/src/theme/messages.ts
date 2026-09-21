import type { ThemePreference } from './theme'

/*
 * Os textos da preferência de tema.
 *
 * "Tema" e não "Tema escuro", que era o rótulo do desenho da E3: lá era uma
 * chave de liga/desliga, e o nome dizia o que ela ligava. Com três escolhas o
 * rótulo passa a nomear o assunto, e as opções é que dizem cada estado.
 *
 * "Sistema" é a palavra do aparelho delas — é assim que o Android chama a
 * opção nas próprias configurações de tela —, e a linha abaixo do controle
 * explica o que ela faz, para quem nunca reparou que o celular troca de tema
 * sozinho.
 */
export const THEME_MESSAGES = {
  label: 'Tema',
  hint: 'Em Sistema, acompanha o tema do aparelho.',
  group: 'Escolher o tema do aplicativo',
} as const

export const THEME_OPTION_LABELS: Record<ThemePreference, string> = {
  light: 'Claro',
  dark: 'Escuro',
  system: 'Sistema',
}
