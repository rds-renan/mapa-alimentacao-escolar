import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mae/local/app_database.dart';
import 'package:mae/day/register.dart' show setMealsServed, touch;
import 'package:mae/local/day.dart';
import 'package:mae/local/day_repository.dart';
import 'package:mae/local/month_gateway.dart';
import 'package:mae/local/month_repository.dart';
import 'package:mae/local/sync_engine.dart';
import 'package:mae/local/sync_messages.dart';
import 'package:mae/local/sync_queue_store.dart';
import 'package:mae/version/version_gate.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import 'fake_connectivity_gateway.dart';
import 'fake_month_gateway.dart';
import 'fake_sync_gateway.dart';
import '../version/fake_version_gateway.dart';

/*
 * A fila é o que quebra em silêncio neste produto: um mapa que não subiu não
 * reclama, e ninguém descobre até o dia da entrega do documento. Por isso a
 * decisão 13 da E6 aponta para cá o peso dos testes da etapa — mesmo
 * raciocínio de `web/src/local/sync.test.ts`.
 *
 * O servidor é de mentira, mas o contrato é o de verdade: as respostas e os
 * códigos de erro daqui são os que `save_meal_map` devolve, como está
 * descrito em docs/05-web/gravacao-do-dia.md.
 */

const _date = '2026-09-10';

DayPayload _dayFor(String updatedAt, {String mapDate = _date}) => DayPayload(
  id: 'a0000000-0000-4000-8000-000000000001',
  mapDate: mapDate,
  updatedAt: updatedAt,
  nonSchoolDay: false,
  note: null,
  mealsServed: 312,
  meals: const [
    MealPayload(
      id: 'b0000000-0000-4000-8000-000000000001',
      type: 'morning_snack',
      description: 'Pão com manteiga e leite com achocolatado',
      acceptance: 'great',
      foodItems: [
        FoodItemPayload(
          foodItemId: null,
          name: 'Pão',
          unit: 'quilo',
          quantity: 4,
        ),
      ],
      menuChange: null,
    ),
  ],
);

// O "Pão" de [_dayFor] vai sem identificador, e a resposta de verdade traz
// todo gênero citado no dia.
const _bread = {
  'sent_id': null,
  'id': '5005748a-0000-4000-8000-000000000001',
  'name': 'Pão',
  'unit': 'quilo',
  'created': true,
};

Map<String, dynamic> _saved({
  String mealMapId = 'c0000010-0000-4000-8000-000000000010',
  List<Map<String, dynamic>> foodItems = const [_bread],
}) => {
  'status': 'saved',
  'meal_map_id': mealMapId,
  'sent_meal_map_id': 'a0000000-0000-4000-8000-000000000001',
  'map_date': _date,
  'locked': false,
  'updated_at': '2026-09-10T21:30:00+00:00',
  'updated_by': '22222222-2222-4222-8222-222222222222',
  'food_items': foodItems,
};

Map<String, dynamic> _superseded({
  required String updatedAt,
  String updatedBy = '33333333-3333-4333-8333-333333333333',
}) => {
  'status': 'superseded',
  'meal_map_id': 'c0000010-0000-4000-8000-000000000010',
  'sent_meal_map_id': 'a0000000-0000-4000-8000-000000000001',
  'map_date': _date,
  'locked': false,
  'updated_at': updatedAt,
  'updated_by': updatedBy,
  'food_items': const [],
};

