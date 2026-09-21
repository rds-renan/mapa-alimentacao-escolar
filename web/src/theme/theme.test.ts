import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'

import {
  applyTheme,
  DEFAULT_PREFERENCE,
  isThemePreference,
  readPreference,
  resolveTheme,
  systemTheme,
  THEME_STORAGE_KEY,
  writePreference,
} from './theme'

/*
 * A preferência de tema sem interface: o que se guarda, o que se lê de volta e
 * o que a página veste no fim (issue #71).
 */

/** O aparelho respondendo "estou no escuro" — ou não. */
function givenSystemDark(dark: boolean) {
  vi.stubGlobal(
    'matchMedia',
    vi.fn((query: string) => ({
      matches: dark && query.includes('dark'),
      media: query,
      addEventListener: vi.fn(),
      removeEventListener: vi.fn(),
    }))
  )
}

beforeEach(() => {
  localStorage.clear()
  document.documentElement.className = ''
  document.documentElement.style.colorScheme = ''
  document.head.innerHTML = '<meta name="theme-color" content="#397ba1" />'
})

afterEach(() => {
  vi.unstubAllGlobals()
})

describe('a preferência guardada', () => {
  it('nasce seguindo o aparelho', () => {
    expect(readPreference()).toBe('system')
    expect(DEFAULT_PREFERENCE).toBe('system')
  })

  it('permanece entre sessões (CA#1 da US024)', () => {
    writePreference('dark')

    // Ler de novo é o que uma abertura seguinte do aplicativo faz.
    expect(readPreference()).toBe('dark')
    expect(localStorage.getItem(THEME_STORAGE_KEY)).toBe('dark')
  })

  it('ignora o que estiver guardado e não for uma das três escolhas', () => {
    localStorage.setItem(THEME_STORAGE_KEY, 'roxo')

    expect(readPreference()).toBe('system')
  })

  it('reconhece as três escolhas, e só elas', () => {
    expect(isThemePreference('light')).toBe(true)
    expect(isThemePreference('dark')).toBe(true)
    expect(isThemePreference('system')).toBe(true)
    expect(isThemePreference(null)).toBe(false)
    expect(isThemePreference('escuro')).toBe(false)
  })

  it('não derruba o aplicativo quando o navegador recusa o armazenamento', () => {
    const getItem = vi
      .spyOn(Storage.prototype, 'getItem')
      .mockImplementation(() => {
        throw new Error('armazenamento bloqueado')
      })
    const setItem = vi
      .spyOn(Storage.prototype, 'setItem')
      .mockImplementation(() => {
        throw new Error('armazenamento bloqueado')
      })

    expect(() => writePreference('dark')).not.toThrow()
    expect(readPreference()).toBe('system')

    getItem.mockRestore()
    setItem.mockRestore()
  })
})

describe('resolver "sistema"', () => {
  it('acompanha o aparelho no escuro', () => {
    givenSystemDark(true)

    expect(systemTheme()).toBe('dark')
    expect(resolveTheme('system')).toBe('dark')
  })

  it('acompanha o aparelho no claro', () => {
    givenSystemDark(false)

    expect(systemTheme()).toBe('light')
    expect(resolveTheme('system')).toBe('light')
  })

  it('não acompanha o aparelho quando a escolha é explícita', () => {
    givenSystemDark(true)

    expect(resolveTheme('light')).toBe('light')
    expect(resolveTheme('dark')).toBe('dark')
  })

  it('fica no claro onde não há como perguntar ao aparelho', () => {
    vi.stubGlobal('matchMedia', undefined)

    expect(systemTheme()).toBe('light')
  })
})

describe('vestir a página', () => {
  it('liga a classe que troca a paleta inteira de tokens', () => {
    applyTheme('dark')

    expect(document.documentElement.classList.contains('dark')).toBe(true)

    applyTheme('light')

    expect(document.documentElement.classList.contains('dark')).toBe(false)
  })

  it('diz ao navegador em que esquema desenhar o que é dele', () => {
    applyTheme('dark')
    expect(document.documentElement.style.colorScheme).toBe('dark')

    applyTheme('light')
    expect(document.documentElement.style.colorScheme).toBe('light')
  })

  it('apaga a barra do navegador junto com a tela', () => {
    const meta = () =>
      document
        .querySelector('meta[name="theme-color"]')
        ?.getAttribute('content')

    applyTheme('dark')
    expect(meta()).toBe('#09090b')

    applyTheme('light')
    expect(meta()).toBe('#397ba1')
  })
})
