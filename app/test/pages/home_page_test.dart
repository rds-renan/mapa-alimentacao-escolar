import 'package:clock/clock.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mae/auth/auth_controller.dart';
import 'package:mae/auth/profile.dart';
import 'package:mae/day/messages.dart' show dayTitle;
import 'package:mae/local/app_database.dart';
import 'package:mae/local/local_providers.dart';
import 'package:mae/local/month_gateway.dart';
import 'package:mae/routing/app_router.dart';
import 'package:mae/theme/theme.dart';
import 'package:mae/theme/theme_preference.dart';
import 'package:mae/version/version_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/fake_auth_gateway.dart';
import '../documents/fake_documents.dart';
import '../documents/fake_generation_gateway.dart';
import '../local/fake_catalog_gateway.dart';
import '../local/fake_connectivity_gateway.dart';
import '../local/fake_month_gateway.dart';
import '../local/fake_sync_gateway.dart';
import '../version/fake_version_gateway.dart';

/// A visão do mês e o menu (issue #104), com o relógio fixado em 9 de
/// setembro de 2026 (uma quarta-feira) — o mês que a tela abre, o destaque de
/// "hoje" e a quebra das semanas dependem todos da data.
void main() {
  late FakeAuthGateway gateway;
  late FakeMonthGateway monthGateway;
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
    container = ProviderContainer(
      overrides: [
        authGatewayProvider.overrideWithValue(gateway),
        monthGatewayProvider.overrideWithValue(monthGateway),
        // O toque num dia empurra para o registro (issue #105), que já liga
        // a fila de envio — sem este falso, o provedor de verdade tentaria
        // o Supabase que este teste nunca inicializa.
        syncGatewayProvider.overrideWithValue(FakeSyncGateway()),
        // A tela-casa e a fila conferem a versão mínima (issue #113).
        versionGatewayProvider.overrideWithValue(FakeVersionGateway()),
        // A seleção de mapas (issue #108) lê a porta da geração ao abrir.
        generationGatewayProvider.overrideWithValue(FakeGenerationGateway()),
        // "Documentos gerados" lê a lista (issue #109).
        documentsGatewayProvider.overrideWithValue(FakeDocumentsGateway()),
        documentSharerProvider.overrideWithValue(FakeDocumentSharer()),
        // "Gerenciar gêneros" abre a manutenção do catálogo (issue #107),
        // que lê o catálogo e pergunta pela rede.
        catalogGatewayProvider.overrideWithValue(FakeCatalogGateway()),
        connectivityGatewayProvider.overrideWithValue(
          FakeConnectivityGateway(),
        ),
        appDatabaseProvider.overrideWith(
          (ref, profileId) => AppDatabase(NativeDatabase.memory()),
        ),
      ],
    );
  });

  tearDown(() async {
    // `container.dispose()` fecha o banco em memória por baixo (`onDispose`
    // em `appDatabaseProvider`), mas sem esperar a promessa: sem este
    // `await`, o próximo teste abre o dele antes do anterior terminar de
    // fechar, e o Drift avisa (com razão) de dois bancos vivos ao mesmo
    // tempo.
    await container.read(appDatabaseProvider(cook.id)).close();
    container.dispose();
    gateway.dispose();
  });

  Future<void> pumpHome(WidgetTester tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: Consumer(
          builder: (context, ref, _) => MaterialApp.router(
            theme: maeLightTheme,
            darkTheme: maeDarkTheme,
            themeMode: ref.watch(themePreferenceProvider).mode,
            routerConfig: container.read(appRouterProvider),
          ),
        ),
      ),
    );
    await tester.pump();
    gateway.emitSession(_session('cook-1'));
    await tester.pumpAndSettle();
  }

  /// Descarta a árvore dentro do teste: a assinatura do Drift cancela com um
  /// `Timer` de duração zero, e o binding de teste explode se ele ainda
  /// estiver pendente quando o corpo do teste termina.
  Future<void> dispose(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
  }

  RemoteMealMap map({
    required String id,
    required DateTime mapDate,
    bool nonSchoolDay = false,
    String? note,
    int? mealsServed,
    bool locked = false,
    List<RemoteMeal> meals = const [],
  }) => RemoteMealMap(
    id: id,
    mapDate: mapDate,
    nonSchoolDay: nonSchoolDay,
    note: note,
    mealsServed: mealsServed,
    locked: locked,
    updatedAt: mapDate,
    meals: meals,
  );

  const threeMeals = [
    RemoteMeal(
      id: 'm1',
      type: 'morning_snack',
      description: 'Pão',
      acceptance: 'great',
    ),
    RemoteMeal(
      id: 'm2',
      type: 'lunch',
      description: 'Arroz e feijão',
      acceptance: 'great',
    ),
    RemoteMeal(
      id: 'm3',
      type: 'afternoon_snack',
      description: 'Fruta',
      acceptance: 'good',
    ),
  ];

  testWidgets(
    'os cinco estados aparecem na lista, cada um com etiqueta própria',
    (tester) async {
      await withClock(Clock.fixed(DateTime(2026, 9, 9)), () async {
        monthGateway.maps = [
          map(
            id: 'complete',
            mapDate: DateTime(2026, 9, 1),
            mealsServed: 300,
            meals: threeMeals,
          ),
          map(
            id: 'non-school',
            mapDate: DateTime(2026, 9, 2),
            nonSchoolDay: true,
            note: 'Conselho de classe',
          ),
          map(id: 'locked', mapDate: DateTime(2026, 9, 3), locked: true),
          // 4 de setembro (sexta) fica vazio de propósito: sem entrada nenhuma.
        ];

        await pumpHome(tester);

        expect(find.text('Preenchido'), findsOneWidget);
        expect(find.text('Não letivo'), findsOneWidget);
        expect(find.text('No documento'), findsOneWidget);
        expect(find.text('Pendente'), findsNothing);
        expect(find.text('Vazio'), findsWidgets);

        await dispose(tester);
      });
    },
  );

  testWidgets(
    'funciona sem rede com o que já está no aparelho (CA#3 da issue #104)',
    (tester) async {
      await withClock(Clock.fixed(DateTime(2026, 9, 9)), () async {
        monthGateway.maps = [
          map(
            id: 'map-1',
            mapDate: DateTime(2026, 9, 1),
            mealsServed: 300,
            meals: threeMeals,
          ),
        ];

        await pumpHome(tester);
        expect(find.text('Preenchido'), findsOneWidget);

        // "Reabre" a tela sem rede: o gateway do servidor passa a falhar.
        monthGateway.fetchError = Exception('sem rede');
        await dispose(tester);
        await pumpHome(tester);

        expect(find.text('Preenchido'), findsOneWidget);

        await dispose(tester);
      });
    },
  );

  testWidgets('toque num dia abre o registro daquele dia (CA#2 da US008)', (
    tester,
  ) async {
    await withClock(Clock.fixed(DateTime(2026, 9, 9)), () async {
      await pumpHome(tester);

      await tester.tap(find.text('1').first);
      await tester.pumpAndSettle();

      expect(find.text(dayTitle('2026-09-01')), findsOneWidget);

      await dispose(tester);
    });
  });

  testWidgets(
    'toque num dia bloqueado também abre: somente leitura não é inalcançável',
    (tester) async {
      await withClock(Clock.fixed(DateTime(2026, 9, 9)), () async {
        monthGateway.maps = [
          map(id: 'locked', mapDate: DateTime(2026, 9, 3), locked: true),
        ];
        await pumpHome(tester);

        await tester.tap(find.text('3').first);
        await tester.pumpAndSettle();

        expect(find.text(dayTitle('2026-09-03')), findsOneWidget);

        await dispose(tester);
      });
    },
  );

  testWidgets('navegação entre meses troca o título', (tester) async {
    await withClock(Clock.fixed(DateTime(2026, 9, 9)), () async {
      await pumpHome(tester);

      expect(find.text('Setembro de 2026'), findsOneWidget);

      await tester.tap(find.byTooltip('Próximo mês'));
      await tester.pumpAndSettle();
      expect(find.text('Outubro de 2026'), findsOneWidget);

      await tester.tap(find.byTooltip('Mês anterior'));
      await tester.tap(find.byTooltip('Mês anterior'));
      await tester.pumpAndSettle();
      expect(find.text('Agosto de 2026'), findsOneWidget);

      await dispose(tester);
    });
  });

  testWidgets(
    '"Gerar documento" abre a seleção com o mês que ela estava vendo (#108)',
    (tester) async {
      await withClock(Clock.fixed(DateTime(2026, 9, 9)), () async {
        await pumpHome(tester);

        await tester.tap(find.byTooltip('Próximo mês'));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(FilledButton, 'Gerar documento'));
        await tester.pumpAndSettle();

        expect(
          find.text('Escolha os mapas de outubro de 2026'),
          findsOneWidget,
        );

        container.read(syncEngineProvider(cook.id)).stop();
        await dispose(tester);
      });
    },
  );

  group('menu', () {
    testWidgets('um toque abre e reúne os itens da decisão 9 da E3', (
      tester,
    ) async {
      await withClock(Clock.fixed(DateTime(2026, 9, 9)), () async {
        await pumpHome(tester);

        await tester.tap(find.byTooltip('Abrir o menu'));
        await tester.pumpAndSettle();

        expect(find.text('Merendeira'), findsOneWidget);
        expect(find.text('merendeira@escola.com'), findsOneWidget);
        expect(find.text('Documentos gerados'), findsOneWidget);
        expect(find.text('Gerenciar gêneros'), findsOneWidget);
        expect(find.text('Tema'), findsOneWidget);
        for (final option in ['Claro', 'Escuro', 'Sistema']) {
          expect(find.text(option), findsOneWidget);
        }
        expect(find.text('Sair'), findsOneWidget);

        // Nenhum caminho para a área da direção (RN#1 da US020).
        expect(find.textContaining('Painel'), findsNothing);
        expect(find.textContaining('Gestão'), findsNothing);

        await dispose(tester);
      });
    });

    testWidgets('escolher o tema escurece a tela na hora e fica guardado', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await withClock(Clock.fixed(DateTime(2026, 9, 9)), () async {
        await pumpHome(tester);

        await tester.tap(find.byTooltip('Abrir o menu'));
        await tester.pumpAndSettle();

        Brightness brightness() =>
            Theme.of(tester.element(find.text('Tema'))).brightness;
        expect(brightness(), Brightness.light);

        await tester.tap(find.text('Escuro'));
        await tester.pumpAndSettle();

        expect(brightness(), Brightness.dark);
        expect(await loadThemePreference(), ThemePreference.dark);

        await tester.tap(find.text('Claro'));
        await tester.pumpAndSettle();

        expect(brightness(), Brightness.light);
        expect(await loadThemePreference(), ThemePreference.light);

        await dispose(tester);
      });
    });

    testWidgets('"Documentos gerados" leva à lista de documentos', (
      tester,
    ) async {
      await withClock(Clock.fixed(DateTime(2026, 9, 9)), () async {
        await pumpHome(tester);

        await tester.tap(find.byTooltip('Abrir o menu'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Documentos gerados'));
        await tester.pumpAndSettle();

        expect(
          find.text('O arquivo fica disponível por 7 dias'),
          findsOneWidget,
        );

        await dispose(tester);
      });
    });

    testWidgets('"Gerenciar gêneros" leva à manutenção do catálogo', (
      tester,
    ) async {
      await withClock(Clock.fixed(DateTime(2026, 9, 9)), () async {
        await pumpHome(tester);

        await tester.tap(find.byTooltip('Abrir o menu'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Gerenciar gêneros'));
        await tester.pumpAndSettle();

        expect(find.text('Catálogo de gêneros'), findsOneWidget);

        await dispose(tester);
      });
    });

    testWidgets('sair encerra a sessão e volta para o login', (tester) async {
      await withClock(Clock.fixed(DateTime(2026, 9, 9)), () async {
        await pumpHome(tester);

        await tester.tap(find.byTooltip('Abrir o menu'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Sair'));
        await tester.pumpAndSettle();

        expect(find.text('Entrar'), findsWidgets);

        await dispose(tester);
      });
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
