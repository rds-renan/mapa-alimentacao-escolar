import 'package:flutter_test/flutter_test.dart';
import 'package:mae/local/day.dart';

/*
 * O contrato da gravação é explícito: o cliente precisa adotar os
 * identificadores que voltaram, porque são eles que fazem o próximo envio
 * encontrar o registro em vez de tentar criá-lo de novo. Mesmo raciocínio de
 * `web/src/local/day.test.ts`.
 */

DayPayload _day() => const DayPayload(
  id: 'a0000000-0000-4000-8000-000000000001',
  mapDate: '2026-09-10',
  updatedAt: '2026-09-10T18:30:00-03:00',
  nonSchoolDay: false,
  note: null,
  mealsServed: 312,
  meals: [
    MealPayload(
      id: 'b0000000-0000-4000-8000-000000000001',
      type: 'lunch',
      description: 'Arroz, feijão e frango',
      acceptance: 'good',
      foodItems: [
        // Um do catálogo, com o identificador que o aparelho inventou...
        FoodItemPayload(
          foodItemId: 'd0000000-0000-4000-8000-000000000001',
          name: 'Arroz',
          unit: 'quilo',
          quantity: 5,
        ),
        // ...e um que vai nascer no servidor, que só tem nome.
        FoodItemPayload(
          foodItemId: null,
          name: ' ovo ',
          unit: 'bandeja',
          quantity: 3,
        ),
      ],
      menuChange: MenuChangePayload(
        id: 'e0000000-0000-4000-8000-000000000001',
        reason: 'Não veio o frango na entrega da semana.',
        foodItems: [
          FoodItemPayload(
            foodItemId: null,
            name: 'Ovo',
            unit: 'bandeja',
            quantity: 3,
          ),
        ],
      ),
    ),
  ],
);

SaveResponse _response() => const SaveResponse(
  status: 'saved',
  // O dia já existia no servidor, criado pelo outro aparelho: vale o dele.
  mealMapId: 'c0000010-0000-4000-8000-000000000010',
  sentMealMapId: 'a0000000-0000-4000-8000-000000000001',
  mapDate: '2026-09-10',
  locked: false,
  updatedAt: '2026-09-10T21:30:00+00:00',
  updatedBy: '22222222-2222-4222-8222-222222222222',
  foodItems: [
    SaveResponseFoodItem(
      sentId: 'd0000000-0000-4000-8000-000000000001',
      id: 'f0000000-0000-4000-8000-000000000009',
      name: 'Arroz',
      unit: 'quilo',
      created: false,
    ),
    SaveResponseFoodItem(
      sentId: null,
      id: 'f0000000-0000-4000-8000-000000000010',
      name: 'Ovo',
      unit: 'bandeja',
      created: true,
    ),
  ],
);

