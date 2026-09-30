import 'package:drift/drift.dart';

import 'app_database.dart';
import 'day.dart';

/// O dia como o banco local o tem — a cópia já convergida pelo servidor via
/// [MonthRepository.refreshMonth] — mais o único fato que só ele conhece:
/// se o mapa está bloqueado.
///
/// O dia vem inteiro, com os gêneros utilizados e a alteração do cardápio de
/// cada refeição (issue #106): é isto que a tela reenvia a cada tecla, e o
/// contrato de `save_meal_map` substitui a lista inteira — ler o dia sem os
/// gêneros e reenviá-lo os apagaria do servidor.
class ConfirmedDay {
  const ConfirmedDay({required this.day, required this.locked});

  final DayPayload day;
  final bool locked;
}

/// A leitura de um dia só, para a tela do registro — ao lado de
/// [MonthRepository], que lê o mês inteiro para a visão dele (US008).
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
      final mealIds = meals.map((meal) => meal.id).toList();

      final mealItems =
          await (_db.select(_db.mealFoodItems)
                ..where((t) => t.mealId.isIn(mealIds))
                ..orderBy([(t) => OrderingTerm(expression: t.position)]))
              .get();
      final changes = await (_db.select(
        _db.menuChanges,
      )..where((t) => t.mealId.isIn(mealIds))).get();
      final changeItems =
          await (_db.select(_db.menuChangeFoodItems)
                ..where(
                  (t) => t.menuChangeId.isIn(changes.map((one) => one.id)),
                )
                ..orderBy([(t) => OrderingTerm(expression: t.position)]))
              .get();

      MenuChangePayload? changeOf(String mealId) {
        for (final change in changes) {
          if (change.mealId != mealId) continue;
          return MenuChangePayload(
            id: change.id,
            reason: change.reason,
            foodItems: [
              for (final item in changeItems)
                if (item.menuChangeId == change.id)
                  FoodItemPayload(
                    foodItemId: item.foodItemId,
                    name: item.name,
                    unit: item.unit,
                    quantity: item.quantity,
                  ),
            ],
          );
        }
        return null;
      }

      return ConfirmedDay(
        locked: map.locked,
        day: DayPayload(
          id: map.id,
          mapDate: mapDate,
          updatedAt: map.updatedAt.toIso8601String(),
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
                foodItems: [
                  for (final item in mealItems)
                    if (item.mealId == meal.id)
                      FoodItemPayload(
                        foodItemId: item.foodItemId,
                        name: item.name,
                        unit: item.unit,
                        quantity: item.quantity,
                      ),
                ],
                menuChange: changeOf(meal.id),
              ),
          ],
        ),
      );
    });
  }
}
