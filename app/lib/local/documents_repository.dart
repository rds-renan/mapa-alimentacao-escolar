import 'package:drift/drift.dart';

import '../documents/generated.dart';
import 'app_database.dart';
import 'documents_gateway.dart';

/// A cópia local da lista de documentos gerados (issue #109, CA#3), na mesma
/// forma do [MonthRepository]: [watch] sempre lê do aparelho, e [refresh]
/// escreve por baixo sem bloquear quem está lendo.
class GeneratedDocumentsRepository {
  GeneratedDocumentsRepository(this._db, this._gateway);

  final AppDatabase _db;
  final DocumentsGateway _gateway;

  Stream<List<GeneratedDocumentRecord>> watch() {
    final query = _db.select(_db.generatedDocuments)
      ..orderBy([
        (t) => OrderingTerm(expression: t.requestedAt, mode: OrderingMode.desc),
      ]);

    return query.watch().map(
      (rows) => [for (final row in rows) _toRecord(row)],
    );
  }

  /// Busca a lista no servidor e a substitui por inteiro: o que o servidor
  /// não devolveu mais (passou das últimas vinte) sai daqui também. Lança se
  /// a rede não responder; a cópia local não é tocada nesse caso.
  Future<void> refresh() async {
    final remote = await _gateway.fetchRecent();

    await _db.transaction(() async {
      await (_db.delete(
        _db.generatedDocuments,
      )..where((t) => t.id.isNotIn([for (final doc in remote) doc.id]))).go();

      for (final doc in remote) {
        await _db
            .into(_db.generatedDocuments)
            .insertOnConflictUpdate(
              GeneratedDocumentsCompanion.insert(
                id: doc.id,
                status: doc.status,
                requestedAt: doc.requestedAt,
                completedAt: Value(doc.completedAt),
                expiresAt: Value(doc.expiresAt),
                filePath: Value(doc.filePath),
                fileName: Value(doc.fileName),
                dates: doc.dates.join(','),
              ),
            );
      }
    });
  }

  GeneratedDocumentRecord _toRecord(StoredDocument row) =>
      GeneratedDocumentRecord(
        id: row.id,
        status: row.status,
        requestedAt: row.requestedAt,
        completedAt: row.completedAt,
        expiresAt: row.expiresAt,
        filePath: row.filePath,
        fileName: row.fileName,
        dates: [
          if (row.dates.isNotEmpty)
            for (final date in row.dates.split(',')) DateTime.parse(date),
        ],
      );
}
