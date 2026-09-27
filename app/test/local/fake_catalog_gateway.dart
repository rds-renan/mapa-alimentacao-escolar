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
}
