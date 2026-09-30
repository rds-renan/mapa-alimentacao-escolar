import 'day.dart';

/// O que a leitura do mês precisa do Supabase, isolado atrás de uma
/// interface — o mesmo raciocínio do [CatalogGateway] e do `AuthGateway`
/// (decisão 4 da E6).
abstract class MonthGateway {
  /// [firstDay] e [lastDay] são inclusivos. Mesma consulta que a visão do
  /// mês já faz na web: por `map_date`, trazendo o mapa e as suas refeições,
  /// com os gêneros utilizados e a alteração do cardápio de cada uma (issue
  /// #106) — a tela do dia precisa deles para reenviar o dia inteiro.
  Future<List<RemoteMealMap>> fetchMonth({
    required DateTime firstDay,
    required DateTime lastDay,
  });
}

class RemoteMeal {
  const RemoteMeal({
    required this.id,
    required this.type,
    this.description,
    this.acceptance,
    this.foodItems = const [],
    this.menuChange,
  });

  factory RemoteMeal.fromRow(Map<String, dynamic> row) {
    final change = row['menu_change'] as Map<String, dynamic>?;

    return RemoteMeal(
      id: row['id'] as String,
      type: row['type'] as String,
      description: row['description'] as String?,
      acceptance: row['acceptance'] as String?,
      foodItems: _foodItemsFromRows(row['meal_food_item']),
      menuChange: change == null
          ? null
          : MenuChangePayload(
              id: change['id'] as String,
              reason: change['reason'] as String,
              foodItems: _foodItemsFromRows(change['menu_change_food_item']),
            ),
    );
  }

  final String id;
  final String type;
  final String? description;
  final String? acceptance;

  /// Os gêneros já na forma em que sobem — o nome e a unidade vêm do
  /// catálogo, pela junção, como na web (`web/src/day/queries.ts`).
  final List<FoodItemPayload> foodItems;
  final MenuChangePayload? menuChange;
}

List<FoodItemPayload> _foodItemsFromRows(Object? rows) {
  return [
    for (final row in (rows as List<dynamic>? ?? const []))
      _foodItemFromRow(row as Map<String, dynamic>),
  ];
}

FoodItemPayload _foodItemFromRow(Map<String, dynamic> row) {
  final item = row['food_item'] as Map<String, dynamic>?;

  return FoodItemPayload(
    foodItemId: row['food_item_id'] as String,
    name: item?['name'] as String? ?? '',
    unit: item?['default_unit'] as String?,
    quantity: row['quantity'] as int,
  );
}

class RemoteMealMap {
  const RemoteMealMap({
    required this.id,
    required this.mapDate,
    required this.nonSchoolDay,
    required this.note,
    required this.mealsServed,
    required this.locked,
    required this.updatedAt,
    required this.meals,
  });

  factory RemoteMealMap.fromRow(Map<String, dynamic> row) => RemoteMealMap(
    id: row['id'] as String,
    mapDate: DateTime.parse(row['map_date'] as String),
    nonSchoolDay: row['non_school_day'] as bool,
    note: row['note'] as String?,
    mealsServed: row['meals_served'] as int?,
    locked: row['locked'] as bool,
    updatedAt: DateTime.parse(row['updated_at'] as String),
    meals: (row['meal'] as List<dynamic>)
        .map((meal) => RemoteMeal.fromRow(meal as Map<String, dynamic>))
        .toList(),
  );

  final String id;
  final DateTime mapDate;
  final bool nonSchoolDay;
  final String? note;
  final int? mealsServed;
  final bool locked;
  final DateTime updatedAt;
  final List<RemoteMeal> meals;
}
