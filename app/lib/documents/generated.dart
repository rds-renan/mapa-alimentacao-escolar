/// O documento gerado como a tela de documentos gerados precisa dele — porto
/// de `web/src/documents/generated.ts` (issue #109, tela 2b da E3).
///
/// Tudo aqui é função pura sobre data e número, pelo mesmo motivo do mês: o
/// que a tela tem de difícil não é desenhar os cartões, é dizer em que
/// situação está cada documento — e essa conta se faz com o relógio de quem
/// olha, que por isso é sempre explícito ([now]). A situação não está gravada
/// em lugar nenhum: é a comparação entre o prazo que o banco carimbou e o dia
/// de hoje (decisão 10 da E4).
library;

import '../month/month.dart';

/// A situação do documento **para quem olha agora**, que não é a do banco.
enum DocumentAvailability {
  /// A geração está em curso.
  processing,

  /// O arquivo está no ar e ainda tem folga.
  available,

  /// Está no ar, mas sai hoje ou amanhã.
  expiring,

  /// Passou da janela de sete dias: o arquivo já não existe (RN#1 da US021).
  expired,

  /// A geração não produziu arquivo nenhum.
  failed,
}

/// Um documento gerado, como a lista o guarda no aparelho.
class GeneratedDocumentRecord {
  const GeneratedDocumentRecord({
    required this.id,
    required this.status,
    required this.requestedAt,
    required this.completedAt,
    required this.expiresAt,
    required this.filePath,
    required this.fileName,
    required this.dates,
  });

  final String id;

  /// `processing`, `available` ou `failed`, como no banco.
  final String status;
  final DateTime requestedAt;
  final DateTime? completedAt;
  final DateTime? expiresAt;

  /// O endereço no balde. É com ele que o arquivo se busca.
  final String? filePath;

  /// O nome com que o arquivo chega em quem o recebe — o que a geração
  /// gravou, e não uma regra recalculada aqui.
  final String? fileName;

  /// As datas dos mapas incluídos, em ordem. Delas saem o período e a conta.
  final List<DateTime> dates;
}

// ---------------------------------------------------------------------------
// A situação
// ---------------------------------------------------------------------------

/// Quantos dias de calendário faltam para o arquivo sair do ar. É conta de
/// calendário, e não de vinte e quatro horas: um documento que vence às 23h de
/// hoje não sai "em um dia" para quem olha às 8h da manhã. Zero é hoje;
/// negativo já saiu.
int? daysLeft(GeneratedDocumentRecord document, DateTime now) {
  final expiresAt = document.expiresAt;
  if (expiresAt == null) return null;

  final today = dateOnly(now);
  final expiry = dateOnly(expiresAt.toLocal());

  // Em UTC para a diferença não escorregar na virada do horário de verão.
  return DateTime.utc(
    expiry.year,
    expiry.month,
    expiry.day,
  ).difference(DateTime.utc(today.year, today.month, today.day)).inDays;
}

DocumentAvailability availabilityOf(
  GeneratedDocumentRecord document,
  DateTime now,
) {
  if (document.status == 'failed') return DocumentAvailability.failed;
  if (document.status == 'processing') return DocumentAvailability.processing;

  // Disponível sem prazo não existe — o check do banco exige os dois juntos
  // —, mas o cliente não é quem garante isso. Tratar o caso impossível como
  // vencido é o lado seguro: no máximo ela vê um documento a menos, e nunca
  // um botão que busca o nada.
  final expiresAt = document.expiresAt;
  if (expiresAt == null || !expiresAt.isAfter(now)) {
    return DocumentAvailability.expired;
  }

  return daysLeft(document, now)! <= 1
      ? DocumentAvailability.expiring
      : DocumentAvailability.available;
}

/// O arquivo pode ser aberto e compartilhado agora.
bool downloadable(DocumentAvailability availability) =>
    availability == DocumentAvailability.available ||
    availability == DocumentAvailability.expiring;

// ---------------------------------------------------------------------------
// O período
// ---------------------------------------------------------------------------

/// Todo dia útil do mês entrou. É o que separa "1 a 30 de setembro" de
/// "Setembro · mês inteiro" — e a conta é possível porque o mês inteiro, no
/// MAE, é exatamente os dias úteis: o dia não letivo também tem mapa, e o fim
/// de semana só entra quando alguém registrou.
bool _coversWholeMonth(List<DateTime> sorted) {
  final month = sorted.first;
  final included = {for (final date in sorted) dateOnly(date)};
  final lastDay = lastDayOfMonth(month).day;

  for (var day = 1; day <= lastDay; day += 1) {
    final date = DateTime(month.year, month.month, day);
    if (isWeekday(date) && !included.contains(date)) return false;
  }

  return true;
}

/// O título do cartão: o que a merendeira chama de "aquele documento".
///
/// São as três formas do desenho da E3, e a régua entre elas é não mentir: um
/// dia só é a data; o mês fechado se diz pelo nome, porque é assim que ela o
/// pediu; e o resto é o intervalo, que é o que o documento realmente cobre.
String periodTitle(List<DateTime> dates) {
  if (dates.isEmpty) return '';

  final sorted = [for (final date in dates) dateOnly(date)]..sort();
  final first = sorted.first;
  final last = sorted.last;

  if (first == last) return dayAndMonth(first);

  // Seleção que atravessa o ano-novo: sem o ano, os dois lados ficam iguais.
  if (first.year != last.year) {
    return '${dayAndMonth(first)} de ${first.year} a '
        '${dayAndMonth(last)} de ${last.year}';
  }

  if (first.month != last.month) {
    return '${dayAndMonth(first)} a ${dayAndMonth(last)}';
  }

  if (_coversWholeMonth(sorted)) {
    final name = monthName(first);
    return '${name[0].toUpperCase()}${name.substring(1)} · mês inteiro';
  }

  return '${first.day} a ${dayAndMonth(last)}';
}

// ---------------------------------------------------------------------------
// As linhas de apoio
// ---------------------------------------------------------------------------

String mapCountLabel(int count) => count == 1 ? '1 mapa' : '$count mapas';

/// "14h32" — a hora como ela aparece no cartão do dia em que foi gerado.
String _timeOfDay(DateTime moment) =>
    '${moment.hour}h${moment.minute.toString().padLeft(2, '0')}';

/// "gerado hoje, 14h32" ou "gerado em 1 de setembro".
///
/// A hora só aparece no dia em que aconteceu, que é quando ela distingue duas
/// gerações; num documento de três dias atrás, a hora é ruído.
String generatedLabel(GeneratedDocumentRecord document, DateTime now) {
  final instant = (document.completedAt ?? document.requestedAt).toLocal();

  return dateOnly(instant) == dateOnly(now)
      ? 'gerado hoje, ${_timeOfDay(instant)}'
      : 'gerado em ${dayAndMonth(instant)}';
}

/// "10 mapas · gerado hoje, 14h32" — a linha sob o título do cartão.
String documentSummary(GeneratedDocumentRecord document, DateTime now) =>
    '${mapCountLabel(document.dates.length)} · '
    '${generatedLabel(document, now)}';

/// "Sai do ar em 16 de setembro".
String expiryLabel(GeneratedDocumentRecord document) {
  final expiresAt = document.expiresAt;
  if (expiresAt == null) return '';
  return 'Sai do ar em ${dayAndMonth(expiresAt.toLocal())}';
}
