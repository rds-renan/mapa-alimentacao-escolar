/// Os textos do registro do dia (issue #105) — porto do que
/// `web/src/day/messages.ts` tem para os campos que esta tela já cobre:
/// cardápio previsto, aceitação, número de refeições e dia não letivo. Os
/// gêneros utilizados e a alteração do cardápio ficam para a #106.
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

  /// A decisão 3 da E3 em uma linha: não há botão de salvar, e isso se diz.
  static const autosave = 'Salva sozinho, sem botão de salvar.';
  static const progress = 'Partes preenchidas do dia';
}
