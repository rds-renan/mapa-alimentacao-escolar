import { act, fireEvent, render, screen } from '@testing-library/react'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'

import { ThemeChoice } from './theme-choice'
import { ThemeProvider } from './theme-provider'
import { THEME_STORAGE_KEY } from './theme'

/*
 * O controle do tema visto de fora: os três estados do critério 1 da issue
 * #71, a permanência entre sessões e o "sistema" que continua acompanhando o
 * aparelho com o aplicativo aberto.
 */

/** Um aparelho de mentira cujo tema dá para virar no meio do caso. */
function givenDevice(dark: boolean) {
  const listeners = new Set<(event: MediaQueryListEvent) => void>()
  let current = dark

  vi.stubGlobal(
    'matchMedia',
    vi.fn((query: string) => ({
      get matches() {
        return current && query.includes('dark')
      },
      media: query,
      addEventListener: (
        _: string,
        listener: (e: MediaQueryListEvent) => void
      ) => void listeners.add(listener),
      removeEventListener: (
        _: string,
        listener: (e: MediaQueryListEvent) => void
      ) => void listeners.delete(listener),
    }))
  )

  return {
    /** O aparelho anoiteceu com o aplicativo aberto. */
    turn(next: boolean) {
      current = next
      act(() => {
        for (const listener of listeners) {
          listener({ matches: next } as MediaQueryListEvent)
        }
      })
    },
  }
}

function renderChoice() {
  return render(
    <ThemeProvider>
      <ThemeChoice />
    </ThemeProvider>
  )
}

const isDark = () => document.documentElement.classList.contains('dark')

function choose(label: string) {
  fireEvent.click(screen.getByRole('radio', { name: label }))
}

beforeEach(() => {
  localStorage.clear()
  document.documentElement.className = ''
  document.documentElement.style.colorScheme = ''
})

afterEach(() => {
  vi.unstubAllGlobals()
})

describe('o controle do tema', () => {
  it('oferece claro, escuro e o padrão do sistema', () => {
    givenDevice(false)
    renderChoice()

    expect(screen.getByRole('radio', { name: 'Claro' })).toBeInTheDocument()
    expect(screen.getByRole('radio', { name: 'Escuro' })).toBeInTheDocument()
    expect(screen.getByRole('radio', { name: 'Sistema' })).toBeInTheDocument()
  })

  it('abre em Sistema para quem nunca escolheu', () => {
    givenDevice(false)
    renderChoice()

    expect(screen.getByRole('radio', { name: 'Sistema' })).toBeChecked()
  })

  it('escurece a tela ao escolher Escuro', () => {
    givenDevice(false)
    renderChoice()

    expect(isDark()).toBe(false)

    choose('Escuro')

    expect(isDark()).toBe(true)
    expect(screen.getByRole('radio', { name: 'Escuro' })).toBeChecked()
  })

  it('clareia de volta ao escolher Claro, mesmo com o aparelho no escuro', () => {
    givenDevice(true)
    renderChoice()

    // Seguindo o aparelho, a tela abriu escura.
    expect(isDark()).toBe(true)

    choose('Claro')

    expect(isDark()).toBe(false)
  })

  it('permanece entre sessões (CA#1 da US024)', () => {
    givenDevice(false)
    const { unmount } = renderChoice()

    choose('Escuro')
    expect(localStorage.getItem(THEME_STORAGE_KEY)).toBe('dark')

    // Fechar e abrir de novo é o que o aplicativo faz no dia seguinte.
    unmount()
    document.documentElement.className = ''
    renderChoice()

    expect(screen.getByRole('radio', { name: 'Escuro' })).toBeChecked()
    expect(isDark()).toBe(true)
  })
})

describe('seguir o aparelho', () => {
  it('escurece junto com o aparelho, com o aplicativo aberto', () => {
    const device = givenDevice(false)
    renderChoice()

    expect(isDark()).toBe(false)

    device.turn(true)

    expect(isDark()).toBe(true)
  })

  it('não se mexe quando a escolha é explícita', () => {
    const device = givenDevice(false)
    renderChoice()

    choose('Claro')
    device.turn(true)

    expect(isDark()).toBe(false)
    expect(screen.getByRole('radio', { name: 'Claro' })).toBeChecked()
  })

  it('volta a acompanhar o aparelho ao voltar para Sistema', () => {
    const device = givenDevice(false)
    renderChoice()

    choose('Claro')
    device.turn(true)
    expect(isDark()).toBe(false)

    choose('Sistema')

    expect(isDark()).toBe(true)
    expect(localStorage.getItem(THEME_STORAGE_KEY)).toBe('system')
  })
})
