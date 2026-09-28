import 'package:flutter_test/flutter_test.dart';
import 'package:mae/day/register.dart';
import 'package:mae/local/day.dart';

/*
 * As regras do registro, sem tela no meio — o mesmo raciocínio de
 * `web/src/day/register.test.ts`, mas só para o que a issue #105 cobre: a
 * descrição, a aceitação, o número de refeições e o dia não letivo. Os
 * gêneros utilizados e a alteração do cardápio ficam para a #106.
 */

const _date = '2026-09-10';

DayPayload _dayWithMeals() {
  var day = emptyDay(_date);
  day = setDescription(day, 'morning_snack', 'Pão com manteiga');
  day = setAcceptance(day, 'morning_snack', 'great');
  day = setDescription(day, 'lunch', 'Arroz, feijão e frango');
  day = setMealsServed(day, 312);
  return day;
}

void main() {
  group('o estado de cada refeição', () {
    final day = _dayWithMeals();

    test('é preenchida com descrição e aceitação, pendente com uma só, vazia '
        'sem nenhuma', () {
      expect(mealState(mealOf(day, 'morning_snack')), MealState.complete);
      expect(mealState(mealOf(day, 'lunch')), MealState.pending);
      expect(mealState(mealOf(day, 'afternoon_snack')), MealState.empty);
    });

    test('não conta descrição que é só espaço', () {
      final blank = setDescription(emptyDay(_date), 'lunch', '   ');
      expect(mealState(mealOf(blank, 'lunch')), MealState.empty);
    });

    test('abre a tela na primeira refeição que falta', () {
      expect(firstUnfinishedMeal(day), 'lunch');
      expect(firstUnfinishedMeal(emptyDay(_date)), 'morning_snack');
    });
  });

  group('o andamento do dia', () {
    test('conta as três refeições e o número de refeições', () {
      final progress = dayProgress(_dayWithMeals());
      expect(progress.done, 2);
      expect(progress.total, 4);

      final empty = dayProgress(emptyDay(_date));
      expect(empty.done, 0);
      expect(empty.total, 4);
    });

    test('no dia não letivo, conta só a observação', () {
      final marked = setNonSchoolDay(emptyDay(_date), true);

      final progress = dayProgress(marked);
      expect(progress.done, 0);
      expect(progress.total, 1);

      final withNote = dayProgress(setNote(marked, 'Conselho de classe'));
      expect(withNote.done, 1);
      expect(withNote.total, 1);
    });
  });

  group('mexer numa parte não mexe no resto', () {
    test('cria a refeição na primeira tecla, sem tocar nas outras', () {
      final day = setDescription(_dayWithMeals(), 'afternoon_snack', 'Bolo');

      expect(day.meals, hasLength(3));
      expect(mealOf(day, 'morning_snack')?.description, 'Pão com manteiga');
      expect(mealOf(day, 'morning_snack')?.acceptance, 'great');
      expect(day.mealsServed, 312);
    });

    test('a aceitação é de uma refeição só (RN#1 da US004)', () {
      final day = setAcceptance(_dayWithMeals(), 'lunch', 'poor');

      expect(mealOf(day, 'lunch')?.acceptance, 'poor');
      expect(mealOf(day, 'morning_snack')?.acceptance, 'great');
      expect(mealOf(day, 'lunch')?.description, 'Arroz, feijão e frango');
    });

    test('o carimbo da edição anda a cada mudança', () async {
      final before = emptyDay(_date);
      await Future<void>.delayed(const Duration(milliseconds: 2));

      expect(touch(before).updatedAt.compareTo(before.updatedAt) > 0, isTrue);
    });
  });

  group('o dia não letivo', () {
    test('tira as refeições e o número do dia que vai subir (RN#1 da '
        'US006)', () {
      final marked = setNonSchoolDay(_dayWithMeals(), true);

      expect(marked.nonSchoolDay, isTrue);
      expect(marked.meals, isEmpty);
      expect(marked.mealsServed, isNull);
      expect(marked.note, '');
    });

    test('devolve o que estava digitado quando ela desmarca (CA#3 da '
        'US006)', () {
      final day = _dayWithMeals();
      final kept = schoolDayContent(day);
      final marked = setNote(setNonSchoolDay(day, true), 'Conselho de classe');

      final back = setNonSchoolDay(marked, false, restored: kept);

      expect(back.nonSchoolDay, isFalse);
      expect(back.note, isNull);
      expect(back.mealsServed, 312);
      expect(mealOf(back, 'morning_snack')?.description, 'Pão com manteiga');
    });
  });

  group('o número de refeições', () {
    test('aceita só dígitos e recusa o zero', () {
      expect(parseMealsServed('312'), 312);
      expect(parseMealsServed('3a1,2'), 312);
      expect(parseMealsServed(''), isNull);
      expect(parseMealsServed('0'), isNull);
      expect(parseMealsServed('-5'), 5);
    });

    test('não passa do que o banco guarda', () {
      expect(parseMealsServed('99999'), 32767);
    });

    test('anda de um em um, e abaixo de um volta a ser vazio', () {
      expect(stepMealsServed(null, 1), 1);
      expect(stepMealsServed(312, 1), 313);
      expect(stepMealsServed(1, -1), isNull);
      expect(stepMealsServed(null, -1), isNull);
    });
  });
}
