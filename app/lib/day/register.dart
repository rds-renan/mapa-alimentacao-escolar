/// O dia sendo preenchido, em funções puras — porto de
/// `web/src/day/register.ts` para o aplicativo (issues #105 e #106).
///
/// Cada função recebe o dia e devolve outro; nada aqui grava, envia ou
/// desenha. É de propósito: a tela do registro é um formulário grande, e a
/// única coisa difícil dela é **não perder nada** ao mexer numa parte. Com o
/// dia inteiro entrando e saindo de cada função, o que não foi tocado
/// atravessa intacto, e quem grava (a fila, issue #103) recebe sempre o dia
/// completo — o que o contrato de `save_meal_map` exige, já que a lista que
/// sobe é o dia todo e não um acréscimo.
library;

import '../local/day.dart';
import '../month/month.dart' show mealOrder;

/// Carimba a edição com o relógio do aparelho.
///
/// É "quando ela mexeu", não "quando chegou": um mapa preenchido na sexta sem
/// sinal e enviado no domingo precisa perder para a correção que a colega fez
/// no sábado. Toda mudança desta tela passa por aqui.
DayPayload touch(DayPayload day) => DayPayload(
  id: day.id,
  mapDate: day.mapDate,
  updatedAt: DateTime.now().toIso8601String(),
  nonSchoolDay: day.nonSchoolDay,
  note: day.note,
  mealsServed: day.mealsServed,
  meals: day.meals,
);

MealPayload? mealOf(DayPayload day, String type) {
  for (final meal in day.meals) {
    if (meal.type == type) return meal;
  }
  return null;
}

enum MealState { complete, pending, empty }

bool _filled(String? text) => text != null && text.trim().isNotEmpty;

/// Uma refeição está pronta quando descreve o que foi servido **e** tem a
/// aceitação (CA#3 da US004). Gêneros continuam opcionais (RN#3 da US001) e
/// por isso não entram na conta — mesma regra de [mealIsComplete] no domínio
/// do mês, que este estado não pode contradizer.
bool _mealIsComplete(MealPayload? meal) =>
    meal != null && _filled(meal.description) && meal.acceptance != null;

/// O estado da refeição, como o cartão o mostra.
MealState mealState(MealPayload? meal) {
  if (_mealIsComplete(meal)) return MealState.complete;
  if (meal != null && (_filled(meal.description) || meal.acceptance != null)) {
    return MealState.pending;
  }
  return MealState.empty;
}

/// A primeira refeição que ainda não está pronta — é nela que a tela abre.
/// Num dia vazio é o lanche da manhã; num dia que ela está completando, é
/// onde o trabalho parou. Com tudo pronto, nenhuma abre: o que ela quer ver
/// aí é o resumo dos três cartões fechados.
String? firstUnfinishedMeal(DayPayload day) {
  for (final type in mealOrder) {
    if (!_mealIsComplete(mealOf(day, type))) return type;
  }
  return null;
}

class DayProgress {
  const DayProgress({required this.done, required this.total});

  final int done;
  final int total;
}

/// Quanto do dia está preenchido. São quatro partes no dia letivo — as três
/// refeições e o número de refeições —, os mesmos quatro que a visão do mês
/// confere para chamar o dia de preenchido. No dia não letivo é uma só: a
/// observação.
DayProgress dayProgress(DayPayload day) {
  if (day.nonSchoolDay) {
    return DayProgress(done: _filled(day.note) ? 1 : 0, total: 1);
  }

  final meals = mealOrder
      .where((type) => _mealIsComplete(mealOf(day, type)))
      .length;

  return DayProgress(
    done: meals + (day.mealsServed == null ? 0 : 1),
    total: mealOrder.length + 1,
  );
}

/// Mexe numa refeição, criando-a se for a primeira tecla dada nela.
DayPayload _withMeal(
  DayPayload day,
  String type,
  MealPayload Function(MealPayload meal) change,
) {
  final existing = mealOf(day, type);

  if (existing != null) {
    return DayPayload(
      id: day.id,
      mapDate: day.mapDate,
      updatedAt: day.updatedAt,
      nonSchoolDay: day.nonSchoolDay,
      note: day.note,
      mealsServed: day.mealsServed,
      meals: [
        for (final meal in day.meals) meal.type == type ? change(meal) : meal,
      ],
    );
  }

  final born = MealPayload(
    id: newId(),
    type: type,
    description: null,
    acceptance: null,
    foodItems: const [],
    menuChange: null,
  );

  return DayPayload(
    id: day.id,
    mapDate: day.mapDate,
    updatedAt: day.updatedAt,
    nonSchoolDay: day.nonSchoolDay,
    note: day.note,
    mealsServed: day.mealsServed,
    meals: [...day.meals, change(born)],
  );
}

