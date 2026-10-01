import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mae/local/app_database.dart';
import 'package:mae/local/documents_gateway.dart';
import 'package:mae/local/documents_repository.dart';

import '../documents/fake_documents.dart';

/// A cópia local da lista de documentos (issue #109, CA#3).
void main() {
  late AppDatabase db;
  late FakeDocumentsGateway gateway;
  late GeneratedDocumentsRepository repository;

  RemoteDocument remote(
    String id, {
    String status = 'available',
    List<String> dates = const ['2026-09-01', '2026-09-02'],
    DateTime? requestedAt,
  }) => RemoteDocument(
    id: id,
    status: status,
    requestedAt: requestedAt ?? DateTime.utc(2026, 9, 9, 17, 32),
    completedAt: DateTime.utc(2026, 9, 9, 17, 32),
    expiresAt: DateTime.utc(2026, 9, 16, 17, 32),
    filePath: 'escola/$id.docx',
    fileName: '$id.docx',
    dates: dates,
  );

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    gateway = FakeDocumentsGateway();
    repository = GeneratedDocumentsRepository(db, gateway);
  });

  tearDown(() => db.close());

  test('guarda a lista e a devolve da mais nova para a mais velha', () async {
    gateway.documents = [
      remote('antigo', requestedAt: DateTime.utc(2026, 9, 1)),
      remote('novo', dates: ['2026-09-08']),
    ];

    await repository.refresh();
    final list = await repository.watch().first;

    expect([for (final doc in list) doc.id], ['novo', 'antigo']);
    expect(list.first.dates, [DateTime(2026, 9, 8)]);
    expect(list.last.dates, [DateTime(2026, 9, 1), DateTime(2026, 9, 2)]);
    expect(list.first.fileName, 'novo.docx');
  });

  test('o que o servidor deixou de devolver sai da cópia', () async {
    gateway.documents = [remote('a'), remote('b')];
    await repository.refresh();

    gateway.documents = [remote('b', status: 'failed')];
    await repository.refresh();
    final list = await repository.watch().first;

    expect([for (final doc in list) doc.id], ['b']);
    expect(list.single.status, 'failed');
  });

  test('sem rede a cópia não é tocada, e o erro chega a quem chamou', () async {
    gateway.documents = [remote('a')];
    await repository.refresh();

    gateway.fetchError = Exception('sem rede');

    await expectLater(repository.refresh(), throwsException);
    expect(await repository.watch().first, hasLength(1));
  });

  test('documento sem mapas ligados vira lista de datas vazia', () async {
    gateway.documents = [remote('a', status: 'processing', dates: const [])];

    await repository.refresh();

    expect((await repository.watch().first).single.dates, isEmpty);
  });

  test('lê a resposta do servidor, com as datas da ligação em ordem', () {
    final doc = RemoteDocument.fromRow({
      'id': 'doc-1',
      'status': 'available',
      'requested_at': '2026-09-09T17:32:00+00:00',
      'completed_at': '2026-09-09T17:32:01+00:00',
      'expires_at': '2026-09-16T17:32:01+00:00',
      'file_path': 'escola/doc-1.docx',
      'file_name': 'mapa.docx',
      'document_meal_map': [
        {
          'meal_map': {'map_date': '2026-09-02'},
        },
        {'meal_map': null},
        {
          'meal_map': {'map_date': '2026-09-01'},
        },
      ],
    });

    expect(doc.dates, ['2026-09-01', '2026-09-02']);
    expect(doc.expiresAt, DateTime.utc(2026, 9, 16, 17, 32, 1));
  });
}
