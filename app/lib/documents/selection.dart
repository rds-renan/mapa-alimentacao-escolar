/// A seleção de mapas — a regra da tela 5, sem Flutter e sem rede. Porto de
/// `web/src/documents/selection.ts` (issue #108).
///
/// O que ela decide é uma pergunta só: **quais dias podem entrar num
/// documento oficial?** E a resposta não é a mesma que a visão do mês dá. Lá o
/// estado do dia descreve o que existe; aqui ele decide o que sai numa
/// prestação de contas, e a régua é mais dura em dois pontos:
///
/// - **Dia pendente não entra em documento.** O servidor o aceitaria, mas a
///   decisão do projeto foi outra: um mapa incompleto que vai à prefeitura é
///   um mapa que volta, e o bloqueio da geração é irreversível para a
///   merendeira. Então ele não é selecionável, e o atalho que não consegue
///   fechar o período inteiro não seleciona nada — avisa o que falta.
/// - **Dia que ainda não subiu não entra**, porque o documento é montado no
///   servidor com o que está lá (RN#3 da US012). O rascunho no aparelho tem
///   um identificador próprio que o servidor pode nem ter adotado.
///
/// **Bloqueado, esse, entra.** Bloqueio é sobre editar, nunca sobre sair de
/// novo: sustenta a regeração depois de uma correção (CA#4 da US023) e deixa
/// gerar o mês inteiro depois de já ter gerado uma semana dele.
library;

import '../month/month.dart';

/// Os três jeitos de escolher da tela 5. São modos, e não botões de ação: os
/// dois primeiros escolhem por período e dispensam marcar dia a dia, que é o
/// "poucos toques" do RNF#1 da US013.
enum SelectionMode { month, week, days }

/// Um dia na lista da tela 5.
class DayOption {
  const DayOption({
    required this.date,
    required this.id,
    required this.state,
    required this.unsent,
    required this.eligible,
    required this.meals,
  });

  final DateTime date;

  /// O identificador do mapa no servidor. É o que a geração recebe.
  final String? id;
  final DayState state;

  /// Guardado no aparelho, ainda esperando subir.
  final bool unsent;

  /// Pode entrar num documento.
  final bool eligible;

  /// Quantas refeições o dia descreve.
  final int meals;
}

/// Por que um dia não pode entrar. É o que a merendeira precisa ir resolver.
enum MissingReason { pending, empty, unsent }

const _canBeGenerated = {
  DayState.complete,
  DayState.locked,
  DayState.nonSchool,
};

DayOption toOption(DateTime date, DayRecord? record) {
  final state = dayState(record);
  final unsent = record?.unsent ?? false;
  final id = record?.id;

  return DayOption(
    date: date,
    id: id,
    state: state,
    unsent: unsent,
    eligible: id != null && !unsent && _canBeGenerated.contains(state),
    meals:
        record?.meals
            .where((meal) => meal.description?.trim().isNotEmpty ?? false)
            .length ??
        0,
  );
}

List<DayOption> toOptions(
  List<DateTime> days,
  Map<DateTime, DayRecord> byDate,
) => [for (final date in days) toOption(date, byDate[date])];

/// O motivo de o dia estar de fora, na ordem em que ele é acionável.
///
/// "Esperando enviar" vem antes de tudo porque é o único que se resolve
/// sozinho — basta haver internet —, e mandá-la abrir um dia que já está
/// preenchido para "terminar de preencher" seria mentira.
MissingReason? missingReason(DayOption option) {
  if (option.eligible) return null;
  if (option.unsent) return MissingReason.unsent;
  if (option.state == DayState.pending) return MissingReason.pending;
  return MissingReason.empty;
}

/// Os dias do período que impedem de fechá-lo.
List<DayOption> missingDays(List<DayOption> options) =>
    options.where((option) => !option.eligible).toList();

/// O período fecha: todo dia listado pode entrar no documento.
bool closable(List<DayOption> options) =>
    options.isNotEmpty && options.every((option) => option.eligible);

List<DayOption> eligibleOf(List<DayOption> options) =>
    options.where((option) => option.eligible).toList();

/// Como o período aparece na confirmação: "Gerar o documento de
/// **setembro**?".
///
/// É a mesma regra que o preenchimento do modelo usa no campo "MÊS/ANO": o
/// rótulo nomeia os meses que a seleção toca, e não os dias. O ano só
/// aparece quando a seleção atravessa dois, que é quando omiti-lo passaria a
/// mentir.
String periodLabel(Iterable<DateTime> dates) {
  final months = {
    for (final date in dates) date.year * 12 + date.month - 1,
  }.toList()..sort();
  if (months.isEmpty) return '';

  final years = {for (final month in months) month ~/ 12};
  String name(int month) {
    final date = DateTime(month ~/ 12, month % 12 + 1);
    return years.length > 1
        ? '${monthName(date)} de ${date.year}'
        : monthName(date);
  }

  final first = name(months.first);
  if (months.length == 1) return first;

  final last = name(months.last);
  return months.length == 2 ? '$first e $last' : '$first a $last';
}
