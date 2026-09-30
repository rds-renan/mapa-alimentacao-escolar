/// Os textos do registro do dia (issues #105 e #106) — porto de
/// `web/src/day/messages.ts`, com a tela 3a (alteração do cardápio) e a folha
/// 3b (escolher gênero).
///
/// Valem as três regras do catálogo de avisos: nenhuma mensagem culpa a
/// merendeira, o erro diz primeiro o que não se perdeu, e nada de jargão. O
/// que a faixa de salvamento diz não está aqui: é de `sync_messages.dart`,
/// que é quem sabe em que pé está o envio.
library;

import '../month/month.dart' show dayAndMonth, mealLabels, mealOrder;
import 'register.dart' show MealState;

const List<String> _weekdays = [
  'Domingo',
  'Segunda',
  'Terça',
  'Quarta',
  'Quinta',
  'Sexta',
  'Sábado',
];

String _capitalize(String text) =>
    '${text[0].toUpperCase()}${text.substring(1)}';

/// "Terça, 1 de setembro" — o título da tela, como ela lê a data.
String dayTitle(String mapDate) {
  final date = DateTime.parse(mapDate);
  // `DateTime.weekday`: segunda = 1 … domingo = 7; `_weekdays` é indexado a
  // partir de domingo = 0, como o `Date.getDay()` do JavaScript.
  final weekday = date.weekday % 7;
  return '${_weekdays[weekday]}, ${dayAndMonth(date)}';
}

/// "Lanche da manhã" — o mesmo rótulo do mês, com a inicial de título.
final Map<String, String> mealTitles = {
  for (final type in mealOrder) type: _capitalize(mealLabels[type]!),
};

/// No feminino porque o assunto é a refeição, não o dia: no mês,
/// "Preenchido" é o dia; aqui, "Preenchida" é a refeição do cartão.
const Map<MealState, String> mealStateLabels = {
  MealState.complete: 'Preenchida',
  MealState.pending: 'Pendente',
  MealState.empty: 'Vazia',
};

/// Os três botões da aceitação, na ordem em que aparecem (CA#2 da US004).
const List<String> acceptanceOrder = ['great', 'good', 'poor'];

const Map<String, String> acceptanceLabels = {
  'great': 'Ótimo',
  'good': 'Bom',
  'poor': 'Ruim',
};

class DayMessages {
  const DayMessages._();

  static const loading = 'Carregando o dia…';

  /// A leitura não veio e não há rascunho no aparelho: sem o dia inteiro na
  /// mão, deixar editar reescreveria por cima do que está no servidor — a
  /// lista que sobe é o dia todo, não um acréscimo.
  static const loadFailed =
      'Não deu para carregar este dia. O que você já registrou continua '
      'guardado — foi só a leitura que não veio.';
  static const retry = 'Tentar de novo';

  /// O bloqueio (RN#1 da US007). Diz o porquê e para onde ir, porque reabrir
  /// o mapa é da direção, na web — sem essa frase a tela pareceria quebrada.
  static const locked =
      'Este dia já está em um documento gerado, por isso abre só para '
      'consulta. A direção pode reabrir o mapa para correção.';

  static const nonSchoolDayTitle = 'Dia não letivo';
  static const nonSchoolDayHint = 'Registra apenas uma observação';
  static const noteLabel = 'Observação';
  static const notePlaceholder =
      'Ex.: conselho de classe, sem atendimento '
      'aos alunos';

  /// Diz o que falta sem chamar de erro o que é apenas o meio do caminho.
  static const noteMissing = 'Escreva o motivo para este dia entrar no mapa.';

  /// "Previsto", e não "realizado" como a coluna do formulário oficial se
  /// chama: a linha da refeição permanece fiel ao cardápio previsto mesmo
  /// quando houve troca, e é essa permanência que dá sentido à justificativa
  /// (decisão 8 da E3, decisão 7 da E4).
  static const descriptionLabel = 'Cardápio previsto';
  static const descriptionPlaceholder =
      'Toque para escrever o cardápio da '
      'refeição';
  static const acceptanceLabel = 'Aceitação';

  static const mealsServedTitle = 'Refeições servidas no dia';
  static const mealsServedHint =
      'Número único do dia, informado pela '
      'direção';
  static const mealsServedLess = 'Uma refeição a menos';
  static const mealsServedMore = 'Uma refeição a mais';

