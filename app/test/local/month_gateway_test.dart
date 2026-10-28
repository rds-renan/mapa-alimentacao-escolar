import 'package:flutter_test/flutter_test.dart';
import 'package:mae/local/month_gateway.dart';

/// A forma que o PostgREST devolve para a consulta de
/// `SupabaseMonthGateway` — a mesma que `web/src/day/queries.ts` lê: os
/// gêneros como lista, cada um com o `food_item` embutido, e a alteração
/// como objeto (o mapa é único em `menu_change`, e o PostgREST devolve
/// um-para-um sem lista).
void main() {
  test('lê os gêneros e a alteração do dia (decisão 14 da E4)', () {
    final map = RemoteMealMap.fromRow({
      'id': 'map-1',
      'map_date': '2026-09-10',
      'non_school_day': false,
      'note': null,
      'meals_served': 312,
      'locked': false,
      'updated_at': '2026-09-10T18:00:00+00:00',
      'meal': [
        {
          'id': 'meal-1',
          'type': 'lunch',
          'description': 'Arroz e feijão',
          'acceptance': 'great',
        },
        {
          'id': 'meal-2',
          'type': 'morning_snack',
          'description': null,
          'acceptance': null,
        },
      ],
      'meal_map_food_item': [
        {
          'food_item_id': 'rice',
          'quantity': 4,
          'food_item': {'name': 'Arroz', 'default_unit': 'quilo'},
        },
      ],
      'menu_change': {
        'id': 'change-1',
        'reason': 'Item impróprio',
        'menu_change_food_item': [
          {
            'food_item_id': 'egg',
            'quantity': 3,
            'food_item': {'name': 'Ovo', 'default_unit': 'bandeja'},
          },
        ],
      },
    });

    expect(map.meals, hasLength(2));
    expect(map.foodItems.single.toJson(), {
      'food_item_id': 'rice',
      'name': 'Arroz',
      'unit': 'quilo',
      'quantity': 4,
    });
    expect(map.menuChange!.reason, 'Item impróprio');
    expect(map.menuChange!.foodItems.single.name, 'Ovo');
    expect(map.menuChange!.foodItems.single.unit, 'bandeja');
  });

  test('o dia sem gênero nem alteração chega vazio, sem inventar', () {
    final map = RemoteMealMap.fromRow({
      'id': 'map-1',
      'map_date': '2026-09-10',
      'non_school_day': false,
      'note': null,
      'meals_served': null,
      'locked': false,
      'updated_at': '2026-09-10T18:00:00+00:00',
      'meal': <dynamic>[],
      'meal_map_food_item': <dynamic>[],
      'menu_change': null,
    });

    expect(map.foodItems, isEmpty);
    expect(map.menuChange, isNull);
  });

  test('reaberto é fora do bloqueio e com reabertura no histórico — a regra '
      'da web (issue #152)', () {
    RemoteMealMap read({
      required bool locked,
      required List<dynamic> unlocks,
    }) => RemoteMealMap.fromRow({
      'id': 'map-1',
      'map_date': '2026-09-13',
      'non_school_day': false,
      'note': null,
      'meals_served': null,
      'locked': locked,
      'updated_at': '2026-09-13T18:00:00+00:00',
      'meal_map_unlock': unlocks,
      'meal': <dynamic>[],
    });
    const unlock = {'unlocked_at': '2026-10-08T10:00:00+00:00'};

    expect(read(locked: false, unlocks: [unlock]).reopened, isTrue);
    // Nunca reaberto.
    expect(read(locked: false, unlocks: []).reopened, isFalse);
    // Reaberto e já de volta a um documento: o que ela vê é o bloqueio.
    expect(read(locked: true, unlocks: [unlock]).reopened, isFalse);
  });
}
