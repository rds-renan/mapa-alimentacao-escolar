import 'package:drift/drift.dart';

import 'app_database.dart';
import 'confirmed_copy.dart';
import 'day.dart';
import 'month_gateway.dart';

/// Um dia do mês com as suas refeições, o par que a visão do mês (US008)
/// consulta para calcular os cinco estados — mais se o dia tem gênero
/// lançado, que desde a decisão 14 da E4 conta para ele estar preenchido.
class MealMapWithMeals {
  const MealMapWithMeals({
    required this.mealMap,
    required this.meals,
    this.hasFoodItems = false,
  });

  final MealMap mealMap;
  final List<Meal> meals;
  final bool hasFoodItems;
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

      final withItems = {
        ...(await (_db.selectOnly(_db.mealMapFoodItems, distinct: true)
              ..addColumns([_db.mealMapFoodItems.mealMapId])
              ..where(_db.mealMapFoodItems.mealMapId.isIn(ids)))
            .map((row) => row.read(_db.mealMapFoodItems.mealMapId)!)
            .get()),
        ...(await (_db.selectOnly(_db.menuChanges)
              ..addColumns([_db.menuChanges.mealMapId])
              ..join([
                innerJoin(
                  _db.menuChangeFoodItems,
                  _db.menuChangeFoodItems.menuChangeId.equalsExp(
                    _db.menuChanges.id,
                  ),
                ),
              ])
              ..where(_db.menuChanges.mealMapId.isIn(ids)))
            .map((row) => row.read(_db.menuChanges.mealMapId)!)
            .get()),
      };

      return [
        for (final map in maps)
          MealMapWithMeals(
            mealMap: map,
            meals: meals.where((meal) => meal.mealMapId == map.id).toList(),
            hasFoodItems: withItems.contains(map.id),
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
            reopened: map.reopened,
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
                  ),
              ],
              foodItems: map.foodItems,
              menuChange: map.menuChange,
            ),
          ),
        );
      }
    });
  }
}
