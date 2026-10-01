import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mae/local/app_database.dart';
import 'package:mae/local/catalog_gateway.dart';
import 'package:mae/local/catalog_repository.dart';

import 'fake_catalog_gateway.dart';

void main() {
  late AppDatabase db;
  late FakeCatalogGateway gateway;
  late CatalogRepository repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    gateway = FakeCatalogGateway();
    repository = CatalogRepository(db, gateway);
  });

  tearDown(() => db.close());

  test('abrir do zero sem rede mostra o que já foi baixado', () async {
    await db
        .into(db.foodItems)
        .insert(
          FoodItemsCompanion.insert(
            id: 'item-1',
            name: 'Arroz',
            unit: 'quilo',
            active: true,
          ),
        );

    final items = await repository.watchFoodItems().first;

    expect(items, hasLength(1));
    expect(items.single.name, 'Arroz');
    expect(gateway.fetchCalls, 0);
  });

  test('refresh grava o catálogo buscado no servidor', () async {
    gateway.items = const [
      RemoteFoodItem(id: 'item-1', name: 'Feijão', unit: 'quilo', active: true),
      RemoteFoodItem(
        id: 'item-2',
        name: 'Manteiga',
        unit: 'pote',
        active: false,
      ),
    ];

    await repository.refresh();
    final items = await repository.watchFoodItems().first;

    expect(items.map((item) => item.name), ['Feijão', 'Manteiga']);
    expect(items.singleWhere((item) => item.id == 'item-2').active, isFalse);
  });

  test('refresh atualiza um gênero já existente em vez de duplicar', () async {
    await db
        .into(db.foodItems)
        .insert(
          FoodItemsCompanion.insert(
            id: 'item-1',
            name: 'Arroz',
            unit: 'quilo',
            active: true,
          ),
        );

    gateway.items = const [
      RemoteFoodItem(
        id: 'item-1',
        name: 'Arroz',
        unit: 'pacote',
        active: false,
      ),
    ];
    await repository.refresh();

    final items = await repository.watchFoodItems().first;
    expect(items, hasLength(1));
    expect(items.single.unit, 'pacote');
    expect(items.single.active, isFalse);
  });

  test(
    'quem já está lendo continua vendo o catálogo antigo até refresh terminar, '
    'e recebe a atualização sem reabrir nada',
    () async {
      await db
          .into(db.foodItems)
          .insert(
            FoodItemsCompanion.insert(
              id: 'item-1',
              name: 'Arroz',
              unit: 'quilo',
              active: true,
            ),
          );

      final emissions = <int>[];
      final subscription = repository.watchFoodItems().listen((items) {
        emissions.add(items.length);
      });
      addTearDown(subscription.cancel);
      await Future<void>.delayed(Duration.zero);

      expect(emissions, [1]);

      gateway.items = const [
        RemoteFoodItem(
          id: 'item-1',
          name: 'Arroz',
          unit: 'quilo',
          active: true,
        ),
        RemoteFoodItem(
          id: 'item-2',
          name: 'Feijão',
          unit: 'quilo',
          active: true,
        ),
      ];
      await repository.refresh();
      await Future<void>.delayed(Duration.zero);

      expect(emissions, [1, 2]);
    },
  );

  test('refresh sem rede lança e não toca a cópia local', () async {
    await db
        .into(db.foodItems)
        .insert(
          FoodItemsCompanion.insert(
            id: 'item-1',
            name: 'Arroz',
            unit: 'quilo',
            active: true,
          ),
        );

    gateway.fetchError = Exception('sem rede');
    await expectLater(repository.refresh(), throwsException);

    final items = await repository.watchFoodItems().first;
    expect(items, hasLength(1));
    expect(items.single.name, 'Arroz');
  });

  group('manutenção', () {
    test('salvar grava no servidor e depois na cópia local', () async {
      await repository.save(
        schoolId: 'school-1',
        name: ' Feijão ',
        unit: 'quilo',
      );

      expect(gateway.saved.single['schoolId'], 'school-1');
      final items = await repository.watchFoodItems().first;
      expect(items.single.name, 'Feijão');
      expect(items.single.active, isTrue);
    });

    test('gravação recusada não toca a cópia local', () async {
      gateway.saveError = Exception('sem rede');

      await expectLater(
        repository.save(schoolId: 'school-1', name: 'Feijão', unit: 'quilo'),
        throwsException,
      );

      expect(await repository.watchFoodItems().first, isEmpty);
    });

    test('desativar e reativar atualizam a cópia local', () async {
      gateway.items = const [
        RemoteFoodItem(id: 'a', name: 'Arroz', unit: 'quilo', active: true),
      ];
      await repository.refresh();

      await repository.setActive('a', active: false);
      expect((await repository.watchFoodItems().first).single.active, isFalse);

      await repository.setActive('a', active: true);
      expect((await repository.watchFoodItems().first).single.active, isTrue);
    });
  });
}
