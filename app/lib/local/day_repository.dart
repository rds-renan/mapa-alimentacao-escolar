import 'app_database.dart';
import 'day.dart';

/// O dia como o banco local o tem — a cópia já convergida pelo servidor via
/// [MonthRepository.refreshMonth] — mais o único fato que só ele conhece:
/// se o mapa está bloqueado.
///
/// Os gêneros utilizados e a alteração do cardápio não entram aqui: o banco
/// local ainda não os guarda (ficam para a #106 estender o esquema, mesmo
/// raciocínio que adiou as tabelas na #102), e por isso [day] sempre traz
/// essas duas listas vazias. É por isso que a tela do registro (#105) só lê e
/// grava a descrição, a aceitação, o número de refeições e o dia não letivo.
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
                foodItems: const [],
                menuChange: null,
              ),
          ],
        ),
      );
    });
  }
}
