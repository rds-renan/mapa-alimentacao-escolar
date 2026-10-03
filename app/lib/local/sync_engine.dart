import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show AppLifecycleListener;
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../version/version_gate.dart';
import 'confirmed_copy.dart';
import 'connectivity_gateway.dart';
import 'day.dart';
import 'sync_gateway.dart';
import 'sync_messages.dart';
import 'sync_queue_store.dart';

/*
 * A fila de envio — a versão em Dart de `web/src/local/sync.ts` (issue #103).
 *
 * Ela existe porque a gravação e o envio são dois tempos diferentes: a tecla
 * é agora, a internet é quando der. Cada alteração de campo vira rascunho no
 * aparelho **imediatamente**, e o envio é uma tentativa que se repete
 * sozinha até o servidor confirmar (decisão 8 da E6).
 *
 * A unidade é o dia inteiro, como a decisão 9 da E4 definiu, e é isso que
 * torna a fila idempotente: reenviar é reescrever o mesmo dia, com o mesmo
 * carimbo de edição, e dá o mesmo dia. Quando a rede cai entre a gravação e
 * a confirmação, o aparelho reenvia sem saber se chegou, e o servidor não
 * duplica nada.
 */

/// A espera entre a última tecla e o envio. Não é para poupar o servidor: é
/// para não mandar o dia inteiro a cada letra digitada na descrição da
/// refeição. O rascunho, esse, já foi escrito antes da espera começar.
const _sendDelay = Duration(milliseconds: 1200);

/// A espera antes de tentar de novo, dobrando a cada falha, com teto de um
/// minuto.
Duration _retryDelay(int attempts) {
  final ms = 2000 * pow(2, max(0, attempts - 1));
  return Duration(milliseconds: min(ms, 60000).toInt());
}

class DaySyncState {
  const DaySyncState({
    required this.status,
    required this.message,
    this.detail,
  });

  final SyncStatus status;

  /// O texto da faixa, dos três da E3.
  final String message;

  /// A frase do servidor, quando a recusa tem explicação própria.
  final String? detail;
}

class Conflict {
  const Conflict({
    required this.mapDate,
    required this.message,
    required this.updatedAt,
  });

  final String mapDate;
  final String message;

  /// O carimbo que passou a valer no servidor.
  final String updatedAt;
}

@immutable
class SyncState {
  const SyncState({
    required this.days,
    required this.pending,
    required this.sending,
    required this.conflicts,
  });

  static const empty = SyncState(
    days: {},
    pending: 0,
    sending: false,
    conflicts: [],
  );

  /// O estado de cada dia que esta sessão conhece, pela data.
  final Map<String, DaySyncState> days;

  /// Quantos dias estão guardados no aparelho, ainda não confirmados.
  final int pending;

  /// A fila está tentando enviar agora.
  final bool sending;

  /// Um por dia, e nenhum some sem a usuária ver.
  final List<Conflict> conflicts;

  SyncState copyWith({
    Map<String, DaySyncState>? days,
    int? pending,
    bool? sending,
    List<Conflict>? conflicts,
  }) => SyncState(
    days: days ?? this.days,
    pending: pending ?? this.pending,
    sending: sending ?? this.sending,
    conflicts: conflicts ?? this.conflicts,
  );
}

enum _SendOutcome { ok, retry, again, outdated }

enum _ErrorClass { retry, rejected, outdated }

/*
 * A distinção que decide tudo na fila: **o que se resolve reenviando e o que
 * não se resolve**. A tabela de erros da gravação do dia
 * (`docs/05-web/gravacao-do-dia.md`) é a fonte.
 */
_ErrorClass _classify(String? code) {
  switch (code) {
    // O aplicativo está abaixo da versão mínima (decisão 12 da E6). Nem
    // reenviar nem desistir do dia resolve: o dia fica na fila, intocado,
    // até o aplicativo novo mandá-lo.
    case 'PT426':
      return _ErrorClass.outdated;

    // Payload incoerente ou mapa bloqueado; e perfil sem permissão de
    // registrar. Reenviar daria exatamente o mesmo erro.
    case '23514':
    case '42501':
      return _ErrorClass.rejected;

    // Dois aparelhos criando o mesmo dia no mesmo instante. Na segunda vez o
    // dia já existe e vale a comparação de datas.
    case '40001':
      return _ErrorClass.retry;

    // Sem código é falha de rede, que é o caso comum aqui e sempre se
    // reenvia.
    default:
      return _ErrorClass.retry;
  }
}

