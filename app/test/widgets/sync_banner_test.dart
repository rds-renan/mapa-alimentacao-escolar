import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mae/local/sync_engine.dart';
import 'package:mae/local/sync_messages.dart';
import 'package:mae/theme/theme.dart';
import 'package:mae/widgets/sync_banner.dart';

void main() {
  Future<void> pump(WidgetTester tester, DaySyncState? status) {
    return tester.pumpWidget(
      MaterialApp(
        theme: maeLightTheme,
        home: SyncBanner(status: status),
      ),
    );
  }

  testWidgets('dia que ela ainda não tocou não mostra faixa nenhuma', (
    tester,
  ) async {
    await pump(tester, null);

    expect(find.byType(SyncBanner), findsOneWidget);
    expect(find.text(syncMessages[SyncStatus.pending]!), findsNothing);
  });

  testWidgets('mostra as três frases da E3, ao pé da letra', (tester) async {
    for (final status in SyncStatus.values) {
      await pump(
        tester,
        DaySyncState(status: status, message: syncMessages[status]!),
      );
      expect(find.text(syncMessages[status]!), findsOneWidget);
    }
  });

  testWidgets(
    'quando a recusa tem explicação própria, a frase do servidor entra '
    'depois da terceira',
    (tester) async {
      await pump(
        tester,
        const DaySyncState(
          status: SyncStatus.failed,
          message:
              'Ainda não deu para enviar. Nada foi perdido, vamos '
              'tentar de novo.',
          detail: 'A quantidade de "Pão" precisa ser maior que zero.',
        ),
      );

      expect(
        find.textContaining(
          'A quantidade de "Pão" precisa ser maior que zero.',
        ),
        findsOneWidget,
      );
    },
  );
}
