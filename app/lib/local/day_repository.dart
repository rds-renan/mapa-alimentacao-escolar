import 'package:drift/drift.dart';

import 'app_database.dart';
import 'confirmed_copy.dart';
import 'day.dart';

export 'confirmed_copy.dart' show ConfirmedDay;

/// A leitura de um dia só, para a tela do registro — ao lado de
/// [MonthRepository], que lê o mês inteiro para a visão dele (US008). O que
/// sai daqui é a cópia confirmada: a que [MonthRepository.refreshMonth] baixa
/// e a que a fila grava ao sair o dia dela ([SyncQueueStore.settle]).
class DayRepository {
  DayRepository(this._db);

  final AppDatabase _db;

  Stream<ConfirmedDay?> watchDay(String mapDate) {
    final date = DateTime.parse(mapDate);
    final query = _db.select(_db.mealMaps)
      ..where((t) => t.mapDate.equals(date));

    return query.watchSingleOrNull().asyncMap((map) async {
      if (map == null) return null;

      final meals = await (_db.select(
        _db.meals,
      )..where((t) => t.mealMapId.equals(map.id))).get();
      final items =
          await (_db.select(_db.mealMapFoodItems)
                ..where((t) => t.mealMapId.equals(map.id))
                ..orderBy([(t) => OrderingTerm(expression: t.position)]))
              .get();
      final change = await (_db.select(
        _db.menuChanges,
      )..where((t) => t.mealMapId.equals(map.id))).getSingleOrNull();
      final changeItems = change == null
          ? const <MenuChangeFoodItem>[]
          : await (_db.select(_db.menuChangeFoodItems)
                  ..where((t) => t.menuChangeId.equals(change.id))
                  ..orderBy([(t) => OrderingTerm(expression: t.position)]))
                .get();

      return ConfirmedDay(
        locked: map.locked,
        reopened: map.reopened,
        day: DayPayload(
          id: map.id,
          mapDate: mapDate,
          updatedAt: stampOf(map.updatedAt),
          nonSchoolDay: map.nonSchoolDay,
          note: map.note,
          mealsServed: map.mealsServed,
          meals: [
            for (final meal in meals)
              MealPayload(
                id: meal.id,
                type: meal.type,
                description: meal.description,
                acceptance: meal.acceptance,
              ),
          ],
          foodItems: [
            for (final item in items)
              FoodItemPayload(
                foodItemId: item.foodItemId,
                name: item.name,
                unit: item.unit,
                quantity: item.quantity,
              ),
          ],
          menuChange: change == null
              ? null
              : MenuChangePayload(
                  id: change.id,
                  reason: change.reason,
                  foodItems: [
                    for (final item in changeItems)
                      FoodItemPayload(
                        foodItemId: item.foodItemId,
                        name: item.name,
                        unit: item.unit,
                        quantity: item.quantity,
                      ),
                  ],
                ),
        ),
      );
    });
  }
}
