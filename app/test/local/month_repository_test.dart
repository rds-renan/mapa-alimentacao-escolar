import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mae/local/app_database.dart';
import 'package:mae/local/month_gateway.dart';
import 'package:mae/local/month_repository.dart';

import 'fake_month_gateway.dart';

void main() {
  late AppDatabase db;
  late FakeMonthGateway gateway;
  late MonthRepository repository;

  final september = DateTime(2026, 9);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    gateway = FakeMonthGateway();
    repository = MonthRepository(db, gateway);
  });

  tearDown(() => db.close());

  test('abrir do zero sem rede mostra o mês já consultado', () async {
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
    await db
        .into(db.meals)
        .insert(
          MealsCompanion.insert(
            id: 'meal-1',
            mealMapId: 'map-1',
            type: 'lunch',
            description: Value('Arroz e feijão'),
            acceptance: Value('great'),
          ),
        );

    final days = await repository.watchMonth(september).first;

    expect(days, hasLength(1));
    expect(days.single.mealMap.id, 'map-1');
    expect(days.single.meals.single.acceptance, 'great');
    expect(gateway.fetchCalls, 0);
  });

  test('refreshMonth grava o mês buscado no servidor', () async {
    gateway.maps = [
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
            description: 'Arroz e feijão',
            acceptance: 'great',
          ),
        ],
      ),
      RemoteMealMap(
        id: 'map-2',
        mapDate: DateTime(2026, 9, 11),
        nonSchoolDay: true,
        note: 'Conselho de classe',
        mealsServed: null,
        locked: false,
        updatedAt: DateTime(2026, 9, 11, 8),
        meals: const [],
      ),
    ];

    await repository.refreshMonth(september);
    final days = await repository.watchMonth(september).first;

    expect(days, hasLength(2));
    expect(days[0].mealMap.mealsServed, 312);
    expect(days[0].meals.single.description, 'Arroz e feijão');
    expect(days[1].mealMap.nonSchoolDay, isTrue);
    expect(days[1].mealMap.note, 'Conselho de classe');
    expect(days[1].meals, isEmpty);
  });

  test('refreshMonth substitui as refeições do dia, não acrescenta', () async {
    gateway.maps = [
      RemoteMealMap(
        id: 'map-1',
        mapDate: DateTime(2026, 9, 10),
        nonSchoolDay: false,
        note: null,
        mealsServed: null,
        locked: false,
        updatedAt: DateTime(2026, 9, 10, 12),
        meals: const [
          RemoteMeal(id: 'meal-1', type: 'lunch', acceptance: 'poor'),
        ],
      ),
    ];
    await repository.refreshMonth(september);

    gateway.maps = [
      RemoteMealMap(
        id: 'map-1',
        mapDate: DateTime(2026, 9, 10),
        nonSchoolDay: false,
        note: null,
        mealsServed: 300,
        locked: false,
        updatedAt: DateTime(2026, 9, 10, 20),
        meals: const [
          RemoteMeal(id: 'meal-1', type: 'lunch', acceptance: 'great'),
          RemoteMeal(id: 'meal-2', type: 'afternoon_snack', acceptance: 'good'),
        ],
      ),
    ];
    await repository.refreshMonth(september);

    final days = await repository.watchMonth(september).first;
    expect(days, hasLength(1));
    expect(days.single.meals, hasLength(2));
    expect(
      days.single.meals.firstWhere((m) => m.type == 'lunch').acceptance,
      'great',
    );
  });

  test(
    'quem já está lendo continua vendo o mês antigo até refreshMonth terminar, '
    'e recebe a atualização sem reabrir nada',
    () async {
      final emissions = <int>[];
      final subscription = repository.watchMonth(september).listen((days) {
        emissions.add(days.length);
      });
      addTearDown(subscription.cancel);
      await Future<void>.delayed(Duration.zero);

      expect(emissions, [0]);

      gateway.maps = [
        RemoteMealMap(
          id: 'map-1',
          mapDate: DateTime(2026, 9, 10),
          nonSchoolDay: false,
          note: null,
          mealsServed: null,
          locked: false,
          updatedAt: DateTime(2026, 9, 10, 12),
          meals: const [],
        ),
      ];
      await repository.refreshMonth(september);
      await Future<void>.delayed(Duration.zero);

      expect(emissions, [0, 1]);
    },
  );

  test('refreshMonth sem rede lança e não toca a cópia local', () async {
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

    gateway.fetchError = Exception('sem rede');
    await expectLater(repository.refreshMonth(september), throwsException);

    final days = await repository.watchMonth(september).first;
    expect(days, hasLength(1));
  });
}
