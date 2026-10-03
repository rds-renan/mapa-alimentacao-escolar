import 'package:drift/drift.dart';

import 'app_database.dart';
import 'day.dart';

/// O dia como o servidor o tem — a cópia confirmada que mora nas tabelas de
/// leitura (`meal_maps`, `meals` e as dos gêneros e da alteração) — mais o
/// único fato que só ele conhece: se o mapa está bloqueado.
///
/// O dia vem inteiro, com os gêneros utilizados e a alteração do cardápio de
/// cada refeição (issue #106): é isto que a tela reenvia a cada tecla, e o
/// contrato de `save_meal_map` substitui a lista inteira — ler o dia sem os
/// gêneros e reenviá-lo os apagaria do servidor.
class ConfirmedDay {
  const ConfirmedDay({required this.day, required this.locked});

  final DayPayload day;
  final bool locked;
}

/// O dia que `save_meal_map` acabou de gravar, na forma em que o servidor o
/// guardou (issue #124): os identificadores que ele devolveu adotados, o
/// carimbo de edição dele — que pode ser mais cedo que o do aparelho, se o
/// relógio dela estiver adiantado —, o nome e a unidade do gênero como o
/// catálogo os tem, e os mesmos ajustes que a função faz por dentro (texto
/// aparado, observação só no dia não letivo, número de refeições só no
/// letivo). Os gêneros repetidos, que o servidor junta numa linha só, quem
/// junta é [writeConfirmedDay].
///
/// Nulo quando algum gênero ficou sem identificador — a resposta sempre traz
/// todos, mas, se um dia não trouxer, o certo é o dia sair da fila sem
/// cópia (e esperar a leitura do mês) e não travar a fila tentando gravar
/// uma linha sem chave.
ConfirmedDay? savedDay(DayPayload sent, SaveResponse response) {
  final day = adoptServerIds(sent, response);
  final unresolved = day.meals.any(
    (meal) => [
      ...meal.foodItems,
      ...?meal.menuChange?.foodItems,
    ].any((item) => item.foodItemId == null),
  );
  if (unresolved) return null;
  final catalog = {for (final item in response.foodItems) item.id: item};

  // "pão" digitado vira o "Pão" que já estava no catálogo — é o nome que a
  // leitura do mês traria.
  List<FoodItemPayload> asCatalog(List<FoodItemPayload> items) => [
    for (final item in items)
      if (catalog[item.foodItemId] case final known?)
        FoodItemPayload(
          foodItemId: known.id,
          name: known.name,
          unit: known.unit,
          quantity: item.quantity,
        )
      else
        item,
  ];

  String? trimmed(String? text) {
    final value = text?.trim();
    return value == null || value.isEmpty ? null : value;
  }

  return ConfirmedDay(
    locked: response.locked,
    day: DayPayload(
      id: day.id,
      mapDate: day.mapDate,
      updatedAt: response.updatedAt,
      nonSchoolDay: day.nonSchoolDay,
      note: day.nonSchoolDay ? trimmed(day.note) : null,
      mealsServed: day.nonSchoolDay ? null : day.mealsServed,
      meals: [
        for (final meal in day.meals)
          MealPayload(
            id: meal.id,
            type: meal.type,
            description: trimmed(meal.description),
            acceptance: meal.acceptance,
            foodItems: asCatalog(meal.foodItems),
            menuChange: meal.menuChange == null
                ? null
                : MenuChangePayload(
                    id: meal.menuChange!.id,
                    reason: meal.menuChange!.reason.trim(),
                    foodItems: asCatalog(meal.menuChange!.foodItems),
                  ),
          ),
      ],
    ),
  );
}