DayPayload setDescription(DayPayload day, String type, String description) {
  return _withMeal(
    day,
    type,
    (meal) => MealPayload(
      id: meal.id,
      type: meal.type,
      description: description,
      acceptance: meal.acceptance,
      foodItems: meal.foodItems,
      menuChange: meal.menuChange,
    ),
  );
}

DayPayload setAcceptance(DayPayload day, String type, String acceptance) {
  return _withMeal(
    day,
    type,
    (meal) => MealPayload(
      id: meal.id,
      type: meal.type,
      description: meal.description,
      acceptance: acceptance,
      foodItems: meal.foodItems,
      menuChange: meal.menuChange,
    ),
  );
}

/// O número de refeições do dia, único para as três (RN#1 da US005). Campo
/// vazio é nulo e não zero: o registro pode ficar parcial de propósito, e o
/// servidor recusa zero — refeição servida a ninguém não é um número, é a
/// ausência dele.
DayPayload setMealsServed(DayPayload day, int? mealsServed) => DayPayload(
  id: day.id,
  mapDate: day.mapDate,
  updatedAt: day.updatedAt,
  nonSchoolDay: day.nonSchoolDay,
  note: day.note,
  mealsServed: mealsServed,
  meals: day.meals,
);

/// O teto de tudo que é contado neste dia: `meals_served` e as quantidades
/// dos gêneros são `smallint` no banco. Cortar aqui evita o dia que ela preencheu voltar recusado por um
/// dedo que ficou preso na tecla.
const _maxCount = 32767;

/// O que ela digitou, virando número.
///
/// Só dígitos entram: nada de sinal, ponto ou vírgula (CA#2 da US005). Campo
/// vazio é nulo — o registro parcial é legítimo —, e zero também: o banco só
/// aceita `meals_served` maior que zero, e "nenhuma refeição servida" é a
/// ausência do número, não o número zero.
int? parseMealsServed(String text) {
  final digits = text.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return null;

  final value = int.parse(digits);
  final capped = value > _maxCount ? _maxCount : value;
  return capped == 0 ? null : capped;
}

/// Um a mais, um a menos. Do vazio, o "+" começa em 1; abaixo de 1 não há.
int? stepMealsServed(int? value, int delta) {
  final next = (value ?? 0) + delta;
  if (next < 1) return null;
  return next > _maxCount ? _maxCount : next;
}

DayPayload setNote(DayPayload day, String note) => DayPayload(
  id: day.id,
  mapDate: day.mapDate,
  updatedAt: day.updatedAt,
  nonSchoolDay: day.nonSchoolDay,
  note: note,
  mealsServed: day.mealsServed,
  meals: day.meals,
);

/// O que só existe no dia letivo, guardado para voltar se ela desmarcar.
class SchoolDayContent {
  const SchoolDayContent({required this.meals, required this.mealsServed});

  final List<MealPayload> meals;
  final int? mealsServed;
}

const nothingToRestore = SchoolDayContent(meals: [], mealsServed: null);

SchoolDayContent schoolDayContent(DayPayload day) =>
    SchoolDayContent(meals: day.meals, mealsServed: day.mealsServed);

