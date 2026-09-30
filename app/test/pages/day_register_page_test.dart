import 'package:clock/clock.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mae/auth/auth_controller.dart';
import 'package:mae/auth/profile.dart';
import 'package:mae/local/app_database.dart';
import 'package:mae/local/day.dart';
import 'package:mae/local/local_providers.dart';
import 'package:mae/local/month_gateway.dart';
import 'package:mae/routing/app_router.dart';
import 'package:mae/theme/theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/fake_auth_gateway.dart';
import '../local/fake_catalog_gateway.dart';
import '../local/fake_month_gateway.dart';
import '../local/fake_sync_gateway.dart';

/// A tela central do produto (issues #105 e #106), critério por critério: as
/// três refeições com cardápio previsto e aceitação em três botões, o número
/// de refeições com teclado numérico, o dia não letivo só com observação, o
/// mapa bloqueado sem edição, o botão voltar do Android de volta ao mês — e
/// os gêneros com stepper, a folha de escolher gênero e a alteração do
/// cardápio.
void main() {
  late FakeAuthGateway gateway;
  late FakeMonthGateway monthGateway;
  late FakeSyncGateway syncGateway;
  late FakeCatalogGateway catalogGateway;
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
    catalogGateway = FakeCatalogGateway();
    container = ProviderContainer(
      overrides: [
        authGatewayProvider.overrideWithValue(gateway),
        monthGatewayProvider.overrideWithValue(monthGateway),
        syncGatewayProvider.overrideWithValue(syncGateway),
        catalogGatewayProvider.overrideWithValue(catalogGateway),
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

  /// O catálogo já no aparelho, como se tivesse sido baixado antes. A folha
  /// pede atualização ao abrir, e o gateway falso devolve lista vazia — o
  /// que não apaga nada, como na vida real.
  Future<void> seedCatalog() async {
    final db = container.read(appDatabaseProvider(cook.id));
    await db.batch((batch) {
      batch.insertAll(db.foodItems, [
        FoodItemsCompanion.insert(
          id: 'rice',
          name: 'Arroz',
          unit: 'quilo',
          active: true,
        ),
        FoodItemsCompanion.insert(
          id: 'beans',
          name: 'Feijão',
          unit: 'quilo',
          active: true,
        ),
        FoodItemsCompanion.insert(
          id: 'egg',
          name: 'Ovo',
          unit: 'bandeja',
          active: true,
        ),
        FoodItemsCompanion.insert(
          id: 'salt',
          name: 'Sal',
          unit: 'pacote',
          active: false,
        ),
      ]);
    });
  }

  /// O botão da alteração, enquanto ela não existe — o rótulo também é o
  /// título da seção quando ela existe, então o botão é achado pelo tipo.
  final menuChangeButton = find.widgetWithText(
    OutlinedButton,
    'Alteração do cardápio',
  );

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

  testWidgets(
    'gêneros entram pela folha com busca, em 1, e o stepper anda em inteiros',
    (tester) async {
      await withClock(Clock.fixed(DateTime(2026, 9, 9)), () async {
        await seedCatalog();
        await openDay(tester, 1);

        expect(find.text('Gêneros utilizados'), findsOneWidget);
        await tester.tap(find.text('Adicionar gênero'));
        await tester.pumpAndSettle();

        expect(find.text('Escolher gênero'), findsOneWidget);
        expect(find.text('Arroz'), findsOneWidget);
        // Desativado some das sugestões (CA#3 da US009).
        expect(find.text('Sal'), findsNothing);

        // A busca ignora acento.
        await tester.enterText(
          find.widgetWithText(TextField, 'Buscar gênero'),
          'feijao',
        );
        await tester.pumpAndSettle();
        expect(find.text('Arroz'), findsNothing);

        await tester.tap(find.text('Feijão'));
        await tester.pumpAndSettle();

        expect(find.text('Escolher gênero'), findsNothing);
        expect(find.text('Feijão'), findsOneWidget);
        expect(find.widgetWithText(TextField, '1'), findsOneWidget);

        await tester.tap(find.byTooltip('Um a mais de Feijão'));
        await tester.pump();
        expect(find.widgetWithText(TextField, '2'), findsOneWidget);

        await tester.tap(find.byTooltip('Um a menos de Feijão'));
        await tester.pump();
        await tester.tap(find.byTooltip('Tirar Feijão da lista'));
        await tester.pump();
        expect(find.text('Feijão'), findsNothing);

        await dispose(tester);
      });
    },
  );

  testWidgets(
    'o gênero que já está na refeição aparece marcado e não entra de novo',
    (tester) async {
      await withClock(Clock.fixed(DateTime(2026, 9, 9)), () async {
        await seedCatalog();
        await openDay(tester, 1);

        await tester.tap(find.text('Adicionar gênero'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Arroz'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Adicionar gênero'));
        await tester.pumpAndSettle();
        expect(find.text('já está aqui'), findsOneWidget);

        await tester.tap(find.byTooltip('Fechar a escolha de gênero'));
        await tester.pumpAndSettle();

        await dispose(tester);
      });
    },
  );

  testWidgets('sem rede, cadastra o gênero novo na folha e ele entra na '
      'refeição', (tester) async {
    await withClock(Clock.fixed(DateTime(2026, 9, 9)), () async {
      catalogGateway.fetchError = Exception('sem rede');
      await openDay(tester, 1);

      await tester.tap(find.text('Adicionar gênero'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('O catálogo ainda não foi baixado'),
        findsOneWidget,
      );

      // O que ela buscou já vira o nome do cadastro.
      await tester.enterText(
        find.widgetWithText(TextField, 'Buscar gênero'),
        'Farinha de mandioca',
      );
      await tester.pumpAndSettle();

      final add = find.widgetWithText(FilledButton, 'Adicionar à refeição');
      expect(tester.widget<FilledButton>(add).onPressed, isNull);

      await tester.tap(find.widgetWithText(ChoiceChip, 'quilo'));
      await tester.pumpAndSettle();
      await tester.tap(add);
      await tester.pumpAndSettle();

      expect(find.text('Farinha de mandioca'), findsOneWidget);
      expect(find.text('quilo'), findsOneWidget);

      final draft = await container
          .read(syncEngineProvider(cook.id))
          .load('2026-09-01');
      final item = draft!.meals.single.foodItems.single;
      expect(item.foodItemId, isNull);
      expect(item.name, 'Farinha de mandioca');
      expect(item.unit, 'quilo');
      expect(item.quantity, 1);

      await dispose(tester);
    });
  });

  testWidgets(
    'a alteração do cardápio guarda gêneros e motivo, e vira resumo no '
    'cartão — uma só por refeição',
    (tester) async {
      await withClock(Clock.fixed(DateTime(2026, 9, 9)), () async {
        await seedCatalog();
        await openDay(tester, 1);

        await tester.tap(menuChangeButton);
        await tester.pumpAndSettle();

        expect(
          find.textContaining('continua registrado como o cardápio previsto'),
          findsOneWidget,
        );
        expect(find.text('Gêneros utilizados na troca'), findsOneWidget);

        // A folha 3b sobe por cima da tela 3a.
        await tester.tap(find.text('Adicionar gênero'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Ovo'));
        await tester.pumpAndSettle();

        expect(find.text('Ovo'), findsOneWidget);
        expect(
          find.text('Escreva o motivo para esta alteração entrar no mapa.'),
          findsOneWidget,
        );

        await tester.tap(find.text('Falta de entrega do fornecedor'));
        await tester.pumpAndSettle();
        expect(
          find.text('Escreva o motivo para esta alteração entrar no mapa.'),
          findsNothing,
        );

        await tester.tap(find.text('Confirmar alteração'));
        await tester.pumpAndSettle();

        // De volta ao cartão: o resumo no lugar do botão, e sem botão para
        // uma segunda alteração (RN#2 da US002).
        expect(find.text('1 bandeja de ovo'), findsOneWidget);
        expect(find.text('Falta de entrega do fornecedor'), findsOneWidget);
        expect(menuChangeButton, findsNothing);

        final draft = await container
            .read(syncEngineProvider(cook.id))
            .load('2026-09-01');
        final change = draft!.meals.single.menuChange!;
        expect(change.reason, 'Falta de entrega do fornecedor');
        expect(change.foodItems.single.foodItemId, 'egg');
        // A troca não mexe nos gêneros da refeição (decisão 7 da E4).
        expect(draft.meals.single.foodItems, isEmpty);

        // Tocar no resumo reabre a mesma alteração para editar.
        await tester.tap(find.text('1 bandeja de ovo'));
        await tester.pumpAndSettle();
        expect(find.text('Ovo'), findsOneWidget);
        await tester.tap(find.text('Confirmar alteração'));
        await tester.pumpAndSettle();

        await dispose(tester);
      });
    },
  );

  testWidgets('cancelar a alteração devolve o que havia antes de abrir', (
    tester,
  ) async {
    await withClock(Clock.fixed(DateTime(2026, 9, 9)), () async {
      await seedCatalog();
      await openDay(tester, 1);

      await tester.tap(menuChangeButton);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Toque para escrever o motivo da troca'),
        'Item impróprio',
      );
      await tester.pump();

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(menuChangeButton, findsOneWidget);
      expect(find.text('Item impróprio'), findsNothing);

      final draft = await container
          .read(syncEngineProvider(cook.id))
          .load('2026-09-01');
      expect(draft!.meals.single.menuChange, isNull);

      await dispose(tester);
    });
  });

  testWidgets('fechar a alteração sem nada dentro não deixa alteração vazia', (
    tester,
  ) async {
    await withClock(Clock.fixed(DateTime(2026, 9, 9)), () async {
      await openDay(tester, 1);

      await tester.tap(menuChangeButton);
      await tester.pumpAndSettle();
      final reason = find.widgetWithText(
        TextField,
        'Toque para escrever o motivo da troca',
      );
      await tester.enterText(reason, 'Item');
      await tester.pump();
      await tester.enterText(find.byType(TextField).last, '');
      await tester.pump();

      // O botão voltar do Android, que é confirmar.
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(menuChangeButton, findsOneWidget);
      final draft = await container
          .read(syncEngineProvider(cook.id))
          .load('2026-09-01');
      expect(draft!.meals.single.menuChange, isNull);

      await dispose(tester);
    });
  });

  testWidgets('mapa bloqueado mostra gêneros e alteração só para consulta', (
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
              foodItems: [
                FoodItemPayload(
                  foodItemId: 'rice',
                  name: 'Arroz',
                  unit: 'quilo',
                  quantity: 4,
                ),
              ],
              menuChange: MenuChangePayload(
                id: 'change-1',
                reason: 'Item impróprio',
                foodItems: [
                  FoodItemPayload(
                    foodItemId: 'egg',
                    name: 'Ovo',
                    unit: 'bandeja',
                    quantity: 3,
                  ),
                ],
              ),
            ),
          ],
        ),
      ];

      await openDay(tester, 3);
      await tester.tap(find.text('Almoço'));
      await tester.pumpAndSettle();

      expect(find.text('Arroz'), findsOneWidget);
      expect(find.text('Adicionar gênero'), findsNothing);
      expect(
        tester
            .widget<IconButton>(
              find.widgetWithIcon(IconButton, Icons.add).first,
            )
            .onPressed,
        isNull,
      );
      expect(find.text('3 bandejas de ovo'), findsOneWidget);

      await tester.tap(find.text('3 bandejas de ovo'));
      await tester.pumpAndSettle();

      expect(find.text('Cancelar'), findsNothing);
      expect(find.text('Remover a alteração'), findsNothing);
      await tester.tap(find.widgetWithText(FilledButton, 'Fechar'));
      await tester.pumpAndSettle();

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
