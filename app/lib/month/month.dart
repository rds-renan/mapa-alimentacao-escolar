/// O domínio da visão do mês (US008) — porto de `web/src/month/month.ts`
/// para o aplicativo. A decisão 4 da E4 é levada à letra: só o bloqueio vem
/// gravado do servidor; vazio, pendente e completo são calculados aqui, na
/// leitura, a cada vez. Tudo aqui é função pura sobre texto e número: nada
/// de banco, nada de Flutter.
///
/// Ao contrário da web, as datas não precisam do cuidado com UTC: o
/// `DateTime.parse` do Dart interpreta uma data sem fuso como hora **local**
/// — o oposto do `Date` do JavaScript, que a assume UTC —, e é hora local
/// que [MonthRepository] já usa em toda parte (`DateTime(ano, mês)` para os
/// limites do mês, `DateTime.parse` para o que veio do servidor). Manter os
/// dois sempre em local é o que evita aqui o mesmo problema que a web
/// preveniu obrigando UTC.
///
/// A outra diferença da web: não há duas origens para fundir. `DayRecord`
/// nasce só do banco local (já convergido pelo servidor via `refreshMonth`);
/// o rascunho por enviar entra com a fila (issue #103) e a leitura dele
/// pela visão do mês fica para a #105, como a documentação da fila já
/// registra.
library;

import '../local/month_repository.dart';

enum DayState { locked, nonSchool, complete, pending, empty }

/// A ordem em que as três refeições do dia são exigidas para "completo".
const List<String> mealOrder = ['morning_snack', 'lunch', 'afternoon_snack'];

const Map<String, String> mealLabels = {
  'morning_snack': 'lanche da manhã',
  'lunch': 'almoço',
  'afternoon_snack': 'lanche da tarde',
};

/// Os rótulos de estado — os da tela 2 desenhada na E3, palavra por
/// palavra. "Preenchido" e não "completo", "No documento" e não
/// "bloqueado": o que importa para ela é como fala do dia, não o nome
/// técnico da consequência.
const Map<DayState, String> dayStateLabels = {
  DayState.complete: 'Preenchido',
  DayState.pending: 'Pendente',
  DayState.nonSchool: 'Não letivo',
  DayState.locked: 'No documento',
  DayState.empty: 'Vazio',
};

const Map<DayState, String> _dayStatePlural = {
  DayState.complete: 'preenchidos',
  DayState.pending: 'pendentes',
  DayState.nonSchool: 'não letivos',
  DayState.locked: 'no documento',
  DayState.empty: 'vazios',
};

const List<DayState> _breakdownOrder = [
  DayState.complete,
  DayState.pending,
  DayState.nonSchool,
  DayState.locked,
  DayState.empty,
];

/// Uma refeição, reduzida ao que decide o estado do dia.
class MealRecord {
  const MealRecord({required this.type, this.description, this.acceptance});

  final String type;
  final String? description;
  final String? acceptance;
}

/// Um dia, na forma que esta tela precisa — a versão em Dart do `DayRecord`
/// da web, sem campo para as duas origens: aqui só existe o banco local.
class DayRecord {
  const DayRecord({
    required this.nonSchoolDay,
    required this.note,
    required this.mealsServed,
    required this.locked,
    required this.meals,
  });

  factory DayRecord.fromLocal(MealMapWithMeals row) => DayRecord(
    nonSchoolDay: row.mealMap.nonSchoolDay,
    note: row.mealMap.note,
    mealsServed: row.mealMap.mealsServed,
    locked: row.mealMap.locked,
    meals: row.meals
        .map(
          (meal) => MealRecord(
            type: meal.type,
            description: meal.description,
            acceptance: meal.acceptance,
          ),
        )
        .toList(),
  );

  final bool nonSchoolDay;
  final String? note;
  final int? mealsServed;
  final bool locked;
  final List<MealRecord> meals;
}

/// Zera a hora — a chave de comparação e de agrupamento por dia em todo este
/// arquivo.
DateTime dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

// ---------------------------------------------------------------------------
// O estado de cada dia (decisão 4 da E4, decisão 4 da E3)
// ---------------------------------------------------------------------------

bool _filled(String? text) => text != null && text.trim().isNotEmpty;