void main() {
  // `engine.start()` usa `AppLifecycleListener`, que pede o binding do
  // Flutter mesmo fora de um `testWidgets`.
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late SyncQueueStore store;
  late FakeSyncGateway gateway;
  late FakeConnectivityGateway connectivity;
  late SyncEngine engine;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    store = SyncQueueStore(db);
    gateway = FakeSyncGateway();
    connectivity = FakeConnectivityGateway();
    engine = SyncEngine(store, gateway, connectivity: connectivity);
  });

  tearDown(() {
    engine.stop();
    connectivity.dispose();
    return db.close();
  });

  group('o rascunho no aparelho', () {
    test('guarda cada alteração sem botão de salvar, e sobrevive a reabrir o '
        'aplicativo', () async {
      await engine.save(_dayFor('2026-09-10T18:30:00-03:00'));

      // "Reabrir o aplicativo" é um motor novo sobre o mesmo banco
      // (CA#3 da US010) — o processo pode ter morrido, o arquivo continua.
      final reopened = SyncEngine(store, gateway, connectivity: connectivity);
      final draft = await reopened.load(_date);

      expect(draft?.mealsServed, 312);
      expect(draft?.meals[0].description, contains('Pão com manteiga'));
    });
  });

  group('a fila de envio', () {
    test(
      'sobe o dia inteiro numa chamada e só então o tira do aparelho',
      () async {
        gateway.enqueueSaved(_saved());

        await engine.save(_dayFor('2026-09-10T18:30:00-03:00'));
        await engine.flush();

        expect(gateway.calls, hasLength(1));
        expect(gateway.calls.single['map_date'], _date);
        expect(await store.get(_date), isNull);
        expect(engine.state.pending, 0);
        expect(
          engine.state.days[_date]?.message,
          syncMessages[SyncStatus.sent],
        );
      },
    );

    test('reenvia com a mesma carga, e o dia entregue não vira registro '
        'duplicado', () async {
      // A rede caiu entre a gravação e a confirmação: o aparelho reenvia
      // sem saber se chegou.
      gateway.enqueueError(Exception('Failed to fetch'));
      gateway.enqueueSaved(_saved());

      await engine.save(_dayFor('2026-09-10T18:30:00-03:00'));

      await engine.flush();
      expect(
        engine.state.days[_date]?.message,
        syncMessages[SyncStatus.failed],
      );
      expect(await store.get(_date), isNotNull);

      await engine.flush();

      // A carga é idêntica, com o mesmo carimbo de edição — é isso que faz
      // o servidor reescrever o mesmo dia em vez de criar um segundo.
      expect(gateway.calls, hasLength(2));
      expect(gateway.calls[1], gateway.calls[0]);
      expect(await store.get(_date), isNull);
    });

    test(
      'não tenta enviar sem rede, e a faixa diz que está salvo no aparelho',
      () async {
        connectivity.setOnline(false);

        await engine.save(_dayFor('2026-09-10T18:30:00-03:00'));
        await engine.flush();

        expect(gateway.calls, isEmpty);
        expect(
          engine.state.days[_date]?.message,
          syncMessages[SyncStatus.pending],
        );
      },
    );

    test('reenvia sozinha quando a rede volta, sem a usuária pedir', () async {
      connectivity.setOnline(false);
      gateway.enqueueSaved(_saved());

      engine.start();
      await engine.save(_dayFor('2026-09-10T18:30:00-03:00'));
      await engine.flush();
      expect(gateway.calls, isEmpty);

      // A conectividade avisa que a internet voltou. Ninguém tocou em nada
      // (CA#1 da US011).
      connectivity.setOnline(true);
      await Future<void>.delayed(Duration.zero);
      await engine.flush();

      expect(gateway.calls, hasLength(1));
      expect(await store.get(_date), isNull);
    });

    test('adota o identificador que o servidor devolveu, e não descarta a '
        'tecla que veio no meio', () async {
      // Ela continuou digitando enquanto o envio estava no ar. O dia
      // confirmado não é mais o que está no aparelho: o que fica guardado
      // é o mais novo — já com o gênero que o servidor criou, para o
      // próximo envio achar o registro em vez de tentar criá-lo de novo.
      gateway.beforeRespond = () =>
          engine.save(_dayFor('2026-09-10T18:35:00-03:00'));
      gateway.enqueueSaved(
        _saved(
          foodItems: [
            {
              'sent_id': null,
              'id': '5005748a-0000-4000-8000-000000000001',
              'name': 'Pão',
              'unit': 'quilo',
              'created': true,
            },
          ],
        ),
      );

      await engine.save(_dayFor('2026-09-10T18:30:00-03:00'));
      await engine.flush();

      final stored = await store.get(_date);
      expect(stored?.day.updatedAt, '2026-09-10T18:35:00-03:00');
      expect(stored?.day.id, 'c0000010-0000-4000-8000-000000000010');
      expect(
        stored?.day.meals[0].foodItems[0].foodItemId,
        '5005748a-0000-4000-8000-000000000001',
      );
    });
  });

  group('a convergência entre aparelhos', () {
    test('sinaliza o conflito e nunca o resolve em silêncio', () async {
      gateway.enqueueSaved(_superseded(updatedAt: '2026-09-11T10:00:00+00:00'));

      await engine.save(_dayFor('2026-09-10T18:30:00-03:00'));
      await engine.flush();

      final conflict = engine.state.conflicts.single;
      expect(conflict.mapDate, _date);
      expect(conflict.message, contains('10/09'));
      expect(conflict.message, contains('outro aparelho'));
      expect(conflict.updatedAt, '2026-09-11T10:00:00+00:00');

      // Prevalece a edição mais recente: o dia sai do aparelho. O que não
      // acontece é sair calado.
      expect(await store.get(_date), isNull);

      engine.dismissConflict(_date);
      expect(engine.state.conflicts, isEmpty);
    });

    test(
      'avisa do conflito sem descartar a tecla que veio durante o envio',
      () async {
        gateway.beforeRespond = () =>
            engine.save(_dayFor('2026-09-10T19:00:00-03:00'));
        gateway.enqueueSaved(
          _superseded(updatedAt: '2026-09-10T18:45:00-03:00'),
        );
        gateway.enqueueSaved(_saved());

        await engine.save(_dayFor('2026-09-10T18:30:00-03:00'));
        await engine.flush();

        // Quem perdeu a convergência foi a edição de 18:30, que era a que
        // estava subindo. A de 19:00 é mais nova que a do outro aparelho e
        // ainda tem de subir — apagá-la junto seria perder o que ela acabou de
        // digitar.
        expect(engine.state.conflicts, hasLength(1));
        final stored = await store.get(_date);
        expect(stored?.day.updatedAt, '2026-09-10T19:00:00-03:00');

        await engine.flush();
        expect(await store.get(_date), isNull);
      },
    );
  });

  group('as recusas do servidor', () {
    test(
      'para de insistir no que não se resolve reenviando, sem jogar o dia fora',
      () async {
        gateway.enqueueError(
          PostgrestException(
            code: '23514',
            message: 'A quantidade de "Pão" precisa ser maior que zero.',
          ),
        );

        await engine.save(_dayFor('2026-09-10T18:30:00-03:00'));
        await engine.flush();
        await engine.flush();

        // Uma tentativa só: reenviar daria exatamente o mesmo erro.
        expect(gateway.calls, hasLength(1));

        // Mas o que ela digitou continua no aparelho, esperando a correção.
        expect(await store.get(_date), isNotNull);

        final day = engine.state.days[_date];
        expect(day?.message, syncMessages[SyncStatus.failed]);
        expect(
          day?.detail,
          'A quantidade de "Pão" precisa ser maior que zero.',
        );
      },
    );

    test('volta a tentar assim que ela corrige', () async {
      gateway.enqueueError(
        PostgrestException(
          code: '23514',
          message: 'A quantidade precisa ser maior que zero.',
        ),
      );
      gateway.enqueueSaved(_saved());

      await engine.save(_dayFor('2026-09-10T18:30:00-03:00'));
      await engine.flush();

      await engine.save(_dayFor('2026-09-10T18:40:00-03:00'));
      await engine.flush();

      expect(gateway.calls, hasLength(2));
      expect(await store.get(_date), isNull);
    });

    test('continua na fila quando dois aparelhos criam o mesmo dia no mesmo '
        'instante', () async {
      gateway.enqueueError(
        PostgrestException(
          code: '40001',
          message: 'Outro aparelho gravou este dia neste instante.',
        ),
      );
      gateway.enqueueSaved(_saved());

      await engine.save(_dayFor('2026-09-10T18:30:00-03:00'));
      await engine.flush();

      expect(await store.get(_date), isNotNull);

      await engine.flush();
      expect(gateway.calls, hasLength(2));
      expect(await store.get(_date), isNull);
    });
  });

  /*
   * O meio do caminho do dia não letivo: ela marcou a alternância e ainda
   * está indo escrever o motivo. O servidor recusaria isso (23514), e a
   * faixa diria "ainda não deu para enviar" para quem não fez nada de
   * errado — então a fila guarda e espera.
   */
  group('o dia que ainda não pode subir', () {
    DayPayload nonSchoolDay(String note) => DayPayload(
      id: 'a0000000-0000-4000-8000-000000000001',
      mapDate: _date,
      updatedAt: '2026-09-10T18:30:00-03:00',
      nonSchoolDay: true,
      note: note,
      mealsServed: null,
      meals: const [],
    );

    test(
      'guarda no aparelho o dia não letivo sem observação, e não o envia',
      () async {
        await engine.save(nonSchoolDay(''));
        await engine.flush();

        expect(gateway.calls, isEmpty);
        expect((await engine.load(_date))?.nonSchoolDay, isTrue);
        expect(engine.state.pending, 1);
        expect(
          engine.state.days[_date]?.message,
          syncMessages[SyncStatus.pending],
        );
      },
    );

    test('sobe assim que o motivo existe', () async {
      gateway.enqueueSaved(_saved());

      await engine.save(nonSchoolDay(''));
      await engine.flush();
      await engine.save(nonSchoolDay('Conselho de classe'));
      await engine.flush();

      expect(gateway.calls, hasLength(1));
      expect(await store.get(_date), isNull);
    });
  });

  group('a versão mínima (issue #113)', () {
    late FakeVersionGateway versions;
    late VersionGate gate;

    setUp(() {
      versions = FakeVersionGateway(minimum: 1);
      gate = VersionGate(currentBuild: 3, gateway: versions);
      engine.stop();
      engine = SyncEngine(
        store,
        gateway,
        connectivity: connectivity,
        version: gate,
      );
    });

    tearDown(() => gate.dispose());

    test('confere a versão antes de mandar, e no mínimo manda', () async {
      gateway.enqueueSaved(_saved());

      await engine.save(_dayFor('2026-09-10T18:30:00-03:00'));
      await engine.flush();

      expect(versions.calls, 1);
      expect(gateway.calls, hasLength(1));
      expect(await store.get(_date), isNull);
    });

    test('abaixo do mínimo não manda nada, e o dia fica no aparelho, '
        'com a frase de atualizar', () async {
      versions.minimum = 4;

      await engine.save(_dayFor('2026-09-10T18:30:00-03:00'));
      await engine.flush();

      expect(gateway.calls, isEmpty);
      expect(gate.outdated, isTrue);

      final stored = await store.get(_date);
      expect(stored, isNotNull);
      expect(stored!.rejection, isNull);
      expect(stored.attempts, 0);
      expect(
        engine.state.days[_date]?.message,
        syncMessages[SyncStatus.outdated],
      );
    });

    test('sem rede para perguntar, vale o último mínimo conhecido', () async {
      final known = VersionGate(
        currentBuild: 3,
        gateway: versions..error = Exception('sem rede'),
        knownMinimum: 4,
      );
      addTearDown(known.dispose);
      engine.stop();
      engine = SyncEngine(
        store,
        gateway,
        connectivity: connectivity,
        version: known,
      );

      await engine.save(_dayFor('2026-09-10T18:30:00-03:00'));
      await engine.flush();

      expect(gateway.calls, isEmpty);
      expect(
        engine.state.days[_date]?.message,
        syncMessages[SyncStatus.outdated],
      );
    });

    test(
      'a recusa do banco pela versão não descarta o dia nem insiste',
      () async {
        // O mínimo subiu entre a conferência e o envio.
        gateway.enqueueError(
          PostgrestException(
            code: 'PT426',
            message: 'Esta versão do aplicativo está desatualizada.',
          ),
        );
        gateway.enqueueSaved(_saved());

        await engine.save(_dayFor('2026-09-10T18:30:00-03:00'));
        await engine.save(
          _dayFor('2026-09-11T18:30:00-03:00', mapDate: '2026-09-11'),
        );
        gateway.beforeRespond = () async => versions.minimum = 4;
        await engine.flush();
        // A reconferência que a recusa pede é a que traz o mínimo exato.
        await gate.check();

        // Parou no primeiro: os outros teriam a mesma resposta.
        expect(gateway.calls, hasLength(1));
        expect(gate.outdated, isTrue);
        expect(gate.minimumBuild, 4);

        for (final date in [_date, '2026-09-11']) {
          final stored = await store.get(date);
          expect(stored, isNotNull, reason: date);
          expect(stored!.rejection, isNull, reason: date);
          expect(stored.attempts, 0, reason: date);
        }
      },
    );
  });

  group('a cópia confirmada (issue #124)', () {
    // Um dia com tudo o que a tela reenvia: o gênero que nasce agora, o que
    // já existe no catálogo e a alteração do cardápio.
    DayPayload fullDay(String updatedAt) => DayPayload(
      id: 'a0000000-0000-4000-8000-000000000001',
      mapDate: _date,
      updatedAt: updatedAt,
      nonSchoolDay: false,
      note: null,
      mealsServed: 312,
      meals: const [
        MealPayload(
          id: 'b0000000-0000-4000-8000-000000000001',
          type: 'lunch',
          description: '  Arroz, feijão e frango  ',
          acceptance: 'good',
          foodItems: [
            FoodItemPayload(
              foodItemId: null,
              name: 'pão',
              unit: 'quilo',
              quantity: 4,
            ),
            FoodItemPayload(
              foodItemId: 'f0000000-0000-4000-8000-000000000002',
              name: 'Arroz',
              unit: 'quilo',
              quantity: 6,
            ),
          ],
          menuChange: MenuChangePayload(
            id: 'd0000000-0000-4000-8000-000000000001',
            reason: 'Faltou carne',
            foodItems: [
              FoodItemPayload(
                foodItemId: 'f0000000-0000-4000-8000-000000000003',
                name: 'Frango',
                unit: 'quilo',
                quantity: 5,
              ),
            ],
          ),
        ),
      ],
    );

    Map<String, dynamic> savedFull() => _saved(
      foodItems: [
        {..._bread, 'name': 'Pão'},
        {
          'sent_id': 'f0000000-0000-4000-8000-000000000002',
          'id': 'f0000000-0000-4000-8000-000000000002',
          'name': 'Arroz',
          'unit': 'quilo',
          'created': false,
        },
        {
          'sent_id': 'f0000000-0000-4000-8000-000000000003',
          'id': 'f0000000-0000-4000-8000-000000000003',
          'name': 'Frango',
          'unit': 'quilo',
          'created': false,
        },
      ],
    );

    test('o dia enviado aparece no mês ao voltar, sem buscar o mês de '
        'novo', () async {
      final month = FakeMonthGateway();
      gateway.enqueueSaved(savedFull());

      await engine.save(fullDay('2026-09-10T18:30:00-03:00'));
      await engine.flush();

      final days = await MonthRepository(
        db,
        month,
      ).watchMonth(DateTime(2026, 9)).first;
      expect(month.fetchCalls, 0);
      expect(days.single.mealMap.id, 'c0000010-0000-4000-8000-000000000010');
      expect(days.single.mealMap.mealsServed, 312);
      expect(days.single.meals.single.acceptance, 'good');
    });

    test('reabrir o dia logo após o envio mostra o que subiu, gêneros e '
        'alteração inclusive, como o servidor guardou', () async {
      gateway.enqueueSaved(savedFull());

      await engine.save(fullDay('2026-09-10T18:30:00-03:00'));
      await engine.flush();

      expect(await engine.load(_date), isNull);
      final confirmed = await DayRepository(db).watchDay(_date).first;
      final day = confirmed!.day;
      expect(day.id, 'c0000010-0000-4000-8000-000000000010');
      // O carimbo é o do servidor, o mesmo instante das 18:30 de Brasília.
      expect(
        DateTime.parse(day.updatedAt)
            .isAtSameMomentAs(DateTime.utc(2026, 9, 10, 21, 30)),
        isTrue,
      );

      final meal = day.meals.single;
      expect(meal.description, 'Arroz, feijão e frango');
      expect(meal.foodItems.map((item) => (item.foodItemId, item.name)), [
        ('5005748a-0000-4000-8000-000000000001', 'Pão'),
        ('f0000000-0000-4000-8000-000000000002', 'Arroz'),
      ]);
      expect(meal.menuChange?.reason, 'Faltou carne');
      expect(meal.menuChange?.foodItems.single.name, 'Frango');
    });

    test('enviar, reabrir e editar: o reenvio carrega o dia inteiro', () async {
      gateway.enqueueSaved(savedFull());
      gateway.enqueueSaved(savedFull());

      await engine.save(fullDay('2026-09-10T18:30:00-03:00'));
      await engine.flush();

      // A tela, sem rascunho, parte da cópia confirmada.
      final reopened = (await DayRepository(db).watchDay(_date).first)!.day;
      await engine.save(touch(setMealsServed(reopened, 315)));
      await engine.flush();

      final resent = gateway.calls[1];
      expect(resent['id'], 'c0000010-0000-4000-8000-000000000010');
      expect(resent['meals_served'], 315);
      final meal = (resent['meals'] as List).single as Map<String, dynamic>;
      expect(meal['food_items'], hasLength(2));
      expect(
        (meal['food_items'] as List).first['food_item_id'],
        '5005748a-0000-4000-8000-000000000001',
      );
      expect(
        (meal['menu_change'] as Map<String, dynamic>)['food_items'],
        hasLength(1),
      );
    });

    test('com a tecla que veio no meio, a cópia confirmada é o que subiu e o '
        'rascunho é o mais novo', () async {
      gateway.beforeRespond = () => engine.save(
        setMealsServed(_dayFor('2026-09-10T18:35:00-03:00'), 320),
      );
      gateway.enqueueSaved(_saved());

      await engine.save(_dayFor('2026-09-10T18:30:00-03:00'));
      await engine.flush();

      expect((await engine.load(_date))?.mealsServed, 320);
      final confirmed = await DayRepository(db).watchDay(_date).first;
      expect(confirmed?.day.mealsServed, 312);
    });

    test('a leitura do mês que saiu antes do envio e chegou depois não '
        'traz o dia velho de volta', () async {
      final month = FakeMonthGateway()
        ..maps = [
          RemoteMealMap(
            id: 'c0000010-0000-4000-8000-000000000010',
            mapDate: DateTime(2026, 9, 10),
            nonSchoolDay: false,
            note: null,
            mealsServed: 100,
            locked: false,
            updatedAt: DateTime.utc(2026, 9, 10, 12),
            meals: const [],
          ),
        ];
      gateway.enqueueSaved(_saved());

      await engine.save(_dayFor('2026-09-10T18:30:00-03:00'));
      await engine.flush();
      await MonthRepository(db, month).refreshMonth(DateTime(2026, 9));

      final confirmed = await DayRepository(db).watchDay(_date).first;
      expect(confirmed?.day.mealsServed, 312);
      expect(confirmed?.day.meals, hasLength(1));
    });

    test('quando o servidor tem edição mais recente, a fila busca o dia de '
        'novo, e reabri-lo mostra a edição que venceu', () async {
      // O dia que o aparelho já tinha confirmado, de antes da colega mexer.
      gateway.enqueueSaved(_saved());
      await engine.save(_dayFor('2026-09-10T18:30:00-03:00'));
      await engine.flush();

      final month = FakeMonthGateway()
        ..maps = [
          RemoteMealMap(
            id: 'c0000010-0000-4000-8000-000000000010',
            mapDate: DateTime(2026, 9, 10),
            nonSchoolDay: false,
            note: null,
            mealsServed: 400,
            locked: false,
            updatedAt: DateTime.utc(2026, 9, 11, 10),
            meals: const [],
          ),
        ];
      final refetched = <String>[];
      final withRefetch = SyncEngine(
        store,
        gateway,
        connectivity: connectivity,
        onSuperseded: (mapDate) async {
          refetched.add(mapDate);
          await MonthRepository(
            db,
            month,
          ).refreshMonth(DateTime.parse(mapDate));
        },
      );
      addTearDown(withRefetch.stop);

      // Uma passada pelo dia, com um toque sem intenção, e o servidor diz que
      // a colega editou depois.
      gateway.enqueueSaved(_superseded(updatedAt: '2026-09-11T10:00:00+00:00'));
      await withRefetch.save(_dayFor('2026-09-10T19:00:00-03:00'));
      await withRefetch.flush();
      await pumpEventQueue();

      expect(refetched, [_date]);
      expect(withRefetch.state.conflicts, hasLength(1));
      final confirmed = await DayRepository(db).watchDay(_date).first;
      expect(confirmed?.day.mealsServed, 400);
    });

    test(
      'sem rede para buscar o dia de novo, o conflito ainda é avisado',
      () async {
        final withRefetch = SyncEngine(
          store,
          gateway,
          connectivity: connectivity,
          onSuperseded: (_) async => throw Exception('Failed to fetch'),
        );
        addTearDown(withRefetch.stop);

        gateway.enqueueSaved(
          _superseded(updatedAt: '2026-09-11T10:00:00+00:00'),
        );
        await withRefetch.save(_dayFor('2026-09-10T19:00:00-03:00'));
        await withRefetch.flush();
        await pumpEventQueue();

        expect(withRefetch.state.conflicts, hasLength(1));
        expect(await store.get(_date), isNull);
      },
    );
  });
}