final _sentState = DaySyncState(
  status: SyncStatus.sent,
  message: syncMessages[SyncStatus.sent]!,
);

/// A fila de envio, viva enquanto o aplicativo está aberto (decisão 8 da
/// E6). Nasce sobre o banco da usuária que está com a sessão aberta — não há
/// troca de motor por usuária como na web, porque o arquivo já separa as
/// duas (decisão 6 da E6).
class SyncEngine {
  SyncEngine(
    this._store,
    this._gateway, {
    ConnectivityGateway? connectivity,
    this._version,
    this._onSuperseded,
  }) : _connectivity = connectivity ?? ConnectivityPlusGateway();

  final SyncQueueStore _store;
  final SyncGateway _gateway;
  final ConnectivityGateway _connectivity;

  /// A trava de versão mínima (issue #113). Sem ela, a fila não confere
  /// versão — é como os testes que não falam disso a montam.
  final VersionGate? _version;

  bool get _outdated => _version?.outdated ?? false;

  /// Quem busca o dia de novo no servidor quando ele tem edição mais recente
  /// (issue #124) — na prática, a leitura do mês daquele dia. Sem ela, a
  /// fila não relê nada, que é como os testes que não falam disso a montam.
  final Future<void> Function(String mapDate)? _onSuperseded;

  final ValueNotifier<SyncState> _state = ValueNotifier(SyncState.empty);
  ValueListenable<SyncState> get stateListenable => _state;
  SyncState get state => _state.value;

  bool _started = false;
  Timer? _sendTimer;
  Future<void>? _running;
  bool _rerun = false;
  StreamSubscription<bool>? _connectivitySubscription;
  AppLifecycleListener? _lifecycleListener;

  void _patch({
    Map<String, DaySyncState>? days,
    int? pending,
    bool? sending,
    List<Conflict>? conflicts,
  }) {
    _state.value = _state.value.copyWith(
      days: days,
      pending: pending,
      sending: sending,
      conflicts: conflicts,
    );
  }

  void _setDay(String mapDate, DaySyncState day) {
    _patch(days: {..._state.value.days, mapDate: day});
  }

  DaySyncState _stateOf(SyncStatus status) =>
      DaySyncState(status: status, message: syncMessages[status]!);

  DaySyncState _stateFor(StoredDay record) {
    final rejection = record.rejection;
    if (rejection != null) {
      return DaySyncState(
        status: SyncStatus.failed,
        message: rejectedMessage,
        detail: rejection.message,
      );
    }

    // Abaixo do mínimo, a frase de sempre ("a gente atualiza na nuvem quando
    // a internet voltar") seria falsa.
    if (_outdated) return _stateOf(SyncStatus.outdated);

    /*
     * Falhou tentando, mas é falha que passa: a fila continua insistindo. Só
     * a partir da primeira tentativa frustrada a faixa muda de tom — antes
     * dela o estado honesto é "salvo no aparelho", que é o que de fato
     * aconteceu.
     */
    final status = record.attempts > 0 ? SyncStatus.failed : SyncStatus.pending;
    return DaySyncState(status: status, message: syncMessages[status]!);
  }

  Future<void> _refreshPending() async {
    final records = await _store.list();
    final days = {..._state.value.days};
    for (final record in records) {
      days[record.mapDate] = _stateFor(record);
    }
    _patch(days: days, pending: records.length);
  }

  void _scheduleFlush(Duration delay) {
    if (!_started) return;
    _sendTimer?.cancel();
    _sendTimer = Timer(delay, () {
      _sendTimer = null;
      unawaited(flush());
    });
  }

