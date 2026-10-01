import 'package:flutter_test/flutter_test.dart';
import 'package:mae/food_items/form.dart';
import 'package:mae/local/app_database.dart';

void main() {
  const rice = FoodItem(id: 'rice', name: 'Arroz', unit: 'quilo', active: true);
  const salt = FoodItem(id: 'salt', name: 'Sal', unit: 'pacote', active: false);

  test('nome e unidade são obrigatórios', () {
    expect(canSave(const FoodItemDraft(name: 'Feijão', unit: 'quilo')), isTrue);
    expect(canSave(const FoodItemDraft(name: '  ', unit: 'quilo')), isFalse);
    expect(canSave(const FoodItemDraft(name: 'Feijão', unit: ' ')), isFalse);
  });

  test('o homônimo ignora caixa e espaços, e não conta o próprio gênero', () {
    const items = [rice, salt];

    expect(
      duplicateOf(const FoodItemDraft(name: 'arroz ', unit: 'x'), items),
      rice,
    );
    expect(
      duplicateOf(const FoodItemDraft(name: 'SAL', unit: 'x'), items),
      salt,
    );
    expect(
      duplicateOf(
        const FoodItemDraft(id: 'rice', name: 'Arroz', unit: 'x'),
        items,
      ),
      isNull,
    );
  });

  test('o aviso da unidade só vale para gênero que já existe e mudou', () {
    const items = [rice];

    expect(
      unitChanged(
        const FoodItemDraft(id: 'rice', name: 'Arroz', unit: 'saco'),
        items,
      ),
      isTrue,
    );
    expect(
      unitChanged(
        const FoodItemDraft(id: 'rice', name: 'Arroz', unit: 'quilo '),
        items,
      ),
      isFalse,
    );
    expect(
      unitChanged(const FoodItemDraft(name: 'Arroz', unit: 'saco'), items),
      isFalse,
    );
  });

  test('a busca corta ativos e desativados', () {
    final all = sections(const [rice, salt], 'SAL');

    expect(all.active, isEmpty);
    expect(all.inactive, [salt]);
    expect(sections(const [rice, salt], '').active, [rice]);
  });
}
