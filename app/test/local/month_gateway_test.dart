import 'package:flutter_test/flutter_test.dart';
import 'package:mae/local/month_gateway.dart';

/// A forma que o PostgREST devolve para a consulta de
/// `SupabaseMonthGateway` — a mesma que `web/src/day/queries.ts` lê: os
/// gêneros como lista, cada um com o `food_item` embutido, e a alteração
/// como objeto (a refeição é única em `menu_change`, e o PostgREST devolve
/// um-para-um sem lista).
void main() {
  test('lê os gêneros e a alteração de cada refeição', () {
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
          'meal_food_item': [
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
        },
        {
          'id': 'meal-2',
          'type': 'morning_snack',
          'description': null,
          'acceptance': null,
          'meal_food_item': <dynamic>[],
          'menu_change': null,
        },
      ],
    });

    final lunch = map.meals.first;
    expect(lunch.foodItems.single.toJson(), {
      'food_item_id': 'rice',
      'name': 'Arroz',
      'unit': 'quilo',
      'quantity': 4,
    });
    expect(lunch.menuChange!.reason, 'Item impróprio');
    expect(lunch.menuChange!.foodItems.single.name, 'Ovo');
    expect(lunch.menuChange!.foodItems.single.unit, 'bandeja');

    final snack = map.meals.last;
    expect(snack.foodItems, isEmpty);
    expect(snack.menuChange, isNull);
  });
}
