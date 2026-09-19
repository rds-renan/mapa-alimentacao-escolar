import type { AcceptanceLevel, MealType } from '@/local/day'
import { dayAndMonth, MEAL_LABELS, weekdayOf } from '@/month/month'

import type { MealState } from './register'

/*
 * Os textos do registro do dia. São, onde a E3 os escreveu, os da tela 3 —
 * palavra por palavra —, e valem as três regras do catálogo de avisos: nenhuma
 * mensagem culpa a merendeira, o erro diz primeiro o que não se perdeu, e nada
 * de jargão.
 *
 * O que a faixa de salvamento diz não está aqui: é da camada local, que é quem
 * sabe em que pé está o envio.
 */

const WEEKDAYS = [
  'Domingo',
  'Segunda',
  'Terça',
  'Quarta',
  'Quinta',
  'Sexta',
  'Sábado',
]

/** "Terça, 1 de setembro" — o título da tela, como ela lê a data. */
export function dayTitle(date: string): string {
  return `${WEEKDAYS[weekdayOf(date)]}, ${dayAndMonth(date)}`
}

/** "Lanche da manhã" — o mesmo rótulo do mês, com a inicial de título. */
export const MEAL_TITLES: Record<MealType, string> = {
  morning_snack: capitalize(MEAL_LABELS.morning_snack),
  lunch: capitalize(MEAL_LABELS.lunch),
  afternoon_snack: capitalize(MEAL_LABELS.afternoon_snack),
}

/*
 * No feminino porque o assunto é a refeição, não o dia: no mês, "Preenchido" é
 * o dia; aqui, "Preenchida" é a refeição do cartão.
 */
export const MEAL_STATE_LABELS: Record<MealState, string> = {
  complete: 'Preenchida',
  pending: 'Pendente',
  empty: 'Vazia',
}

/** Os três botões da aceitação, na ordem em que aparecem (CA#2 da US004). */
export const ACCEPTANCE_ORDER: AcceptanceLevel[] = ['great', 'good', 'poor']

export const ACCEPTANCE_LABELS: Record<AcceptanceLevel, string> = {
  great: 'Ótimo',
  good: 'Bom',
  poor: 'Ruim',
}

export const DAY_MESSAGES = {
  backToMonth: 'Voltar para a visão do mês',
  loading: 'Carregando o dia…',
  /*
   * A leitura não veio e não há rascunho no aparelho: sem o dia inteiro na
   * mão, deixar editar reescreveria por cima do que está no servidor — a lista
   * que sobe é o dia todo, não um acréscimo. A mensagem separa as duas coisas,
   * que é o que ela precisa saber.
   */
  loadFailed:
    'Não deu para carregar este dia. O que você já registrou continua guardado — foi só a leitura que não veio.',
  retry: 'Tentar de novo',
  /*
   * O bloqueio (RN#1 da US007). Diz o porquê e para onde ir, porque reabrir o
   * mapa é da direção — e sem essa frase a tela pareceria quebrada.
   */
  locked:
    'Este dia já está em um documento gerado, por isso abre só para consulta. A direção pode reabrir o mapa para correção.',

  nonSchoolDayTitle: 'Dia não letivo',
  nonSchoolDayHint: 'Registra apenas uma observação',
  noteLabel: 'Observação',
  notePlaceholder: 'Ex.: conselho de classe, sem atendimento aos alunos',
  /* Diz o que falta sem chamar de erro o que é apenas o meio do caminho. */
  noteMissing: 'Escreva o motivo para este dia entrar no mapa.',

  descriptionLabel: 'Cardápio realizado',
  descriptionPlaceholder: 'Toque para escrever o que foi servido',
  acceptanceLabel: 'Aceitação',

  mealsServedTitle: 'Refeições servidas no dia',
  mealsServedHint: 'Número único do dia, informado pela direção',
  mealsServedLess: 'Uma refeição a menos',
  mealsServedMore: 'Uma refeição a mais',

  /* A decisão 3 da E3 em uma linha: não há botão de salvar, e isso se diz. */
  autosave: 'Salva sozinho, sem botão de salvar.',
  progress: 'Partes preenchidas do dia',
} as const

function capitalize(text: string): string {
  return `${text.charAt(0).toUpperCase()}${text.slice(1)}`
}
