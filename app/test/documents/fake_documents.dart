import 'dart:typed_data';

import 'package:mae/documents/document_sharer.dart';
import 'package:mae/local/documents_gateway.dart';

/// Um [DocumentsGateway] falso, sem servidor nenhum — o mesmo raciocínio do
/// `FakeMonthGateway` (decisão 4 da E6).
class FakeDocumentsGateway implements DocumentsGateway {
  List<RemoteDocument> documents = const [];
  Object? fetchError;
  int fetchCalls = 0;

  @override
  Future<List<RemoteDocument>> fetchRecent() async {
    fetchCalls++;
    if (fetchError != null) throw fetchError!;
    return documents;
  }

  @override
  Future<Uint8List> download(String filePath) async => Uint8List(0);
}

/// Um [DocumentSharer] falso: a folha do Android não roda em teste.
class FakeDocumentSharer implements DocumentSharer {
  final List<({String filePath, String fileName})> calls = [];
  DocumentFileFailure? failure;

  @override
  Future<void> share({
    required String filePath,
    required String fileName,
  }) async {
    calls.add((filePath: filePath, fileName: fileName));
    if (failure != null) throw failure!;
  }
}
