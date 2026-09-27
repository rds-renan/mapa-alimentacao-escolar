import 'package:supabase_flutter/supabase_flutter.dart';

import 'sync_gateway.dart';

/// A implementação de verdade do [SyncGateway], sobre `supabase_flutter`.
/// `save_meal_map` recusa quem não deveria registrar (sem sessão, perfil de
/// direção) e resolve conflito por dentro — não há filtro de escola aqui,
/// como em [SupabaseCatalogGateway] e [SupabaseMonthGateway].
class SupabaseSyncGateway implements SyncGateway {
  SupabaseSyncGateway(this._client);

  final SupabaseClient _client;

  @override
  Future<Map<String, dynamic>> saveMealMap(Map<String, dynamic> payload) async {
    final response = await _client.rpc(
      'save_meal_map',
      params: {'payload': payload},
    );

    return response as Map<String, dynamic>;
  }
}