/// Liga e desliga o dia não letivo.
///
/// Um dia é letivo ou não letivo, nunca os dois (RN#1 da US006) — e o
/// servidor leva isso à letra: dia não letivo com refeição é recusado, e o
/// número de refeições é descartado. Por isso marcar tira os dois do dia que
/// vai subir, e não só da tela.
///
/// O que estava digitado volta quando ela desmarca, porque quem chama
/// guardou o conteúdo e o devolve aqui (CA#3 da US006). A devolução é da
/// sessão: uma vez gravado como não letivo, o dia não tem mais refeições em
/// lugar nenhum — nem aqui, nem no servidor.
DayPayload setNonSchoolDay(
  DayPayload day,
  bool nonSchoolDay, {
  SchoolDayContent restored = nothingToRestore,
}) {
  if (nonSchoolDay) {
    return DayPayload(
      id: day.id,
      mapDate: day.mapDate,
      updatedAt: day.updatedAt,
      nonSchoolDay: true,
      // Vazia, e não nula: o campo da observação já está na tela esperando o
      // motivo, e é ele que falta para o dia poder subir.
      note: day.note ?? '',
      mealsServed: null,
      meals: const [],
    );
  }

  return DayPayload(
    id: day.id,
    mapDate: day.mapDate,
    updatedAt: day.updatedAt,
    nonSchoolDay: false,
    note: null,
    mealsServed: restored.mealsServed,
    meals: restored.meals,
  );
}

MealPayload _copyMeal(
  MealPayload meal, {
  List<FoodItemPayload>? foodItems,
  MenuChangePayload? Function()? menuChange,
}) => MealPayload(
  id: meal.id,
  type: meal.type,
  description: meal.description,
  acceptance: meal.acceptance,
  foodItems: foodItems ?? meal.foodItems,
  menuChange: menuChange == null ? meal.menuChange : menuChange(),
);

// ---------------------------------------------------------------------------
// Os gêneros utilizados, e a alteração do cardápio (issue #106)
// ---------------------------------------------------------------------------

/// Onde a lista de gêneros mora. São duas listas com a mesma forma, e não
/// uma: elas alimentam **colunas diferentes** do documento oficial — os
/// gêneros da refeição e os gêneros da troca (decisão 7 da E4).
enum FoodItemList { meal, menuChange }

/// O gênero que a folha 3b entrega: do catálogo (com identificador) ou
/// cadastrado ali mesmo (sem identificador, com a unidade com que vai
/// nascer). A quantidade não vem junto — quem põe na lista começa em 1.
typedef FoodItemChoice = ({String? foodItemId, String name, String? unit});

/// Como um gênero é achado dentro da lista.
///
/// É o nome normalizado, e não o identificador, porque é assim que o
/// servidor decide se dois gêneros são o mesmo: o catálogo é único por nome
/// normalizado dentro da escola, e dois nomes que normalizam igual viram uma
/// linha só na gravação. Fosse a chave o identificador, "Arroz" do catálogo e
/// um "arroz " recém-digitado conviveriam aqui e desapareceriam um no outro
/// lá.
String foodItemKey(String name) => normalizedName(name);

List<FoodItemPayload> foodItemsOf(MealPayload? meal, FoodItemList list) {
  if (meal == null) return const [];
  return list == FoodItemList.meal
      ? meal.foodItems
      : (meal.menuChange?.foodItems ?? const []);
}

/// Devolve a refeição com a lista trocada. Mexer nos gêneros da troca quando
/// ainda não há alteração **cria** a alteração, sem motivo: é a ordem em que
/// a tela 3a acontece — primeiro ela escolhe o que usou, depois escreve por
/// quê. Enquanto faltar o motivo, `canBeSent` segura o dia no aparelho.
MealPayload _withList(
  MealPayload meal,
  FoodItemList list,
  List<FoodItemPayload> items,
) {
  if (list == FoodItemList.meal) return _copyMeal(meal, foodItems: items);

  final change = meal.menuChange;
  return _copyMeal(
    meal,
    menuChange: () => MenuChangePayload(
      id: change?.id ?? newId(),
      reason: change?.reason ?? '',
      foodItems: items,
    ),
  );
}

DayPayload _changeList(
  DayPayload day,
  String type,
  FoodItemList list,
  List<FoodItemPayload> Function(List<FoodItemPayload> items) change,
) {
  return _withMeal(
    day,
    type,
    (meal) => _withList(meal, list, change(foodItemsOf(meal, list))),
  );
}

FoodItemPayload _withQuantity(FoodItemPayload item, int quantity) =>
    FoodItemPayload(
      foodItemId: item.foodItemId,
      name: item.name,
      unit: item.unit,
      quantity: quantity,
    );

