import 'package:supabase_flutter/supabase_flutter.dart';

import 'messages.dart';

/// O que a geração devolve — só o que o aplicativo usa agora; o resto da
/// resposta (período, link, prazo) a tela de documentos gerados lê da lista
/// (issue #109).
class GeneratedDocument {
  const GeneratedDocument({required this.id, required this.fileName});

  factory GeneratedDocument.fromJson(Map<String, dynamic> json) =>
      GeneratedDocument(
        id: json['generated_document_id'] as String,
        fileName: json['file_name'] as String,
      );

  final String id;
  final String fileName;
}

/// A geração não aconteceu, e [message] já está escrita para quem vai lê-la.
class GenerationFailure implements Exception {
  const GenerationFailure(this.message);

  final String message;

  @override
  String toString() => 'GenerationFailure($message)';
}

/// O pedido de geração, isolado atrás de uma interface — o mesmo raciocínio
/// do [SyncGateway] (decisão 4 da E6). Lança [GenerationFailure], sempre: a
/// tela não distingue o tipo de falha, só lê a frase.
abstract class GenerationGateway {
  /// Pede o documento dos mapas, **pelos identificadores que eles têm no
  /// servidor**. O que sobe é só a lista: a escola vem do perfil de quem
  /// chamou, e o modelo oficial mora num balde privado que o aparelho nunca
  /// vê (RNF#1 da US012).
  Future<GeneratedDocument> generate(List<String> mealMapIds);
}

/// A frase da recusa, como ela chega na tela.
///
/// A Edge Function devolve a mensagem já escrita — a mesma convenção da
/// gravação do dia, que não deixa tradução para o cliente. O que isto faz é
/// só alcançá-la: o `functions_client` embrulha a resposta em
/// [FunctionException] e guarda o corpo em `details`. Sem isso a merendeira
/// leria o texto da exceção, que não é frase de ninguém. Quando o servidor
/// não respondeu nada, vale a frase que a E3 escreveu para este caso.
String generationFailureMessage(Object error) {
  if (error is FunctionException) {
    final details = error.details;
    final body = details is Map ? details['error'] : null;
    final message = body is Map ? body['message'] : null;

    if (message is String && message.isNotEmpty) {
      final hint = body is Map ? body['hint'] : null;
      return [message, if (hint is String && hint.isNotEmpty) hint].join(' ');
    }
  }

  return FailureMessages.network;
}

class SupabaseGenerationGateway implements GenerationGateway {
  SupabaseGenerationGateway(this._client);

  final SupabaseClient _client;

  @override
  Future<GeneratedDocument> generate(List<String> mealMapIds) async {
    try {
      final response = await _client.functions.invoke(
        'generate-document',
        body: {'meal_map_ids': mealMapIds},
      );

      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw const GenerationFailure(FailureMessages.network);
      }

      return GeneratedDocument.fromJson(data);
    } on GenerationFailure {
      rethrow;
    } catch (error) {
      throw GenerationFailure(generationFailureMessage(error));
    }
  }
}
