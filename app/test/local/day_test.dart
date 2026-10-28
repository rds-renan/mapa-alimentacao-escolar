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
    ),
  ],
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
        adopted.foodItems[0].foodItemId,
        'f0000000-0000-4000-8000-000000000009',
      );
    });

    test('acha pelo nome o gênero que acabou de nascer, mesmo com caixa e '
        'espaços diferentes', () {
      expect(
        adopted.foodItems[1].foodItemId,
        'f0000000-0000-4000-8000-000000000010',
      );
      expect(
        adopted.menuChange?.foodItems[0].foodItemId,
        'f0000000-0000-4000-8000-000000000010',
      );
    });

    test('não mexe no resto do dia', () {
      expect(adopted.mealsServed, 312);
      expect(adopted.updatedAt, '2026-09-10T18:30:00-03:00');
      expect(
        adopted.menuChange?.reason,
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
        foodItems: const [],
        menuChange: null,
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
        foodItems: const [],
        menuChange: null,
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
        foodItems: const [],
        menuChange: null,
      );

      expect(canBeSent(stillWithMeals), isFalse);
    });

    test('segura a alteração do cardápio sem motivo ou sem gênero', () {
      MenuChangePayload? mealWith(MenuChangePayload? change) => change;

      DayPayload dayWith(MenuChangePayload? change) => DayPayload(
        id: schoolDay.id,
        mapDate: schoolDay.mapDate,
        updatedAt: schoolDay.updatedAt,
        nonSchoolDay: false,
        note: null,
        mealsServed: null,
        meals: const [
          MealPayload(
            id: 'meal-1',
            type: 'lunch',
            description: 'Arroz',
            acceptance: 'good',
          ),
        ],
        foodItems: const [],
        menuChange: change,
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
          ),
        ],
        foodItems: [item],
        menuChange: null,
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
      // Os gêneros e a alteração são do dia (decisão 14 da E4), e a
      // refeição não leva nem a chave: o servidor recusa o formato antigo.
      expect(json['food_items'], isNotEmpty);
      expect(json['menu_change']['food_items'], isNotEmpty);
      final meal = json['meals'][0] as Map<String, dynamic>;
      expect(meal.containsKey('food_items'), isFalse);
      expect(meal.containsKey('menu_change'), isFalse);
    });
  });

  /*
   * O rascunho e a fila guardados por um aparelho ainda na 0.1.3 trazem os
   * gêneros dentro de cada refeição. A leitura é a mesma junção da migration
   * e de `upgradeDay` na web: nada se perde, e o que se repete soma.
   */
  group('o dia guardado no formato antigo', () {
    final legacy = DayPayload.fromJson({
      'id': 'a0000000-0000-4000-8000-000000000002',
      'map_date': '2026-10-01',
      'updated_at': '2026-10-01T18:30:00-03:00',
      'non_school_day': false,
      'note': null,
      'meals_served': 90,
      'meals': [
        {
          'id': 'm2',
          'type': 'lunch',
          'description': 'Arroz e frango',
          'acceptance': 'good',
          'food_items': [
            {
              'food_item_id': 'arroz',
              'name': 'Arroz',
              'unit': 'kg',
              'quantity': 3,
            },
          ],
          'menu_change': {
            'id': 'c-almoco',
            'reason': 'Faltou frango',
            'food_items': [
              {
                'food_item_id': 'ovo',
                'name': 'Ovo',
                'unit': 'un',
                'quantity': 10,
              },
              {
                'food_item_id': 'suco',
                'name': 'Suco',
                'unit': 'L',
                'quantity': 1,
              },
            ],
          },
        },
        {
          'id': 'm1',
          'type': 'morning_snack',
          'description': 'Leite',
          'acceptance': 'great',
          'food_items': [
            {
              'food_item_id': 'leite',
              'name': 'Leite',
              'unit': 'L',
              'quantity': 1,
            },
            {
              'food_item_id': null,
              'name': ' arroz ',
              'unit': 'kg',
              'quantity': 2,
            },
          ],
          'menu_change': {
            'id': 'c-manha',
            'reason': 'Faltou leite',
            'food_items': [
              {
                'food_item_id': 'suco',
                'name': 'Suco',
                'unit': 'L',
                'quantity': 2,
              },
            ],
          },
        },
      ],
    });

    test('soma o mesmo gênero que estava em duas refeições', () {
      expect(legacy.foodItems.map((item) => (item.name, item.quantity)), [
        ('Leite', 1),
        ('Arroz', 5),
      ]);
      expect(legacy.foodItems.last.foodItemId, 'arroz');
    });

    test('junta as alterações na ordem das refeições, somando os gêneros', () {
      expect(legacy.menuChange!.id, 'c-manha');
      expect(legacy.menuChange!.reason, 'Faltou leite / Faltou frango');
      expect(
        legacy.menuChange!.foodItems.map((item) => (item.name, item.quantity)),
        [('Suco', 3), ('Ovo', 10)],
      );
    });

    test('a refeição sai só com o que é dela, e o carimbo não muda', () {
      expect(legacy.meals.map((meal) => meal.type), ['lunch', 'morning_snack']);
      expect(legacy.updatedAt, '2026-10-01T18:30:00-03:00');
      expect(legacy.toJson()['meals'][0].containsKey('food_items'), isFalse);
    });
  });
}
