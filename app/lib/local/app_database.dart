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
/// alteração do dia moram nas tabelas abaixo (issues #106 e #172).
class MealMaps extends Table {
  TextColumn get id => text()();
  DateTimeColumn get mapDate => dateTime()();
  BoolColumn get nonSchoolDay => boolean()();
  TextColumn get note => text().nullable()();
  IntColumn get mealsServed => integer().nullable()();
  BoolColumn get locked => boolean()();
  DateTimeColumn get updatedAt => dateTime()();

  /// Reaberto pela direção e ainda fora de documento (CA#2 da US023, issue
  /// #152) — a mesma regra da web: `locked = false` e pelo menos uma linha
  /// em `meal_map_unlock`. Não é tabela espelhada porque o histórico das
  /// reaberturas é da direção; aqui só importa o sinal.
  BoolColumn get reopened => boolean().withDefault(const Constant(false))();

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

/// Um gênero utilizado no dia, espelhando `public.meal_map_food_item`
/// (decisão 14 da E4).
///
/// Guarda o nome e a unidade junto, e não só o identificador: é a forma em
/// que o gênero sobe (`FoodItemPayload`), e o catálogo do aparelho pode ainda
/// não conhecer um gênero que a colega cadastrou pela web — ler pela junção
/// com [FoodItems] deixaria esse gênero sem nome até o catálogo atualizar.
/// `position` guarda a ordem em que o servidor os devolveu.
class MealMapFoodItems extends Table {
  TextColumn get mealMapId =>
      text().references(MealMaps, #id, onDelete: KeyAction.cascade)();
  IntColumn get position => integer()();
  TextColumn get foodItemId => text()();
  TextColumn get name => text()();
  TextColumn get unit => text().nullable()();
  IntColumn get quantity => integer()();

  @override
  Set<Column> get primaryKey => {mealMapId, foodItemId};
}

/// A alteração do cardápio, espelhando `public.menu_change` — no máximo uma
/// por dia (decisão 14 da E4), daí o mapa ser único aqui também.
class MenuChanges extends Table {
  TextColumn get id => text()();
  TextColumn get mealMapId =>
      text().unique().references(MealMaps, #id, onDelete: KeyAction.cascade)();
  TextColumn get reason => text()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Os gêneros que entraram na troca, espelhando
/// `public.menu_change_food_item` — a mesma forma de [MealMapFoodItems], porque
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

/// A lista dos documentos gerados, espelhando `public.generated_document`
/// (issue #109). O que fica no aparelho é a lista, não o arquivo: abrir e
/// compartilhar exigem rede (decisão 6 da E6).
///
/// As datas dos mapas incluídos moram numa coluna só, em texto separado por
/// vírgula, e não numa tabela filha: só se leem juntas, para dizer o período
/// e contar os mapas, e nunca se consultam por data.
@DataClassName('StoredDocument')
class GeneratedDocuments extends Table {
  TextColumn get id => text()();
  TextColumn get status => text()();
  DateTimeColumn get requestedAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  DateTimeColumn get expiresAt => dateTime().nullable()();
  TextColumn get filePath => text().nullable()();
  TextColumn get fileName => text().nullable()();
  TextColumn get dates => text()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    FoodItems,
    MealMaps,
    Meals,
    MealMapFoodItems,
    MenuChanges,
    MenuChangeFoodItems,
    PendingMealMaps,
    GeneratedDocuments,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    // A #103, a #106 e a #109 só acrescentaram tabelas; `createAll()` cria o que
    // falta e ignora o que já existe, então não há dado de nenhum arquivo
    // local de desenvolvimento para migrar de verdade. Os dias baixados antes
    // da #106 ficam sem gêneros até o próximo `refreshMonth` do mês deles —
    // que é a primeira coisa que a visão do mês faz ao abrir.
    //
    // A #152 é a primeira a mexer numa tabela que já existe, e agora já há
    // aparelho com dado de verdade (a 0.1.1, no ensaio da E7): a coluna
    // entra com `addColumn`, valendo falso, e o sinal aparece no próximo
    // `refreshMonth` — de novo, a primeira coisa que a visão do mês faz.
    //
    // A #172 é a primeira a mudar a forma de tabelas que já têm dado de
    // verdade: os gêneros e a alteração saem da refeição e vão para o dia.
    // O que está no aparelho vem junto, para a visão do mês não mostrar sem
    // gênero, até a internet voltar, um dia que já tinha.
    onUpgrade: (m, from, to) async {
      if (from >= 3 && from < 6) await _moveFoodItemsToDay(m);
      await m.createAll();
      if (from < 5) await m.addColumn(mealMaps, mealMaps.reopened);
    },
  );

  /// A cópia confirmada do formato de antes da decisão 14 da E4, levada para
  /// o dia com a mesma junção da migration `20261028120000_generos_do_dia.sql`:
  /// os gêneros das três refeições somados por gênero, e as alterações
  /// juntadas na ordem das refeições, com os gêneros da troca somados.
  ///
  /// A fila não passa por aqui: ela guarda o dia como texto, e quem o lê no
  /// formato antigo é `DayPayload.fromJson`.
  Future<void> _moveFoodItemsToDay(Migrator m) async {
    // O arquivo pode ter nascido sem as tabelas da #106, se veio de um
    // aparelho que nunca abriu um dia; aí não há o que trazer.
    final old = await customSelect(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = "
      "'meal_food_items'",
    ).get();
    if (old.isEmpty) return;

    const order = ['morning_snack', 'lunch', 'afternoon_snack'];
    int rank(String type) => order.indexOf(type);

    final items = await customSelect(
      'SELECT m.meal_map_id AS map_id, m.type AS type, f.food_item_id AS '
      'item_id, f.name AS name, f.unit AS unit, f.quantity AS quantity '
      'FROM meal_food_items f JOIN meals m ON m.id = f.meal_id '
      'ORDER BY f.position',
    ).get();
    final changes = await customSelect(
      'SELECT c.id AS id, c.reason AS reason, m.meal_map_id AS map_id, '
      'm.type AS type FROM menu_changes c JOIN meals m ON m.id = c.meal_id',
    ).get();
    final changeItems = await customSelect(
      'SELECT menu_change_id AS change_id, food_item_id AS item_id, name, '
      'unit, quantity FROM menu_change_food_items ORDER BY position',
    ).get();

    // Por dia, e dentro do dia na ordem das refeições.
    final dayItems =
        <String, Map<String, ({String name, String? unit, int quantity})>>{};
    for (final row
        in [...items]..sort(
          (a, b) =>
              rank(a.read<String>('type'))
                  .compareTo(rank(b.read<String>('type'))),
        )) {
      final byItem = dayItems.putIfAbsent(row.read<String>('map_id'), () => {});
      final id = row.read<String>('item_id');
      final running = byItem[id];
      byItem[id] = (
        name: running?.name ?? row.read<String>('name'),
        unit: running?.unit ?? row.readNullable<String>('unit'),
        quantity: (running?.quantity ?? 0) + row.read<int>('quantity'),
      );
    }

    final dayChanges = <String, List<QueryRow>>{};
    for (final row
        in [...changes]..sort(
          (a, b) =>
              rank(a.read<String>('type'))
                  .compareTo(rank(b.read<String>('type'))),
        )) {
      dayChanges.putIfAbsent(row.read<String>('map_id'), () => []).add(row);
    }

    await m.deleteTable('menu_change_food_items');
    await m.deleteTable('menu_changes');
    await m.deleteTable('meal_food_items');
    await m.createTable(mealMapFoodItems);
    await m.createTable(menuChanges);
    await m.createTable(menuChangeFoodItems);

    await batch((batch) {
      for (final MapEntry(key: mapId, value: byItem) in dayItems.entries) {
        for (final (position, MapEntry(key: id, value: item))
            in byItem.entries.indexed) {
          batch.insert(
            mealMapFoodItems,
            MealMapFoodItemsCompanion.insert(
              mealMapId: mapId,
              position: position,
              foodItemId: id,
              name: item.name,
              unit: Value(item.unit),
              quantity: item.quantity,
            ),
          );
        }
      }

      for (final MapEntry(key: mapId, value: rows) in dayChanges.entries) {
        final keeper = rows.first.read<String>('id');
        final ids = {for (final row in rows) row.read<String>('id')};
        batch.insert(
          menuChanges,
          MenuChangesCompanion.insert(
            id: keeper,
            mealMapId: mapId,
            reason: rows
                .map((row) => row.read<String>('reason').trim())
                .where((reason) => reason.isNotEmpty)
                .join(' / '),
          ),
        );

        final byItem = <String, ({String name, String? unit, int quantity})>{};
        for (final row in changeItems) {
          if (!ids.contains(row.read<String>('change_id'))) continue;
          final id = row.read<String>('item_id');
          final running = byItem[id];
          byItem[id] = (
            name: running?.name ?? row.read<String>('name'),
            unit: running?.unit ?? row.readNullable<String>('unit'),
            quantity: (running?.quantity ?? 0) + row.read<int>('quantity'),
          );
        }
        for (final (position, MapEntry(key: id, value: item))
            in byItem.entries.indexed) {
          batch.insert(
            menuChangeFoodItems,
            MenuChangeFoodItemsCompanion.insert(
              menuChangeId: keeper,
              position: position,
              foodItemId: id,
              name: item.name,
              unit: Value(item.unit),
              quantity: item.quantity,
            ),
          );
        }
      }
    });
  }
}

/// Um arquivo por usuária (decisão 6 da E6): o identificador do perfil, que
/// só existe depois do login, escolhe o nome do banco.
String localDatabaseName(String profileId) => 'mae_$profileId';

QueryExecutor openLocalDatabaseConnection(String profileId) {
  return driftDatabase(name: localDatabaseName(profileId));
}