/// Substitui, nas tabelas de leitura, o dia inteiro pelo que veio — o mesmo
/// raciocínio de `save_meal_map`: o que não vier deixa de existir.
///
/// O dia é a data, não o identificador: se o aparelho tinha o mesmo dia com
/// outro identificador (dois aparelhos criaram o dia sem rede, e o servidor
/// ficou com o da colega), a linha velha sai junto.
///
/// Cópia mais nova não é trocada por mais velha: a leitura do mês que saiu
/// antes do envio e chegou depois dele traria o dia de antes do envio — e o
/// buraco desta issue (#124) voltaria pela outra porta. Devolve se gravou.
///
/// Não abre transação própria — quem chama decide o tamanho dela: o mês
/// inteiro em [MonthRepository.refreshMonth], e o dia junto com a saída da
/// fila em [SyncQueueStore.settle].
Future<bool> writeConfirmedDay(AppDatabase db, ConfirmedDay confirmed) async {
  final day = confirmed.day;
  final mapDate = DateTime.parse(day.mapDate);
  final updatedAt = DateTime.parse(day.updatedAt);

  final previous = await (db.select(
    db.mealMaps,
  )..where((t) => t.mapDate.equals(mapDate) | t.id.equals(day.id))).get();
  // O Drift guarda a data até o segundo; a que chega vem com fração.
  final seconds = updatedAt.millisecondsSinceEpoch ~/ 1000;
  if (previous.any(
    (map) => map.updatedAt.millisecondsSinceEpoch ~/ 1000 > seconds,
  )) {
    return false;
  }

  for (final map in previous) {
    await _deleteMealsOf(db, map.id);
  }
  await (db.delete(
    db.mealMaps,
  )..where((t) => t.id.isIn(previous.map((map) => map.id)))).go();

  await db
      .into(db.mealMaps)
      .insert(
        MealMapsCompanion.insert(
          id: day.id,
          mapDate: mapDate,
          nonSchoolDay: day.nonSchoolDay,
          note: Value(day.note),
          mealsServed: Value(day.mealsServed),
          locked: confirmed.locked,
          updatedAt: updatedAt,
        ),
      );

  await db.batch((batch) {
    for (final meal in day.meals) {
      batch.insert(
        db.meals,
        MealsCompanion.insert(
          id: meal.id,
          mealMapId: day.id,
          type: meal.type,
          description: Value(meal.description),
          acceptance: Value(meal.acceptance),
        ),
      );

      for (final (position, item) in _distinct(meal.foodItems).indexed) {
        batch.insert(
          db.mealFoodItems,
          MealFoodItemsCompanion.insert(
            mealId: meal.id,
            position: position,
            foodItemId: item.foodItemId!,
            name: item.name,
            unit: Value(item.unit),
            quantity: item.quantity,
          ),
        );
      }

      final change = meal.menuChange;
      if (change == null) continue;

      batch.insert(
        db.menuChanges,
        MenuChangesCompanion.insert(
          id: change.id,
          mealId: meal.id,
          reason: change.reason,
        ),
      );

      for (final (position, item) in _distinct(change.foodItems).indexed) {
        batch.insert(
          db.menuChangeFoodItems,
          MenuChangeFoodItemsCompanion.insert(
            menuChangeId: change.id,
            position: position,
            foodItemId: item.foodItemId!,
            name: item.name,
            unit: Value(item.unit),
            quantity: item.quantity,
          ),
        );
      }
    }
  });

  return true;
}

/// O mesmo gênero duas vezes na mesma lista vira uma linha só, com a última
/// quantidade — como `save_meal_map` faz (`on conflict … do update`). Da
/// leitura do servidor isso nunca vem repetido; do dia recém-enviado, pode.
List<FoodItemPayload> _distinct(List<FoodItemPayload> items) {
  final byId = <String, FoodItemPayload>{};
  for (final item in items) {
    final id = item.foodItemId!;
    final first = byId[id] ?? item;
    byId[id] = FoodItemPayload(
      foodItemId: id,
      name: first.name,
      unit: first.unit,
      quantity: item.quantity,
    );
  }
  return byId.values.toList();
}

/// Apaga as refeições de um dia com tudo que pende delas. À mão, e não pelo
/// `onDelete: cascade` do esquema: o SQLite só respeita chave estrangeira
/// com `PRAGMA foreign_keys` ligado, e este banco nunca o ligou.
Future<void> _deleteMealsOf(AppDatabase db, String mealMapId) async {
  final mealIds = db.selectOnly(db.meals)
    ..addColumns([db.meals.id])
    ..where(db.meals.mealMapId.equals(mealMapId));
  final changeIds = db.selectOnly(db.menuChanges)
    ..addColumns([db.menuChanges.id])
    ..where(db.menuChanges.mealId.isInQuery(mealIds));

  await (db.delete(
    db.menuChangeFoodItems,
  )..where((t) => t.menuChangeId.isInQuery(changeIds))).go();
  await (db.delete(
    db.menuChanges,
  )..where((t) => t.mealId.isInQuery(mealIds))).go();
  await (db.delete(
    db.mealFoodItems,
  )..where((t) => t.mealId.isInQuery(mealIds))).go();
  await (db.delete(db.meals)..where((t) => t.mealMapId.equals(mealMapId))).go();
}
