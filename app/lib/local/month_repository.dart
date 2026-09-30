import 'package:drift/drift.dart';

import 'app_database.dart';
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
        await _db
            .into(_db.mealMaps)
            .insertOnConflictUpdate(
              MealMapsCompanion.insert(
                id: map.id,
                mapDate: map.mapDate,
                nonSchoolDay: map.nonSchoolDay,
                note: Value(map.note),
                mealsServed: Value(map.mealsServed),
                locked: map.locked,
                updatedAt: map.updatedAt,
              ),
            );

        // O dia inteiro substitui o que havia — o mesmo raciocínio de
        // `save_meal_map`: o que não vier deixa de existir.
        await _deleteMealsOf(map.id);

        await _db.batch((batch) {
          for (final meal in map.meals) {
            batch.insert(
              _db.meals,
              MealsCompanion.insert(
                id: meal.id,
                mealMapId: map.id,
                type: meal.type,
                description: Value(meal.description),
                acceptance: Value(meal.acceptance),
              ),
            );

            for (final (position, item) in meal.foodItems.indexed) {
              batch.insert(
                _db.mealFoodItems,
                MealFoodItemsCompanion.insert(
                  mealId: meal.id,
                  position: position,
                  foodItemId: item.foodItemId!,
                  name: item.name,
                  unit: Value(item.unit),
                  quantity: item.quantity,
                ),
              );
            }

            final change = meal.menuChange;
            if (change == null) continue;

            batch.insert(
              _db.menuChanges,
              MenuChangesCompanion.insert(
                id: change.id,
                mealId: meal.id,
                reason: change.reason,
              ),
            );

            for (final (position, item) in change.foodItems.indexed) {
              batch.insert(
                _db.menuChangeFoodItems,
                MenuChangeFoodItemsCompanion.insert(
                  menuChangeId: change.id,
                  position: position,
                  foodItemId: item.foodItemId!,
                  name: item.name,
                  unit: Value(item.unit),
                  quantity: item.quantity,
                ),
              );
            }
          }
        });
      }
    });
  }

  /// Apaga as refeições de um dia com tudo que pende delas. À mão, e não pelo
  /// `onDelete: cascade` do esquema: o SQLite só respeita chave estrangeira
  /// com `PRAGMA foreign_keys` ligado, e este banco nunca o ligou.
  Future<void> _deleteMealsOf(String mealMapId) async {
    final mealIds = _db.selectOnly(_db.meals)
      ..addColumns([_db.meals.id])
      ..where(_db.meals.mealMapId.equals(mealMapId));
    final changeIds = _db.selectOnly(_db.menuChanges)
      ..addColumns([_db.menuChanges.id])
      ..where(_db.menuChanges.mealId.isInQuery(mealIds));

    await (_db.delete(
      _db.menuChangeFoodItems,
    )..where((t) => t.menuChangeId.isInQuery(changeIds))).go();
    await (_db.delete(
      _db.menuChanges,
    )..where((t) => t.mealId.isInQuery(mealIds))).go();
    await (_db.delete(
      _db.mealFoodItems,
    )..where((t) => t.mealId.isInQuery(mealIds))).go();
    await (_db.delete(
      _db.meals,
    )..where((t) => t.mealMapId.equals(mealMapId))).go();
  }
}
