import 'package:clock/clock.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mae/auth/auth_controller.dart';
import 'package:mae/auth/profile.dart';
import 'package:mae/local/app_database.dart';
import 'package:mae/local/local_providers.dart';
import 'package:mae/local/month_gateway.dart';
import 'package:mae/routing/app_router.dart';
import 'package:mae/theme/theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/fake_auth_gateway.dart';
import '../local/fake_month_gateway.dart';
import '../local/fake_sync_gateway.dart';

/// A tela central do produto (issue #105), critério por critério: as três
/// refeições com cardápio previsto e aceitação em três botões, o número de
/// refeições com teclado numérico, o dia não letivo só com observação, o
/// mapa bloqueado sem edição, e o botão voltar do Android de volta ao mês.
void main() {
  late FakeAuthGateway gateway;
  late FakeMonthGateway monthGateway;
  late FakeSyncGateway syncGateway;
  late ProviderContainer container;

  const cook = Profile(
    id: 'cook-1',
    name: 'Merendeira',
    email: 'merendeira@escola.com',
    role: 'cook',
    schoolId: 'school-1',
  );

  setUp(() {
    gateway = FakeAuthGateway()..profileForUser = (_) => cook;
    monthGateway = FakeMonthGateway();
    syncGateway = FakeSyncGateway();
    container = ProviderContainer(
      overrides: [
        authGatewayProvider.overrideWithValue(gateway),
        monthGatewayProvider.overrideWithValue(monthGateway),
        syncGatewayProvider.overrideWithValue(syncGateway),
        appDatabaseProvider.overrideWith(
          (ref, profileId) => AppDatabase(NativeDatabase.memory()),
        ),
      ],
    );
  });

  tearDown(() async {
    // Mesmo cuidado do `home_page_test.dart`: esperar o banco em memória
    // fechar antes do próximo teste abrir o dele.
    await container.read(appDatabaseProvider(cook.id)).close();
    container.dispose();
    gateway.dispose();
  });

  /// Abre a visão do mês já autenticada e toca no dia pedido — o mesmo
  /// caminho que a merendeira usa de verdade (CA#2 da US008).
  ///
  /// A janela do teste ganha altura de sobra: a tela é uma lista rolável, e
  /// testar rolagem por cima de cartões que abrem e fecham é frágil demais
  /// para o que se quer verificar aqui — cabe tudo à vista, e cada asserção
  /// já lida com o que está na tela de verdade.
  Future<void> openDay(WidgetTester tester, int day) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          theme: maeLightTheme,
          routerConfig: container.read(appRouterProvider),
        ),
      ),
    );
    await tester.pump();
    gateway.emitSession(_session(cook.id));
    await tester.pumpAndSettle();

    await tester.tap(find.text('$day').first);
    await tester.pumpAndSettle();
  }

  /// Descarta a árvore dentro do teste. Duas limpezas que o binding de teste
  /// exige antes do corpo do teste terminar: a fila (issue #103) agenda um
  /// `Timer` de 1,2s a cada tecla que deixa o dia em condição de subir, e o
  /// Drift agenda outro, de duração zero, ao cancelar a assinatura do fluxo.
  Future<void> dispose(WidgetTester tester) async {
    container.read(syncEngineProvider(cook.id)).stop();
    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
  }

  testWidgets(
    'as três refeições abrem, cada uma com o cardápio previsto e três '
    'botões de aceitação',
    (tester) async {
      await withClock(Clock.fixed(DateTime(2026, 9, 9)), () async {
        await openDay(tester, 1);

        expect(find.text('Lanche da manhã'), findsOneWidget);
        expect(find.text('Almoço'), findsOneWidget);
        expect(find.text('Lanche da tarde'), findsOneWidget);

        // Dia em branco: abre no lanche da manhã (a primeira refeição que
        // falta), com o campo e os três botões à vista.
        expect(find.text('Cardápio previsto'), findsOneWidget);
        expect(find.text('Ótimo'), findsOneWidget);
        expect(find.text('Bom'), findsOneWidget);
        expect(find.text('Ruim'), findsOneWidget);

        // É um acordeão — só um cartão aberto por vez (decisão 5 da E3) —,
        // mas os outros dois abrem do mesmo jeito.
        await tester.tap(find.text('Almoço'));
        await tester.pumpAndSettle();
        expect(find.text('Cardápio previsto'), findsOneWidget);

        await tester.tap(find.text('Lanche da tarde'));
        await tester.pumpAndSettle();
        expect(find.text('Cardápio previsto'), findsOneWidget);

        await dispose(tester);
      });
    },
  );

  testWidgets(
    'digitar e escolher a aceitação grava no aparelho sem botão de salvar',
    (tester) async {
      await withClock(Clock.fixed(DateTime(2026, 9, 9)), () async {
        await openDay(tester, 1);

        await tester.enterText(
          find.widgetWithText(
            TextField,
            'Toque para escrever o cardápio '
            'da refeição',
          ),
          'Pão com manteiga',
        );
        await tester.tap(find.text('Ótimo'));
        await tester.pump();

        expect(
          find.text('Salvo no aparelho. Envia sozinho quando houver internet.'),
          findsOneWidget,
        );

        await dispose(tester);
      });
    },
  );

  testWidgets('o número de refeições só aceita dígitos, com teclado numérico', (
    tester,
  ) async {
    await withClock(Clock.fixed(DateTime(2026, 9, 9)), () async {
      await openDay(tester, 1);
      expect(find.text('Refeições servidas no dia'), findsOneWidget);

      // É o único campo com teclado numérico na tela.
      final numericField = find.byWidgetPredicate(
        (widget) =>
            widget is TextField && widget.keyboardType == TextInputType.number,
      );
      expect(numericField, findsOneWidget);

      await tester.enterText(numericField, '3a12');
      await tester.pump();

      expect(find.text('312'), findsOneWidget);

      await dispose(tester);
    });
  });

  testWidgets(
    'marcar dia não letivo esconde as refeições e só pede a observação',
    (tester) async {
      await withClock(Clock.fixed(DateTime(2026, 9, 9)), () async {
        await openDay(tester, 1);

        expect(find.text('Lanche da manhã'), findsOneWidget);

        await tester.tap(find.byType(Switch));
        await tester.pumpAndSettle();

        expect(find.text('Lanche da manhã'), findsNothing);
        expect(find.text('Refeições servidas no dia'), findsNothing);
        expect(
          find.text('Escreva o motivo para este dia entrar no mapa.'),
          findsOneWidget,
        );

        await tester.enterText(
          find.widgetWithText(
            TextField,
            'Ex.: conselho de classe, sem '
            'atendimento aos alunos',
          ),
          'Conselho de classe',
        );
        await tester.pump();

        expect(
          find.text('Salvo no aparelho. Envia sozinho quando houver internet.'),
          findsOneWidget,
        );

        await dispose(tester);
      });
    },
  );

  testWidgets('mapa bloqueado mostra o estado e não admite edição', (
    tester,
  ) async {
    await withClock(Clock.fixed(DateTime(2026, 9, 9)), () async {
      monthGateway.maps = [
        RemoteMealMap(
          id: 'map-1',
          mapDate: DateTime(2026, 9, 3),
          nonSchoolDay: false,
          note: null,
          mealsServed: 300,
          locked: true,
          updatedAt: DateTime(2026, 9, 3, 18),
          meals: const [
            RemoteMeal(
              id: 'meal-1',
              type: 'lunch',
              description: 'Arroz e feijão',
              acceptance: 'great',
            ),
          ],
        ),
      ];

      await openDay(tester, 3);

      expect(
        find.textContaining('já está em um documento gerado'),
        findsOneWidget,
      );

      await tester.tap(find.text('Almoço'));
      await tester.pumpAndSettle();

      final description = tester.widget<TextField>(
        find.widgetWithText(TextField, 'Arroz e feijão'),
      );
      expect(description.enabled, isFalse);

      final acceptance = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Ótimo'),
      );
      expect(acceptance.onPressed, isNull);

      await dispose(tester);
    });
  });

  testWidgets('o botão voltar do Android volta à visão do mês (CA#5)', (
    tester,
  ) async {
    await withClock(Clock.fixed(DateTime(2026, 9, 9)), () async {
      await openDay(tester, 1);

      expect(find.text('Gerar documento'), findsNothing);

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.text('Gerar documento'), findsOneWidget);

      await dispose(tester);
    });
  });
}

Session _session(String userId) {
  return Session(
    accessToken: 'token-$userId',
    tokenType: 'bearer',
    user: User(
      id: userId,
      appMetadata: const {},
      userMetadata: const {},
      aud: 'authenticated',
      createdAt: DateTime.now().toIso8601String(),
    ),
  );
}
