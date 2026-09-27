/// O que a leitura do mês precisa do Supabase, isolado atrás de uma
/// interface — o mesmo raciocínio do [CatalogGateway] e do `AuthGateway`
/// (decisão 4 da E6).
abstract class MonthGateway {
  /// [firstDay] e [lastDay] são inclusivos. Mesma consulta que a visão do
  /// mês já faz na web: por `map_date`, trazendo o mapa e as suas refeições
  /// — sem gêneros usados nem alteração do cardápio, que ficam para a #105.
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
  });

  factory RemoteMeal.fromRow(Map<String, dynamic> row) => RemoteMeal(
    id: row['id'] as String,
    type: row['type'] as String,
    description: row['description'] as String?,
    acceptance: row['acceptance'] as String?,
  );

  final String id;
  final String type;
  final String? description;
  final String? acceptance;
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
