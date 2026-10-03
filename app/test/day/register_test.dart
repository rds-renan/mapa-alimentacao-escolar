import 'package:flutter_test/flutter_test.dart';
import 'package:mae/day/register.dart';
import 'package:mae/food_items/catalog.dart';
import 'package:mae/local/day.dart';

/*
 * As regras do registro, sem tela no meio — o mesmo raciocínio de
 * `web/src/day/register.test.ts`: a descrição, a aceitação, o número de
 * refeições e o dia não letivo (issue #105), os gêneros utilizados e a
 * alteração do cardápio (issue #106).
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

    test('o carimbo sai com fuso, e é o instante de agora', () {
      // Sem fuso, o Postgres lê a hora local como UTC, e a edição do
      // aparelho chega três horas no passado — perdendo a convergência para
      // a edição da web que veio depois dela.
      final stamp = touch(emptyDay(_date)).updatedAt;

      expect(stamp, endsWith('Z'));
      expect(
        DateTime.parse(stamp).difference(DateTime.now()).inSeconds.abs(),
        lessThan(5),
      );
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

  group('os gêneros de uma refeição (US003)', () {
    const rice = (foodItemId: 'rice', name: 'Arroz', unit: 'quilo');
    const egg = (foodItemId: null, name: 'Ovo', unit: 'bandeja');

    test('entram com a quantidade em 1', () {
      final day = addFoodItem(
        emptyDay(_date),
        'lunch',
        FoodItemList.meal,
        rice,
      );
      final item = mealOf(day, 'lunch')!.foodItems.single;

      expect(item.foodItemId, 'rice');
      expect(item.unit, 'quilo');
      expect(item.quantity, 1);
    });

    test('o mesmo gênero não entra duas vezes nem volta para 1', () {
      var day = addFoodItem(emptyDay(_date), 'lunch', FoodItemList.meal, rice);
      day = setFoodItemQuantity(day, 'lunch', FoodItemList.meal, 'arroz', 4);
      // O mesmo gênero, com a caixa e o espaço que o servidor normalizaria.
      day = addFoodItem(day, 'lunch', FoodItemList.meal, (
        foodItemId: null,
        name: ' ARROZ ',
        unit: 'quilo',
      ));

      final items = mealOf(day, 'lunch')!.foodItems;
      expect(items, hasLength(1));
      expect(items.single.quantity, 4);
    });

    test('andam de um em um, e o "−" de quem está em 1 tira o gênero', () {
      var day = addFoodItem(emptyDay(_date), 'lunch', FoodItemList.meal, rice);
      day = stepFoodItemQuantity(day, 'lunch', FoodItemList.meal, 'arroz', 1);
      expect(mealOf(day, 'lunch')!.foodItems.single.quantity, 2);

      day = stepFoodItemQuantity(day, 'lunch', FoodItemList.meal, 'arroz', -1);
      expect(mealOf(day, 'lunch')!.foodItems.single.quantity, 1);

      day = stepFoodItemQuantity(day, 'lunch', FoodItemList.meal, 'arroz', -1);
      expect(mealOf(day, 'lunch')!.foodItems, isEmpty);
    });

    test('a quantidade digitada é inteira, maior que zero e cabe no banco', () {
      expect(parseQuantity('1,5'), 15);
      expect(parseQuantity('-3'), 3);
      expect(parseQuantity('0'), isNull);
      expect(parseQuantity(''), isNull);

      var day = addFoodItem(emptyDay(_date), 'lunch', FoodItemList.meal, rice);
      day = setFoodItemQuantity(
        day,
        'lunch',
        FoodItemList.meal,
        'arroz',
        99999,
      );
      expect(mealOf(day, 'lunch')!.foodItems.single.quantity, 32767);

      day = setFoodItemQuantity(day, 'lunch', FoodItemList.meal, 'arroz', 0);
      expect(mealOf(day, 'lunch')!.foodItems.single.quantity, 1);
    });

    test('as duas listas não se misturam (decisão 7 da E4)', () {
      var day = addFoodItem(emptyDay(_date), 'lunch', FoodItemList.meal, rice);
      day = addFoodItem(day, 'lunch', FoodItemList.menuChange, egg);

      final lunch = mealOf(day, 'lunch')!;
      expect(lunch.foodItems.single.name, 'Arroz');
      expect(lunch.menuChange!.foodItems.single.name, 'Ovo');
    });

    test('o gênero cadastrado na folha sobe com a unidade e sem id, e o dia '
        'pode subir', () {
      final day = addFoodItem(emptyDay(_date), 'lunch', FoodItemList.meal, egg);
      final item = mealOf(day, 'lunch')!.foodItems.single;

      expect(item.foodItemId, isNull);
      expect(item.unit, 'bandeja');
      expect(canBeSent(day), isTrue);
    });
  });

  group('a alteração do cardápio (US002)', () {
    const egg = (foodItemId: null, name: 'Ovo', unit: 'bandeja');
    const rice = (foodItemId: 'rice', name: 'Arroz', unit: 'quilo');

    test('nasce do primeiro gênero da troca, sem motivo ainda', () {
      final day = addFoodItem(
        emptyDay(_date),
        'lunch',
        FoodItemList.menuChange,
        egg,
      );
      final change = mealOf(day, 'lunch')!.menuChange!;

      expect(change.reason, '');
      expect(change.foodItems.single.quantity, 1);
    });

    test('é uma só por refeição: o segundo gênero entra na mesma', () {
      var day = addFoodItem(
        emptyDay(_date),
        'lunch',
        FoodItemList.menuChange,
        egg,
      );
      final born = mealOf(day, 'lunch')!.menuChange!.id;
      day = addFoodItem(day, 'lunch', FoodItemList.menuChange, rice);
      day = setMenuChangeReason(day, 'lunch', 'Falta de entrega');

      final change = mealOf(day, 'lunch')!.menuChange!;
      expect(change.id, born);
      expect(change.foodItems, hasLength(2));
      expect(change.reason, 'Falta de entrega');
    });

    test('só está inteira com gênero e motivo, e só então o dia sobe', () {
      var day = addFoodItem(
        emptyDay(_date),
        'lunch',
        FoodItemList.menuChange,
        egg,
      );
      expect(menuChangeIsComplete(mealOf(day, 'lunch')!.menuChange), isFalse);
      expect(canBeSent(day), isFalse);

      day = setMenuChangeReason(day, 'lunch', '   ');
      expect(menuChangeIsComplete(mealOf(day, 'lunch')!.menuChange), isFalse);

      day = setMenuChangeReason(day, 'lunch', 'Item impróprio');
      expect(menuChangeIsComplete(mealOf(day, 'lunch')!.menuChange), isTrue);
      expect(canBeSent(day), isTrue);

      day = removeFoodItem(day, 'lunch', FoodItemList.menuChange, 'ovo');
      expect(menuChangeIsComplete(mealOf(day, 'lunch')!.menuChange), isFalse);
    });

    test('vazia é vazia, e tirá-la deixa a refeição sem alteração', () {
      var day = setMenuChangeReason(emptyDay(_date), 'lunch', '');
      expect(menuChangeIsEmpty(mealOf(day, 'lunch')!.menuChange), isTrue);

      day = setMenuChange(day, 'lunch', null);
      expect(mealOf(day, 'lunch')!.menuChange, isNull);
    });

    test('mexer na alteração não mexe no cardápio previsto', () {
      var day = _dayWithMeals();
      day = addFoodItem(day, 'lunch', FoodItemList.menuChange, egg);
      day = setMenuChangeReason(day, 'lunch', 'Item impróprio');

      expect(mealOf(day, 'lunch')!.description, 'Arroz, feijão e frango');
      expect(mealOf(day, 'morning_snack')!.menuChange, isNull);
    });
  });

  group('o catálogo na folha 3b', () {
    test('a busca ignora acento e caixa', () {
      expect(matchesSearch('Feijão', 'feijao'), isTrue);
      expect(matchesSearch('Maçã', 'MACA'), isTrue);
      expect(matchesSearch('Arroz', 'feij'), isFalse);
      expect(matchesSearch('Arroz', ''), isTrue);
    });

    test('a quantidade resumida no cartão leva o plural simples', () {
      expect(quantityLabel(1, 'quilo'), '1 quilo');
      expect(quantityLabel(3, 'bandeja'), '3 bandejas');
      expect(quantityLabel(2, 'latas'), '2 latas');
      expect(quantityLabel(2, null), '2');
    });
  });
}
