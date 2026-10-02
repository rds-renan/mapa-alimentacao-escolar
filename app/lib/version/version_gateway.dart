import 'package:supabase_flutter/supabase_flutter.dart';

/// De onde vem a versão mínima que o banco aceita (decisão 12 da E6), isolado
/// atrás de uma interface pelo mesmo motivo do [SyncGateway]: o [VersionGate]
/// fica testável sem servidor.
abstract class VersionGateway {
  /// O versionCode mínimo. Lança quando não deu para perguntar — sem rede, ou
  /// sem sessão.
  Future<int> fetchMinimumBuild();
}

/// A implementação de verdade, sobre a tabela `app_version`: uma linha só,
/// legível por quem estiver logado.
class SupabaseVersionGateway implements VersionGateway {
  SupabaseVersionGateway(this._client);

  final SupabaseClient _client;

  @override
  Future<int> fetchMinimumBuild() async {
    final row = await _client
        .from('app_version')
        .select('minimum_build')
        .single();

    return row['minimum_build'] as int;
  }
}
