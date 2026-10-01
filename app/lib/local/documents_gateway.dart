import 'dart:typed_data';

/// Um documento gerado, como o servidor o entrega à lista.
class RemoteDocument {
  const RemoteDocument({
    required this.id,
    required this.status,
    required this.requestedAt,
    required this.completedAt,
    required this.expiresAt,
    required this.filePath,
    required this.fileName,
    required this.dates,
  });

  /// O período e a quantidade de mapas nascem da ligação `document_meal_map`,
  /// que é a única que sabe quais dias entraram (decisão 10 da E4) — por isso
  /// as datas vêm junto, e não gravadas no documento.
  factory RemoteDocument.fromRow(Map<String, dynamic> row) {
    final links = row['document_meal_map'] as List<dynamic>? ?? const [];
    final dates = <String>[
      for (final link in links)
        if ((link as Map<String, dynamic>)['meal_map'] case {
          'map_date': final String date,
        })
          date,
    ]..sort();

    DateTime? instant(String column) {
      final value = row[column] as String?;
      return value == null ? null : DateTime.parse(value);
    }

    return RemoteDocument(
      id: row['id'] as String,
      status: row['status'] as String,
      requestedAt: DateTime.parse(row['requested_at'] as String),
      completedAt: instant('completed_at'),
      expiresAt: instant('expires_at'),
      filePath: row['file_path'] as String?,
      fileName: row['file_name'] as String?,
      dates: dates,
    );
  }

  final String id;
  final String status;
  final DateTime requestedAt;
  final DateTime? completedAt;
  final DateTime? expiresAt;
  final String? filePath;
  final String? fileName;

  /// AAAA-MM-DD, em ordem.
  final List<String> dates;
}

/// O que a lista de documentos gerados precisa do Supabase, isolado atrás de
/// uma interface — o mesmo raciocínio do [MonthGateway] (decisão 4 da E6).
abstract class DocumentsGateway {
  /// As últimas gerações, da mais nova para a mais velha.
  Future<List<RemoteDocument>> fetchRecent();

  /// Os bytes do arquivo publicado. Lança se a rede não responder ou se o
  /// arquivo já saiu do ar.
  Future<Uint8List> download(String filePath);
}
