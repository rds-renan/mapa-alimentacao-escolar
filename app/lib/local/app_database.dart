import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

/// O catálogo de gêneros, espelhando `public.food_item` (issue #102). A
/// unidade normalizada e o nome duplicado por escola não atravessam: o banco
/// local já é o de uma escola só, a da usuária dona do arquivo.
class FoodItems extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get unit => text()();
  BoolColumn get active => boolean()();

  @override
  Set<Column> get primaryKey => {id};
}

/// O mapa de um dia, espelhando `public.meal_map` — só os campos que a
/// visão do mês (US008) precisa para calcular os cinco estados; gêneros
/// usados e alteração do cardápio ficam para quando a #105 abrir o dia.
class MealMaps extends Table {
  TextColumn get id => text()();
  DateTimeColumn get mapDate => dateTime()();
  BoolColumn get nonSchoolDay => boolean()();
  TextColumn get note => text().nullable()();
  IntColumn get mealsServed => integer().nullable()();
  BoolColumn get locked => boolean()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {mapDate},
  ];
}

/// Uma das três refeições do dia, espelhando `public.meal`. `type` e
/// `acceptance` guardam os mesmos textos do banco (`morning_snack`,
/// `great`, …) — sem tradução no meio, como a gravação do dia já faz.
class Meals extends Table {
  TextColumn get id => text()();
  TextColumn get mealMapId =>
      text().references(MealMaps, #id, onDelete: KeyAction.cascade)();
  TextColumn get type => text()();
  TextColumn get description => text().nullable()();
  TextColumn get acceptance => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {mealMapId, type},
  ];
}

@DriftDatabase(tables: [FoodItems, MealMaps, Meals])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 1;
}

/// Um arquivo por usuária (decisão 6 da E6): o identificador do perfil, que
/// só existe depois do login, escolhe o nome do banco.
String localDatabaseName(String profileId) => 'mae_$profileId';

QueryExecutor openLocalDatabaseConnection(String profileId) {
  return driftDatabase(name: localDatabaseName(profileId));
}
