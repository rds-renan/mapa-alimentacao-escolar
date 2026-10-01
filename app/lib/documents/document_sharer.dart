import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../local/documents_gateway.dart';
import 'messages.dart';

const _docxType =
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document';

/// O arquivo não chegou, e [message] já está escrita para quem vai lê-la.
class DocumentFileFailure implements Exception {
  const DocumentFileFailure(this.message);

  final String message;

  @override
  String toString() => 'DocumentFileFailure($message)';
}

/// Pegar o arquivo do documento e entregá-lo à folha de compartilhamento do
/// Android (CA#1 da issue #109) — isolado atrás de uma interface, como os
/// portões da decisão 4 da E6, porque a folha é do sistema e não roda em teste.
abstract class DocumentSharer {
  /// Lança [DocumentFileFailure] se o arquivo não vier. Quem fecha a folha
  /// sem escolher nada não errou nada, e a chamada volta normalmente.
  Future<void> share({required String filePath, required String fileName});
}

class PlatformDocumentSharer implements DocumentSharer {
  PlatformDocumentSharer(this._gateway);

  final DocumentsGateway _gateway;

  /// Baixa o arquivo para o aparelho e abre a folha. O arquivo vai para a
  /// pasta temporária do aplicativo — é de lá que a folha o lê — e a cada
  /// pedido é baixado de novo, porque o que vale é o que está no ar agora, e
  /// ele some do servidor depois de sete dias.
  @override
  Future<void> share({
    required String filePath,
    required String fileName,
  }) async {
    final File file;

    try {
      final bytes = await _gateway.download(filePath);
      final directory = await getTemporaryDirectory();
      file = File('${directory.path}/$fileName');
      await file.writeAsBytes(bytes, flush: true);
    } catch (_) {
      throw const DocumentFileFailure(DocumentMessages.fileFailed);
    }

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: _docxType, name: fileName)],
        title: fileName,
      ),
    );
  }
}
