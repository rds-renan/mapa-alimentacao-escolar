import 'package:supabase_flutter/supabase_flutter.dart';

import 'catalog_gateway.dart';

/// A implementação de verdade do [CatalogGateway], sobre `supabase_flutter`.
/// Não há filtro de escola na consulta — quem recorta é o RLS da E4
/// (decisão 6 da E6).
class SupabaseCatalogGateway implements CatalogGateway {
  SupabaseCatalogGateway(this._client);

  final SupabaseClient _client;

  static const _columns = 'id, name, default_unit, active';

  @override
  Future<List<RemoteFoodItem>> fetchFoodItems() async {
    final rows = await _client.from('food_item').select(_columns);

    return rows.map(RemoteFoodItem.fromRow).toList();
  }

  @override
  Future<RemoteFoodItem> saveFoodItem({
    String? id,
    required String schoolId,
    required String name,
    required String unit,
  }) async {
    final values = {'name': name.trim(), 'default_unit': unit.trim()};

    final query = id == null
        ? _client.from('food_item').insert({'school_id': schoolId, ...values})
        : _client.from('food_item').update(values).eq('id', id);

    final row = await query.select(_columns).single();
    return RemoteFoodItem.fromRow(row);
  }

  @override
  Future<RemoteFoodItem> setFoodItemActive(
    String id, {
    required bool active,
  }) async {
    final row = await _client
        .from('food_item')
        .update({'active': active})
        .eq('id', id)
        .select(_columns)
        .single();
    return RemoteFoodItem.fromRow(row);
  }
}
