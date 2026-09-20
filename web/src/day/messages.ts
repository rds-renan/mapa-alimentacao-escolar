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
  /*
   * O outro lado do bloqueio (CA#2 da US023): a direção reabriu, e o dia voltou
   * a aceitar edição. A justificativa que ela escreveu **não** aparece aqui, por
   * decisão de escopo — o texto é prestação de contas, não recado —, então a
   * frase diz o que mudou e o que fazer com isso, e não por quê.
   */
  reopened:
    'A direção reabriu este dia para correção. Ele voltou a aceitar edição, e o que você corrigir entra no próximo documento gerado.',

  nonSchoolDayTitle: 'Dia não letivo',
  nonSchoolDayHint: 'Registra apenas uma observação',
  noteLabel: 'Observação',
  notePlaceholder: 'Ex.: conselho de classe, sem atendimento aos alunos',
  /* Diz o que falta sem chamar de erro o que é apenas o meio do caminho. */
  noteMissing: 'Escreva o motivo para este dia entrar no mapa.',

  /*
   * "Previsto", e não "realizado" como a coluna do formulário oficial se
   * chama: a linha da refeição permanece fiel ao cardápio previsto mesmo
   * quando houve troca, e é essa permanência que dá sentido à justificativa
   * (decisão 8 da E3, decisão 7 da E4). Chamá-la de "realizado" na tela
   * pediria à merendeira exatamente o que a tela 3a lhe diz para não fazer.
   */
  descriptionLabel: 'Cardápio previsto',
  descriptionPlaceholder: 'Toque para escrever o cardápio da refeição',
  acceptanceLabel: 'Aceitação',

  mealsServedTitle: 'Refeições servidas no dia',
  mealsServedHint: 'Número único do dia, informado pela direção',
  mealsServedLess: 'Uma refeição a menos',
  mealsServedMore: 'Uma refeição a mais',

  foodItemsLabel: 'Gêneros utilizados',
  foodItemsOptional: 'opcional',
  addFoodItem: 'Adicionar gênero',
  menuChange: 'Alteração do cardápio',
  /*
   * O "−" de quem está em 1 tira o gênero da lista, e o leitor de tela precisa
   * dizer isso antes do toque: quantidade zero não existe (RN#1 da US003), e
   * um botão que às vezes diminui e às vezes apaga não pode ter um nome só.
   */
  foodItemLess: (name: string, last: boolean) =>
    last ? `Tirar ${name} da lista` : `Um a menos de ${name}`,
  foodItemMore: (name: string) => `Um a mais de ${name}`,
  foodItemQuantity: (name: string, unit: string | null) =>
    unit ? `Quantidade de ${name}, em ${unit}` : `Quantidade de ${name}`,

  /* A decisão 3 da E3 em uma linha: não há botão de salvar, e isso se diz. */
  autosave: 'Salva sozinho, sem botão de salvar.',
  progress: 'Partes preenchidas do dia',
} as const

/** "Almoço · Terça, 9 de setembro" — o subtítulo das telas 3a e 3b. */
export function mealSubtitle(type: MealType, date: string): string {
  return `${MEAL_TITLES[type]} · ${dayTitle(date)}`
}

/*
 * A alteração do cardápio — tela 3a (US002).
 *
 * O aviso do alto é a decisão 8 da E3 dita para quem está preenchendo: a
 * refeição não muda, aqui vai só o que entrou no lugar. Sem ele a tela
 * convidaria a reescrever o cardápio, que é justamente o que tiraria o sentido
 * da justificativa.
 */
export const MENU_CHANGE_MESSAGES = {
  title: 'Alteração do cardápio',
  close: 'Fechar a alteração do cardápio',
  notice: (type: MealType) =>
    `O ${MEAL_LABELS[type]} continua registrado como o cardápio previsto. Aqui vão só os gêneros que você usou no lugar.`,
  itemsLabel: 'Gêneros utilizados na troca',
  reasonLabel: 'Motivo',
  reasonPlaceholder: 'Toque para escrever o motivo da troca',
  /* Texto livre com sugestões de motivos frequentes (RNF#1 da US002). */
  reasonSuggestions: [
    'Falta de entrega do fornecedor',
    'Item impróprio',
    'Quantidade insuficiente',
  ],
  document:
    'Os gêneros e o motivo saem no documento oficial, na coluna reservada às alterações.',
  /*
   * As duas linhas do meio do caminho, no mesmo tom da observação do dia não
   * letivo: dizem o que falta para o dia subir, sem chamar de erro o que é
   * apenas o preenchimento em andamento.
   */
  itemsMissing: 'Escolha o gênero que entrou para esta alteração valer.',
  reasonMissing: 'Escreva o motivo para esta alteração entrar no mapa.',
  remove: 'Remover a alteração',
  /* No dia bloqueado não há o que cancelar nem confirmar: só fechar. */
  done: 'Fechar',
  cancel: 'Cancelar',
  confirm: 'Confirmar alteração',
} as const

/*
 * Escolher gênero — tela 3b, a folha que sobe sobre o registro (decisão 7 da
 * E3). Sair da tela do dia para o catálogo seria literalmente sair do fluxo, e
 * o item cadastrado lá não se prenderia sozinho à refeição.
 */
export const FOOD_ITEM_SHEET_MESSAGES = {
  title: 'Escolher gênero',
  close: 'Fechar a escolha de gênero',
  search: 'Buscar gênero',
  loading: 'Carregando o catálogo…',
  /*
   * Sem catálogo ela não fica parada: o cadastro embaixo continua de pé, e o
   * gênero nasce junto com o dia quando ele subir.
   */
  loadFailed:
    'Não deu para carregar o catálogo. Você pode cadastrar o gênero aqui mesmo.',
  noResults: 'Nenhum gênero com esse nome. Cadastre abaixo.',
  alreadyChosen: 'já está aqui',
  newTitle: 'Não está na lista?',
  newHint: 'Cadastre aqui e o item já entra na refeição.',
  newNameLabel: 'Nome do gênero',
  newNamePlaceholder: 'Ex.: feijão preto',
  newUnitLabel: 'Unidade padrão',
  add: 'Adicionar à refeição',
} as const

function capitalize(text: string): string {
  return `${text.charAt(0).toUpperCase()}${text.slice(1)}`
}
