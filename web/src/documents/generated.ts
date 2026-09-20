import {
  dateToday,
  dayAndMonth,
  isWeekday,
  monthKeyOf,
  monthName,
  monthRange,
  type MonthKey,
} from '@/month/month'

/*
 * O documento gerado, como a tela 2b precisa dele.
 *
 * Tudo aqui é função pura sobre texto e número, pelo mesmo motivo do mês: o
 * que esta tela tem de difícil não é desenhar os cartões, é dizer em que
 * situação está cada documento — e essa conta se faz com o relógio de quem
 * está olhando, que num teste precisa estar parado.
 *
 * Duas coisas **não** vêm gravadas no servidor e são derivadas aqui, porque a
 * decisão 10 da E4 assim o quis: o período e a quantidade de mapas nascem da
 * ligação `document_meal_map`, que é a única que sabe quais dias entraram.
 * O que vem gravado é o que não se recalcula sem mentir — a validade, que o
 * banco carimbou, e o nome do arquivo, que a geração escolheu.
 */

/** A situação do documento **para quem olha agora**, que não é a do banco. */
export type DocumentAvailability =
  /** A geração está em curso. */
  | 'processing'
  /** O arquivo está no ar e ainda tem folga. */
  | 'available'
  /** Está no ar, mas sai hoje ou amanhã. */
  | 'expiring'
  /** Passou da janela de sete dias: o arquivo já não existe (RN#1 da US021). */
  | 'expired'
  /** A geração não produziu arquivo nenhum. */
  | 'failed'

/** Um documento gerado, como o servidor o entrega à lista. */
export interface GeneratedDocumentRecord {
  id: string
  status: 'processing' | 'available' | 'failed'
  requestedAt: string
  completedAt: string | null
  expiresAt: string | null
  /** O endereço no balde. É com ele que se assina o link de download. */
  filePath: string | null
  /** O nome com que o arquivo chega em quem o recebe. */
  fileName: string | null
  /** As datas dos mapas incluídos, em ordem. Delas saem o período e a conta. */
  dates: string[]
}

// ---------------------------------------------------------------------------
// A situação
// ---------------------------------------------------------------------------

/** Dias de calendário entre duas datas AAAA-MM-DD. Em UTC, que é onde não escorrega. */
function daysBetween(from: string, to: string): number {
  const [fromYear, fromMonth, fromDay] = from.split('-').map(Number)
  const [toYear, toMonth, toDay] = to.split('-').map(Number)

  const difference =
    Date.UTC(toYear, toMonth - 1, toDay) -
    Date.UTC(fromYear, fromMonth - 1, fromDay)

  return Math.round(difference / 86_400_000)
}

/** A data local de um instante do servidor, em AAAA-MM-DD. */
function localDate(instant: string): string {
  return dateToday(new Date(instant))
}

/**
 * Quantos dias de calendário faltam para o arquivo sair do ar.
 *
 * É conta de calendário, e não de vinte e quatro horas: é assim que se pensa
 * num prazo, e um documento que vence às 23h de hoje não sai "em um dia" para
 * quem olha às 8h da manhã. Zero é hoje; negativo já saiu.
 */
export function daysLeft(
  document: GeneratedDocumentRecord,
  now = new Date()
): number | null {
  if (!document.expiresAt) return null
  return daysBetween(dateToday(now), localDate(document.expiresAt))
}

export function availabilityOf(
  document: GeneratedDocumentRecord,
  now = new Date()
): DocumentAvailability {
  if (document.status === 'failed') return 'failed'
  if (document.status === 'processing') return 'processing'

  /*
   * Disponível sem prazo não existe — o check do banco exige os dois juntos —,
   * mas o cliente não é quem garante isso. Tratar o caso impossível como
   * vencido é o lado seguro: no máximo ela vê um documento a menos, e nunca um
   * botão que baixa o nada.
   */
  if (!document.expiresAt) return 'expired'
  if (Date.parse(document.expiresAt) <= now.getTime()) return 'expired'

  const left = daysLeft(document, now) as number
  return left <= 1 ? 'expiring' : 'available'
}

