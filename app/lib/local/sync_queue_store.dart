import 'dart:convert';

import 'package:drift/drift.dart';

import 'app_database.dart';
import 'day.dart';

/// Por que um dia parou de ser reenviado.
class Rejection {
  const Rejection({required this.code, required this.message});

  /// O SQLSTATE que veio do servidor, para o teste e o relato dizerem qual
  /// foi.
  final String code;

  /// A frase do servidor, que já vem legível para quem vai lê-la.
  final String message;
}

/// Um dia guardado no aparelho. Está aqui porque ainda não subiu — ou porque
/// subiu e voltou recusado, e jogá-lo fora seria perder o que ela digitou.
class StoredDay {
  const StoredDay({
    required this.day,
    required this.attempts,
    required this.rejection,
    required this.queuedAt,
  });

  final DayPayload day;

  /// Tentativas de envio seguidas sem sucesso. Comanda a espera até a
  /// próxima.
  final int attempts;
  final Rejection? rejection;

  /// Quando entrou na fila. É a ordem de envio.
  final DateTime queuedAt;

  String get mapDate => day.mapDate;
}

/// O que aconteceu com o dia depois de o servidor responder.
enum SettleOutcome { removed, kept, gone }

/// O armazenamento local da fila: uma linha por dia ainda não confirmado.
///
/// Mesma regra de `web/src/local/store.ts` — **estar guardado aqui é ser dia
/// que o servidor ainda não confirmou** (RN#1 da US011) —, mas sobre o
/// Drift, e sem coluna de usuária: o arquivo já é de uma só (decisão 6 da
/// E6), então a chave é só a data do dia.
class SyncQueueStore {
  SyncQueueStore(this._db);

  final AppDatabase _db;

  /// Grava o dia, zerando tentativas e recusa: ela mexeu de novo, e o que
  /// causou a recusa da vez passada pode ter sido corrigido agora.
  Future<void> put(DayPayload day) async {
    final key = DateTime.parse(day.mapDate);
    final existing = await _getRow(key);

    await _db
        .into(_db.pendingMealMaps)
        .insertOnConflictUpdate(
          PendingMealMapsCompanion.insert(
            mapDate: key,
            payload: jsonEncode(day.toJson()),
            attempts: const Value(0),
            // Explícitos, não omitidos: em cima de um conflito,
            // `insertOnConflictUpdate` só toca as colunas presentes na
            // companion, e uma recusa antiga tem de sair daqui também.
            rejectionCode: const Value(null),
            rejectionMessage: const Value(null),
            queuedAtMicros:
                existing?.queuedAtMicros ??
                DateTime.now().microsecondsSinceEpoch,
          ),
        );
  }

  Future<StoredDay?> get(String mapDate) async {
    final row = await _getRow(DateTime.parse(mapDate));
    return row == null ? null : _fromRow(row);
  }

  /// Os dias por enviar, na ordem em que entraram na fila.
  Future<List<StoredDay>> list() async {
    final rows = await (_db.select(
      _db.pendingMealMaps,
    )..orderBy([(t) => OrderingTerm(expression: t.queuedAtMicros)])).get();

    return rows.map(_fromRow).toList();
  }

  /// O servidor confirmou. O dia sai do aparelho — **a não ser** que ela
  /// tenha continuado digitando enquanto aquilo subia: nesse caso o que está
  /// aqui já é mais novo que o confirmado, e fica na fila, com os
  /// identificadores que o servidor devolveu já adotados.
  ///
  /// A comparação e a saída acontecem na mesma transação: entre uma e outra
  /// cabe a tecla seguinte, e apagar aí seria descartar o que ela acabou de
  /// digitar.
  Future<SettleOutcome> settle(
    String mapDate,
    String sentUpdatedAt,
    DayPayload Function(DayPayload) adopt,
  ) async {
    final key = DateTime.parse(mapDate);

    return _db.transaction(() async {
      final row = await _getRow(key);
      if (row == null) return SettleOutcome.gone;

      final day = _decode(row.payload);

      if (day.updatedAt == sentUpdatedAt) {
        await (_db.delete(
          _db.pendingMealMaps,
        )..where((t) => t.mapDate.equals(key))).go();
        return SettleOutcome.removed;
      }

      await _db
          .update(_db.pendingMealMaps)
          .replace(
            row.copyWith(
              payload: jsonEncode(adopt(day).toJson()),
              attempts: 0,
              rejectionCode: const Value(null),
              rejectionMessage: const Value(null),
            ),
          );
      return SettleOutcome.kept;
    });
  }

  /// Marca mais uma tentativa sem sucesso, sem tocar no dia. O que ela
  /// digitou enquanto o envio estava no ar continua sendo o que está
  /// guardado.
  Future<void> markRetried(String mapDate) async {
    final key = DateTime.parse(mapDate);

    await _db.transaction(() async {
      final row = await _getRow(key);
      if (row == null) return;

      await _db
          .update(_db.pendingMealMaps)
          .replace(row.copyWith(attempts: row.attempts + 1));
    });
  }

  /// Recusa que não se resolve reenviando. O dia continua guardado — só para
  /// de ser tentado.
  Future<void> markRejected(String mapDate, Rejection rejection) async {
    final key = DateTime.parse(mapDate);

    await _db.transaction(() async {
      final row = await _getRow(key);
      if (row == null) return;

      await _db
          .update(_db.pendingMealMaps)
          .replace(
            row.copyWith(
              attempts: 0,
              rejectionCode: Value(rejection.code),
              rejectionMessage: Value(rejection.message),
            ),
          );
    });
  }

  Future<PendingMealMap?> _getRow(DateTime mapDate) {
    return (_db.select(
      _db.pendingMealMaps,
    )..where((t) => t.mapDate.equals(mapDate))).getSingleOrNull();
  }

  StoredDay _fromRow(PendingMealMap row) => StoredDay(
    day: _decode(row.payload),
    attempts: row.attempts,
    rejection: row.rejectionCode == null
        ? null
        : Rejection(code: row.rejectionCode!, message: row.rejectionMessage!),
    queuedAt: DateTime.fromMicrosecondsSinceEpoch(row.queuedAtMicros),
  );

  DayPayload _decode(String payload) =>
      DayPayload.fromJson(jsonDecode(payload) as Map<String, dynamic>);
}
