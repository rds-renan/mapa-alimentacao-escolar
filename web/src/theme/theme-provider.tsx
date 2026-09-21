import { useCallback, useEffect, useMemo, useState } from 'react'

import {
  applyTheme,
  DARK_QUERY,
  readPreference,
  resolveTheme,
  writePreference,
  type ResolvedTheme,
  type ThemePreference,
} from './theme'
import { ThemeContext, type ThemeContextValue } from './theme-context'

/*
 * O tema vivo.
 *
 * Ele fica acima de tudo, junto com a sessão e a fila, porque veste o
 * aplicativo inteiro — inclusive as três telas que existem antes do login. A
 * merendeira que abre o MAE de madrugada para conferir um dia não recebe uma
 * tela de login branca na cara para só depois, lá dentro, o tema escuro valer.
 *
 * **A página já nasce vestida.** Quem aplica o tema na primeira pintura é o
 * script curto no `index.html`, que roda antes do React existir; este
 * componente assume dali em diante. Sem esse script haveria um lampejo branco
 * a cada abertura, que é exatamente o incômodo que a US024 veio resolver.
 */
export function ThemeProvider({ children }: { children: React.ReactNode }) {
  const [preference, setPreference] = useState<ThemePreference>(readPreference)
  const [systemDark, setSystemDark] = useState(
    () => typeof matchMedia === 'function' && matchMedia(DARK_QUERY).matches
  )

  /*
   * Seguir o aparelho é seguir o aparelho **enquanto ele muda**, não só na
   * abertura: com o aplicativo aberto no fim da tarde, quem está em "sistema"
   * vê a tela escurecer junto com o celular. A escuta fica de pé sempre, e não
   * só quando a preferência é "sistema", para que voltar a essa opção já
   * encontre o valor certo em vez de esperar a próxima virada.
   */
  useEffect(() => {
    if (typeof matchMedia !== 'function') return

    const query = matchMedia(DARK_QUERY)
    const onChange = (event: MediaQueryListEvent) =>
      setSystemDark(event.matches)

    query.addEventListener('change', onChange)
    return () => query.removeEventListener('change', onChange)
  }, [])

  const theme: ResolvedTheme =
    preference === 'system' ? (systemDark ? 'dark' : 'light') : preference

  useEffect(() => {
    applyTheme(theme)
  }, [theme])

  const choose = useCallback((next: ThemePreference) => {
    setPreference(next)
    writePreference(next)
    // Aplicar aqui também, e não só pelo efeito: a troca é um toque dela, e o
    // que responde a um toque não espera o próximo desenho da tela.
    applyTheme(resolveTheme(next))
  }, [])

  const value = useMemo<ThemeContextValue>(
    () => ({ preference, theme, choose }),
    [preference, theme, choose]
  )

  return <ThemeContext value={value}>{children}</ThemeContext>
}
