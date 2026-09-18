import type { DayState } from './month'

/*
 * Os textos da visão do mês. Valem as três regras do catálogo de avisos da E3:
 * nenhuma mensagem culpa a merendeira, o erro diz primeiro o que não se
 * perdeu, e nada de jargão.
 *
 * Os rótulos de estado são os da tela 2 desenhada na E3, palavra por palavra.
 * "Preenchido" e não "completo" porque é assim que ela fala do dia que acabou
 * de registrar; "No documento" e não "bloqueado" porque o que importa para ela
 * é onde o dia foi parar, não o nome técnico da consequência.
 */

export const DAY_STATE_LABELS: Record<DayState, string> = {
  complete: 'Preenchido',
  pending: 'Pendente',
  non_school: 'Não letivo',
  locked: 'No documento',
  empty: 'Vazio',
}

/** O mesmo rótulo, no plural, para a linha de andamento do mês. */
const PLURAL: Record<DayState, string> = {
  complete: 'preenchidos',
  pending: 'pendentes',
  non_school: 'não letivos',
  locked: 'no documento',
  empty: 'vazios',
}

/** A ordem em que os estados aparecem na linha de andamento. */
const BREAKDOWN_ORDER: DayState[] = [
  'complete',
  'pending',
  'non_school',
  'locked',
  'empty',
]

/**
 * "6 preenchidos · 1 pendente · 1 não letivo · 5 no documento".
 *
 * Estado zerado não aparece: "0 pendentes" ocupa espaço para dizer que nada
 * aconteceu, e a linha existe para ela achar rápido o que falta.
 */
export function progressBreakdown(counts: Record<DayState, number>): string {
  return BREAKDOWN_ORDER.filter((state) => counts[state] > 0)
    .map((state) => {
      const amount = counts[state]
      const label =
        amount === 1 ? DAY_STATE_LABELS[state].toLowerCase() : PLURAL[state]
      return `${amount} ${label}`
    })
    .join(' · ')
}

export function schoolDaysLabel(days: number): string {
  return days === 1 ? '1 dia letivo' : `${days} dias letivos`
}

export function progressLabel(done: number, schoolDays: number): string {
  return `${done} de ${schoolDays} ${schoolDays === 1 ? 'dia' : 'dias'}`
}

export const MONTH_MESSAGES = {
  /*
   * A web não promete navegar sem internet — isso é a E6 (decisão 2 da E5). O
   * que a mensagem precisa fazer, então, é separar as duas coisas na cabeça
   * dela: a lista não veio, mas o que ela digitou está guardado.
   */
  loadFailed:
    'Não deu para carregar os dias deste mês. O que você já registrou continua guardado — foi só a lista que não veio.',
  retry: 'Tentar de novo',
  loading: 'Carregando os dias do mês…',
  empty: 'Nenhum dia para mostrar neste mês.',
} as const

/** "1 dia salvo neste computador…", a nota que acompanha a falha de carga. */
export function keptOnDeviceLabel(pending: number): string {
  return pending === 1
    ? '1 dia salvo neste computador continua esperando para ser enviado.'
    : `${pending} dias salvos neste computador continuam esperando para ser enviados.`
}
