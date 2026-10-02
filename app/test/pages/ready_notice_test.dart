import 'package:clock/clock.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mae/auth/auth_controller.dart';
import 'package:mae/auth/profile.dart';
import 'package:mae/documents/messages.dart';
import 'package:mae/local/app_database.dart';
import 'package:mae/local/documents_gateway.dart';
import 'package:mae/local/local_providers.dart';
import 'package:mae/routing/app_router.dart';
import 'package:mae/theme/theme.dart';
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

/// O aviso de documento pronto ao abrir o aplicativo (issue #110), com o
/// relógio fixado em 9 de setembro de 2026, 14h32.
void main() {
  late FakeAuthGateway auth;
  late FakeDocumentsGateway documents;
  late FakeDocumentSharer sharer;
  late FakeConnectivityGateway connectivity;
  late ProviderContainer container;

  final now = DateTime(2026, 9, 9, 14, 32);

  const cook = Profile(
    id: 'cook-1',
    name: 'Merendeira',
    email: 'merendeira@escola.com',
    role: 'cook',
    schoolId: 'school-1',
  );

  RemoteDocument remote(
    String id, {
    String status = 'available',
    DateTime? requestedAt,
    List<String> dates = const ['2026-09-01', '2026-09-02', '2026-09-03'],
  }) => RemoteDocument(
    id: id,
    status: status,
    requestedAt: requestedAt ?? now,
    completedAt: status == 'processing' ? null : requestedAt ?? now,
    expiresAt: status == 'available' ? now.add(const Duration(days: 7)) : null,
    filePath: status == 'available' ? 'escola/$id.docx' : null,
    fileName: status == 'available' ? '$id.docx' : null,
    dates: dates,
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    auth = FakeAuthGateway()..profileForUser = (_) => cook;
    documents = FakeDocumentsGateway();
    sharer = FakeDocumentSharer();
    connectivity = FakeConnectivityGateway();
    container = ProviderContainer(
      overrides: [
        authGatewayProvider.overrideWithValue(auth),
        documentsGatewayProvider.overrideWithValue(documents),
        documentSharerProvider.overrideWithValue(sharer),
        monthGatewayProvider.overrideWithValue(FakeMonthGateway()),
        syncGatewayProvider.overrideWithValue(FakeSyncGateway()),
        // A tela-casa e a fila conferem a versão mínima (issue #113).
        versionGatewayProvider.overrideWithValue(FakeVersionGateway()),
        generationGatewayProvider.overrideWithValue(FakeGenerationGateway()),
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

  Future<void> openApp(WidgetTester tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 2400);
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
  }

  Future<void> dispose(WidgetTester tester) async {
    container.read(syncEngineProvider(cook.id)).stop();
    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
  }

  final share = find.widgetWithText(FilledButton, 'Compartilhar');

  testWidgets('documento pronto que ela não viu aparece ao abrir', (
    tester,
  ) async {
    await withClock(Clock.fixed(now), () async {
      documents.documents = [remote('novo')];

      await openApp(tester);

      expect(find.text(ReadyNoticeMessages.single), findsOneWidget);
      expect(find.text('1 a 3 de setembro · 3 mapas'), findsOneWidget);
      expect(share, findsOneWidget);

      await dispose(tester);
    });
  });

  testWidgets('sem documento novo, não há aviso', (tester) async {
    await withClock(Clock.fixed(now), () async {
      documents.documents = [
        remote('falhou', status: 'failed'),
        remote('gerando', status: 'processing'),
      ];

      await openApp(tester);

      expect(find.text(ReadyNoticeMessages.single), findsNothing);
      expect(share, findsNothing);

      await dispose(tester);
    });
  });

  testWidgets('o que já foi visto no aparelho não avisa de novo', (
    tester,
  ) async {
    await withClock(Clock.fixed(now), () async {
      SharedPreferences.setMockInitialValues({
        'mae.seen_documents.cook-1': ['novo'],
      });
      documents.documents = [remote('novo')];

      await openApp(tester);

      expect(find.text(ReadyNoticeMessages.single), findsNothing);

      await dispose(tester);
    });
  });

  testWidgets('com mais de um, fala do mais novo e conta quantos são', (
    tester,
  ) async {
    await withClock(Clock.fixed(now), () async {
      documents.documents = [
        remote('novo'),
        remote(
          'velho',
          requestedAt: DateTime(2026, 9, 5),
          dates: const ['2026-08-31'],
        ),
      ];

      await openApp(tester);

      expect(find.text('2 documentos ficaram prontos'), findsOneWidget);
      expect(
        find.text('O mais recente é de 1 a 3 de setembro · 3 mapas.'),
        findsOneWidget,
      );

      await dispose(tester);
    });
  });

  testWidgets('"Compartilhar" leva à tela do documento, e o aviso some', (
    tester,
  ) async {
    await withClock(Clock.fixed(now), () async {
      documents.documents = [remote('novo')];
      await openApp(tester);

      await tester.tap(share);
      await tester.pumpAndSettle();

      // A tela do documento, com o cartão do que acabou de ficar pronto.
      expect(find.text(DocumentMessages.title), findsOneWidget);
      expect(find.text(DocumentMessages.justGenerated), findsOneWidget);

      container.read(appRouterProvider).pop();
      await tester.pumpAndSettle();

      expect(find.text(ReadyNoticeMessages.single), findsNothing);

      await dispose(tester);
    });
  });

  testWidgets('abrir os documentos pelo menu também dá o aviso por visto', (
    tester,
  ) async {
    await withClock(Clock.fixed(now), () async {
      documents.documents = [remote('novo')];
      await openApp(tester);

      container.read(appRouterProvider).push('/documentos');
      await tester.pumpAndSettle();
      container.read(appRouterProvider).pop();
      await tester.pumpAndSettle();

      expect(find.text(ReadyNoticeMessages.single), findsNothing);

      await dispose(tester);
    });
  });

  testWidgets('o X dispensa o aviso e guarda isso no aparelho', (tester) async {
    await withClock(Clock.fixed(now), () async {
      documents.documents = [remote('novo')];
      await openApp(tester);

      await tester.tap(find.byTooltip(ReadyNoticeMessages.dismiss));
      await tester.pumpAndSettle();

      expect(find.text(ReadyNoticeMessages.single), findsNothing);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList('mae.seen_documents.cook-1'), ['novo']);

      await dispose(tester);
    });
  });

  testWidgets('sem rede avisa do que já está no aparelho', (tester) async {
    await withClock(Clock.fixed(now), () async {
      documents.documents = [remote('novo')];
      await openApp(tester);
      await dispose(tester);

      // Segunda abertura, com a rede fora: a lista é a cópia local.
      documents.fetchError = Exception('sem rede');
      await openApp(tester);

      expect(find.text(ReadyNoticeMessages.single), findsOneWidget);

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
