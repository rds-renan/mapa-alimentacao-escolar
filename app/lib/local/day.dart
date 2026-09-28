/// O dia como ele sobe.
///
/// Esta forma não é uma invenção do cliente: é, campo por campo, o payload de
/// `save_meal_map` descrito em `docs/05-web/gravacao-do-dia.md` — a mesma
/// forma que `web/src/local/day.ts` já usa. O rascunho local guarda
/// exatamente isto, e é essa igualdade que torna a fila simples — enviar é
/// pegar o rascunho e mandar, sem tradução no meio que possa divergir do
/// contrato do servidor.
///
/// Os campos Dart são camelCase, mas [toJson]/[fromJson] usam os nomes do
/// banco, em snake_case — quem manda na forma do fio é a função do servidor,
/// não o Dart.
library;

import 'package:uuid/uuid.dart';

const _uuid = Uuid();

String newId() => _uuid.v4();

class FoodItemPayload {
  const FoodItemPayload({
    required this.foodItemId,
    required this.name,
    required this.unit,
    required this.quantity,
  });

  factory FoodItemPayload.fromJson(Map<String, dynamic> json) =>
      FoodItemPayload(
        foodItemId: json['food_item_id'] as String?,
        name: json['name'] as String,
        unit: json['unit'] as String?,
        quantity: json['quantity'] as int,
      );

  /// O gênero do catálogo, quando ele já existe. Nulo é gênero a nascer.
  final String? foodItemId;
  final String name;

  /// Só é exigido pelo servidor quando o gênero vai nascer.
  final String? unit;
  final int quantity;

  Map<String, dynamic> toJson() => {
    'food_item_id': foodItemId,
    'name': name,
    'unit': unit,
    'quantity': quantity,
  };

  FoodItemPayload withFoodItemId(String id) => FoodItemPayload(
    foodItemId: id,
    name: name,
    unit: unit,
    quantity: quantity,
  );
}

class MenuChangePayload {
  const MenuChangePayload({
    required this.id,
    required this.reason,
    required this.foodItems,
  });

  factory MenuChangePayload.fromJson(Map<String, dynamic> json) =>
      MenuChangePayload(
        id: json['id'] as String,
        reason: json['reason'] as String,
        foodItems: (json['food_items'] as List<dynamic>)
            .map(
              (item) => FoodItemPayload.fromJson(item as Map<String, dynamic>),
            )
            .toList(),
      );

  final String id;
  final String reason;
  final List<FoodItemPayload> foodItems;

  Map<String, dynamic> toJson() => {
    'id': id,
    'reason': reason,
    'food_items': foodItems.map((item) => item.toJson()).toList(),
  };
}

class MealPayload {
  const MealPayload({
    required this.id,
    required this.type,
    required this.description,
    required this.acceptance,
    required this.foodItems,
    required this.menuChange,
  });

  factory MealPayload.fromJson(Map<String, dynamic> json) => MealPayload(
    id: json['id'] as String,
    type: json['type'] as String,
    description: json['description'] as String?,
    acceptance: json['acceptance'] as String?,
    foodItems: (json['food_items'] as List<dynamic>)
        .map((item) => FoodItemPayload.fromJson(item as Map<String, dynamic>))
        .toList(),
    menuChange: json['menu_change'] == null
        ? null
        : MenuChangePayload.fromJson(
            json['menu_change'] as Map<String, dynamic>,
          ),
  );

  final String id;
  final String type;

  /// O cardápio previsto — continua sendo ele mesmo quando houve troca.
  final String? description;
  final String? acceptance;
  final List<FoodItemPayload> foodItems;
  final MenuChangePayload? menuChange;

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'description': description,
    'acceptance': acceptance,
    'food_items': foodItems.map((item) => item.toJson()).toList(),
    'menu_change': menuChange?.toJson(),
  };
}

class DayPayload {
  const DayPayload({
    required this.id,
    required this.mapDate,
    required this.updatedAt,
    required this.nonSchoolDay,
    required this.note,
    required this.mealsServed,
    required this.meals,
  });

  factory DayPayload.fromJson(Map<String, dynamic> json) => DayPayload(
    id: json['id'] as String,
    mapDate: json['map_date'] as String,
    updatedAt: json['updated_at'] as String,
    nonSchoolDay: json['non_school_day'] as bool,
    note: json['note'] as String?,
    mealsServed: json['meals_served'] as int?,
    meals: (json['meals'] as List<dynamic>)
        .map((meal) => MealPayload.fromJson(meal as Map<String, dynamic>))
        .toList(),
  );

  /// UUID gerado no aparelho. O servidor pode devolver outro, e vale o dele.
  final String id;

  /// A data do dia, em AAAA-MM-DD. É ela que identifica o dia.
  final String mapDate;

  /// Quando a merendeira mexeu, no relógio do aparelho — não quando chegou.
  final String updatedAt;
  final bool nonSchoolDay;
  final String? note;
  final int? mealsServed;
  final List<MealPayload> meals;

  Map<String, dynamic> toJson() => {
    'id': id,
    'map_date': mapDate,
    'updated_at': updatedAt,
    'non_school_day': nonSchoolDay,
    'note': note,
    'meals_served': mealsServed,
    'meals': meals.map((meal) => meal.toJson()).toList(),
  };
}

/// Um dia em branco, pronto para a primeira tecla — a versão em Dart de
/// `emptyDay` (`web/src/local/day.ts`).
DayPayload emptyDay(String mapDate) => DayPayload(
  id: newId(),
  mapDate: mapDate,
  updatedAt: DateTime.now().toIso8601String(),
  nonSchoolDay: false,
  note: null,
  mealsServed: null,
  meals: const [],
);

