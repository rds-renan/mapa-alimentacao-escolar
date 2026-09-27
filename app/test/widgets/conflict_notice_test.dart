import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mae/local/sync_engine.dart';
import 'package:mae/theme/theme.dart';
import 'package:mae/widgets/conflict_notice.dart';

void main() {
  testWidgets('sem conflito, nenhum aviso aparece', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: maeLightTheme,
        home: ConflictNotice(conflicts: const [], onDismiss: (_) {}),
      ),
    );

    expect(find.byType(ConflictNotice), findsOneWidget);
    expect(find.byType(TextButton), findsNothing);
  });

  testWidgets('mostra a mensagem do conflito, e "Entendi" a apaga', (
    tester,
  ) async {
    var dismissed = '';

    await tester.pumpWidget(
      MaterialApp(
        theme: maeLightTheme,
        home: ConflictNotice(
          conflicts: const [
            Conflict(
              mapDate: '2026-09-10',
              message:
                  'O dia 10/09 foi registrado em outro aparelho depois da '
                  'sua edição, e o que vale é o registro mais recente. '
                  'Confira se está como você deixou.',
              updatedAt: '2026-09-11T10:00:00+00:00',
            ),
          ],
          onDismiss: (mapDate) => dismissed = mapDate,
        ),
      ),
    );

    expect(find.textContaining('outro aparelho'), findsOneWidget);

    await tester.tap(find.text('Entendi'));
    await tester.pump();

    expect(dismissed, '2026-09-10');
  });

  testWidgets('um por dia: dois conflitos aparecem, dois "Entendi"', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: maeLightTheme,
        home: ConflictNotice(
          conflicts: const [
            Conflict(
              mapDate: '2026-09-10',
              message: 'Conflito do dia 10.',
              updatedAt: '2026-09-11T10:00:00+00:00',
            ),
            Conflict(
              mapDate: '2026-09-11',
              message: 'Conflito do dia 11.',
              updatedAt: '2026-09-12T10:00:00+00:00',
            ),
          ],
          onDismiss: (_) {},
        ),
      ),
    );

    expect(find.text('Conflito do dia 10.'), findsOneWidget);
    expect(find.text('Conflito do dia 11.'), findsOneWidget);
    expect(find.text('Entendi'), findsNWidgets(2));
  });
}
