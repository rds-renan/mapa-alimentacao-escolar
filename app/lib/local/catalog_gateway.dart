/// O que a leitura do catálogo precisa do Supabase, isolado atrás de uma
/// interface — o mesmo raciocínio do `AuthGateway` (decisão 4 da E6): torna o
/// [CatalogRepository] testável sem servidor.
abstract class CatalogGateway {
  /// Ativos e desativados: separar os dois é leitura, não busca (mesma
  /// distinção que a manutenção do catálogo faz na web).
  Future<List<RemoteFoodItem>> fetchFoodItems();
}

class RemoteFoodItem {
  const RemoteFoodItem({
    required this.id,
    required this.name,
    required this.unit,
    required this.active,
  });

  factory RemoteFoodItem.fromRow(Map<String, dynamic> row) => RemoteFoodItem(
    id: row['id'] as String,
    name: row['name'] as String,
    unit: row['default_unit'] as String,
    active: row['active'] as bool,
  );

  final String id;
  final String name;
  final String unit;
  final bool active;
}
