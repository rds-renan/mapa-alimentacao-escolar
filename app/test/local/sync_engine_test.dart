import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mae/local/app_database.dart';
import 'package:mae/local/day.dart';
import 'package:mae/local/sync_engine.dart';
import 'package:mae/local/sync_messages.dart';
import 'package:mae/local/sync_queue_store.dart';
import 'package:mae/version/version_gate.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import 'fake_connectivity_gateway.dart';
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

Map<String, dynamic> _saved({
  String mealMapId = 'c0000010-0000-4000-8000-000000000010',
  List<Map<String, dynamic>> foodItems = const [],
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
}
