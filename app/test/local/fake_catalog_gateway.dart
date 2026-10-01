import 'package:mae/local/catalog_gateway.dart';

/// Um [CatalogGateway] falso, sem servidor nenhum — o mesmo raciocínio do
/// `FakeAuthGateway` (decisão 4 da E6).
class FakeCatalogGateway implements CatalogGateway {
  List<RemoteFoodItem> items = const [];
  Object? fetchError;
  int fetchCalls = 0;

  @override
  Future<List<RemoteFoodItem>> fetchFoodItems() async {
    fetchCalls++;
    if (fetchError != null) throw fetchError!;
    return items;
  }

  Object? saveError;
  final List<Map<String, Object?>> saved = [];

  @override
  Future<RemoteFoodItem> saveFoodItem({
    String? id,
    required String schoolId,
    required String name,
    required String unit,
  }) async {
    if (saveError != null) throw saveError!;
    saved.add({'id': id, 'schoolId': schoolId, 'name': name, 'unit': unit});

    final existing = items.where((one) => one.id == id).firstOrNull;
    return RemoteFoodItem(
      id: id ?? 'new-${saved.length}',
      name: name.trim(),
      unit: unit.trim(),
      active: existing?.active ?? true,
    );
  }

  @override
  Future<RemoteFoodItem> setFoodItemActive(
    String id, {
    required bool active,
  }) async {
    if (saveError != null) throw saveError!;
    final existing = items.firstWhere((one) => one.id == id);
    return RemoteFoodItem(
      id: id,
      name: existing.name,
      unit: existing.unit,
      active: active,
    );
  }
}