  /// Manda um dia e decide o que fazer com a resposta. `again` é o caso em
  /// que ela continuou digitando enquanto aquilo subia: o dia continua na
  /// fila, e o que sobe na volta seguinte já é o texto novo.
  Future<_SendOutcome> _send(StoredDay record) async {
    final sentUpdatedAt = record.day.updatedAt;

    Map<String, dynamic> response;
    try {
      response = await _gateway.saveMealMap(record.day.toJson());
    } on PostgrestException catch (error) {
      final errorClass = _classify(error.code);
      if (errorClass == _ErrorClass.outdated) {
        _version?.reportRejected();
        return _SendOutcome.outdated;
      }
      if (errorClass == _ErrorClass.retry) {
        await _store.markRetried(record.mapDate);
        return _SendOutcome.retry;
      }

      /*
       * Recusa que não passa. O item sai da fila — insistir daria o mesmo
       * erro —, **mas o dia continua guardado no aparelho**: jogá-lo fora
       * seria perder o que ela digitou, que é exatamente o que a RN#1 da
       * US011 proíbe. Ele volta a ser enviado quando ela corrigir e o
       * rascunho for escrito de novo.
       */
      final rejection = Rejection(
        code: error.code ?? '',
        message: error.message,
      );
      await _store.markRejected(record.mapDate, rejection);
      _setDay(
        record.mapDate,
        DaySyncState(
          status: SyncStatus.failed,
          message: rejectedMessage,
          detail: rejection.message,
        ),
      );
      return _SendOutcome.ok;
    }

    final parsed = SaveResponse.fromJson(response);

    if (parsed.isSuperseded) {
      /*
       * O servidor tem edição mais recente e nada foi gravado. Prevalece a
       * mais recente, por decisão, e o caso é **sinalizado** — o rascunho
       * local sai do aparelho, mas não em silêncio (CA#3 da US011).
       */
      final settled = await _store.settle(
        record.mapDate,
        sentUpdatedAt,
        (day) => adoptServerIds(day, parsed),
      );

      if (settled != SettleOutcome.kept) _setDay(record.mapDate, _sentState);

      /*
       * A resposta não traz o dia que venceu, e a cópia confirmada do
       * aparelho ainda é a de antes dele. Reaberto nesse estado, o dia
       * partiria da cópia velha, e qualquer toque sem intenção — a tela
       * grava sozinha — reenviaria o dia velho com carimbo novo, apagando a
       * edição da colega (issue #124). Por isso a fila manda buscar o dia
       * de novo. Sem esperar: é uma leitura de rede, e a fila não tem por que
       * parar por ela; se falhar, a próxima abertura do mês a refaz.
       */
      final refetch = _onSuperseded;
      if (refetch != null) {
        unawaited(
          Future.sync(() => refetch(record.mapDate)).catchError((Object _) {}),
        );
      }

      _patch(
        conflicts: [
          ..._state.value.conflicts.where(
            (one) => one.mapDate != record.mapDate,
          ),
          Conflict(
            mapDate: record.mapDate,
            message: conflictMessage(record.mapDate),
            updatedAt: parsed.updatedAt,
          ),
        ],
      );

      return settled == SettleOutcome.kept
          ? _SendOutcome.again
          : _SendOutcome.ok;
    }

    /*
     * Gravou. Antes de sair da fila, o dia adota o identificador do mapa e
     * os dos gêneros que o servidor devolveu — são eles que fazem o próximo
     * envio encontrar o registro em vez de tentar criá-lo de novo. E o que
     * subiu passa a ser a cópia confirmada do aparelho, para o dia não sumir
     * entre o rascunho e a próxima leitura do mês (issue #124).
     */
    final outcome = await _store.settle(
      record.mapDate,
      sentUpdatedAt,
      (day) => adoptServerIds(day, parsed),
      confirmed: savedDay(record.day, parsed),
    );

    if (outcome != SettleOutcome.kept) _setDay(record.mapDate, _sentState);

    return outcome == SettleOutcome.kept ? _SendOutcome.again : _SendOutcome.ok;
  }