  static const foodItemsLabel = 'Gêneros utilizados';
  static const foodItemsOptional = 'opcional';
  static const addFoodItem = 'Adicionar gênero';
  static const menuChange = 'Alteração do cardápio';

  /// O "−" de quem está em 1 tira o gênero da lista, e o leitor de tela
  /// precisa dizer isso antes do toque: quantidade zero não existe (RN#1 da
  /// US003), e um botão que às vezes diminui e às vezes apaga não pode ter um
  /// nome só.
  static String foodItemLess(String name, {required bool last}) =>
      last ? 'Tirar $name da lista' : 'Um a menos de $name';
  static String foodItemMore(String name) => 'Um a mais de $name';
  static String foodItemQuantity(String name, String? unit) =>
      unit == null || unit.isEmpty
      ? 'Quantidade de $name'
      : 'Quantidade de $name, em $unit';

  /// A decisão 3 da E3 em uma linha: não há botão de salvar, e isso se diz.
  static const autosave = 'Salva sozinho, sem botão de salvar.';
  static const progress = 'Partes preenchidas do dia';
}

/// "Almoço · Terça, 9 de setembro" — o subtítulo das telas 3a e 3b.
String mealSubtitle(String type, String mapDate) =>
    '${mealTitles[type]} · ${dayTitle(mapDate)}';

/// A alteração do cardápio — tela 3a (US002).
///
/// O aviso do alto é a decisão 8 da E3 dita para quem está preenchendo: a
/// refeição não muda, aqui vai só o que entrou no lugar. Sem ele a tela
/// convidaria a reescrever o cardápio, que é justamente o que tiraria o
/// sentido da justificativa.
class MenuChangeMessages {
  const MenuChangeMessages._();

  static const title = 'Alteração do cardápio';
  static const close = 'Fechar a alteração do cardápio';
  static String notice(String type) =>
      'O ${mealLabels[type]} continua registrado como o cardápio previsto. '
      'Aqui vão só os gêneros que você usou no lugar.';
  static const itemsLabel = 'Gêneros utilizados na troca';
  static const reasonLabel = 'Motivo';
  static const reasonPlaceholder = 'Toque para escrever o motivo da troca';

  /// Texto livre com sugestões de motivos frequentes (RNF#1 da US002).
  static const reasonSuggestions = [
    'Falta de entrega do fornecedor',
    'Item impróprio',
    'Quantidade insuficiente',
  ];
  static const document =
      'Os gêneros e o motivo saem no documento oficial, na coluna reservada '
      'às alterações.';

  /// As duas linhas do meio do caminho, no mesmo tom da observação do dia
  /// não letivo: dizem o que falta para o dia subir, sem chamar de erro o que
  /// é apenas o preenchimento em andamento.
  static const itemsMissing =
      'Escolha o gênero que entrou para esta alteração valer.';
  static const reasonMissing =
      'Escreva o motivo para esta alteração entrar no mapa.';
  static const remove = 'Remover a alteração';

  /// No dia bloqueado não há o que cancelar nem confirmar: só fechar.
  static const done = 'Fechar';
  static const cancel = 'Cancelar';
  static const confirm = 'Confirmar alteração';
}

/// Escolher gênero — folha 3b, que sobe sobre o registro (decisão 7 da E3).
class FoodItemSheetMessages {
  const FoodItemSheetMessages._();

  static const title = 'Escolher gênero';
  static const close = 'Fechar a escolha de gênero';
  static const search = 'Buscar gênero';

  /// O catálogo vem do aparelho, e só fica vazio antes da primeira vez que
  /// houve rede. Mesmo assim ela não fica parada: o cadastro embaixo continua
  /// de pé, e o gênero nasce junto com o dia quando ele subir.
  static const empty =
      'O catálogo ainda não foi baixado neste aparelho. Você pode cadastrar o '
      'gênero aqui mesmo.';
  static const noResults = 'Nenhum gênero com esse nome. Cadastre abaixo.';
  static const alreadyChosen = 'já está aqui';
  static const newTitle = 'Não está na lista?';
  static const newHint = 'Cadastre aqui e o item já entra na refeição.';
  static const newNameLabel = 'Nome do gênero';
  static const newNamePlaceholder = 'Ex.: feijão preto';
  static const newUnitLabel = 'Unidade padrão';
  static const add = 'Adicionar à refeição';
}
