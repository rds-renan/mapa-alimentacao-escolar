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
}
