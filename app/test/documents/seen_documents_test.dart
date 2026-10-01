import 'package:flutter_test/flutter_test.dart';
import 'package:mae/documents/generated.dart';
import 'package:mae/documents/seen_documents.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// O "já visto" dos documentos gerados (issue #110): a regra de quem entra no
/// aviso e o que fica guardado no aparelho.
void main() {
  final now = DateTime(2026, 9, 9, 14, 32);

  GeneratedDocumentRecord document(
    String id, {
    String status = 'available',
    DateTime? expiresAt,
  }) => GeneratedDocumentRecord(
    id: id,
    status: status,
    requestedAt: now,
    completedAt: status == 'processing' ? null : now,
    expiresAt: status == 'available'
        ? expiresAt ?? now.add(const Duration(days: 7))
        : null,
    filePath: status == 'available' ? 'escola/$id.docx' : null,
    fileName: status == 'available' ? '$id.docx' : null,
    dates: [DateTime(2026, 9, 1)],
  );

  group('unseenReady', () {
    test('entra o que está pronto e não foi visto, na ordem da lista', () {
      final result = unseenReady(
        [document('novo'), document('velho'), document('visto')],
        {'visto'},
        now,
      );

      expect([for (final d in result) d.id], ['novo', 'velho']);
    });

    test('o que não dá para abrir não é notícia', () {
      final result = unseenReady(
        [
          document('falhou', status: 'failed'),
          document('gerando', status: 'processing'),
          document('vencido', expiresAt: DateTime(2026, 9, 8)),
          document('sai-amanha', expiresAt: DateTime(2026, 9, 10, 8)),
        ],
        const {},
        now,
      );

      // O que sai amanhã ainda dá para compartilhar, então ainda é aviso.
      expect([for (final d in result) d.id], ['sai-amanha']);
    });
  });

  group('SeenDocuments', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('só vale depois de ler o aparelho', () async {
      final seen = SeenDocuments('cook-1');
      expect(seen.loaded, isFalse);

      await seen.load();

      expect(seen.loaded, isTrue);
      expect(seen.ids, isEmpty);
    });

    test('o que ela viu sobrevive a fechar o aplicativo', () async {
      final first = SeenDocuments('cook-1');
      await first.markSeen(['a', 'b']);

      final reopened = SeenDocuments('cook-1');
      await reopened.load();

      expect(reopened.ids, {'a', 'b'});
    });

    test('cada perfil guarda o seu', () async {
      await SeenDocuments('cook-1').markSeen(['a']);

      final other = SeenDocuments('cook-2');
      await other.load();

      expect(other.ids, isEmpty);
    });

    test('marcar o que já foi visto não avisa ninguém', () async {
      final seen = SeenDocuments('cook-1');
      await seen.markSeen(['a']);

      var notified = 0;
      seen.addListener(() => notified++);
      await seen.markSeen(['a']);

      expect(notified, 0);
    });

    test('marcar antes de ler não perde o que já estava guardado', () async {
      SharedPreferences.setMockInitialValues({
        'mae.seen_documents.cook-1': ['antigo'],
      });

      final seen = SeenDocuments('cook-1');
      await seen.markSeen(['novo']);

      expect(seen.ids, {'antigo', 'novo'});
    });

    test('guarda só os últimos, e descarta os mais velhos', () async {
      final seen = SeenDocuments('cook-1');
      await seen.markSeen([
        for (var i = 0; i < SeenDocuments.limit + 5; i++) 'doc-$i',
      ]);

      expect(seen.ids, hasLength(SeenDocuments.limit));
      expect(seen.ids, isNot(contains('doc-0')));
      expect(seen.ids, contains('doc-${SeenDocuments.limit + 4}'));
    });
  });
}
