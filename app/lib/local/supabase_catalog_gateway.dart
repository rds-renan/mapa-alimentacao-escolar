import 'package:supabase_flutter/supabase_flutter.dart';

import 'catalog_gateway.dart';

/// A implementação de verdade do [CatalogGateway], sobre `supabase_flutter`.
/// Não há filtro de escola na consulta — quem recorta é o RLS da E4
/// (decisão 6 da E6).
class SupabaseCatalogGateway implements CatalogGateway {
  SupabaseCatalogGateway(this._client);

  final SupabaseClient _client;

  @override
  Future<List<RemoteFoodItem>> fetchFoodItems() async {
    final rows = await _client
        .from('food_item')
        .select('id, name, default_unit, active');

    return rows.map(RemoteFoodItem.fromRow).toList();
  }
}
