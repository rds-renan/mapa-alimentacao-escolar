import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mae/auth/auth_controller.dart';
import 'package:mae/auth/profile.dart';
import 'package:mae/local/app_database.dart';
import 'package:mae/local/catalog_gateway.dart';
import 'package:mae/local/local_providers.dart';
import 'package:mae/pages/food_items_page.dart';
import 'package:mae/theme/theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/fake_auth_gateway.dart';
import '../local/fake_catalog_gateway.dart';
import '../local/fake_connectivity_gateway.dart';

/// A manutenção do catálogo (issue #107), critério por critério: listar,
/// cadastrar, editar, desativar e reativar; a unidade em texto com as
/// pílulas como sugestão; o aviso de que trocar a unidade reescreve os dias
/// já registrados; e a lista que se lê sem rede enquanto alterar exige.
void main() {
  late FakeAuthGateway auth;
  late FakeCatalogGateway catalog;
  late FakeConnectivityGateway connectivity;
  late ProviderContainer container;

  const cook = Profile(
    id: 'cook-1',
    name: 'Merendeira',
    email: 'merendeira@escola.com',
    role: 'cook',
    schoolId: 'school-1',
  );

  const initial = [
    RemoteFoodItem(id: 'rice', name: 'Arroz', unit: 'quilo', active: true),
    RemoteFoodItem(id: 'beans', name: 'Feijão', unit: 'quilo', active: true),
    RemoteFoodItem(id: 'salt', name: 'Sal', unit: 'pacote', active: false),
  ];

  setUp(() {
    auth = FakeAuthGateway()..profileForUser = (_) => cook;
    catalog = FakeCatalogGateway()..items = initial;
    connectivity = FakeConnectivityGateway();
    container = ProviderContainer(
      overrides: [
        authGatewayProvider.overrideWithValue(auth),
        catalogGatewayProvider.overrideWithValue(catalog),
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

  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Entra direto na tela, já com a sessão: o roteador tem outra cobertura.
    container.read(authControllerProvider);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(theme: maeLightTheme, home: const FoodItemsPage()),
      ),
    );
    auth.emitSession(_session(cook.id));
    await tester.pumpAndSettle();
  }

  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
  }

  final nameField = find.widgetWithText(TextField, 'Nome');
  final unitField = find.widgetWithText(TextField, 'Unidade padrão');

  testWidgets('lista os gêneros com a unidade, e os desativados recolhidos', (
    tester,
  ) async {
    await open(tester);

    expect(find.text('Arroz'), findsOneWidget);
    expect(find.text('Feijão'), findsOneWidget);
    expect(find.text('Desativados (1)'), findsOneWidget);
    expect(find.text('Sal'), findsNothing);

    await tester.tap(find.text('Desativados (1)'));
    await tester.pumpAndSettle();
    expect(find.text('Sal'), findsOneWidget);

    await close(tester);
  });

  testWidgets('a lista se lê sem rede e a tela diz que alterar exige rede', (
    tester,
  ) async {
    // O catálogo já foi baixado num dia com rede; hoje a atualização falha.
    await container.read(catalogRepositoryProvider(cook.id)).refresh();
    catalog.fetchError = Exception('sem rede');
    await open(tester);
    connectivity.setOnline(false);
    await tester.pumpAndSettle();

    // A lista continua à mão…
    expect(find.text('Arroz'), findsOneWidget);
    expect(find.textContaining('Sem internet'), findsOneWidget);

    // …e o cadastro, completo, não deixa enviar.
    await tester.enterText(nameField, 'Macarrão');
    await tester.tap(find.widgetWithText(ChoiceChip, 'saco'));
    await tester.pump();

    final add = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(add.onPressed, isNull);

    await close(tester);
  });

  testWidgets('cadastra com a pílula de sugestão', (tester) async {
    await open(tester);

    await tester.enterText(nameField, 'Macarrão');
    await tester.tap(find.widgetWithText(ChoiceChip, 'saco'));
    await tester.pump();
    await tester.tap(find.text('Adicionar ao catálogo'));
    await tester.pumpAndSettle();

    expect(catalog.saved.single['name'], 'Macarrão');
    expect(catalog.saved.single['unit'], 'saco');
    expect(catalog.saved.single['schoolId'], 'school-1');
    expect(find.text('Macarrão'), findsOneWidget);

    await close(tester);
  });

  testWidgets('a unidade é texto livre', (tester) async {
    await open(tester);

    await tester.enterText(nameField, 'Ovo');
    await tester.enterText(unitField, 'bandeja');
    await tester.pump();
    await tester.tap(find.text('Adicionar ao catálogo'));
    await tester.pumpAndSettle();

    expect(catalog.saved.single['unit'], 'bandeja');

    await close(tester);
  });

  testWidgets('nome repetido é dito antes de tentar', (tester) async {
    await open(tester);

    await tester.enterText(nameField, 'arroz');
    await tester.enterText(unitField, 'quilo');
    await tester.pump();

    expect(find.textContaining('já está no catálogo'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );

    await tester.enterText(nameField, 'sal');
    await tester.pump();
    expect(find.textContaining('entre os desativados'), findsOneWidget);

    await close(tester);
  });

  testWidgets('tocar uma linha edita; trocar a unidade avisa', (tester) async {
    await open(tester);

    await tester.tap(find.bySemanticsLabel('Editar Arroz'));
    await tester.pumpAndSettle();

    expect(find.text('Editar gênero'), findsOneWidget);
    expect(find.textContaining('Mudar a unidade'), findsNothing);

    await tester.enterText(unitField, 'saco');
    await tester.pump();
    expect(find.textContaining('Mudar a unidade'), findsOneWidget);

    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(catalog.saved.single['id'], 'rice');
    expect(catalog.saved.single['unit'], 'saco');
    expect(find.text('Novo gênero'), findsOneWidget);

    await close(tester);
  });

  testWidgets('gravação recusada mantém o formulário', (tester) async {
    await open(tester);
    catalog.saveError = Exception('caiu');

    await tester.enterText(nameField, 'Macarrão');
    await tester.enterText(unitField, 'saco');
    await tester.pump();
    await tester.tap(find.text('Adicionar ao catálogo'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Não deu para salvar agora'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Macarrão'), findsOneWidget);

    await close(tester);
  });

  testWidgets('desativa, abre os desativados, e reativa', (tester) async {
    await open(tester);

    await tester.tap(find.bySemanticsLabel('Editar Arroz'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Desativar'));
    await tester.pumpAndSettle();

    expect(find.text('Desativados (2)'), findsOneWidget);
    expect(find.bySemanticsLabel('Editar Arroz'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Editar Arroz'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reativar'));
    await tester.pumpAndSettle();

    expect(find.text('Desativados (1)'), findsOneWidget);

    await close(tester);
  });

  testWidgets('a busca ignora acento e corta as duas listas', (tester) async {
    await open(tester);

    await tester.enterText(
      find.widgetWithText(TextField, 'Buscar gênero'),
      'feijao',
    );
    await tester.pump();

    expect(find.text('Feijão'), findsOneWidget);
    expect(find.text('Arroz'), findsNothing);
    expect(find.textContaining('Desativados'), findsNothing);

    await close(tester);
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
