/// As regras do formulário da manutenção do catálogo — porto de
/// `web/src/food-items/form.ts` (issue #107).
library;

import '../local/app_database.dart';
import '../local/day.dart' show normalizedName;
import 'catalog.dart' show matchesSearch;

/// O que está no cartão. [id] nulo é gênero novo; preenchido é o gênero da
/// lista que está sendo editado.
class FoodItemDraft {
  const FoodItemDraft({this.id, this.name = '', this.unit = ''});

  factory FoodItemDraft.of(FoodItem item) =>
      FoodItemDraft(id: item.id, name: item.name, unit: item.unit);

  final String? id;
  final String name;
  final String unit;
}

/// Nome e unidade são obrigatórios (CA#1 da US009) — e é só isso que o botão
/// espera. Nada aqui culpa quem está digitando: o botão fica apagado até
/// haver o que salvar (regra 1 da linguagem da E3).
bool canSave(FoodItemDraft draft) =>
    draft.name.trim().isNotEmpty && draft.unit.trim().isNotEmpty;

/// O gênero de mesmo nome que já está no catálogo, se houver.
///
/// O banco tem o índice único por escola e nome normalizado (decisão 8 da
/// E4), então a gravação seria recusada de qualquer jeito. Achar aqui serve
/// para dizer o que aconteceu antes de tentar — e, quando o homônimo está
/// desativado, para dizer onde ele está.
FoodItem? duplicateOf(FoodItemDraft draft, List<FoodItem> items) {
  final name = normalizedName(draft.name);

  for (final item in items) {
    if (item.id != draft.id && normalizedName(item.name) == name) return item;
  }
  return null;
}

/// A unidade de um gênero que já existe está sendo trocada.
///
/// Vale um aviso porque a troca alcança o passado: `meal_food_item` guarda a
/// quantidade e o gênero, e a unidade é lida do catálogo — trocar "pote" por
/// "quilo" faz um dia já registrado passar a dizer "3 quilos de manteiga".
bool unitChanged(FoodItemDraft draft, List<FoodItem> items) {
  if (draft.id == null) return false;

  for (final item in items) {
    if (item.id == draft.id) return item.unit != draft.unit.trim();
  }
  return false;
}

/// A lista da tela: ativos em cima, desativados na seção recolhida do pé. A
/// busca corta as duas — procurar um gênero desativado é como se descobre
/// que ele foi desativado.
({List<FoodItem> active, List<FoodItem> inactive}) sections(
  List<FoodItem> items,
  String search,
) {
  final found = items.where((item) => matchesSearch(item.name, search));

  return (
    active: found.where((item) => item.active).toList(),
    inactive: found.where((item) => !item.active).toList(),
  );
}
