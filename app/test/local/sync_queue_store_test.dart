import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mae/local/app_database.dart';
import 'package:mae/local/day.dart';
import 'package:mae/local/sync_queue_store.dart';

DayPayload _day({
  String mapDate = '2026-09-10',
  String updatedAt = '2026-09-10T18:30:00-03:00',
}) => DayPayload(
  id: 'a0000000-0000-4000-8000-000000000001',
  mapDate: mapDate,
  updatedAt: updatedAt,
  nonSchoolDay: false,
  note: null,
  mealsServed: 312,
  meals: const [],
);

void main() {
  late AppDatabase db;
  late SyncQueueStore store;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    store = SyncQueueStore(db);
  });

  tearDown(() => db.close());

  test('guarda o dia e devolve exatamente o que foi gravado', () async {
    await store.put(_day());

    final stored = await store.get('2026-09-10');
    expect(stored, isNotNull);
    expect(stored!.day.mealsServed, 312);
    expect(stored.attempts, 0);
    expect(stored.rejection, isNull);
  });

  test('dia que não existe devolve nulo', () async {
    expect(await store.get('2026-09-10'), isNull);
  });

  test('lista na ordem em que os dias entraram na fila', () async {
    await store.put(_day(mapDate: '2026-09-11'));
    await store.put(_day(mapDate: '2026-09-10'));

    final days = await store.list();
    expect(days.map((d) => d.mapDate), ['2026-09-11', '2026-09-10']);
  });

  test(
    'gravar de novo zera tentativas e recusa, sem perder a posição na fila',
    () async {
      await store.put(_day(mapDate: '2026-09-11'));
      await store.put(_day(mapDate: '2026-09-10'));
      await store.markRejected(
        '2026-09-10',
        const Rejection(code: '23514', message: 'Quantidade inválida.'),
      );

      // Ela corrigiu e o rascunho foi escrito de novo.
      await store.put(
        _day(mapDate: '2026-09-10', updatedAt: '2026-09-10T19:00:00-03:00'),
      );

      final days = await store.list();
      expect(days.map((d) => d.mapDate), ['2026-09-11', '2026-09-10']);
      final corrected = days.firstWhere((d) => d.mapDate == '2026-09-10');
      expect(corrected.attempts, 0);
      expect(corrected.rejection, isNull);
      expect(corrected.day.updatedAt, '2026-09-10T19:00:00-03:00');
    },
  );

  group('settle', () {
    test(
      'remove o dia quando o carimbo enviado é o que está guardado',
      () async {
        await store.put(_day());

        final outcome = await store.settle(
          '2026-09-10',
          '2026-09-10T18:30:00-03:00',
          (day) => day,
        );

        expect(outcome, SettleOutcome.removed);
        expect(await store.get('2026-09-10'), isNull);
      },
    );

    test(
      'mantém e adota quando ela digitou de novo enquanto isso subia',
      () async {
        await store.put(_day());
        await store.put(_day(updatedAt: '2026-09-10T19:00:00-03:00'));

        final outcome = await store.settle(
          '2026-09-10',
          '2026-09-10T18:30:00-03:00',
          (day) => DayPayload(
            id: 'c0000010-0000-4000-8000-000000000010',
            mapDate: day.mapDate,
            updatedAt: day.updatedAt,
            nonSchoolDay: day.nonSchoolDay,
            note: day.note,
            mealsServed: day.mealsServed,
            meals: day.meals,
          ),
        );

        expect(outcome, SettleOutcome.kept);
        final stored = await store.get('2026-09-10');
        expect(stored!.day.updatedAt, '2026-09-10T19:00:00-03:00');
        expect(stored.day.id, 'c0000010-0000-4000-8000-000000000010');
        expect(stored.attempts, 0);
        expect(stored.rejection, isNull);
      },
    );

    test('devolve "gone" quando o dia já não está na fila', () async {
      final outcome = await store.settle(
        '2026-09-10',
        '2026-09-10T18:30:00-03:00',
        (day) => day,
      );

      expect(outcome, SettleOutcome.gone);
    });
  });

  test('markRetried soma uma tentativa sem tocar no dia', () async {
    await store.put(_day());
    await store.markRetried('2026-09-10');
    await store.markRetried('2026-09-10');

    final stored = await store.get('2026-09-10');
    expect(stored!.attempts, 2);
    expect(stored.rejection, isNull);
  });

  test(
    'markRejected zera tentativas e guarda a recusa, sem apagar o dia',
    () async {
      await store.put(_day());
      await store.markRetried('2026-09-10');
      await store.markRejected(
        '2026-09-10',
        const Rejection(code: '23514', message: 'Quantidade inválida.'),
      );

      final stored = await store.get('2026-09-10');
      expect(stored!.attempts, 0);
      expect(stored.rejection?.code, '23514');
      expect(stored.rejection?.message, 'Quantidade inválida.');
      expect(stored.day.mealsServed, 312);
    },
  );
}