/// Uma refeição está pronta quando descreve o que foi servido **e** tem a
/// aceitação (CA#3 da US004). Gêneros continuam opcionais (RN#3 da US001) e
/// por isso não entram na conta.
bool mealIsComplete(MealRecord? meal) =>
    meal != null && _filled(meal.description) && meal.acceptance != null;

/// Um dia que existe mas em que ninguém escreveu nada ainda é um dia vazio.
bool _hasContent(DayRecord day) =>
    day.nonSchoolDay ||
    day.mealsServed != null ||
    day.meals.any(
      (meal) => _filled(meal.description) || meal.acceptance != null,
    );

DayState dayState(DayRecord? day) {
  if (day == null) return DayState.empty;

  /*
   * O bloqueio vem primeiro porque é o único estado que muda o que ela PODE
   * fazer: o dia já saiu num documento oficial e virou somente leitura
   * (RN#1 da US007). Saber que ele também estava completo não muda nada.
   */
  if (day.locked) return DayState.locked;
  if (day.nonSchoolDay) return DayState.nonSchool;
  if (!_hasContent(day)) return DayState.empty;

  final byType = {for (final meal in day.meals) meal.type: meal};
  final complete =
      day.mealsServed != null &&
      mealOrder.every((type) => mealIsComplete(byType[type]));

  return complete ? DayState.complete : DayState.pending;
}

/// O que ainda falta num dia pendente, em português corrente.
String _missingParts(DayRecord day) {
  final byType = {for (final meal in day.meals) meal.type: meal};
  final missingMeals = mealOrder
      .where((type) => !mealIsComplete(byType[type]))
      .toList();

  final items = missingMeals.length == mealOrder.length
      ? ['as três refeições']
      : missingMeals.map((type) => 'o ${mealLabels[type]}').toList();

  if (day.mealsServed == null) items.add('o número de refeições');

  final verb = items.length > 1 || items.first == 'as três refeições'
      ? 'faltam'
      : 'falta';
  final list = items.length > 1
      ? '${items.sublist(0, items.length - 1).join(', ')} e ${items.last}'
      : items.first;

  return '$verb $list';
}

/// A linha de apoio de cada dia: o que ele tem, quando tem; o que falta,
/// quando falta. O "Hoje" na frente é o único destaque de data da lista.
String daySummary(DayRecord? day, {bool isToday = false}) {
  final prefix = isToday ? 'Hoje · ' : '';

  if (day == null || !_hasContent(day)) return '${prefix}Sem registro';

  if (day.nonSchoolDay) {
    final note = day.note?.trim();
    return '$prefix${(note != null && note.isNotEmpty) ? note : 'Dia não letivo'}';
  }

  final state = dayState(day);
  if (state == DayState.pending) return '$prefix${_missingParts(day)}';

  final meals = day.meals.where((meal) => _filled(meal.description)).length;
  final served = day.mealsServed == null ? null : '${day.mealsServed} servidas';

  final parts = ['$meals refeições', ?served];
  return '$prefix${parts.join(' · ')}';
}

// ---------------------------------------------------------------------------
// Datas e rótulos
// ---------------------------------------------------------------------------

const List<String> _monthNames = [
  'janeiro',
  'fevereiro',
  'março',
  'abril',
  'maio',
  'junho',
  'julho',
  'agosto',
  'setembro',
  'outubro',
  'novembro',
  'dezembro',
];

/// `DateTime.weekday`: segunda = 1 … domingo = 7.
const Map<int, String> _weekdayAbbrev = {
  1: 'SEG',
  2: 'TER',
  3: 'QUA',
  4: 'QUI',
  5: 'SEX',
  6: 'SÁB',
  7: 'DOM',
};

String weekdayAbbrev(DateTime date) => _weekdayAbbrev[date.weekday]!;

/// Segunda a sexta. Fim de semana não conta como pendência (RN#1 da US008).
bool isWeekday(DateTime date) => date.weekday >= 1 && date.weekday <= 5;

DateTime firstDayOfMonth(DateTime month) => DateTime(month.year, month.month);

DateTime lastDayOfMonth(DateTime month) =>
    DateTime(month.year, month.month + 1, 0);

DateTime shiftMonth(DateTime month, int months) =>
    DateTime(month.year, month.month + months);

