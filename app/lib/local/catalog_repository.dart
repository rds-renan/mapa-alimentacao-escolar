import 'package:drift/drift.dart';

import 'app_database.dart';
import 'catalog_gateway.dart';

/// A cópia local do catálogo (CA#1 da issue #102): quem lê é sempre o banco
/// no aparelho, e [refresh] escreve por baixo sem que quem está lendo
/// perceba travamento — a leitura continua vindo do que já havia até a
/// escrita terminar, e [watchFoodItems] avisa sozinha quando o resultado
/// muda (decisão 6 da E6).
class CatalogRepository {
  CatalogRepository(this._db, this._gateway);

  final AppDatabase _db;
  final CatalogGateway _gateway;

  Stream<List<FoodItem>> watchFoodItems() {
    return (_db.select(
      _db.foodItems,
    )..orderBy([(t) => OrderingTerm(expression: t.name)])).watch();
  }

  /// Busca o catálogo no servidor e substitui a cópia local, gênero por
  /// gênero. Lança se a rede não responder — quem chama decide se tenta de
  /// novo; a cópia local não é tocada nesse caso.
  Future<void> refresh() async {
    final items = await _gateway.fetchFoodItems();

    await _db.batch((batch) {
      batch.insertAllOnConflictUpdate(
        _db.foodItems,
        items.map(
          (item) => FoodItemsCompanion.insert(
            id: item.id,
            name: item.name,
            unit: item.unit,
            active: item.active,
          ),
        ),
      );
    });
  }

  /// Cadastra ou edita direto no servidor e, só depois que ele aceitou,
  /// grava a cópia local — assim a lista nunca mostra o que o servidor
  /// recusou. Lança se a gravação não passar; a cópia local não é tocada.
  Future<void> save({
    String? id,
    required String schoolId,
    required String name,
    required String unit,
  }) async {
    final saved = await _gateway.saveFoodItem(
      id: id,
      schoolId: schoolId,
      name: name,
      unit: unit,
    );
    await _store(saved);
  }

  Future<void> setActive(String id, {required bool active}) async {
    await _store(await _gateway.setFoodItemActive(id, active: active));
  }

  Future<void> _store(RemoteFoodItem item) {
    return _db
        .into(_db.foodItems)
        .insertOnConflictUpdate(
          FoodItemsCompanion.insert(
            id: item.id,
            name: item.name,
            unit: item.unit,
            active: item.active,
          ),
        );
  }
}
