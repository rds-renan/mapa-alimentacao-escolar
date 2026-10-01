import 'package:flutter_test/flutter_test.dart';
import 'package:mae/documents/generation_gateway.dart';
import 'package:mae/documents/selection.dart';
import 'package:mae/local/day.dart';
import 'package:mae/month/month.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// A regra da tela 5, sem Flutter e sem rede — a versão em Dart de
/// `web/src/documents/selection.test.ts`.
void main() {
  const meals = [
    MealRecord(type: 'morning_snack', description: 'Pão', acceptance: 'great'),
    MealRecord(type: 'lunch', description: 'Arroz', acceptance: 'great'),
    MealRecord(
      type: 'afternoon_snack',
      description: 'Fruta',
      acceptance: 'good',
    ),
  ];

  DayRecord day({
    String? id = 'map-1',
    bool locked = false,
    bool nonSchoolDay = false,
    bool unsent = false,
    int? mealsServed = 300,
    List<MealRecord> meals = meals,
  }) => DayRecord(
    id: id,
    nonSchoolDay: nonSchoolDay,
    note: null,
    mealsServed: mealsServed,
    locked: locked,
    unsent: unsent,
    meals: meals,
  );

  final date = DateTime(2026, 9, 1);

  test('dia preenchido e enviado entra', () {
    expect(toOption(date, day()).eligible, isTrue);
  });

  test('dia não letivo entra: também é registro do mês', () {
    final option = toOption(date, day(nonSchoolDay: true, meals: const []));
    expect(option.eligible, isTrue);
  });

  test('dia já incluído em outro documento entra de novo (CA#4 da US023)', () {
    final option = toOption(date, day(locked: true));
    expect(option.state, DayState.locked);
    expect(option.eligible, isTrue);
  });

  test('dia pendente não entra, e o motivo é pendente', () {
    final option = toOption(date, day(meals: meals.sublist(0, 1)));
    expect(option.eligible, isFalse);
    expect(missingReason(option), MissingReason.pending);
  });

  test('dia sem registro nenhum não entra: não há mapa no servidor', () {
    final option = toOption(date, null);
    expect(option.eligible, isFalse);
    expect(missingReason(option), MissingReason.empty);
  });

  test('dia preenchido que não subiu não entra (RN#3 da US012)', () {
    final option = toOption(date, day(id: null, unsent: true));
    expect(option.eligible, isFalse);
    expect(missingReason(option), MissingReason.unsent);
  });

  test('dia que não subiu e está incompleto: o motivo é esperando enviar', () {
    final option = toOption(
      date,
      day(id: null, unsent: true, meals: meals.sublist(0, 1)),
    );
    expect(missingReason(option), MissingReason.unsent);
  });

  test(
    'o rascunho vale sobre o servidor, menos o bloqueio e o identificador',
    () {
      final server = day(locked: true);
      final draft = DayRecord.fromDraft(
        _draft(nonSchoolDay: false, mealsServed: 250),
      );
      expect(draft.id, isNull);
      expect(draft.locked, isFalse);

      final merged = server.withDraft(
        _draft(nonSchoolDay: false, mealsServed: 250),
      );
      expect(merged.id, 'map-1');
      expect(merged.locked, isTrue);
      expect(merged.unsent, isTrue);
      expect(merged.mealsServed, 250);
    },
  );

  test('período fecha só com todos os dias elegíveis; vazio não fecha', () {
    final ok = toOption(date, day());
    final pending = toOption(date, day(meals: meals.sublist(0, 1)));

    expect(closable([ok, ok]), isTrue);
    expect(closable([ok, pending]), isFalse);
    expect(missingDays([ok, pending]), [pending]);
    expect(closable(const []), isFalse);
  });

  group('rótulo do período', () {
    test('um mês', () {
      expect(
        periodLabel([DateTime(2026, 9, 3), DateTime(2026, 9, 9)]),
        'setembro',
      );
    });

    test('dois meses', () {
      expect(
        periodLabel([DateTime(2026, 8, 31), DateTime(2026, 9, 1)]),
        'agosto e setembro',
      );
    });

    test('três meses', () {
      expect(
        periodLabel([
          DateTime(2026, 7, 1),
          DateTime(2026, 8, 1),
          DateTime(2026, 9, 1),
        ]),
        'julho a setembro',
      );
    });

    test('dois anos repetem o ano dos dois lados', () {
      expect(
        periodLabel([DateTime(2026, 12, 21), DateTime(2027, 1, 5)]),
        'dezembro de 2026 e janeiro de 2027',
      );
    });
  });

  group('a frase da recusa', () {
    test('vem do servidor quando a recusa tem explicação própria', () {
      const error = FunctionException(
        status: 422,
        details: {
          'error': {
            'message': 'A escola ainda não tem um modelo oficial cadastrado.',
            'hint': 'Fale com a direção.',
          },
        },
      );

      expect(
        generationFailureMessage(error),
        'A escola ainda não tem um modelo oficial cadastrado. Fale com a direção.',
      );
    });

    test('sem resposta do servidor, vale a frase da rede', () {
      expect(
        generationFailureMessage(Exception('sem rede')),
        contains('A internet caiu no meio do caminho'),
      );
      expect(
        generationFailureMessage(
          const FunctionException(status: 500, details: 'Internal'),
        ),
        contains('A internet caiu no meio do caminho'),
      );
    });
  });
}

DayPayload _draft({required bool nonSchoolDay, required int mealsServed}) =>
    DayPayload(
      id: 'local-1',
      mapDate: '2026-09-01',
      updatedAt: '2026-09-01T10:00:00.000',
      nonSchoolDay: nonSchoolDay,
      note: null,
      mealsServed: mealsServed,
      meals: const [],
    );
