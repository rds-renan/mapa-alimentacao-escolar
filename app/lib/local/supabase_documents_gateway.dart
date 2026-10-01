import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'documents_gateway.dart';

const _bucket = 'generated-documents';

/// As últimas gerações, e não a história inteira. O registro é permanente de
/// propósito (decisão 10 da E4), então a tabela só cresce; a tela, não. Vinte
/// cobre bem mais de um ano de uso — a escola gera um documento por mês, mais
/// as regerações de correção.
const _recent = 20;

/// A implementação de verdade do [DocumentsGateway]. Não há filtro de escola
/// nas consultas: quem recorta é o RLS da E4 (decisão 6 da E6), tanto na
/// tabela quanto no balde — que só libera o objeto enquanto o registro está
/// disponível e dentro do prazo.
class SupabaseDocumentsGateway implements DocumentsGateway {
  SupabaseDocumentsGateway(this._client);

  final SupabaseClient _client;

  @override
  Future<List<RemoteDocument>> fetchRecent() async {
    final rows = await _client
        .from('generated_document')
        .select(
          'id, status, requested_at, completed_at, expires_at, file_path, '
          'file_name, document_meal_map(meal_map(map_date))',
        )
        .order('requested_at', ascending: false)
        .limit(_recent);

    return rows.map(RemoteDocument.fromRow).toList();
  }

  /// Direto pela sessão dela, sem link assinado: o aplicativo não precisa de
  /// um endereço que circule, só dos bytes — e a política do balde é a mesma
  /// que assinaria o link na web.
  @override
  Future<Uint8List> download(String filePath) =>
      _client.storage.from(_bucket).download(filePath);
}
