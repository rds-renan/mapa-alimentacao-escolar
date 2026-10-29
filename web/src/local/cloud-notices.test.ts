import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'

import { CloudNotices } from './cloud-notices'
import { REJECTED_MESSAGE, SYNC_MESSAGES, type SyncStatus } from './messages'
import type { DaySyncState } from './sync'

function state(status: SyncStatus): DaySyncState {
  return { status, message: SYNC_MESSAGES[status], detail: null }
}

describe('os avisos da nuvem (issue #178)', () => {
  let shown: string[]
  let notices: CloudNotices

  beforeEach(() => {
    vi.useFakeTimers()
    shown = []
    notices = new CloudNotices((text) => shown.push(text))
  })

  afterEach(() => {
    notices.dispose()
    vi.useRealTimers()
  })

  it('não dizem nada de um dia que ela ainda não tocou', () => {
    notices.update(null)
    vi.advanceTimersByTime(5000)

    expect(shown).toEqual([])
  })

  it('digitando com rede, "Salvo na nuvem." aparece uma vez só', () => {
    // Cada gravação passa por "Salvo neste aparelho…" antes de subir.
    for (let i = 0; i < 4; i++) {
      notices.update(state('pending'))
      vi.advanceTimersByTime(1200)
      notices.update(state('sent'))
    }
    vi.advanceTimersByTime(5000)

    expect(shown).toEqual([SYNC_MESSAGES.sent])
  })

  it('"Salvo neste aparelho…" só aparece se durar, e a volta da rede avisa', () => {
    notices.update(state('sent'))
    notices.update(state('pending'))
    vi.advanceTimersByTime(2000)
    expect(shown).toEqual([SYNC_MESSAGES.sent])

    vi.advanceTimersByTime(1000)
    expect(shown).toEqual([SYNC_MESSAGES.sent, SYNC_MESSAGES.pending])

    notices.update(state('sent'))
    expect(shown).toEqual([
      SYNC_MESSAGES.sent,
      SYNC_MESSAGES.pending,
      SYNC_MESSAGES.sent,
    ])
  })

  it('a falha avisa na hora, e a recusa traz a explicação do banco', () => {
    notices.update(state('failed'))
    notices.update({
      status: 'failed',
      message: REJECTED_MESSAGE,
      detail: 'A quantidade de "Pão" precisa ser maior que zero.',
    })

    expect(shown).toEqual([
      SYNC_MESSAGES.failed,
      `${REJECTED_MESSAGE} A quantidade de "Pão" precisa ser maior que zero.`,
    ])
  })
})
