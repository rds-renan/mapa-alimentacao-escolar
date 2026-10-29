import { Toaster as Sonner } from 'sonner'

import { useTheme } from '@/theme/useTheme'

/*
 * Os toasts da web (issue #178), no canto superior direito: é onde a decisão
 * da E7 os pôs, longe do rodapé do dia, que é onde ela trabalha. Seguem o tema
 * escolhido no aplicativo, e não o do sistema, e usam as cores do cartão.
 */
export function Toaster() {
  const { theme } = useTheme()

  return (
    <Sonner
      theme={theme}
      position="top-right"
      style={
        {
          '--normal-bg': 'var(--card)',
          '--normal-text': 'var(--card-foreground)',
          '--normal-border': 'var(--border)',
        } as React.CSSProperties
      }
    />
  )
}
