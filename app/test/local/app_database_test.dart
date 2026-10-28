import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mae/local/app_database.dart';

void main() {
  test('cada perfil ganha o nome do próprio arquivo de banco', () {
    expect(localDatabaseName('user-1'), isNot(localDatabaseName('user-2')));
  });

  test('o mesmo perfil sempre abre o mesmo arquivo', () {
    expect(localDatabaseName('user-1'), localDatabaseName('user-1'));
  });

  test('o banco da versão 4 ganha a coluna da reabertura sem perder os dias '
      '(issue #152)', () async {
    // A `meal_maps` como a 0.1.1 a criou, com um dia já baixado.
    final db = AppDatabase(
      NativeDatabase.memory(
        setup: (raw) {
          raw.execute(
            'CREATE TABLE meal_maps (id TEXT NOT NULL, map_date INTEGER NOT '
            'NULL, non_school_day INTEGER NOT NULL, note TEXT NULL, '
            'meals_served INTEGER NULL, locked INTEGER NOT NULL, updated_at '
            'INTEGER NOT NULL, PRIMARY KEY (id), UNIQUE (map_date))',
          );
          final date = DateTime(2026, 9, 13).millisecondsSinceEpoch ~/ 1000;
          raw.execute(
            "INSERT INTO meal_maps VALUES ('map-13', $date, 0, NULL, 300, 0, "
            '$date)',
          );
          raw.execute('PRAGMA user_version = 4');
        },
      ),
    );
    addTearDown(db.close);

    final map = (await db.select(db.mealMaps).get()).single;
    expect(map.id, 'map-13');
    expect(map.mealsServed, 300);
    expect(map.reopened, isFalse);
  });

  test('o banco da versão 5 leva os gêneros e a alteração para o dia, '
      'somando o que se repete (issue #172)', () async {
    // As tabelas da cópia confirmada como a 0.1.3 as criou, com um dia que
    // tinha arroz em duas refeições e uma alteração em cada uma.
    final db = AppDatabase(
      NativeDatabase.memory(
        setup: (raw) {
          final date = DateTime(2026, 10, 1).millisecondsSinceEpoch ~/ 1000;
          for (final sql in [
            'CREATE TABLE meal_maps (id TEXT NOT NULL, map_date INTEGER NOT '
                'NULL, non_school_day INTEGER NOT NULL, note TEXT NULL, '
                'meals_served INTEGER NULL, locked INTEGER NOT NULL, '
                'updated_at INTEGER NOT NULL, reopened INTEGER NOT NULL '
                'DEFAULT 0, PRIMARY KEY (id), UNIQUE (map_date))',
            'CREATE TABLE meals (id TEXT NOT NULL, meal_map_id TEXT NOT NULL, '
                'type TEXT NOT NULL, description TEXT NULL, acceptance TEXT '
                'NULL, PRIMARY KEY (id), UNIQUE (meal_map_id, type))',
            'CREATE TABLE meal_food_items (meal_id TEXT NOT NULL, position '
                'INTEGER NOT NULL, food_item_id TEXT NOT NULL, name TEXT NOT '
                'NULL, unit TEXT NULL, quantity INTEGER NOT NULL, PRIMARY KEY '
                '(meal_id, food_item_id))',
            'CREATE TABLE menu_changes (id TEXT NOT NULL, meal_id TEXT NOT '
                'NULL UNIQUE, reason TEXT NOT NULL, PRIMARY KEY (id))',
            'CREATE TABLE menu_change_food_items (menu_change_id TEXT NOT '
                'NULL, position INTEGER NOT NULL, food_item_id TEXT NOT NULL, '
                'name TEXT NOT NULL, unit TEXT NULL, quantity INTEGER NOT '
                'NULL, PRIMARY KEY (menu_change_id, food_item_id))',
            "INSERT INTO meal_maps VALUES ('map-1', $date, 0, NULL, 90, 0, "
                '$date, 0)',
            "INSERT INTO meals VALUES ('m1', 'map-1', 'morning_snack', "
                "'Leite', 'great')",
            "INSERT INTO meals VALUES ('m2', 'map-1', 'lunch', 'Arroz', "
                "'good')",
            "INSERT INTO meal_food_items VALUES ('m2', 0, 'arroz', 'Arroz', "
                "'quilo', 3)",
            "INSERT INTO meal_food_items VALUES ('m1', 0, 'leite', 'Leite', "
                "'litro', 1)",
            "INSERT INTO meal_food_items VALUES ('m1', 1, 'arroz', 'Arroz', "
                "'quilo', 2)",
            "INSERT INTO menu_changes VALUES ('c-almoco', 'm2', "
                "'Faltou frango')",
            "INSERT INTO menu_changes VALUES ('c-manha', 'm1', "
                "'Faltou leite')",
            "INSERT INTO menu_change_food_items VALUES ('c-almoco', 0, "
                "'ovo', 'Ovo', 'unidade', 10)",
            "INSERT INTO menu_change_food_items VALUES ('c-almoco', 1, "
                "'suco', 'Suco', 'litro', 1)",
            "INSERT INTO menu_change_food_items VALUES ('c-manha', 0, "
                "'suco', 'Suco', 'litro', 2)",
            'PRAGMA user_version = 5',
          ]) {
            raw.execute(sql);
          }
        },
      ),
    );
    addTearDown(db.close);

    final items = await db.select(db.mealMapFoodItems).get();
    expect(
      {for (final item in items) item.foodItemId: item.quantity},
      {'leite': 1, 'arroz': 5},
    );
    expect(items.every((item) => item.mealMapId == 'map-1'), isTrue);

    final change = (await db.select(db.menuChanges).get()).single;
    expect(change.id, 'c-manha');
    expect(change.mealMapId, 'map-1');
    expect(change.reason, 'Faltou leite / Faltou frango');

    final changeItems = await db.select(db.menuChangeFoodItems).get();
    expect(
      {for (final item in changeItems) item.foodItemId: item.quantity},
      {'suco': 3, 'ovo': 10},
    );
    expect(changeItems.every((item) => item.menuChangeId == 'c-manha'), isTrue);

    // As refeições e o dia continuam onde estavam.
    expect(await db.select(db.meals).get(), hasLength(2));
    expect((await db.select(db.mealMaps).get()).single.mealsServed, 90);
  });
}