/// "Setembro de 2026", com a inicial maiúscula do título da tela.
String monthLabel(DateTime month) {
  final name = _monthNames[month.month - 1];
  return '${name[0].toUpperCase()}${name.substring(1)} de ${month.year}';
}

/// "1 de setembro" — como a linha de apoio e o rótulo de acessibilidade
/// leem a data.
String dayAndMonth(DateTime date) =>
    '${date.day} de ${_monthNames[date.month - 1]}';

/// "2026-09-10": a forma que a rota do registro do dia usa.
String isoDate(DateTime date) {
  String pad(int value) => value.toString().padLeft(2, '0');
  return '${date.year.toString().padLeft(4, '0')}-${pad(date.month)}-${pad(date.day)}';
}

/// Os dias que a tela lista.
///
/// Segunda a sexta sempre, porque é neles que pode faltar mapa. Sábado e
/// domingo entram **só** quando têm registro: a regra diz que fim de semana
/// não é pendência, não que um dia registrado possa ficar inalcançável.
List<DateTime> listedDays(DateTime month, Set<DateTime> registered) {
  final last = lastDayOfMonth(month);
  final days = <DateTime>[];

  for (var day = 1; day <= last.day; day++) {
    final date = DateTime(month.year, month.month, day);
    if (isWeekday(date) || registered.contains(date)) days.add(date);
  }

  return days;
}

class Week {
  const Week({required this.number, required this.label, required this.days});

  /// Sequencial dentro do mês: é o que a merendeira chama de "semana 1".
  final int number;
  final String label;
  final List<DateTime> days;
}

/// Agrupa os dias listados em semanas de segunda a domingo.
///
/// A quebra é pela segunda-feira e não por um bloco de sete dias, senão a
/// primeira semana de um mês que começa numa quinta arrastaria o sábado
/// seguinte para dentro dela.
List<Week> groupIntoWeeks(List<DateTime> days) {
  final weeks = <List<DateTime>>[];

  for (final date in days) {
    final startsWeek = weeks.isEmpty || date.weekday == 1;
    if (startsWeek) weeks.add(<DateTime>[]);
    weeks.last.add(date);
  }

  return [
    for (var i = 0; i < weeks.length; i++)
      Week(number: i + 1, label: _weekLabel(i + 1, weeks[i]), days: weeks[i]),
  ];
}

String _weekLabel(int number, List<DateTime> days) {
  final first = days.first;
  final last = days.last;
  final range = first == last
      ? dayAndMonth(first)
      : '${first.day} a ${dayAndMonth(last)}';

  return 'Semana $number · $range';
}

// ---------------------------------------------------------------------------
// O andamento do mês
// ---------------------------------------------------------------------------

class MonthProgress {
  const MonthProgress({
    required this.schoolDays,
    required this.done,
    required this.counts,
  });

  /// Dias letivos do mês: os listados, menos os marcados como não letivos.
  final int schoolDays;

  /// Dias prontos — completos ou já dentro de um documento.
  final int done;
  final Map<DayState, int> counts;
}

MonthProgress monthProgress(
  List<DateTime> days,
  Map<DateTime, DayRecord> byDate,
) {
  final counts = {for (final state in DayState.values) state: 0};

  for (final date in days) {
    final state = dayState(byDate[date]);
    counts[state] = counts[state]! + 1;
  }

  return MonthProgress(
    schoolDays: days.length - counts[DayState.nonSchool]!,
    done: counts[DayState.complete]! + counts[DayState.locked]!,
    counts: counts,
  );
}

/// "6 preenchidos · 1 pendente · 1 não letivo · 5 no documento".
///
/// Estado zerado não aparece: "0 pendentes" ocupa espaço para dizer que nada
/// aconteceu, e a linha existe para ela achar rápido o que falta.
String progressBreakdown(Map<DayState, int> counts) {
  return _breakdownOrder
      .where((state) => counts[state]! > 0)
      .map((state) {
        final amount = counts[state]!;
        final label = amount == 1
            ? dayStateLabels[state]!.toLowerCase()
            : _dayStatePlural[state]!;
        return '$amount $label';
      })
      .join(' · ');
}

String schoolDaysLabel(int days) =>
    days == 1 ? '1 dia letivo' : '$days dias letivos';

String progressLabel(int done, int schoolDays) =>
    '$done de $schoolDays ${schoolDays == 1 ? 'dia' : 'dias'}';