/// Põe um gênero na lista, com a quantidade em 1 (decisão 7 da E3: escolhido
/// o item, ele entra na refeição já com o stepper em 1).
///
/// Um gênero que já está na lista não entra de novo nem volta para 1: a
/// gravação funde os dois pelo nome e ficaria valendo a última quantidade, o
/// que apagaria em silêncio o número que ela já tinha ajustado.
DayPayload addFoodItem(
  DayPayload day,
  String type,
  FoodItemList list,
  FoodItemChoice item,
) {
  return _changeList(
    day,
    type,
    list,
    (items) =>
        items.any((one) => foodItemKey(one.name) == foodItemKey(item.name))
        ? items
        : [
            ...items,
            FoodItemPayload(
              foodItemId: item.foodItemId,
              name: item.name,
              unit: item.unit,
              quantity: 1,
            ),
          ],
  );
}

DayPayload setFoodItemQuantity(
  DayPayload day,
  String type,
  FoodItemList list,
  String key,
  int quantity,
) {
  final bounded = quantity < 1
      ? 1
      : (quantity > _maxCount ? _maxCount : quantity);

  return _changeList(
    day,
    type,
    list,
    (items) => [
      for (final item in items)
        foodItemKey(item.name) == key ? _withQuantity(item, bounded) : item,
    ],
  );
}

DayPayload removeFoodItem(
  DayPayload day,
  String type,
  FoodItemList list,
  String key,
) {
  return _changeList(
    day,
    type,
    list,
    (items) => [
      for (final item in items)
        if (foodItemKey(item.name) != key) item,
    ],
  );
}

/// Um a mais, um a menos — e, no "−" de quem está em 1, o gênero sai da
/// lista.
///
/// Quantidade zero não existe no banco (RN#1 da US003), então o botão
/// precisava parar em 1 ou tirar o item. Tirar é o que ela quer: o gênero foi
/// posto ali por engano, e um cesto de lixo a mais em cada linha encheria o
/// cartão de ícone para um gesto que o "−" já nomeia.
DayPayload stepFoodItemQuantity(
  DayPayload day,
  String type,
  FoodItemList list,
  String key,
  int delta,
) {
  final matches = foodItemsOf(
    mealOf(day, type),
    list,
  ).where((one) => foodItemKey(one.name) == key);
  if (matches.isEmpty) return day;

  final next = matches.first.quantity + delta;
  if (next < 1) return removeFoodItem(day, type, list, key);

  return setFoodItemQuantity(day, type, list, key, next);
}

/// A quantidade que ela digitou, virando número.
///
/// Só dígitos entram, como no número de refeições (CA#2 da US003). O vazio
/// volta nulo para o campo poder ficar vazio enquanto ela troca o número — a
/// lista só aceita inteiro maior que zero, e quem comete o valor é quem
/// chama.
int? parseQuantity(String text) => parseMealsServed(text);

DayPayload setMenuChangeReason(DayPayload day, String type, String reason) {
  return _withMeal(
    day,
    type,
    (meal) => _copyMeal(
      meal,
      menuChange: () => MenuChangePayload(
        id: meal.menuChange?.id ?? newId(),
        reason: reason,
        foodItems: meal.menuChange?.foodItems ?? const [],
      ),
    ),
  );
}

/// Põe a alteração de volta como estava, ou tira-a. É o "Cancelar" da tela
/// 3a, e é também a limpeza do que ficou vazio: alteração sem gênero e sem
/// motivo não é alteração — é a tela 3a aberta e fechada sem nada.
DayPayload setMenuChange(
  DayPayload day,
  String type,
  MenuChangePayload? change,
) {
  return _withMeal(
    day,
    type,
    (meal) => _copyMeal(meal, menuChange: () => change),
  );
}

bool menuChangeIsEmpty(MenuChangePayload? change) {
  if (change == null) return true;
  return !_filled(change.reason) && change.foodItems.isEmpty;
}

/// A alteração está inteira? São as duas exigências do servidor: a
/// justificativa (CA#2 da US002) e ao menos um gênero — sem os gêneros que
/// entraram, a troca não descreve nada. Enquanto faltar uma delas, o dia
/// fica guardado no aparelho e a tela diz o que falta.
bool menuChangeIsComplete(MenuChangePayload? change) =>
    change != null && _filled(change.reason) && change.foodItems.isNotEmpty;
