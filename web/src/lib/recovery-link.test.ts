import { describe, expect, it } from 'vitest'

import { isRecoveryHash } from './recovery-link'

/*
 * O que separa a aba que veio do link das outras abas do mesmo navegador.
 */
describe('endereço do link de senha nova', () => {
  it('reconhece o que o Supabase devolve ao abrir o link', () => {
    expect(
      isRecoveryHash('#access_token=abc&expires_in=3600&type=recovery')
    ).toBe(true)
    expect(isRecoveryHash('#type=recovery')).toBe(true)
  })

  it('não confunde com os outros endereços do aplicativo', () => {
    expect(isRecoveryHash('')).toBe(false)
    expect(isRecoveryHash('#access_token=abc&type=magiclink')).toBe(false)
    // O link já usado devolve erro, e não sessão: também não é a aba do link.
    expect(isRecoveryHash('#error=access_denied&error_code=otp_expired')).toBe(
      false
    )
    // Nada de casar com um pedaço de outra palavra.
    expect(isRecoveryHash('#kind=recovery-mode')).toBe(false)
  })
})
