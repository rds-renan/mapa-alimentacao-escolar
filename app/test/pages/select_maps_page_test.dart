import 'package:clock/clock.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mae/auth/auth_controller.dart';
import 'package:mae/auth/profile.dart';
import 'package:mae/documents/generation_gateway.dart';
import 'package:mae/local/app_database.dart';
import 'package:mae/local/day.dart';
import 'package:mae/local/local_providers.dart';
import 'package:mae/local/month_gateway.dart';
import 'package:mae/local/sync_queue_store.dart';
import 'package:mae/routing/app_router.dart';
import 'package:mae/theme/theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/fake_auth_gateway.dart';
import '../documents/fake_generation_gateway.dart';
import '../local/fake_catalog_gateway.dart';
import '../local/fake_connectivity_gateway.dart';
import '../local/fake_month_gateway.dart';
import '../local/fake_sync_gateway.dart';

/// A seleção de mapas e o pedido de geração (issue #108), com o relógio
/// fixado em setembro de 2026 — o mês de 22 dias úteis (terça 1º a quarta
/// 30), em que cada semana e cada dia têm lugar certo.
void main() {
  late FakeAuthGateway auth;
  late FakeMonthGateway monthGateway;
  late FakeSyncGateway syncGateway;
  late FakeGenerationGateway generation;
  late FakeConnectivityGateway connectivity;
  late ProviderContainer container;

  const cook = Profile(
    id: 'cook-1',
    name: 'Merendeira',
    email: 'merendeira@escola.com',
    role: 'cook',
    schoolId: 'school-1',
  );

  /// Os ids das refeições são chave primária: dois dias não podem
  /// repartir os mesmos.
  List<RemoteMeal> meals(int day, {int count = 3}) => [
    for (final (index, (type, acceptance)) in [
      ('morning_snack', 'great'),
      ('lunch', 'great'),
      ('afternoon_snack', 'good'),
    ].indexed.take(count))
      RemoteMeal(
        id: 'meal-$day-$index',
        type: type,
        description: 'Comida',
        acceptance: acceptance,
      ),
  ];

  setUp(() {
    auth = FakeAuthGateway()..profileForUser = (_) => cook;
    monthGateway = FakeMonthGateway();
    syncGateway = FakeSyncGateway();
    generation = FakeGenerationGateway();
    connectivity = FakeConnectivityGateway();
    container = ProviderContainer(
      overrides: [
        authGatewayProvider.overrideWithValue(auth),
        monthGatewayProvider.overrideWithValue(monthGateway),
        syncGatewayProvider.overrideWithValue(syncGateway),
        generationGatewayProvider.overrideWithValue(generation),
        catalogGatewayProvider.overrideWithValue(FakeCatalogGateway()),
        connectivityGatewayProvider.overrideWithValue(connectivity),
        appDatabaseProvider.overrideWith(
          (ref, profileId) => AppDatabase(NativeDatabase.memory()),
        ),
      ],
    );
  });

  tearDown(() async {
    await container.read(appDatabaseProvider(cook.id)).close();
    container.dispose();
    auth.dispose();
    connectivity.dispose();
  });

  RemoteMealMap map(int day, {bool locked = false, int mealCount = 3}) =>
      RemoteMealMap(
        id: 'map-$day',
        mapDate: DateTime(2026, 9, day),
        nonSchoolDay: false,
        note: null,
        mealsServed: 300,
        locked: locked,
        updatedAt: DateTime(2026, 9, day),
        meals: meals(day, count: mealCount),
      );

  /// Os 22 dias úteis de setembro, todos preenchidos. `without` tira dias
  /// (ficam sem registro); `replace` troca um deles.
  List<RemoteMealMap> fullMonth({
    Set<int> without = const {},
    Map<int, RemoteMealMap> replace = const {},
  }) => [
    for (var day = 1; day <= 30; day++)
      if (DateTime(2026, 9, day).weekday <= 5 && !without.contains(day))
        replace[day] ?? map(day),
  ];

  Future<void> openSelection(WidgetTester tester) async {
    // Tela alta o bastante para a lista inteira existir: o `ListView` só
    // monta o que cabe na janela.
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 3600);
    addTearDown(tester.view.reset);

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
    auth.emitSession(_session('cook-1'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Gerar documento'));
    await tester.pumpAndSettle();
  }

  /// Descarta a árvore e a fila dentro do teste: o Drift cancela a assinatura
  /// com um `Timer`, e o reenvio da fila agenda outro.
  Future<void> dispose(WidgetTester tester) async {
    container.read(syncEngineProvider(cook.id)).stop();
    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
  }

  final generateButton = find.widgetWithText(FilledButton, 'Gerar documento');

  testWidgets('abre com o mês inteiro marcado, sem nenhum toque (RNF#1)', (
    tester,
  ) async {
    await withClock(Clock.fixed(DateTime(2026, 9, 9)), () async {
      monthGateway.maps = fullMonth();
      await openSelection(tester);

      expect(find.text('Escolha os mapas de setembro de 2026'), findsOneWidget);
      expect(find.text('22 mapas selecionados'), findsOneWidget);
      expect(_enabled(tester, generateButton), isTrue);

      await dispose(tester);
    });
  });

  testWidgets('dia já no documento continua selecionável e vai junto', (
    tester,
  ) async {
    await withClock(Clock.fixed(DateTime(2026, 9, 9)), () async {
      monthGateway.maps = fullMonth(replace: {3: map(3, locked: true)});
      await openSelection(tester);

      expect(find.text('No documento'), findsOneWidget);
      expect(find.text('22 mapas selecionados'), findsOneWidget);

      await dispose(tester);
    });
  });

  testWidgets(
    'mês com dia pendente: não seleciona nada e o aviso nomeia o dia',
    (tester) async {
      await withClock(Clock.fixed(DateTime(2026, 9, 9)), () async {
        monthGateway.maps = fullMonth(replace: {3: map(3, mealCount: 1)});
        await openSelection(tester);

        expect(find.text('Nenhum mapa selecionado'), findsOneWidget);
        expect(
          find.text('Ainda falta 1 dia para fechar setembro.'),
          findsOneWidget,
        );
        expect(find.text('3 de setembro · pendente'), findsOneWidget);
        expect(_enabled(tester, generateButton), isFalse);

        await dispose(tester);
      });
    },
  );

  testWidgets('dia sem registro também é buraco do mês', (tester) async {
    await withClock(Clock.fixed(DateTime(2026, 9, 9)), () async {
      monthGateway.maps = fullMonth(without: {4});
      await openSelection(tester);

      expect(find.text('4 de setembro · sem registro'), findsOneWidget);
      expect(find.text('Nenhum mapa selecionado'), findsOneWidget);

      await dispose(tester);
    });
  });

  testWidgets(
    'modo Semana: a semana inteira num toque; a incompleta não marca',
    (tester) async {
      await withClock(Clock.fixed(DateTime(2026, 9, 9)), () async {
        monthGateway.maps = fullMonth(replace: {10: map(10, mealCount: 1)});
        await openSelection(tester);

        await tester.tap(find.text('Semana'));
        await tester.pumpAndSettle();
        expect(find.text('Nenhum mapa selecionado'), findsOneWidget);

        // Semana 1: 1 a 4 (4 dias). A semana 2 tem o dia 10 pendente.
        await tester.tap(find.text('Semana 1 · 1 a 4 de setembro'));
        await tester.pumpAndSettle();
        expect(find.text('4 mapas selecionados'), findsOneWidget);

        expect(find.text('falta 1 dia'), findsOneWidget);
        await tester.tap(find.text('Semana 2 · 7 a 11 de setembro'));
        await tester.pumpAndSettle();
        expect(find.text('4 mapas selecionados'), findsOneWidget);

        await dispose(tester);
      });
    },
  );

  testWidgets('modo Escolher dias aceita avulsos e recusa o pendente', (
    tester,
  ) async {
    await withClock(Clock.fixed(DateTime(2026, 9, 9)), () async {
      monthGateway.maps = fullMonth(replace: {2: map(2, mealCount: 1)});
      await openSelection(tester);

      await tester.tap(find.text('Escolher dias'));
      await tester.pumpAndSettle();
      expect(find.text('Nenhum mapa selecionado'), findsOneWidget);

      await tester.tap(find.text('QUA, 2'));
      await tester.pumpAndSettle();
      expect(find.text('Nenhum mapa selecionado'), findsOneWidget);

      await tester.tap(find.text('TER, 1'));
      await tester.tap(find.text('QUI, 3'));
      await tester.pumpAndSettle();
      expect(find.text('2 mapas selecionados'), findsOneWidget);

      await tester.tap(find.text('TER, 1'));
      await tester.pumpAndSettle();
      expect(find.text('1 mapa selecionado'), findsOneWidget);

      await dispose(tester);
    });
  });

  testWidgets(
    'dia esperando enviar fica fora do documento, e "Enviar agora" o sobe',
    (tester) async {
      await withClock(Clock.fixed(DateTime(2026, 9, 9)), () async {
        // O servidor ainda não tem o dia 1; o aparelho tem, completo.
        monthGateway.maps = fullMonth(without: {1});
        await SyncQueueStore(container.read(appDatabaseProvider(cook.id)))
            .put(_completeDraft('2026-09-01'));
        // A primeira tentativa da fila, ao abrir, falha: ela ainda está sem
        // sinal.
        syncGateway.enqueueError(Exception('sem rede'));

        await openSelection(tester);

        expect(find.text('Esperando enviar'), findsOneWidget);
        expect(
          find.textContaining('Tem 1 dia salvo neste aparelho'),
          findsOneWidget,
        );
        expect(find.text('Nenhum mapa selecionado'), findsOneWidget);

        // Agora o servidor passa a ter o dia, e a fila consegue subir.
        monthGateway.maps = fullMonth();
        syncGateway.enqueueSaved({
          'status': 'saved',
          'meal_map_id': 'map-1',
          'sent_meal_map_id': 'local-1',
          'map_date': '2026-09-01',
          'locked': false,
          'updated_at': '2026-09-01T10:00:00.000',
          'updated_by': null,
          'food_items': <Map<String, dynamic>>[],
        });

        await tester.tap(find.text('Enviar agora'));
        await tester.pumpAndSettle();

        expect(find.text('Esperando enviar'), findsNothing);
        expect(find.text('Enviar agora'), findsNothing);
        expect(find.text('22 mapas selecionados'), findsOneWidget);

        await dispose(tester);
      });
    },
  );

  testWidgets('sem rede, a tela explica a espera e o botão fica desabilitado', (
    tester,
  ) async {
    await withClock(Clock.fixed(DateTime(2026, 9, 9)), () async {
      connectivity.setOnline(false);
      monthGateway.maps = fullMonth();
      await openSelection(tester);

      expect(
        find.textContaining('Sem internet não dá para gerar o documento'),
        findsOneWidget,
      );
      expect(find.text('22 mapas selecionados'), findsNothing);
      expect(_enabled(tester, generateButton), isFalse);

      // A rede volta: a explicação sai e o botão acende, sem reabrir a tela.
      connectivity.setOnline(true);
      await tester.pumpAndSettle();
      expect(find.text('22 mapas selecionados'), findsOneWidget);
      expect(_enabled(tester, generateButton), isTrue);

      await dispose(tester);
    });
  });

  testWidgets('a confirmação diz período e bloqueio; Voltar não gera nada', (
    tester,
  ) async {
    await withClock(Clock.fixed(DateTime(2026, 9, 9)), () async {
      monthGateway.maps = fullMonth();
      await openSelection(tester);

      await tester.tap(generateButton);
      await tester.pumpAndSettle();

      expect(find.text('Gerar o documento de setembro?'), findsOneWidget);
      expect(
        find.text(
          'Os 22 mapas incluídos ficam bloqueados para edição depois de '
          'gerar. Se ainda falta corrigir algum, é agora.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Voltar'));
      await tester.pumpAndSettle();

      expect(generation.calls, isEmpty);
      expect(find.text('Gerar o documento de setembro?'), findsNothing);

      await dispose(tester);
    });
  });

  testWidgets('Gerar manda os 22 dias e leva aos documentos gerados', (
    tester,
  ) async {
    await withClock(Clock.fixed(DateTime(2026, 9, 9)), () async {
      monthGateway.maps = fullMonth();
      await openSelection(tester);

      await tester.tap(generateButton);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Gerar'));
      await tester.pumpAndSettle();

      expect(generation.calls, hasLength(1));
      expect(generation.calls.single, hasLength(22));
      expect(generation.calls.single, contains('map-1'));
      expect(find.text('Documentos gerados'), findsWidgets);
      expect(find.text('Gerar o documento de setembro?'), findsNothing);

      await dispose(tester);
    });
  });

  testWidgets(
    'a geração falha: diz que nada foi bloqueado, e Tentar de novo repete',
    (tester) async {
      await withClock(Clock.fixed(DateTime(2026, 9, 9)), () async {
        monthGateway.maps = fullMonth();
        generation.failures.add(
          const GenerationFailure(
            'A escola ainda não tem um modelo oficial cadastrado.',
          ),
        );
        await openSelection(tester);

        await tester.tap(generateButton);
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(FilledButton, 'Gerar'));
        await tester.pumpAndSettle();

        expect(find.text('Não deu para gerar o documento'), findsOneWidget);
        expect(
          find.textContaining('modelo oficial cadastrado.'),
          findsOneWidget,
        );
        expect(find.textContaining('nenhum foi bloqueado'), findsOneWidget);

        await tester.tap(find.text('Tentar de novo'));
        await tester.pumpAndSettle();

        expect(generation.calls, hasLength(2));
        expect(generation.calls.last, generation.calls.first);
        expect(find.text('Não deu para gerar o documento'), findsNothing);

        await dispose(tester);
      });
    },
  );
}

bool _enabled(WidgetTester tester, Finder finder) =>
    tester.widget<FilledButton>(finder).onPressed != null;

DayPayload _completeDraft(String mapDate) => DayPayload(
  id: 'local-1',
  mapDate: mapDate,
  updatedAt: '2026-09-01T10:00:00.000',
  nonSchoolDay: false,
  note: null,
  mealsServed: 300,
  meals: [
    for (final (index, type) in [
      'morning_snack',
      'lunch',
      'afternoon_snack',
    ].indexed)
      MealPayload(
        id: 'local-meal-$index',
        type: type,
        description: 'Comida',
        acceptance: 'great',
        foodItems: const [],
        menuChange: null,
      ),
  ],
);

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
