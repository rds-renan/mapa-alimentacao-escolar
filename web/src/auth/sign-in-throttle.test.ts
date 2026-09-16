import { beforeEach, describe, expect, it } from 'vitest'

import {
  clearAttempts,
  MAX_ATTEMPTS,
  registerFailure,
  remainingWait,
} from './sign-in-throttle'

/*
 * O freio de tentativas. O que se verifica aqui é a escalada: um engano custa
 * nada, cinco enganos custam um minuto, e insistir custa mais.
 */
describe('freio de tentativas', () => {
  beforeEach(() => {
    localStorage.clear()
  })

  it('não freia quem errou menos que o limite', () => {
    for (let tentativa = 1; tentativa < MAX_ATTEMPTS; tentativa += 1) {
      expect(registerFailure()).toBe(0)
    }

    expect(remainingWait()).toBe(0)
  })

  it('freia por um minuto na primeira série', () => {
    let wait = 0
    for (let tentativa = 0; tentativa < MAX_ATTEMPTS; tentativa += 1) {
      wait = registerFailure()
    }

    expect(wait).toBe(60_000)
    expect(remainingWait()).toBeGreaterThan(0)
  })

  it('cobra mais caro de quem insiste', () => {
    let wait = 0
    for (let tentativa = 0; tentativa < MAX_ATTEMPTS * 2; tentativa += 1) {
      wait = registerFailure()
    }
    expect(wait).toBe(300_000)

    for (let tentativa = 0; tentativa < MAX_ATTEMPTS; tentativa += 1) {
      wait = registerFailure()
    }
    expect(wait).toBe(900_000)
  })

  it('a espera acaba quando o tempo passa', () => {
    const agora = Date.now()
    for (let tentativa = 0; tentativa < MAX_ATTEMPTS; tentativa += 1) {
      registerFailure(agora)
    }

    expect(remainingWait(agora + 59_000)).toBeGreaterThan(0)
    expect(remainingWait(agora + 61_000)).toBe(0)
  })

  it('entrar zera a contagem', () => {
    for (let tentativa = 0; tentativa < MAX_ATTEMPTS; tentativa += 1) {
      registerFailure()
    }

    clearAttempts()

    expect(remainingWait()).toBe(0)
    expect(registerFailure()).toBe(0)
  })
})