void main() {
  group('adotar o que o servidor devolveu', () {
    final adopted = adoptServerIds(_day(), _response());

    test('troca o identificador do mapa pelo que valeu', () {
      expect(adopted.id, 'c0000010-0000-4000-8000-000000000010');
    });

    test('troca o identificador do gênero que o aparelho tinha inventado', () {
      expect(
        adopted.meals[0].foodItems[0].foodItemId,
        'f0000000-0000-4000-8000-000000000009',
      );
    });

    test('acha pelo nome o gênero que acabou de nascer, mesmo com caixa e '
        'espaços diferentes', () {
      expect(
        adopted.meals[0].foodItems[1].foodItemId,
        'f0000000-0000-4000-8000-000000000010',
      );
      expect(
        adopted.meals[0].menuChange?.foodItems[0].foodItemId,
        'f0000000-0000-4000-8000-000000000010',
      );
    });

    test('não mexe no resto do dia', () {
      expect(adopted.mealsServed, 312);
      expect(adopted.updatedAt, '2026-09-10T18:30:00-03:00');
      expect(
        adopted.meals[0].menuChange?.reason,
        'Não veio o frango na entrega da semana.',
      );
    });
  });

  /*
   * A pergunta que a fila faz antes de tentar: o servidor aceitaria este
   * dia? Ela existe para que o meio do caminho — o dia não letivo cuja
   * observação ela ainda não escreveu — fique guardado no aparelho em vez
   * de voltar recusado.
   */
  group('o dia em condição de subir', () {
    final schoolDay = _day();

    test('deixa passar o dia letivo, completo ou pela metade', () {
      expect(canBeSent(schoolDay), isTrue);

      final empty = DayPayload(
        id: schoolDay.id,
        mapDate: schoolDay.mapDate,
        updatedAt: schoolDay.updatedAt,
        nonSchoolDay: schoolDay.nonSchoolDay,
        note: schoolDay.note,
        mealsServed: null,
        meals: const [],
      );
      expect(canBeSent(empty), isTrue);
    });

    test('segura o dia não letivo enquanto não há o motivo', () {
      DayPayload marked(String note) => DayPayload(
        id: schoolDay.id,
        mapDate: schoolDay.mapDate,
        updatedAt: schoolDay.updatedAt,
        nonSchoolDay: true,
        note: note,
        mealsServed: null,
        meals: const [],
      );

      expect(canBeSent(marked('')), isFalse);
      expect(canBeSent(marked('   ')), isFalse);
      expect(canBeSent(marked('Conselho de classe')), isTrue);
    });

    test('segura o dia não letivo que ainda carrega refeições', () {
      final stillWithMeals = DayPayload(
        id: schoolDay.id,
        mapDate: schoolDay.mapDate,
        updatedAt: schoolDay.updatedAt,
        nonSchoolDay: true,
        note: 'Conselho de classe',
        mealsServed: schoolDay.mealsServed,
        meals: schoolDay.meals,
      );

      expect(canBeSent(stillWithMeals), isFalse);
    });

    test('segura a alteração do cardápio sem motivo ou sem gênero', () {
      MealPayload mealWith(MenuChangePayload? change) => MealPayload(
        id: 'meal-1',
        type: 'lunch',
        description: 'Arroz',
        acceptance: 'good',
        foodItems: const [],
        menuChange: change,
      );

      DayPayload dayWith(MealPayload meal) => DayPayload(
        id: schoolDay.id,
        mapDate: schoolDay.mapDate,
        updatedAt: schoolDay.updatedAt,
        nonSchoolDay: false,
        note: null,
        mealsServed: null,
        meals: [meal],
      );

      final withoutReason = dayWith(
        mealWith(
          const MenuChangePayload(
            id: 'change-1',
            reason: '',
            foodItems: [
              FoodItemPayload(
                foodItemId: null,
                name: 'Ovo',
                unit: 'bandeja',
                quantity: 1,
              ),
            ],
          ),
        ),
      );
      expect(canBeSent(withoutReason), isFalse);

      final withoutFoodItems = dayWith(
        mealWith(
          const MenuChangePayload(
            id: 'change-1',
            reason: 'Faltou',
            foodItems: [],
          ),
        ),
      );
      expect(canBeSent(withoutFoodItems), isFalse);
    });

    test('segura o gênero a nascer sem unidade, e deixa passar com ela', () {
      DayPayload dayWithItem(FoodItemPayload item) => DayPayload(
        id: schoolDay.id,
        mapDate: schoolDay.mapDate,
        updatedAt: schoolDay.updatedAt,
        nonSchoolDay: false,
        note: null,
        mealsServed: null,
        meals: [
          MealPayload(
            id: 'meal-1',
            type: 'lunch',
            description: 'Arroz',
            acceptance: 'good',
            foodItems: [item],
            menuChange: null,
          ),
        ],
      );

      expect(
        canBeSent(
          dayWithItem(
            const FoodItemPayload(
              foodItemId: null,
              name: 'Arroz',
              unit: null,
              quantity: 1,
            ),
          ),
        ),
        isFalse,
      );

      expect(
        canBeSent(
          dayWithItem(
            const FoodItemPayload(
              foodItemId: null,
              name: 'Arroz',
              unit: 'quilo',
              quantity: 1,
            ),
          ),
        ),
        isTrue,
      );

      expect(
        canBeSent(
          dayWithItem(
            const FoodItemPayload(
              foodItemId: null,
              name: 'Arroz',
              unit: 'quilo',
              quantity: 0,
            ),
          ),
        ),
        isFalse,
      );
    });
  });

  group('o payload de fio', () {
    test('sobrevive a uma volta de toJson/fromJson', () {
      final day = _day();
      final roundTripped = DayPayload.fromJson(day.toJson());

      expect(roundTripped.toJson(), day.toJson());
    });

    test('usa os nomes do banco, em snake_case', () {
      final json = _day().toJson();

      expect(json['map_date'], '2026-09-10');
      expect(json['non_school_day'], isFalse);
      expect(json['meals_served'], 312);
      final meal = json['meals'][0] as Map<String, dynamic>;
      expect(meal['food_items'], isNotEmpty);
      expect(meal['menu_change']['food_items'], isNotEmpty);
    });
  });
}