class SaveResponseFoodItem {
  const SaveResponseFoodItem({
    required this.sentId,
    required this.id,
    required this.name,
    required this.unit,
    required this.created,
  });

  factory SaveResponseFoodItem.fromJson(Map<String, dynamic> json) =>
      SaveResponseFoodItem(
        sentId: json['sent_id'] as String?,
        id: json['id'] as String,
        name: json['name'] as String,
        unit: json['unit'] as String,
        created: json['created'] as bool,
      );

  final String? sentId;
  final String id;
  final String name;
  final String unit;
  final bool created;
}

/// O que `save_meal_map` devolve. O contrato inteiro está na doc da gravação
/// (`docs/05-web/gravacao-do-dia.md`).
class SaveResponse {
  const SaveResponse({
    required this.status,
    required this.mealMapId,
    required this.sentMealMapId,
    required this.mapDate,
    required this.locked,
    required this.updatedAt,
    required this.updatedBy,
    required this.foodItems,
  });

  factory SaveResponse.fromJson(Map<String, dynamic> json) => SaveResponse(
    status: json['status'] as String,
    mealMapId: json['meal_map_id'] as String,
    sentMealMapId: json['sent_meal_map_id'] as String?,
    mapDate: json['map_date'] as String,
    locked: json['locked'] as bool,
    updatedAt: json['updated_at'] as String,
    updatedBy: json['updated_by'] as String?,
    foodItems: (json['food_items'] as List<dynamic>)
        .map(
          (item) => SaveResponseFoodItem.fromJson(item as Map<String, dynamic>),
        )
        .toList(),
  );

  /// `'saved'` ou `'superseded'`.
  final String status;
  final String mealMapId;
  final String? sentMealMapId;
  final String mapDate;
  final bool locked;
  final String updatedAt;
  final String? updatedBy;
  final List<SaveResponseFoodItem> foodItems;

  bool get isSuperseded => status == 'superseded';
}

/// O dia está em condição de subir?
///
/// Não é validação de formulário — é a pergunta de se o servidor aceitaria
/// este payload. A tela grava cada tecla no aparelho (CA#2 da US010), e a
/// fila leva só o que não vai voltar recusado: entre marcar "dia não letivo"
/// e escrever o motivo passam alguns segundos, e nesse intervalo o dia está
/// guardado, não debaixo de uma faixa dizendo que não deu para enviar.
bool canBeSent(DayPayload day) {
  if (day.nonSchoolDay) {
    return _notBlank(day.note) && day.meals.isEmpty;
  }

  return day.meals.every(_mealCanBeSent);
}

bool _notBlank(String? text) => text != null && text.trim().isNotEmpty;

/// A refeição em si nunca impede o envio — descrição e aceitação nulas são o
/// registro parcial, de propósito (CA#3 da US001). O que impede é o que o
/// servidor recusa: alteração sem motivo ou sem gênero, e gênero a nascer
/// sem unidade.
bool _mealCanBeSent(MealPayload meal) {
  if (!meal.foodItems.every(_itemCanBeSent)) return false;

  final change = meal.menuChange;
  if (change == null) return true;

  return _notBlank(change.reason) &&
      change.foodItems.isNotEmpty &&
      change.foodItems.every(_itemCanBeSent);
}

/// A quantidade já chega inteira e o tipo garante isso (RN#1 da US003); só
/// falta ser maior que zero. O gênero que ainda não está no catálogo precisa
/// da unidade com que vai nascer — o catálogo manda na unidade de quem já
/// existe, e não aceita item sem ela.
bool _itemCanBeSent(FoodItemPayload item) {
  if (item.quantity <= 0) return false;

  return item.foodItemId != null || _notBlank(item.unit);
}

/// A mesma normalização que o servidor usa para decidir se dois nomes são o
/// mesmo gênero. Serve para adotar o identificador que voltou.
String normalizedName(String name) =>
    name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

/// Adota o que o servidor devolveu.
///
/// O contrato é explícito: o cliente precisa assumir o `meal_map_id` e os
/// identificadores de gênero que voltaram, porque são eles que fazem o
/// próximo envio encontrar o registro em vez de tentar criá-lo de novo. Dois
/// aparelhos podem ter criado o mesmo dia offline, cada um com o seu UUID —
/// quem vale é o que já estava no servidor.
DayPayload adoptServerIds(DayPayload day, SaveResponse response) {
  final bySentId = <String, String>{};
  final byName = <String, String>{};

  for (final item in response.foodItems) {
    if (item.sentId != null) bySentId[item.sentId!] = item.id;
    // O gênero que nasceu agora não tem `sentId`: o nome é o que o liga à
    // linha que o aparelho mandou.
    byName[normalizedName(item.name)] = item.id;
  }

  FoodItemPayload adoptItem(FoodItemPayload item) {
    final resolved =
        (item.foodItemId != null ? bySentId[item.foodItemId] : null) ??
        byName[normalizedName(item.name)];

    return resolved == null ? item : item.withFoodItemId(resolved);
  }

  return DayPayload(
    id: response.mealMapId,
    mapDate: day.mapDate,
    updatedAt: day.updatedAt,
    nonSchoolDay: day.nonSchoolDay,
    note: day.note,
    mealsServed: day.mealsServed,
    meals: day.meals
        .map(
          (meal) => MealPayload(
            id: meal.id,
            type: meal.type,
            description: meal.description,
            acceptance: meal.acceptance,
            foodItems: meal.foodItems.map(adoptItem).toList(),
            menuChange: meal.menuChange == null
                ? null
                : MenuChangePayload(
                    id: meal.menuChange!.id,
                    reason: meal.menuChange!.reason,
                    foodItems: meal.menuChange!.foodItems
                        .map(adoptItem)
                        .toList(),
                  ),
          ),
        )
        .toList(),
  );
}