  Future<void> _drain() async {
    do {
      _rerun = false;

      final records = await _store.list();
      /*
       * Fora da fila ficam dois: o recusado, que reenviar não resolve, e o
       * que ainda não pode subir — o dia não letivo cuja observação ela não
       * escreveu. Os dois continuam guardados no aparelho; o que não
       * acontece é a tentativa que já se sabe perdida.
       */
      final queue = records
          .where((record) => record.rejection == null && canBeSent(record.day))
          .toList();

      _patch(pending: records.length, sending: queue.isNotEmpty);

      if (queue.isEmpty) {
        _patch(sending: false);
        return;
      }

      /*
       * Sem rede não se tenta. A tentativa falharia do mesmo jeito, e a
       * faixa passaria a dizer "aguardando internet" quando a verdade é a
       * outra frase, a que a E3 escreveu para este caso.
       */
      if (!await _connectivity.isOnline()) {
        _patch(sending: false);
        return;
      }

      /*
       * Antes de mandar, a versão (decisão 12 da E6). Abaixo do mínimo, nada
       * sai: o banco recusaria cada dia, e o aplicativo velho não tem por que
       * descobrir isso um dia de cada vez.
       */
      final version = _version;
      if (version != null && await version.check()) {
        await _refreshPending();
        _patch(sending: false);
        return;
      }

      var worstAttempts = 0;
      var again = false;
      var outdated = false;

      for (final record in queue) {
        _SendOutcome outcome;
        try {
          outcome = await _send(record);
        } catch (_) {
          // Erro que nem chegou a virar resposta — rede caindo no meio.
          await _store.markRetried(record.mapDate);
          outcome = _SendOutcome.retry;
        }

        if (outcome == _SendOutcome.retry) {
          worstAttempts = max(worstAttempts, record.attempts + 1);
        }
        if (outcome == _SendOutcome.again) again = true;
        if (outcome == _SendOutcome.outdated) {
          // O banco recusou a versão: os outros dias teriam a mesma resposta.
          outdated = true;
          break;
        }
      }

      await _refreshPending();
      _patch(sending: false);

      // Sem nova tentativa agendada: só o aplicativo novo manda esses dias.
      if (outdated) return;

      if (worstAttempts > 0) {
        _scheduleFlush(_retryDelay(worstAttempts));
      } else if (again) {
        // Sobrou texto novo que chegou durante o envio: sobe já, sem
        // esperar.
        _scheduleFlush(_sendDelay);
      }
    } while (_rerun);
  }

  /// Tenta enviar tudo o que está na fila, agora.
  Future<void> flush() {
    final running = _running;
    if (running != null) {
      _rerun = true;
      return running;
    }

    final future = _drain();
    _running = future.whenComplete(() => _running = null);
    return _running!;
  }

  /// Grava o dia no aparelho e agenda o envio. É o autosave.
  Future<void> save(DayPayload day) async {
    await _store.put(day);

    _setDay(
      day.mapDate,
      _stateOf(_outdated ? SyncStatus.outdated : SyncStatus.pending),
    );

    await _refreshPending();
    // A tecla seguinte pode ser justamente a que completa o dia: quando ela
    // chegar, `save` roda de novo e é aí que o envio é agendado.
    if (canBeSent(day)) _scheduleFlush(_sendDelay);
  }

  /// O rascunho local do dia, ou nulo quando ele já está confirmado.
  Future<DayPayload?> load(String mapDate) async {
    final record = await _store.get(mapDate);
    return record?.day;
  }

  /// Quantos dias estão guardados agora, perguntando ao disco.
  Future<int> pendingCount() async => (await _store.list()).length;

  /// Os dias guardados no aparelho cuja data cai dentro do prefixo —
  /// `2026-09` para um mês inteiro. A visão do mês precisa deles porque um
  /// dia por enviar é um dia que já está preenchido.
  Future<List<DayPayload>> pendingDays(String prefix) async {
    final records = await _store.list();
    return records
        .where((record) => record.mapDate.startsWith(prefix))
        .map((record) => record.day)
        .toList();
  }

  void dismissConflict(String mapDate) {
    _patch(
      conflicts: _state.value.conflicts
          .where((one) => one.mapDate != mapDate)
          .toList(),
    );
  }

  void start() {
    if (_started) return;
    _started = true;

    // A rede voltou: é a hora de tentar, sem a usuária pedir (CA#1 da
    // US011).
    _connectivitySubscription = _connectivity.onChange.listen((online) {
      if (online) unawaited(flush());
    });

    // Cobre o que a mudança de conectividade pode ter perdido em segundo
    // plano — o mesmo papel que o `visibilitychange` cumpre na web.
    _lifecycleListener = AppLifecycleListener(
      onResume: () => unawaited(flush()),
    );

    // A versão mudou de estado — a tela-casa conferiu, ou o banco recusou: a
    // faixa de cada dia guardado passa a dizer a frase certa.
    _version?.addListener(_onVersionChange);

    // Reabrir o aplicativo no meio do preenchimento não perde nada (CA#3 da
    // US010): o que estava na fila é lido do aparelho e volta a subir.
    unawaited(_refreshPending().then((_) => flush()));
  }

  void _onVersionChange() => unawaited(_refreshPending());

  void stop() {
    _started = false;
    _version?.removeListener(_onVersionChange);
    _sendTimer?.cancel();
    _sendTimer = null;
    unawaited(_connectivitySubscription?.cancel());
    _lifecycleListener?.dispose();
    _lifecycleListener = null;
  }
}
