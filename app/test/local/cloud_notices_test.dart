import 'package:flutter_test/flutter_test.dart';
import 'package:mae/local/cloud_notices.dart';
import 'package:mae/local/sync_engine.dart';
import 'package:mae/local/sync_messages.dart';

DaySyncState _state(SyncStatus status) =>
    DaySyncState(status: status, message: syncMessages[status]!);

void main() {
  late List<String> shown;
  late CloudNotices notices;

  setUp(() {
    shown = [];
    notices = CloudNotices(show: shown.add);
  });

  tearDown(() => notices.dispose());

  // Os testes que esperam o tempo passar rodam dentro de `testWidgets`, que
  // tem relógio falso: o `Timer` da espera anda com `tester.pump`.

  testWidgets('dia que ela ainda não tocou não avisa nada', (tester) async {
    notices.update(null);
    await tester.pump(const Duration(seconds: 5));

    expect(shown, isEmpty);
  });

  testWidgets('digitando com rede, "Salvo na nuvem." aparece uma vez só', (
    tester,
  ) async {
    // Cada gravação passa por "Salvo no seu celular…" antes de subir.
    for (var i = 0; i < 4; i++) {
      notices.update(_state(SyncStatus.pending));
      await tester.pump(const Duration(milliseconds: 1200));
      notices.update(_state(SyncStatus.sent));
    }
    await tester.pump(const Duration(seconds: 5));

    expect(shown, [syncMessages[SyncStatus.sent]]);
  });

  testWidgets(
    '"Salvo no seu celular…" só aparece se durar, e a volta da rede avisa',
    (tester) async {
      notices.update(_state(SyncStatus.sent));
      notices.update(_state(SyncStatus.pending));
      await tester.pump(const Duration(seconds: 2));
      expect(shown, [syncMessages[SyncStatus.sent]]);

      await tester.pump(const Duration(seconds: 1));
      expect(shown, [
        syncMessages[SyncStatus.sent],
        syncMessages[SyncStatus.pending],
      ]);

      // Outras gravações sem rede repetem a mesma frase: caladas.
      notices.update(_state(SyncStatus.pending));
      await tester.pump(const Duration(seconds: 5));

      notices.update(_state(SyncStatus.sent));
      expect(shown, [
        syncMessages[SyncStatus.sent],
        syncMessages[SyncStatus.pending],
        syncMessages[SyncStatus.sent],
      ]);
    },
  );

  testWidgets('o mesmo estado notificado de novo não recomeça a espera', (
    tester,
  ) async {
    notices.update(_state(SyncStatus.pending));
    await tester.pump(const Duration(seconds: 2));
    // A fila notifica de outro dia; o deste continua igual.
    notices.update(_state(SyncStatus.pending));
    await tester.pump(const Duration(seconds: 1));

    expect(shown, [syncMessages[SyncStatus.pending]]);
  });

  test('falha e versão desatualizada avisam na hora', () {
    notices.update(_state(SyncStatus.failed));
    notices.update(_state(SyncStatus.outdated));

    expect(shown, [
      syncMessages[SyncStatus.failed],
      syncMessages[SyncStatus.outdated],
    ]);
  });

  test('quando o banco recusa, a frase da recusa vem antes da explicação', () {
    notices.update(
      const DaySyncState(
        status: SyncStatus.failed,
        message: rejectedMessage,
        detail: 'A quantidade de "Pão" precisa ser maior que zero.',
      ),
    );

    expect(shown, [
      '$rejectedMessage A quantidade de "Pão" precisa ser maior que zero.',
    ]);
  });
}
