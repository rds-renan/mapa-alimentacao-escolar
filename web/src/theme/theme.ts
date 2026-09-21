/*
 * A preferência de tema (US024).
 *
 * São três escolhas e não duas: claro, escuro e **seguir o aparelho**. A
 * terceira é o padrão, e não é um detalhe de conveniência — o celular dela já
 * troca de tema sozinho ao anoitecer, e o motivo da história é justamente o
 * preenchimento à noite, em casa. Quem nunca abrir esta preferência recebe o
 * tema escuro na hora certa sem ter pedido nada.
 *
 * A escolha mora no `localStorage` e não no banco (decisão 12 da E4, RN#1 da
 * US024): é do aparelho, não da conta. Duas merendeiras que dividam o
 * computador da escola não disputam a preferência uma da outra, e sair da
 * conta não a apaga — `clearLocalData` limpa o que é da pessoa, e o tema não é.
 */

export type ThemePreference = 'light' | 'dark' | 'system'

/** O que sobra depois de resolver "sistema": o tema que a tela vai vestir. */
export type ResolvedTheme = 'light' | 'dark'

export const THEME_STORAGE_KEY = 'mae.theme'

export const DEFAULT_PREFERENCE: ThemePreference = 'system'

const PREFERENCES: ThemePreference[] = ['light', 'dark', 'system']

/** A consulta que responde qual é o tema do aparelho. */
export const DARK_QUERY = '(prefers-color-scheme: dark)'

/*
 * A cor da barra do navegador no celular. No claro é o azul da marca, como o
 * `index.html` sempre teve; no escuro é o próprio fundo da página — uma faixa
 * azul acesa sobre a tela quase preta seria a luz que a história quer apagar.
 */
const BROWSER_BAR: Record<ResolvedTheme, string> = {
  light: '#397ba1',
  dark: '#09090b',
}

export function isThemePreference(value: unknown): value is ThemePreference {
  return PREFERENCES.includes(value as ThemePreference)
}

/**
 * A preferência guardada, ou o padrão quando não há nada guardado — e também
 * quando o navegador recusa o armazenamento (janela anônima com cookies
 * bloqueados). Preferência que não se lê não é motivo para a tela não abrir.
 */
export function readPreference(): ThemePreference {
  try {
    const stored = localStorage.getItem(THEME_STORAGE_KEY)
    return isThemePreference(stored) ? stored : DEFAULT_PREFERENCE
  } catch {
    return DEFAULT_PREFERENCE
  }
}

export function writePreference(preference: ThemePreference): void {
  try {
    localStorage.setItem(THEME_STORAGE_KEY, preference)
  } catch {
    // Armazenamento bloqueado: o tema vale para esta sessão e não sobrevive.
  }
}

/** O que o aparelho pede agora. */
export function systemTheme(): ResolvedTheme {
  return typeof matchMedia === 'function' && matchMedia(DARK_QUERY).matches
    ? 'dark'
    : 'light'
}

export function resolveTheme(preference: ThemePreference): ResolvedTheme {
  return preference === 'system' ? systemTheme() : preference
}

/**
 * Veste a página com o tema resolvido.
 *
 * A classe `dark` é o que a variante do Tailwind procura (`@custom-variant` no
 * `index.css`), e é ela que troca a paleta inteira de tokens de uma vez.
 *
 * O `color-scheme` é o outro lado da mesma troca, e é o que a classe não
 * alcança: barra de rolagem, seletor de data e caixa de texto do navegador são
 * desenhados por ele, não por nós. Sem isso, a tela escura vem com uma barra de
 * rolagem branca do lado e o calendário nativo aceso na cara de quem escolheu
 * o escuro.
 */
export function applyTheme(theme: ResolvedTheme): void {
  const root = document.documentElement

  root.classList.toggle('dark', theme === 'dark')
  root.style.colorScheme = theme

  document
    .querySelector('meta[name="theme-color"]')
    ?.setAttribute('content', BROWSER_BAR[theme])
}
