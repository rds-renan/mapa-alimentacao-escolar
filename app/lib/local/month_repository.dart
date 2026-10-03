import 'package:drift/drift.dart';

import 'app_database.dart';
import 'confirmed_copy.dart';
import 'day.dart';
import 'month_gateway.dart';

/// Um dia do mês com as suas refeições, o par que a visão do mês (US008)
/// consulta para calcular os cinco estados.
class MealMapWithMeals {
  const MealMapWithMeals({required this.mealMap, required this.meals});

  final MealMap mealMap;
  final List<Meal> meals;
}

/// A cópia local do mês (CA#1 da issue #102), no mesmo espírito do
/// [CatalogRepository]: [watchMonth] sempre lê do aparelho, e [refreshMonth]
/// escreve por baixo sem bloquear quem está lendo.
class MonthRepository {
  MonthRepository(this._db, this._gateway);

  final AppDatabase _db;
  final MonthGateway _gateway;

  Stream<List<MealMapWithMeals>> watchMonth(DateTime month) {
    final first = DateTime(month.year, month.month);
    final last = DateTime(month.year, month.month + 1, 0);

    final query = _db.select(_db.mealMaps)
      ..where((t) => t.mapDate.isBetweenValues(first, last))
      ..orderBy([(t) => OrderingTerm(expression: t.mapDate)]);

    return query.watch().asyncMap((maps) async {
      if (maps.isEmpty) return const <MealMapWithMeals>[];

      final ids = maps.map((map) => map.id).toList();
      final meals = await (_db.select(
        _db.meals,
      )..where((t) => t.mealMapId.isIn(ids))).get();

      return [
        for (final map in maps)
          MealMapWithMeals(
            mealMap: map,
            meals: meals.where((meal) => meal.mealMapId == map.id).toList(),
          ),
      ];
    });
  }

  /// Busca o mês no servidor e substitui a cópia local, dia por dia. Lança
  /// se a rede não responder; a cópia local não é tocada nesse caso.
  Future<void> refreshMonth(DateTime month) async {
    final first = DateTime(month.year, month.month);
    final last = DateTime(month.year, month.month + 1, 0);

    final remoteMaps = await _gateway.fetchMonth(
      firstDay: first,
      lastDay: last,
    );

    await _db.transaction(() async {
      for (final map in remoteMaps) {
        await writeConfirmedDay(
          _db,
          ConfirmedDay(
            locked: map.locked,
            day: DayPayload(
              id: map.id,
              mapDate: map.mapDate.toIso8601String().substring(0, 10),
              updatedAt: stampOf(map.updatedAt),
              nonSchoolDay: map.nonSchoolDay,
              note: map.note,
              mealsServed: map.mealsServed,
              meals: [
                for (final meal in map.meals)
                  MealPayload(
                    id: meal.id,
                    type: meal.type,
                    description: meal.description,
                    acceptance: meal.acceptance,
                    foodItems: meal.foodItems,
                    menuChange: meal.menuChange,
                  ),
              ],
            ),
          ),
        );
      }
    });
  }
}
