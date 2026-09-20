import {
  dayState,
  filled,
  monthKeyOf,
  monthName,
  type DayRecord,
  type DayState,
} from '@/month/month'

/*
 * A seleção de mapas — a regra da tela 5, sem React e sem rede.
 *
 * O que ela decide é uma pergunta só: **quais dias podem entrar num documento
 * oficial?** E a resposta não é a mesma que a visão do mês dá. Lá o estado do
 * dia descreve o que existe; aqui ele decide o que sai numa prestação de
 * contas, e a régua é mais dura em dois pontos:
 *
 * - **Dia pendente não entra em documento.** A US012 pedia apenas que os
 *   pendentes fossem *apontados* antes de gerar (CA#3), e o servidor os aceita
 *   — sairiam como o formulário em branco naquela refeição. A decisão do
 *   projeto foi outra: um mapa incompleto que vai à prefeitura é um mapa que
 *   volta, e o bloqueio da geração é irreversível para a merendeira. Então ele
 *   não é selecionável, e um atalho que não consegue fechar o período inteiro
 *   não seleciona nada — avisa o que falta.
 * - **Dia que ainda não subiu não entra**, porque o documento é montado no
 *   servidor com o que está lá (RN#3 da US012). O rascunho no aparelho tem um
 *   identificador próprio que o servidor pode nem ter adotado; mandá-lo seria
 *   pedir um dia que não existe.
 *
 * **Bloqueado, esse, entra.** Bloqueio é sobre editar, nunca sobre sair de
 * novo: é o que sustenta a regeração depois de uma correção (CA#4 da US023), e
 * é o que permite gerar o mês inteiro depois de já ter gerado uma semana dele.
 */

/**
 * Os três jeitos de escolher da tela 5. São modos, e não botões de ação: o
 * desenho da E3 mostra os três como um seletor, e só desenhou o terceiro
 * aberto — os dois primeiros escolhem por período e dispensam marcar dia a
 * dia, que é o "poucos toques" do RNF#1 da US013.
 */
export type SelectionMode = 'month' | 'week' | 'days'

/** Um dia na lista da tela 5. */
export interface DayOption {
  date: string
  /** O identificador do mapa no servidor. É o que a geração recebe. */
  id: string | null
  state: DayState
  /** Guardado no aparelho, ainda esperando subir. */
  unsent: boolean
  /** Pode entrar num documento. */
  eligible: boolean
  /** Quantas refeições o dia descreve — é o que a linha mostra quando ele entra. */
  meals: number
}

/** Por que um dia não pode entrar. É o que a merendeira precisa ir resolver. */
export type MissingReason = 'pending' | 'empty' | 'unsent'

const CAN_BE_GENERATED: DayState[] = ['complete', 'locked', 'non_school']

export function toOption(
  date: string,
  record: DayRecord | undefined
): DayOption {
  const state = dayState(record)
  const unsent = record?.pendingUpload ?? false
  const id = record?.id ?? null

  return {
    date,
    id,
    state,
    unsent,
    eligible: id !== null && !unsent && CAN_BE_GENERATED.includes(state),
    meals: (record?.meals ?? []).filter((meal) => filled(meal.description))
      .length,
  }
}

export function toOptions(
  days: string[],
  byDate: Map<string, DayRecord>
): DayOption[] {
  return days.map((date) => toOption(date, byDate.get(date)))
}

/**
 * O motivo de o dia estar de fora, na ordem em que ele é acionável.
 *
 * "Esperando enviar" vem antes de tudo porque é o único que se resolve sozinho
 * — basta haver internet —, e mandá-la abrir um dia que já está preenchido
 * para "terminar de preencher" seria mentira.
 */
export function missingReason(option: DayOption): MissingReason | null {
  if (option.eligible) return null
  if (option.unsent) return 'unsent'
  if (option.state === 'pending') return 'pending'
  return 'empty'
}

/** Os dias do período que impedem de fechá-lo. */
export function missingDays(options: DayOption[]): DayOption[] {
  return options.filter((option) => !option.eligible)
}

/** O período fecha: todo dia listado pode entrar no documento. */
export function closable(options: DayOption[]): boolean {
  return options.length > 0 && options.every((option) => option.eligible)
}

export function eligibleIds(options: DayOption[]): string[] {
  return options
    .filter((option) => option.eligible)
    .map((option) => option.id as string)
}

/**
 * Como o período aparece na confirmação: "Gerar o documento de **setembro**?".
 *
 * É a mesma regra que o preenchimento do modelo usa no campo "MÊS/ANO": o
 * rótulo nomeia os meses que a seleção toca, e não os dias — quais dias
 * entraram é o que a tabela do documento mostra, linha a linha. O ano só
 * aparece quando a seleção atravessa dois, que é quando omiti-lo passaria a
 * mentir.
 */
export function periodLabel(dates: string[]): string {
  const months = [...new Set(dates.map(monthKeyOf))].sort()
  if (months.length === 0) return ''

  const years = new Set(months.map((month) => month.slice(0, 4)))
  const name = (month: string) =>
    years.size > 1
      ? `${monthName(month)} de ${month.slice(0, 4)}`
      : monthName(month)

  const first = name(months[0])
  if (months.length === 1) return first

  const last = name(months[months.length - 1])
  return months.length === 2 ? `${first} e ${last}` : `${first} a ${last}`
}
