/// O dia sendo preenchido, em funções puras — porto de
/// `web/src/day/register.ts` para o aplicativo (issue #105).
///
/// Cada função recebe o dia e devolve outro; nada aqui grava, envia ou
/// desenha. É de propósito: a tela do registro é um formulário grande, e a
/// única coisa difícil dela é **não perder nada** ao mexer numa parte. Com o
/// dia inteiro entrando e saindo de cada função, o que não foi tocado
/// atravessa intacto, e quem grava (a fila, issue #103) recebe sempre o dia
/// completo — o que o contrato de `save_meal_map` exige, já que a lista que
/// sobe é o dia todo e não um acréscimo.
///
/// Os gêneros utilizados e a alteração do cardápio (US002, US003) ficam para
/// a issue #106: o que esta tela lê e grava por enquanto é só a descrição, a
/// aceitação, o número de refeições e o dia não letivo — os campos que as
/// `MealPayload`/`DayPayload` já carregam continuam vazios/nulos até a #106
/// ganhar a interface que os preenche.
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

/// O teto de tudo que é contado neste dia: `meals_served` é `smallint` no
/// banco. Cortar aqui evita o dia que ela preencheu voltar recusado por um
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
