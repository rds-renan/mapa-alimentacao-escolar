import 'package:clock/clock.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mae/auth/auth_controller.dart';
import 'package:mae/auth/profile.dart';
import 'package:mae/documents/document_sharer.dart';
import 'package:mae/documents/messages.dart';
import 'package:mae/local/app_database.dart';
import 'package:mae/local/documents_gateway.dart';
import 'package:mae/local/local_providers.dart';
import 'package:mae/routing/app_router.dart';
import 'package:mae/theme/theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/fake_auth_gateway.dart';
import '../documents/fake_documents.dart';
import '../documents/fake_generation_gateway.dart';
import '../local/fake_catalog_gateway.dart';
import '../local/fake_connectivity_gateway.dart';
import '../local/fake_month_gateway.dart';
import '../local/fake_sync_gateway.dart';

/// Os documentos gerados (issue #109), com o relógio fixado em 9 de setembro
/// de 2026, 14h32 — a situação de cada documento depende da data.
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

  /// Um documento no ar, gerado hoje, com os dias 1 a 3 de setembro.
  RemoteDocument remote(
    String id, {
    String status = 'available',
    DateTime? requestedAt,
    DateTime? expiresAt,
    List<String> dates = const ['2026-09-01', '2026-09-02', '2026-09-03'],
  }) => RemoteDocument(
    id: id,
    status: status,
    requestedAt: requestedAt ?? now,
    completedAt: status == 'processing' ? null : requestedAt ?? now,
    expiresAt: status == 'available'
        ? expiresAt ?? now.add(const Duration(days: 7))
        : null,
    filePath: status == 'available' ? 'escola/$id.docx' : null,
    fileName: status == 'available' ? '$id.docx' : null,
    dates: dates,
  );

  setUp(() {
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

  Future<void> openDocuments(
    WidgetTester tester, {
    String? justGenerated,
  }) async {
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

    container.read(appRouterProvider).push('/documentos', extra: justGenerated);
    await tester.pumpAndSettle();
  }

  Future<void> dispose(WidgetTester tester) async {
    container.read(syncEngineProvider(cook.id)).stop();
    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
  }

  final shareButton = find.widgetWithText(OutlinedButton, 'Compartilhar');

  testWidgets('lista os documentos com período, situação e prazo', (
    tester,
  ) async {
    await withClock(Clock.fixed(now), () async {
      documents.documents = [
        remote('novo'),
        remote(
          'amanha',
          requestedAt: DateTime(2026, 9, 3),
          expiresAt: DateTime(2026, 9, 10, 8),
          dates: const ['2026-08-31'],
        ),
        remote(
          'vencido',
          requestedAt: DateTime(2026, 8, 20),
          expiresAt: DateTime(2026, 8, 27),
          dates: const ['2026-08-10', '2026-08-11'],
        ),
      ];

      await openDocuments(tester);

      expect(find.text('1 a 3 de setembro'), findsOneWidget);
      expect(find.text('3 mapas · gerado hoje, 14h32'), findsOneWidget);
      expect(find.text('Disponível'), findsOneWidget);
      expect(find.text('Sai do ar em 16 de setembro'), findsOneWidget);
      expect(find.text('Sai amanhã'), findsOneWidget);

      // O vencido aparece, mas como indisponível: sem botão (CA#2).
      expect(find.text('10 a 11 de agosto'), findsOneWidget);
      expect(find.text('Fora do ar'), findsOneWidget);
      expect(find.text(DocumentMessages.expiredNote), findsOneWidget);
      expect(shareButton, findsNWidgets(2));

      await dispose(tester);
    });
  });

  testWidgets('a geração que falhou e a em curso não oferecem arquivo', (
    tester,
  ) async {
    await withClock(Clock.fixed(now), () async {
      documents.documents = [
        remote('falhou', status: 'failed'),
        remote('gerando', status: 'processing'),
      ];

      await openDocuments(tester);

      expect(find.text('Não saiu'), findsOneWidget);
      expect(find.text(DocumentMessages.failedNote), findsOneWidget);
      expect(find.text('Gerando'), findsOneWidget);
      expect(find.text(DocumentMessages.processingNote), findsOneWidget);
      expect(find.text('Compartilhar'), findsNothing);

      await dispose(tester);
    });
  });

  testWidgets('Compartilhar entrega o arquivo à folha do Android', (
    tester,
  ) async {
    await withClock(Clock.fixed(now), () async {
      documents.documents = [remote('novo')];
      await openDocuments(tester);

      await tester.tap(shareButton);
      await tester.pumpAndSettle();

      expect(sharer.calls.single.filePath, 'escola/novo.docx');
      expect(sharer.calls.single.fileName, 'novo.docx');

      await dispose(tester);
    });
  });

  testWidgets('se o arquivo não vem, diz que ele continua no ar', (
    tester,
  ) async {
    await withClock(Clock.fixed(now), () async {
      documents.documents = [remote('novo')];
      sharer.failure = const DocumentFileFailure(DocumentMessages.fileFailed);
      await openDocuments(tester);

      await tester.tap(shareButton);
      await tester.pumpAndSettle();

      expect(find.text(DocumentMessages.fileFailed), findsOneWidget);

      await dispose(tester);
    });
  });

  testWidgets(
    'sem rede, a lista abre do aparelho e compartilhar fica desabilitado',
    (tester) async {
      await withClock(Clock.fixed(now), () async {
        documents.documents = [remote('novo')];
        await openDocuments(tester);
        await dispose(tester);

        // Segunda abertura: o servidor não responde e a rede caiu.
        documents.fetchError = Exception('sem rede');
        connectivity.setOnline(false);
        await openDocuments(tester);

        expect(find.text('1 a 3 de setembro'), findsOneWidget);
        expect(find.text(DocumentMessages.offline), findsOneWidget);
        expect(find.text(DocumentMessages.loadFailed), findsNothing);
        expect(tester.widget<OutlinedButton>(shareButton).onPressed, isNull);

        await dispose(tester);
      });
    },
  );

  testWidgets('sem nada no aparelho e sem rede, a falha tem saída', (
    tester,
  ) async {
    documents.fetchError = Exception('sem rede');
    await openDocuments(tester);

    expect(find.text(DocumentMessages.loadFailed), findsOneWidget);

    documents
      ..fetchError = null
      ..documents = [remote('novo')];
    await tester.tap(find.text('Tentar de novo'));
    await tester.pumpAndSettle();

    expect(find.text(DocumentMessages.loadFailed), findsNothing);

    await dispose(tester);
  });

  testWidgets('sem documentos, convida a gerar o primeiro', (tester) async {
    await withClock(Clock.fixed(now), () async {
      await openDocuments(tester);

      expect(find.textContaining(DocumentMessages.empty), findsOneWidget);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Gerar documento'));
      await tester.pumpAndSettle();

      expect(find.text('Gerar documento'), findsWidgets);
      expect(find.text('Gerar o documento de setembro?'), findsNothing);

      await dispose(tester);
    });
  });

  testWidgets('o recém-gerado vira a tela 6: confirmação, nome e bloqueio', (
    tester,
  ) async {
    await withClock(Clock.fixed(now), () async {
      documents.documents = [
        remote('novo'),
        remote('antigo', requestedAt: DateTime(2026, 9, 2)),
      ];

      await openDocuments(tester, justGenerated: 'novo');

      expect(find.text(DocumentMessages.justGenerated), findsOneWidget);
      expect(find.text('novo.docx'), findsOneWidget);
      expect(find.text(lockedNotice(3)), findsOneWidget);
      expect(find.text(DocumentMessages.expireNote), findsOneWidget);

      // E só ele: o outro cartão é a lista de sempre.
      expect(find.text('antigo.docx'), findsNothing);
      expect(find.widgetWithText(FilledButton, 'Compartilhar'), findsOneWidget);

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
