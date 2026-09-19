/*
 * Os textos da manutenção do catálogo. Valem as três regras da linguagem do
 * catálogo de avisos da E3: nenhuma mensagem culpa a merendeira, o erro diz
 * primeiro o que não se perdeu, e nada de jargão.
 *
 * "Desativar" e não "excluir" porque não é o que acontece: o gênero sai das
 * sugestões e continua nos dias que já o usaram (CA#3 da US009). O texto do
 * botão é a única explicação que ela vai ler, então ele diz a consequência —
 * "sai das sugestões" — e não o nome da operação.
 */

export const CATALOG_MESSAGES = {
  title: 'Catálogo de gêneros',
  subtitle: 'Cada item tem a sua unidade padrão',
  back: 'Voltar para a visão do mês',

  search: 'Buscar gênero',

  newTitle: 'Novo gênero',
  editTitle: 'Editar gênero',
  cancelEdit: 'Cancelar a edição',
  nameLabel: 'Nome',
  namePlaceholder: 'Feijão preto',
  unitLabel: 'Unidade padrão',
  unitPlaceholder: 'quilo, pote, bandeja…',
  unitHint: 'Escolha uma sugestão ou escreva a unidade que a cozinha usa.',
  add: 'Adicionar ao catálogo',
  save: 'Salvar',
  deactivate: 'Desativar',
  reactivate: 'Reativar',

  /*
   * O aviso da consequência retroativa. Não é erro nem proibição: é o que ela
   * precisa saber para decidir, e aparece só quando a unidade de um gênero que
   * já existe muda.
   */
  unitChanged:
    'Mudar a unidade muda também os dias que já usaram este gênero, e o documento que ainda não foi gerado sai com a unidade nova.',

  listTitle: 'No catálogo',
  loading: 'Carregando o catálogo…',
  loadFailed:
    'Não deu para carregar o catálogo. Nada foi perdido — foi só a lista que não veio.',
  retry: 'Tentar de novo',
  empty:
    'O catálogo ainda está vazio. Cadastre o primeiro gênero aqui em cima.',
  noResults: 'Nenhum gênero com esse nome.',

  saving: 'Salvando…',
  saveFailed:
    'Não deu para salvar agora, quase sempre é a internet. O que você escreveu continua no formulário — é só tentar de novo.',
} as const

/** "Editar Arroz", o nome do alvo de toque de cada linha para o leitor de tela. */
export function editLabel(name: string): string {
  return `Editar ${name}`
}

/** "Desativados (2)", o título da seção recolhida do pé da lista. */
export function inactiveTitle(amount: number): string {
  return `Desativados (${amount})`
}

/** O que sai depois de cadastrar, editar, desativar e reativar. */
export function addedLabel(name: string): string {
  return `${name} entrou no catálogo.`
}

export function savedLabel(name: string): string {
  return `${name} foi salvo.`
}

export function deactivatedLabel(name: string): string {
  return `${name} saiu das sugestões. Os dias que já o usaram continuam como estão.`
}

export function reactivatedLabel(name: string): string {
  return `${name} voltou para as sugestões.`
}

/**
 * O nome já está no catálogo.
 *
 * Quando o homônimo está desativado, a mensagem diz onde ele está: sem isso,
 * ela ficaria tentando cadastrar um gênero que a lista de cima não mostra.
 */
export function duplicateLabel(name: string, active: boolean): string {
  return active
    ? `${name} já está no catálogo.`
    : `${name} já está no catálogo, entre os desativados. Reative para usar de novo.`
}
