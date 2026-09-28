import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mae/local/app_database.dart';
import 'package:mae/local/day_repository.dart';

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
    // Gêneros utilizados e alteração do cardápio ficam para a #106: o banco
    // local ainda não os guarda, e a leitura nunca inventa o que não tem.
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
}
