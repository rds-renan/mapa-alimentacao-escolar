import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mae/local/app_database.dart';
import 'package:mae/local/day.dart';
import 'package:mae/local/day_repository.dart';
import 'package:mae/local/month_gateway.dart';
import 'package:mae/local/month_repository.dart';

import 'fake_month_gateway.dart';

void main() {
  late AppDatabase db;
  late DayRepository repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = DayRepository(db);
  });

  tearDown(() => db.close());

  test('dia sem linha no banco local devolve nulo', () async {
    final confirmed = await repository.watchDay('2026-09-10').first;
    expect(confirmed, isNull);
  });

  test('lê o mapa e as refeições já convergidas pelo servidor', () async {
    await db
        .into(db.mealMaps)
        .insert(
          MealMapsCompanion.insert(
            id: 'map-1',
            mapDate: DateTime(2026, 9, 10),
            nonSchoolDay: false,
            note: const Value(null),
            mealsServed: const Value(312),
            locked: false,
            updatedAt: DateTime(2026, 9, 10, 18, 30),
          ),
        );
    await db
        .into(db.meals)
        .insert(
          MealsCompanion.insert(
            id: 'meal-1',
            mealMapId: 'map-1',
            type: 'lunch',
            description: const Value('Arroz e feijão'),
            acceptance: const Value('great'),
          ),
        );

    final confirmed = await repository.watchDay('2026-09-10').first;

    expect(confirmed, isNotNull);
    expect(confirmed!.locked, isFalse);
    expect(confirmed.day.id, 'map-1');
    expect(confirmed.day.mapDate, '2026-09-10');
    expect(confirmed.day.mealsServed, 312);
    expect(confirmed.day.meals, hasLength(1));
    expect(confirmed.day.meals.single.type, 'lunch');
    expect(confirmed.day.meals.single.description, 'Arroz e feijão');
    expect(confirmed.day.meals.single.acceptance, 'great');
    // Sem gênero nem alteração no banco, a leitura não inventa nenhum.
    expect(confirmed.day.meals.single.foodItems, isEmpty);
    expect(confirmed.day.meals.single.menuChange, isNull);
  });

  test('mapa bloqueado chega marcado', () async {
    await db
        .into(db.mealMaps)
        .insert(
          MealMapsCompanion.insert(
            id: 'map-1',
            mapDate: DateTime(2026, 9, 10),
            nonSchoolDay: false,
            locked: true,
            updatedAt: DateTime(2026, 9, 10, 18),
          ),
        );

    final confirmed = await repository.watchDay('2026-09-10').first;
    expect(confirmed!.locked, isTrue);
  });

  test('avisa quem está lendo assim que o banco muda por baixo', () async {
    final emissions = <bool>[];
    final subscription = repository
        .watchDay('2026-09-10')
        .listen((confirmed) => emissions.add(confirmed != null));
    addTearDown(subscription.cancel);
    await Future<void>.delayed(Duration.zero);

    expect(emissions, [false]);

    await db
        .into(db.mealMaps)
        .insert(
          MealMapsCompanion.insert(
            id: 'map-1',
            mapDate: DateTime(2026, 9, 10),
            nonSchoolDay: false,
            locked: false,
            updatedAt: DateTime(2026, 9, 10, 18),
          ),
        );
    await Future<void>.delayed(Duration.zero);

    expect(emissions, [false, true]);
  });

  test('o dia volta inteiro, com os gêneros e a alteração que o servidor '
      'mandou (issue #106)', () async {
    // O caminho de verdade: o mês baixado por `refreshMonth` e lido de volta
    // um dia só. Se a leitura perdesse os gêneros, o próximo envio da tela
    // os apagaria do servidor — a lista que sobe é o dia todo.
    final gateway = FakeMonthGateway()
      ..maps = [
        RemoteMealMap(
          id: 'map-1',
          mapDate: DateTime(2026, 9, 10),
          nonSchoolDay: false,
          note: null,
          mealsServed: 312,
          locked: false,
          updatedAt: DateTime(2026, 9, 10, 18),
          meals: const [
            RemoteMeal(
              id: 'meal-1',
              type: 'lunch',
              description: 'Arroz, feijão e frango',
              acceptance: 'good',
              foodItems: [
                FoodItemPayload(
                  foodItemId: 'rice',
                  name: 'Arroz',
                  unit: 'quilo',
                  quantity: 4,
                ),
                FoodItemPayload(
                  foodItemId: 'beans',
                  name: 'Feijão',
                  unit: 'quilo',
                  quantity: 2,
                ),
              ],
              menuChange: MenuChangePayload(
                id: 'change-1',
                reason: 'Falta de entrega do fornecedor',
                foodItems: [
                  FoodItemPayload(
                    foodItemId: 'egg',
                    name: 'Ovo',
                    unit: 'bandeja',
                    quantity: 3,
                  ),
                ],
              ),
            ),
            RemoteMeal(id: 'meal-2', type: 'morning_snack'),
          ],
        ),
      ];
    await MonthRepository(db, gateway).refreshMonth(DateTime(2026, 9));

    final day = (await repository.watchDay('2026-09-10').first)!.day;
    final lunch = day.meals.firstWhere((meal) => meal.type == 'lunch');
    final snack = day.meals.firstWhere((meal) => meal.type == 'morning_snack');

    expect(lunch.foodItems.map((item) => item.toJson()).toList(), [
      {'food_item_id': 'rice', 'name': 'Arroz', 'unit': 'quilo', 'quantity': 4},
      {
        'food_item_id': 'beans',
        'name': 'Feijão',
        'unit': 'quilo',
        'quantity': 2,
      },
    ]);
    expect(lunch.menuChange!.id, 'change-1');
    expect(lunch.menuChange!.reason, 'Falta de entrega do fornecedor');
    expect(lunch.menuChange!.foodItems.single.name, 'Ovo');
    expect(lunch.menuChange!.foodItems.single.quantity, 3);
    expect(snack.foodItems, isEmpty);
    expect(snack.menuChange, isNull);
  });
}
