import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mae/local/app_database.dart';
import 'package:mae/local/confirmed_copy.dart';
import 'package:mae/local/day.dart';
import 'package:mae/local/day_repository.dart';

DayPayload _day({
  String id = 'map-1',
  String updatedAt = '2026-09-10T21:30:00Z',
  List<FoodItemPayload> foodItems = const [],
}) => DayPayload(
  id: id,
  mapDate: '2026-09-10',
  updatedAt: updatedAt,
  nonSchoolDay: false,
  note: null,
  mealsServed: 312,
  meals: [
    MealPayload(
      id: 'meal-$id',
      type: 'lunch',
      description: 'Arroz e feijão',
      acceptance: 'great',
      foodItems: foodItems,
      menuChange: null,
    ),
  ],
);

SaveResponse _response({List<Map<String, dynamic>> foodItems = const []}) =>
    SaveResponse.fromJson({
      'status': 'saved',
      'meal_map_id': 'map-1',
      'sent_meal_map_id': 'map-1',
      'map_date': '2026-09-10',
      'locked': false,
      'updated_at': '2026-09-10T21:30:00+00:00',
      'updated_by': null,
      'food_items': foodItems,
    });

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test(
    'o mesmo gênero duas vezes vira uma linha só, com a última quantidade',
    () async {
      await writeConfirmedDay(
        db,
        ConfirmedDay(
          locked: false,
          day: _day(
            foodItems: const [
              FoodItemPayload(
                foodItemId: 'rice',
                name: 'Arroz',
                unit: 'quilo',
                quantity: 4,
              ),
              FoodItemPayload(
                foodItemId: 'rice',
                name: 'arroz',
                unit: 'quilo',
                quantity: 6,
              ),
            ],
          ),
        ),
      );

      final day = (await DayRepository(db).watchDay('2026-09-10').first)!.day;
      final item = day.meals.single.foodItems.single;
      expect(item.name, 'Arroz');
      expect(item.quantity, 6);
    },
  );

  test('o dia é a data: o mesmo dia com outro identificador sai junto, '
      'refeições inclusive', () async {
    await writeConfirmedDay(
      db,
      ConfirmedDay(
        locked: false,
        day: _day(id: 'mine', updatedAt: '2026-09-10T20:00:00Z'),
      ),
    );
    await writeConfirmedDay(
      db,
      ConfirmedDay(locked: false, day: _day(id: 'colleague')),
    );

    expect(await db.select(db.mealMaps).get(), hasLength(1));
    final meals = await db.select(db.meals).get();
    expect(meals.map((meal) => meal.id), ['meal-colleague']);
  });

  test('cópia mais velha não substitui a mais nova', () async {
    await writeConfirmedDay(db, ConfirmedDay(locked: false, day: _day()));

    final written = await writeConfirmedDay(
      db,
      ConfirmedDay(
        locked: false,
        day: _day(id: 'old', updatedAt: '2026-09-10T12:00:00Z'),
      ),
    );

    expect(written, isFalse);
    final maps = await db.select(db.mealMaps).get();
    expect(maps.single.id, 'map-1');
  });

  test('sem identificador para algum gênero, não há cópia a gravar', () {
    final sent = _day(
      foodItems: const [
        FoodItemPayload(
          foodItemId: null,
          name: 'Pão',
          unit: 'quilo',
          quantity: 4,
        ),
      ],
    );

    expect(savedDay(sent, _response()), isNull);
    expect(
      savedDay(
        sent,
        _response(
          foodItems: [
            {
              'sent_id': null,
              'id': 'bread',
              'name': 'Pão',
              'unit': 'quilo',
              'created': true,
            },
          ],
        ),
      )?.day.meals.single.foodItems.single.foodItemId,
      'bread',
    );
  });
}
