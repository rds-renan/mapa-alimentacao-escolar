/// Os textos da manutenção do catálogo — porto de
/// `web/src/food-items/messages.ts` (issue #107). Valem as três regras do
/// catálogo de avisos da E3: nenhuma mensagem culpa a merendeira, o erro diz
/// primeiro o que não se perdeu, e nada de jargão.
///
/// "Desativar" e não "excluir" porque não é o que acontece: o gênero sai das
/// sugestões e continua nos dias que já o usaram (CA#3 da US009).
library;

class CatalogMessages {
  const CatalogMessages._();

  static const title = 'Catálogo de gêneros';
  static const subtitle = 'Cada item tem a sua unidade padrão';

  static const search = 'Buscar gênero';

  static const newTitle = 'Novo gênero';
  static const editTitle = 'Editar gênero';
  static const cancelEdit = 'Cancelar a edição';
  static const nameLabel = 'Nome';
  static const namePlaceholder = 'Feijão preto';
  static const unitLabel = 'Unidade padrão';
  static const unitPlaceholder = 'quilo, pote, bandeja…';
  static const add = 'Adicionar ao catálogo';
  static const save = 'Salvar';
  static const saving = 'Salvando…';
  static const deactivate = 'Desativar';
  static const reactivate = 'Reativar';

  /// Diz que o aplicativo está sem rede e o que isso custa: a lista continua
  /// à mão, só alterar é que espera a internet.
  static const offline =
      'Sem internet. Dá para ver a lista, mas para cadastrar ou alterar '
      'precisa de internet.';

  /// O aviso da consequência retroativa. Não é erro nem proibição: é o que
  /// ela precisa saber para decidir, e aparece só quando a unidade de um
  /// gênero que já existe muda (#64).
  static const unitChanged =
      'Mudar a unidade muda também os dias que já usaram este gênero, e o '
      'documento que ainda não foi gerado sai com a unidade nova.';

  static const listTitle = 'No catálogo';
  static const empty =
      'O catálogo ainda está vazio. Cadastre o primeiro gênero aqui em cima.';
  static const noResults = 'Nenhum gênero com esse nome.';

  static const saveFailed =
      'Não deu para salvar agora, quase sempre é a internet. O que você '
      'escreveu continua no formulário — é só tentar de novo.';

  static String edit(String name) => 'Editar $name';

  static String inactiveTitle(int amount) => 'Desativados ($amount)';

  /// Quando o homônimo está desativado, a mensagem diz onde ele está: sem
  /// isso ela ficaria tentando cadastrar um gênero que a lista de cima não
  /// mostra, sem entender por que não entra.
  static String duplicate(String name, {required bool active}) => active
      ? '"$name" já está no catálogo.'
      : '"$name" já está no catálogo, entre os desativados. Reative-o em '
            'vez de cadastrar de novo.';
}
