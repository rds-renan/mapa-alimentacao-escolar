import { describe, expect, it } from 'vitest'

import {
  availabilityOf,
  documentSummary,
  downloadable,
  expiryLabel,
  mapCountLabel,
  periodTitle,
  type GeneratedDocumentRecord,
} from './generated'

/*
 * As regras da tela 2b, sem React e sem rede.
 *
 * O relógio é sempre explícito, e é o ponto: a situação de um documento não
 * está gravada em lugar nenhum — ela é a comparação entre o prazo que o banco
 * carimbou e o dia em que a merendeira está olhando. Um teste que usasse o
 * relógio da máquina mudaria de resultado conforme a hora em que roda.
 */

/** 9 de setembro de 2026, 14h32, no fuso de quem está olhando. */
const AGORA = new Date(2026, 8, 9, 14, 32)

function documento(
  changes: Partial<GeneratedDocumentRecord> = {}
): GeneratedDocumentRecord {
  return {
    id: 'doc-1',
    status: 'available',
    requestedAt: new Date(2026, 8, 9, 14, 32).toISOString(),
    completedAt: new Date(2026, 8, 9, 14, 32).toISOString(),
    expiresAt: new Date(2026, 8, 16, 14, 32).toISOString(),
    filePath: 'escola/doc-1.docx',
    fileName: 'mapa-da-alimentacao-escolar-setembro-2026.docx',
    dates: ['2026-09-01', '2026-09-02', '2026-09-03'],
    ...changes,
  }
}

/** Todos os dias úteis de setembro de 2026: o mês que fecha inteiro. */
function setembroInteiro(): string[] {
  const dates: string[] = []

  for (let day = 1; day <= 30; day += 1) {
    const date = new Date(Date.UTC(2026, 8, day))
    const weekday = date.getUTCDay()
    if (weekday >= 1 && weekday <= 5) {
      dates.push(`2026-09-${String(day).padStart(2, '0')}`)
    }
  }

  return dates
}

describe('a situação do documento', () => {
  it('no ar e com folga é disponível', () => {
    expect(availabilityOf(documento(), AGORA)).toBe('available')
    expect(downloadable('available')).toBe(true)
  })

  it('vencendo amanhã é "sai amanhã", e ainda baixa', () => {
    const amanha = documento({
      expiresAt: new Date(2026, 8, 10, 8, 0).toISOString(),
    })

    expect(availabilityOf(amanha, AGORA)).toBe('expiring')
    expect(downloadable('expiring')).toBe(true)
  })

  it('vencendo hoje à noite ainda está no ar', () => {
    const hoje = documento({
      expiresAt: new Date(2026, 8, 9, 23, 0).toISOString(),
    })

    expect(availabilityOf(hoje, AGORA)).toBe('expiring')
  })

  it('passado o prazo, sai do ar', () => {
    const vencido = documento({
      expiresAt: new Date(2026, 8, 9, 12, 0).toISOString(),
    })

    expect(availabilityOf(vencido, AGORA)).toBe('expired')
    expect(downloadable('expired')).toBe(false)
  })

  it('a geração em curso não oferece arquivo', () => {
    const gerando = documento({
      status: 'processing',
      completedAt: null,
      expiresAt: null,
      filePath: null,
      fileName: null,
    })

    expect(availabilityOf(gerando, AGORA)).toBe('processing')
    expect(downloadable('processing')).toBe(false)
  })

  it('a geração que falhou fica no registro, e não baixa nada', () => {
    const falhou = documento({
      status: 'failed',
      expiresAt: null,
      filePath: null,
      fileName: null,
    })

    expect(availabilityOf(falhou, AGORA)).toBe('failed')
    expect(downloadable('failed')).toBe(false)
  })
})

describe('o período do documento', () => {
  it('um dia só é a data', () => {
    expect(periodTitle(['2026-09-10'])).toBe('10 de setembro')
  })

  it('dias dentro do mês são o intervalo', () => {
    expect(periodTitle(['2026-09-01', '2026-09-08', '2026-09-12'])).toBe(
      '1 a 12 de setembro'
    )
  })

  it('o mês fechado se diz pelo nome', () => {
    expect(periodTitle(setembroInteiro())).toBe('Setembro · mês inteiro')
  })

  it('faltando um dia útil, volta a ser intervalo', () => {
    const semODia15 = setembroInteiro().filter((date) => date !== '2026-09-15')
    expect(periodTitle(semODia15)).toBe('1 a 30 de setembro')
  })

  it('a seleção que atravessa meses nomeia os dois', () => {
    expect(periodTitle(['2026-08-31', '2026-09-04'])).toBe(
      '31 de agosto a 4 de setembro'
    )
  })

  it('atravessando o ano-novo, o ano aparece dos dois lados', () => {
    expect(periodTitle(['2026-12-28', '2027-01-05'])).toBe(
      '28 de dezembro de 2026 a 5 de janeiro de 2027'
    )
  })

  it('a ordem em que os dias chegam não muda o rótulo', () => {
    expect(periodTitle(['2026-09-12', '2026-09-01'])).toBe('1 a 12 de setembro')
  })
})

describe('as linhas de apoio do cartão', () => {
  it('conta os mapas no singular e no plural', () => {
    expect(mapCountLabel(1)).toBe('1 mapa')
    expect(mapCountLabel(10)).toBe('10 mapas')
  })

  it('gerado hoje mostra a hora, que é o que separa duas gerações', () => {
    expect(documentSummary(documento(), AGORA)).toBe(
      '3 mapas · gerado hoje, 14h32'
    )
  })

  it('gerado antes de hoje mostra a data, e a hora vira ruído', () => {
    const ontem = documento({
      completedAt: new Date(2026, 8, 1, 9, 5).toISOString(),
    })

    expect(documentSummary(ontem, AGORA)).toBe(
      '3 mapas · gerado em 1 de setembro'
    )
  })

  it('a geração em curso se data pelo pedido, que é o que ela tem', () => {
    const gerando = documento({
      status: 'processing',
      completedAt: null,
      requestedAt: new Date(2026, 8, 9, 14, 30).toISOString(),
    })

    expect(documentSummary(gerando, AGORA)).toBe('3 mapas · gerado hoje, 14h30')
  })

  it('diz quando o arquivo sai do ar', () => {
    expect(expiryLabel(documento())).toBe('Sai do ar em 16 de setembro')
  })
})
