import { describe, expect, it } from 'vitest'

import type { DayRecord } from '@/month/month'

import {
  closable,
  eligibleIds,
  missingDays,
  missingReason,
  periodLabel,
  toOption,
  toOptions,
} from './selection'

/*
 * A regra da tela 5, sem React e sem rede: **quais dias podem entrar num
 * documento oficial?**
 *
 * É aqui que mora a decisão que a US012 não tinha — pendente não entra — e a
 * que ela tinha e é fácil de inverter por descuido: bloqueado entra, porque
 * bloqueio é sobre editar.
 */

const MEALS: DayRecord['meals'] = [
  { type: 'morning_snack', description: 'Pão com leite', acceptance: 'great' },
  { type: 'lunch', description: 'Arroz e frango', acceptance: 'good' },
  { type: 'afternoon_snack', description: 'Bolo', acceptance: 'great' },
]

function day(overrides: Partial<DayRecord> = {}): DayRecord {
  return {
    id: 'map-2026-09-01',
    mapDate: '2026-09-01',
    nonSchoolDay: false,
    note: null,
    mealsServed: 300,
    locked: false,
    meals: MEALS,
    pendingUpload: false,
    ...overrides,
  }
}

describe('quem pode entrar no documento', () => {
  it('o dia preenchido e enviado entra', () => {
    expect(toOption('2026-09-01', day()).eligible).toBe(true)
  })

  it('o dia não letivo entra, porque ele também é registro do mês', () => {
    const option = toOption(
      '2026-09-01',
      day({ nonSchoolDay: true, note: 'Conselho de classe', mealsServed: null })
    )

    expect(option.state).toBe('non_school')
    expect(option.eligible).toBe(true)
  })

  it('o dia já incluído em outro documento entra de novo', () => {
    /*
     * O bloqueio é sobre editar, nunca sobre sair de novo — é o que sustenta
     * a regeração depois de uma correção (CA#4 da US023) e o mês inteiro
     * depois de uma semana já gerada.
     */
    const option = toOption('2026-09-01', day({ locked: true }))

    expect(option.state).toBe('locked')
    expect(option.eligible).toBe(true)
  })

  it('o dia pendente não entra, e diz o que falta nele', () => {
    const option = toOption('2026-09-01', day({ mealsServed: null }))

    expect(option.eligible).toBe(false)
    expect(missingReason(option)).toBe('pending')
  })

  it('o dia sem registro nenhum não entra', () => {
    const option = toOption('2026-09-01', undefined)

    expect(option.id).toBeNull()
    expect(option.eligible).toBe(false)
    expect(missingReason(option)).toBe('empty')
  })

  it('o dia que ainda não subiu não entra, mesmo preenchido (RN#3 da US012)', () => {
    /*
     * O documento é montado no servidor, com o que está lá. Um dia preenchido
     * que ainda está no aparelho não existe para a geração — e o rascunho nem
     * identificador do servidor tem.
     */
    const option = toOption(
      '2026-09-01',
      day({ id: null, pendingUpload: true })
    )

    expect(option.eligible).toBe(false)
    expect(missingReason(option)).toBe('unsent')
  })

  it('esperar enviar vem antes de faltar preencher', () => {
    // Mandá-la terminar um dia que já está preenchido seria mentira: o que
    // falta ali é internet, e isso se resolve sozinho.
    const option = toOption(
      '2026-09-01',
      day({ id: null, pendingUpload: true, mealsServed: null })
    )

    expect(missingReason(option)).toBe('unsent')
  })
})

describe('o período fecha ou não fecha', () => {
  const byDate = new Map([
    ['2026-09-01', day({ id: 'a', mapDate: '2026-09-01' })],
    ['2026-09-02', day({ id: 'b', mapDate: '2026-09-02', locked: true })],
    ['2026-09-03', day({ id: 'c', mapDate: '2026-09-03', mealsServed: null })],
  ])

  const dates = ['2026-09-01', '2026-09-02', '2026-09-03']

  it('uma semana com dia pendente não fecha', () => {
    expect(closable(toOptions(dates, byDate))).toBe(false)
  })

  it('e o que impede é nomeado dia a dia', () => {
    const missing = missingDays(toOptions(dates, byDate))

    expect(missing.map((option) => option.date)).toEqual(['2026-09-03'])
  })

  it('sem o dia pendente, fecha — e leva o bloqueado junto', () => {
    const closed = toOptions(['2026-09-01', '2026-09-02'], byDate)

    expect(closable(closed)).toBe(true)
    expect(eligibleIds(closed)).toEqual(['a', 'b'])
  })

  it('período sem dia nenhum não fecha: não há documento de nada', () => {
    expect(closable([])).toBe(false)
  })
})

describe('como o período aparece na confirmação', () => {
  it('uma seleção dentro de um mês é o mês, mesmo com dias soltos', () => {
    expect(periodLabel(['2026-09-01', '2026-09-15', '2026-09-30'])).toBe(
      'setembro'
    )
  })

  it('dois meses são nomeados, porque o rótulo não pode mentir', () => {
    expect(periodLabel(['2026-08-31', '2026-09-01'])).toBe('agosto e setembro')
  })

  it('três ou mais viram intervalo', () => {
    expect(periodLabel(['2026-08-31', '2026-09-10', '2026-10-01'])).toBe(
      'agosto a outubro'
    )
  })

  it('atravessando o ano, o ano aparece dos dois lados', () => {
    expect(periodLabel(['2026-12-20', '2027-01-05'])).toBe(
      'dezembro de 2026 e janeiro de 2027'
    )
  })
})
