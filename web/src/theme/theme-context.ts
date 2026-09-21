import { createContext } from 'react'

import type { ResolvedTheme, ThemePreference } from './theme'

export interface ThemeContextValue {
  /** O que ela escolheu: claro, escuro ou seguir o aparelho. */
  preference: ThemePreference
  /** O que a tela está vestindo agora, com "sistema" já resolvido. */
  theme: ResolvedTheme
  choose(preference: ThemePreference): void
}

export const ThemeContext = createContext<ThemeContextValue | null>(null)
