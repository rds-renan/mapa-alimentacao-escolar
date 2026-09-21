import { useId } from 'react'
import { Moon } from 'lucide-react'

import { THEME_MESSAGES, THEME_OPTION_LABELS } from './messages'
import type { ThemePreference } from './theme'
import { useTheme } from './useTheme'

/*
 * O controle do tema (CA#1 da US024): claro, escuro e seguir o aparelho, os
 * três à vista.
 *
 * **Diverge do desenho da E3 de propósito.** A tela 2a trazia "Tema escuro"
 * como uma chave de liga/desliga, e numa chave não cabem três estados: quem a
 * tocasse uma vez deixaria de acompanhar o aparelho para sempre, sem caminho
 * de volta. O desenho foi atualizado junto com esta issue.
 *
 * São três opções lado a lado e não uma lista suspensa pelo mesmo motivo da
 * aceitação (US004): a escolha inteira cabe na tela e trocar custa um toque. O
 * que muda em relação àquele caso é a semântica — aqui as opções se excluem de
 * verdade, então são botões de rádio de verdade, com a navegação por setas que
 * o navegador já dá de graça.
 *
 * Sem ícone dentro das opções: o mesmo controle serve o menu da merendeira e a
 * barra lateral da direção, que tem 240 px de largura — ícone mais palavra não
 * cabe em três colunas ali, e "Sistema" cortado não é reconhecimento nenhum.
 *
 * **Quem marca a escolha é a pílula, não a cor da palavra.** O caminho natural
 * seria apagar as duas opções não escolhidas com `muted-foreground`, e ele
 * esbarra no critério 3: cinza de apoio sobre o cinza do trilho dá 4,40 no tema
 * claro, abaixo dos 4,5 do AA. As três palavras ficam legíveis o tempo todo, e
 * o que diz qual está valendo é o fundo claro com sombra embaixo dela — que é
 * como o próprio aparelho delas desenha um controle destes.
 */

const ORDER: ThemePreference[] = ['light', 'dark', 'system']

export function ThemeChoice() {
  const { preference, choose } = useTheme()
  const name = useId()

  return (
    <fieldset className="flex flex-col gap-1.5">
      <legend className="sr-only">{THEME_MESSAGES.group}</legend>

      <div className="flex items-center gap-3 px-1">
        <Moon
          className="size-5 shrink-0 text-muted-foreground"
          aria-hidden="true"
        />
        <span className="text-base font-medium">{THEME_MESSAGES.label}</span>
      </div>

      <div className="flex gap-1 rounded-lg bg-muted p-1">
        {ORDER.map((option) => (
          <label key={option} className="flex-1 cursor-pointer">
            <input
              type="radio"
              name={name}
              value={option}
              checked={preference === option}
              onChange={() => choose(option)}
              className="peer sr-only"
            />
            <span className="flex h-touch items-center justify-center rounded-md text-sm font-medium text-secondary-foreground transition-colors peer-checked:bg-card peer-checked:shadow-sm peer-focus-visible:ring-2 peer-focus-visible:ring-ring peer-focus-visible:ring-offset-1 peer-focus-visible:ring-offset-muted">
              {THEME_OPTION_LABELS[option]}
            </span>
          </label>
        ))}
      </div>

      <p className="px-1 text-xs text-muted-foreground">
        {THEME_MESSAGES.hint}
      </p>
    </fieldset>
  )
}