/** O arquivo pode ser baixado agora. */
export function downloadable(availability: DocumentAvailability): boolean {
  return availability === 'available' || availability === 'expiring'
}

// ---------------------------------------------------------------------------
// O período
// ---------------------------------------------------------------------------

/** "Setembro", sozinho e com inicial maiúscula. */
function capitalizedMonth(month: MonthKey): string {
  const name = monthName(month)
  return `${name.charAt(0).toUpperCase()}${name.slice(1)}`
}

/**
 * Todo dia útil do mês entrou. É o que separa "1 a 30 de setembro" de
 * "Setembro · mês inteiro" no desenho da E3 — e a conta é possível aqui
 * porque o mês inteiro, no MAE, é exatamente os dias úteis: o dia não letivo
 * também tem mapa, e o fim de semana só entra quando alguém registrou.
 */
function coversWholeMonth(dates: string[]): boolean {
  const month = monthKeyOf(dates[0])
  const included = new Set(dates)
  const lastDay = Number(monthRange(month).last.slice(-2))

  for (let day = 1; day <= lastDay; day += 1) {
    const date = `${month}-${String(day).padStart(2, '0')}`
    if (isWeekday(date) && !included.has(date)) return false
  }

  return true
}

/**
 * O título do cartão: o que a merendeira chama de "aquele documento".
 *
 * São as três formas do desenho da E3, e a régua entre elas é não mentir: um
 * dia só é a data; o mês fechado se diz pelo nome, porque é assim que ela o
 * pediu; e o resto é o intervalo, que é o que o documento realmente cobre —
 * dias avulsos dentro dele são o que a tabela do arquivo mostra, linha a
 * linha.
 */
export function periodTitle(dates: string[]): string {
  if (dates.length === 0) return ''

  const sorted = [...dates].sort()
  const first = sorted[0]
  const last = sorted[sorted.length - 1]

  if (first === last) return dayAndMonth(first)

  // Seleção que atravessa o ano-novo: sem o ano, os dois lados ficam iguais.
  if (first.slice(0, 4) !== last.slice(0, 4)) {
    return `${dayAndMonth(first)} de ${first.slice(0, 4)} a ${dayAndMonth(last)} de ${last.slice(0, 4)}`
  }

  const months = new Set(sorted.map(monthKeyOf))
  if (months.size > 1) return `${dayAndMonth(first)} a ${dayAndMonth(last)}`

  if (coversWholeMonth(sorted)) {
    return `${capitalizedMonth(monthKeyOf(first))} · mês inteiro`
  }

  return `${Number(first.slice(-2))} a ${dayAndMonth(last)}`
}

// ---------------------------------------------------------------------------
// As linhas de apoio
// ---------------------------------------------------------------------------

export function mapCountLabel(count: number): string {
  return count === 1 ? '1 mapa' : `${count} mapas`
}

/** "14h32" — a hora como ela aparece no cartão do dia em que foi gerado. */
function timeOfDay(instant: string): string {
  const moment = new Date(instant)
  return `${moment.getHours()}h${String(moment.getMinutes()).padStart(2, '0')}`
}

/**
 * "gerado hoje, 14h32" ou "gerado em 1 de setembro".
 *
 * A hora só aparece no dia em que aconteceu, que é quando ela distingue duas
 * gerações; num documento de três dias atrás, a hora é ruído.
 */
export function generatedLabel(
  document: GeneratedDocumentRecord,
  now = new Date()
): string {
  const instant = document.completedAt ?? document.requestedAt
  const date = localDate(instant)

  return date === dateToday(now)
    ? `gerado hoje, ${timeOfDay(instant)}`
    : `gerado em ${dayAndMonth(date)}`
}

/** "10 mapas · gerado hoje, 14h32" — a linha sob o título do cartão. */
export function documentSummary(
  document: GeneratedDocumentRecord,
  now = new Date()
): string {
  return `${mapCountLabel(document.dates.length)} · ${generatedLabel(document, now)}`
}

/** "Sai do ar em 9 de setembro." */
export function expiryLabel(document: GeneratedDocumentRecord): string {
  if (!document.expiresAt) return ''
  return `Sai do ar em ${dayAndMonth(localDate(document.expiresAt))}`
}
