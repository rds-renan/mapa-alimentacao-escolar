import 'package:flutter_test/flutter_test.dart';
import 'package:mae/documents/generated.dart';
import 'package:mae/documents/messages.dart';

/// As regras da tela 2b, sem Flutter e sem rede. O relógio é sempre
/// explícito, e é o ponto: a situação de um documento não está gravada em
/// lugar nenhum — ela é a comparação entre o prazo que o banco carimbou e o
/// dia em que a merendeira olha.
void main() {
  /// 9 de setembro de 2026, 14h32.
  final now = DateTime(2026, 9, 9, 14, 32);

  GeneratedDocumentRecord document({
    String status = 'available',
    DateTime? requestedAt,
    DateTime? completedAt,
    DateTime? expiresAt,
    List<DateTime>? dates,
  }) => GeneratedDocumentRecord(
    id: 'doc-1',
    status: status,
    requestedAt: requestedAt ?? DateTime(2026, 9, 9, 14, 32),
    completedAt: completedAt ?? DateTime(2026, 9, 9, 14, 32),
    expiresAt: expiresAt ?? DateTime(2026, 9, 16, 14, 32),
    filePath: 'escola/doc-1.docx',
    fileName: 'mapa-da-alimentacao-escolar-setembro-2026.docx',
    dates: dates ?? [DateTime(2026, 9, 1), DateTime(2026, 9, 2)],
  );

  /// Todos os dias úteis de setembro de 2026: o mês que fecha inteiro.
  List<DateTime> setembroInteiro() => [
    for (var day = 1; day <= 30; day++)
      if (DateTime(2026, 9, day).weekday <= 5) DateTime(2026, 9, day),
  ];

  group('a situação do documento', () {
    test('no ar e com folga é disponível', () {
      final available = availabilityOf(document(), now);

      expect(available, DocumentAvailability.available);
      expect(downloadable(available), isTrue);
    });

    test('vencendo amanhã é "sai amanhã", e ainda abre', () {
      final amanha = document(expiresAt: DateTime(2026, 9, 10, 8));
      final availability = availabilityOf(amanha, now);

      expect(availability, DocumentAvailability.expiring);
      expect(
        availabilityLabel(availability, daysLeft(amanha, now)),
        'Sai amanhã',
      );
      expect(downloadable(availability), isTrue);
    });

    test('vencendo hoje à noite ainda está no ar, e diz "Sai hoje"', () {
      final hoje = document(expiresAt: DateTime(2026, 9, 9, 23));
      final availability = availabilityOf(hoje, now);

      expect(availability, DocumentAvailability.expiring);
      expect(availabilityLabel(availability, daysLeft(hoje, now)), 'Sai hoje');
    });

    test('passado o prazo, sai do ar e não oferece arquivo', () {
      final vencido = document(expiresAt: DateTime(2026, 9, 9, 12));
      final availability = availabilityOf(vencido, now);

      expect(availability, DocumentAvailability.expired);
      expect(downloadable(availability), isFalse);
    });

    test(
      'disponível sem prazo, que o banco não permite, é tratado como vencido',
      () {
        final semPrazo = GeneratedDocumentRecord(
          id: 'doc-1',
          status: 'available',
          requestedAt: now,
          completedAt: now,
          expiresAt: null,
          filePath: null,
          fileName: null,
          dates: const [],
        );

        expect(availabilityOf(semPrazo, now), DocumentAvailability.expired);
      },
    );

    test('a geração em curso e a que falhou não oferecem arquivo', () {
      final gerando = document(status: 'processing');
      final falhou = document(status: 'failed');

      expect(availabilityOf(gerando, now), DocumentAvailability.processing);
      expect(downloadable(availabilityOf(gerando, now)), isFalse);
      expect(availabilityOf(falhou, now), DocumentAvailability.failed);
      expect(downloadable(availabilityOf(falhou, now)), isFalse);
    });
  });

  group('o período do documento', () {
    test('um dia só é a data', () {
      expect(periodTitle([DateTime(2026, 9, 10)]), '10 de setembro');
    });

    test('dias dentro do mês são o intervalo', () {
      expect(
        periodTitle([
          DateTime(2026, 9, 1),
          DateTime(2026, 9, 8),
          DateTime(2026, 9, 12),
        ]),
        '1 a 12 de setembro',
      );
    });

    test('o mês fechado se diz pelo nome', () {
      expect(periodTitle(setembroInteiro()), 'Setembro · mês inteiro');
    });

    test('faltando um dia útil, volta a ser intervalo', () {
      final semODia15 = setembroInteiro()..remove(DateTime(2026, 9, 15));

      expect(periodTitle(semODia15), '1 a 30 de setembro');
    });

    test('a seleção que atravessa meses nomeia os dois', () {
      expect(
        periodTitle([DateTime(2026, 8, 31), DateTime(2026, 9, 4)]),
        '31 de agosto a 4 de setembro',
      );
    });

    test('atravessando o ano-novo, o ano aparece dos dois lados', () {
      expect(
        periodTitle([DateTime(2026, 12, 28), DateTime(2027, 1, 5)]),
        '28 de dezembro de 2026 a 5 de janeiro de 2027',
      );
    });

    test('a ordem em que os dias chegam não muda o rótulo', () {
      expect(
        periodTitle([DateTime(2026, 9, 12), DateTime(2026, 9, 1)]),
        '1 a 12 de setembro',
      );
    });
  });

  group('as linhas de apoio do cartão', () {
    test('conta os mapas no singular e no plural', () {
      expect(mapCountLabel(1), '1 mapa');
      expect(mapCountLabel(10), '10 mapas');
    });

    test('gerado hoje mostra a hora, que é o que separa duas gerações', () {
      expect(documentSummary(document(), now), '2 mapas · gerado hoje, 14h32');
    });

    test('gerado antes de hoje mostra a data, e a hora vira ruído', () {
      final ontem = document(completedAt: DateTime(2026, 9, 1, 9, 5));

      expect(documentSummary(ontem, now), '2 mapas · gerado em 1 de setembro');
    });

    test('a geração em curso se data pelo pedido, que é o que ela tem', () {
      final gerando = GeneratedDocumentRecord(
        id: 'doc-1',
        status: 'processing',
        requestedAt: DateTime(2026, 9, 9, 14, 30),
        completedAt: null,
        expiresAt: null,
        filePath: null,
        fileName: null,
        dates: [DateTime(2026, 9, 1)],
      );

      expect(documentSummary(gerando, now), '1 mapa · gerado hoje, 14h30');
    });

    test('diz quando o arquivo sai do ar', () {
      expect(expiryLabel(document()), 'Sai do ar em 16 de setembro');
    });
  });

  test('a mensagem de bloqueio concorda com a quantidade', () {
    expect(lockedNotice(1), startsWith('O mapa incluído ficou bloqueado'));
    expect(lockedNotice(22), startsWith('Os 22 mapas incluídos ficaram'));
  });
}
