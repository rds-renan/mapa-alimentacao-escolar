import 'package:flutter_test/flutter_test.dart';
import 'package:mae/month/month.dart';

void main() {
  DayRecord day({
    bool nonSchoolDay = false,
    String? note,
    int? mealsServed,
    bool locked = false,
    List<MealRecord> meals = const [],
  }) => DayRecord(
    nonSchoolDay: nonSchoolDay,
    note: note,
    mealsServed: mealsServed,
    locked: locked,
    meals: meals,
  );

  MealRecord meal(String type, {String? description, String? acceptance}) =>
      MealRecord(type: type, description: description, acceptance: acceptance);

  group('dayState', () {
    test('sem registro é vazio', () {
      expect(dayState(null), DayState.empty);
    });

    test('registro que existe mas está em branco é vazio, não pendente', () {
      expect(dayState(day()), DayState.empty);
    });

    test('falta a aceitação de uma refeição: continua pendente', () {
      final record = day(
        mealsServed: 300,
        meals: [
          meal('morning_snack', description: 'Pão', acceptance: 'great'),
          meal('lunch', description: 'Arroz e feijão', acceptance: null),
          meal('afternoon_snack', description: 'Fruta', acceptance: 'good'),
        ],
      );

      expect(dayState(record), DayState.pending);
    });

    test('falta o número de refeições: continua pendente', () {
      final record = day(
        meals: [
          meal('morning_snack', description: 'Pão', acceptance: 'great'),
          meal('lunch', description: 'Arroz e feijão', acceptance: 'great'),
          meal('afternoon_snack', description: 'Fruta', acceptance: 'good'),
        ],
      );

      expect(dayState(record), DayState.pending);
    });

    test('as três refeições e o número de refeições: completo', () {
      final record = day(
        mealsServed: 300,
        meals: [
          meal('morning_snack', description: 'Pão', acceptance: 'great'),
          meal('lunch', description: 'Arroz e feijão', acceptance: 'great'),
          meal('afternoon_snack', description: 'Fruta', acceptance: 'good'),
        ],
      );

      expect(dayState(record), DayState.complete);
    });

    test('não letivo, com a observação', () {
      final record = day(nonSchoolDay: true, note: 'Conselho de classe');
      expect(dayState(record), DayState.nonSchool);
    });

    test('bloqueado ganha de completo e de não letivo', () {
      final complete = day(
        locked: true,
        mealsServed: 300,
        meals: [
          meal('morning_snack', description: 'Pão', acceptance: 'great'),
          meal('lunch', description: 'Arroz e feijão', acceptance: 'great'),
          meal('afternoon_snack', description: 'Fruta', acceptance: 'good'),
        ],
      );
      final nonSchool = day(locked: true, nonSchoolDay: true);

      expect(dayState(complete), DayState.locked);
      expect(dayState(nonSchool), DayState.locked);
    });
  });

  group('daySummary', () {
    test('falta uma refeição, no singular', () {
      final record = day(
        mealsServed: 300,
        meals: [
          meal('morning_snack', description: 'Pão', acceptance: 'great'),
          meal('lunch', description: 'Arroz e feijão', acceptance: 'great'),
          meal('afternoon_snack', description: null, acceptance: null),
        ],
      );

      expect(daySummary(record), 'falta o lanche da tarde');
    });

    test('faltam as três refeições, no plural', () {
      expect(daySummary(day(mealsServed: 300)), 'faltam as três refeições');
    });

    test('"Hoje" na frente quando é o dia de hoje', () {
      expect(daySummary(null, isToday: true), 'Hoje · Sem registro');
    });
  });

  group('listedDays', () {
    test('fim de semana fica fora, salvo quando tem registro', () {
      // Setembro de 2026: sábado 5 e domingo 6 são fim de semana.
      final month = DateTime(2026, 9);
      final days = listedDays(month, {DateTime(2026, 9, 5)});

      expect(days, isNot(contains(DateTime(2026, 9, 6))));
      expect(days, contains(DateTime(2026, 9, 5)));
      expect(days, contains(DateTime(2026, 9, 1)));
    });
  });

  group('groupIntoWeeks', () {
    test('quebra na segunda-feira, num mês que começa numa terça', () {
      // Setembro de 2026 começa numa terça-feira.
      final month = DateTime(2026, 9);
      final days = listedDays(month, {});
      final weeks = groupIntoWeeks(days);

      expect(weeks.first.days.first, DateTime(2026, 9, 1));
      expect(weeks.first.days.last.weekday, DateTime.friday);
      expect(weeks[1].days.first.weekday, DateTime.monday);
    });
  });

  group('monthProgress', () {
    test('não letivo sai do total de dias letivos', () {
      final month = DateTime(2026, 9);
      final days = listedDays(month, {});
      final byDate = {DateTime(2026, 9, 2): day(nonSchoolDay: true)};

      final progress = monthProgress(days, byDate);

      expect(progress.schoolDays, days.length - 1);
      expect(progress.counts[DayState.nonSchool], 1);
    });
  });

  group('virada de mês', () {
    test('virada de ano', () {
      expect(shiftMonth(DateTime(2026, 12), 1), DateTime(2027, 1));
    });

    test('fevereiro bissexto fecha no dia 29', () {
      expect(lastDayOfMonth(DateTime(2028, 2)).day, 29);
    });

    test('fevereiro não bissexto fecha no dia 28', () {
      expect(lastDayOfMonth(DateTime(2026, 2)).day, 28);
    });
  });
}
