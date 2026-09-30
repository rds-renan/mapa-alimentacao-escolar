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

/// O mapa de um dia, espelhando `public.meal_map` — os campos que a visão do
/// mês (US008) precisa para calcular os cinco estados. Os gêneros e a
/// alteração de cada refeição moram nas tabelas abaixo (issue #106).
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

/// Um gênero utilizado numa refeição, espelhando `public.meal_food_item`.
///
/// Guarda o nome e a unidade junto, e não só o identificador: é a forma em
/// que o gênero sobe (`FoodItemPayload`), e o catálogo do aparelho pode ainda
/// não conhecer um gênero que a colega cadastrou pela web — ler pela junção
/// com [FoodItems] deixaria esse gênero sem nome até o catálogo atualizar.
/// `position` guarda a ordem em que o servidor os devolveu.
class MealFoodItems extends Table {
  TextColumn get mealId =>
      text().references(Meals, #id, onDelete: KeyAction.cascade)();
  IntColumn get position => integer()();
  TextColumn get foodItemId => text()();
  TextColumn get name => text()();
  TextColumn get unit => text().nullable()();
  IntColumn get quantity => integer()();

  @override
  Set<Column> get primaryKey => {mealId, foodItemId};
}

/// A alteração do cardápio, espelhando `public.menu_change` — no máximo uma
/// por refeição (RN#2 da US002), daí a refeição ser única aqui também.
class MenuChanges extends Table {
  TextColumn get id => text()();
  TextColumn get mealId =>
      text().unique().references(Meals, #id, onDelete: KeyAction.cascade)();
  TextColumn get reason => text()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Os gêneros que entraram na troca, espelhando
/// `public.menu_change_food_item` — a mesma forma de [MealFoodItems], porque
/// é a mesma lista, só que para outra coluna do documento (decisão 7 da E4).
class MenuChangeFoodItems extends Table {
  TextColumn get menuChangeId =>
      text().references(MenuChanges, #id, onDelete: KeyAction.cascade)();
  IntColumn get position => integer()();
  TextColumn get foodItemId => text()();
  TextColumn get name => text()();
  TextColumn get unit => text().nullable()();
  IntColumn get quantity => integer()();

  @override
  Set<Column> get primaryKey => {menuChangeId, foodItemId};
}

/// O dia por enviar, ainda não confirmado pelo servidor (issue #103) —
/// rascunho e fila de envio são a mesma coisa, como na
/// [camada local](../../../docs/06-app/fila-de-envio-e-convergencia.md) da
/// web: **estar guardado aqui é ser dia que o servidor ainda não confirmou**
/// (RN#1 da US011). `payload` é o próprio [DayPayload] serializado, campo por
/// campo o payload de `save_meal_map` — sem tradução no meio.
///
/// Ao contrário do IndexedDB da web, não há coluna de usuária: o arquivo já é
/// de uma só (decisão 6 da E6), então a chave é só a data do dia.
class PendingMealMaps extends Table {
  DateTimeColumn get mapDate => dateTime()();
  TextColumn get payload => text()();

  /// Tentativas de envio seguidas sem sucesso. Comanda a espera até a
  /// próxima.
  IntColumn get attempts => integer().withDefault(const Constant(0))();

  /// Recusa que não se resolve reenviando. Enquanto existir, a fila não
  /// insiste — mas o dia continua aqui.
  TextColumn get rejectionCode => text().nullable()();
  TextColumn get rejectionMessage => text().nullable()();

  /// Quando entrou na fila, em microssegundos desde a época — um `int`, não
  /// um [DateTimeColumn], porque o armazenamento padrão do Drift trunca para
  /// o segundo, e dois dias diferentes gravados na mesma rodada de teste (ou
  /// no mesmo segundo de uso) empatariam e perderiam a ordem de envio.
  IntColumn get queuedAtMicros => integer()();

  @override
  Set<Column> get primaryKey => {mapDate};
}

@DriftDatabase(
  tables: [
    FoodItems,
    MealMaps,
    Meals,
    MealFoodItems,
    MenuChanges,
    MenuChangeFoodItems,
    PendingMealMaps,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    // A #103 e a #106 só acrescentaram tabelas; `createAll()` cria o que
    // falta e ignora o que já existe, então não há dado de nenhum arquivo
    // local de desenvolvimento para migrar de verdade. Os dias baixados antes
    // da #106 ficam sem gêneros até o próximo `refreshMonth` do mês deles —
    // que é a primeira coisa que a visão do mês faz ao abrir.
    onUpgrade: (m, from, to) async => m.createAll(),
  );
}

/// Um arquivo por usuária (decisão 6 da E6): o identificador do perfil, que
/// só existe depois do login, escolhe o nome do banco.
String localDatabaseName(String profileId) => 'mae_$profileId';

QueryExecutor openLocalDatabaseConnection(String profileId) {
  return driftDatabase(name: localDatabaseName(profileId));
}
