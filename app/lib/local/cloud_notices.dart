import 'dart:async';

import 'sync_engine.dart';
import 'sync_messages.dart';

/// Quando o aviso da nuvem aparece (issue #178) — a versão em Dart de
/// `web/src/local/cloud-notices.ts`.
///
/// Até a E7 os avisos eram uma faixa no alto do dia, e a faixa acompanhava o
/// estado a cada tecla: com rede, cada gravação punha o dia em "Salvo no seu
/// celular…" e, 1,2 s depois, em "Salvo na nuvem.". A faixa aparecia, sumia e
/// empurrava a tela enquanto ela digitava. Agora o aviso é um snackbar, e esta
/// peça decide quando ele sobe:
///
/// - **só quando a frase muda.** Digitando com rede, "Salvo na nuvem." aparece
///   uma vez; as gravações seguintes, que terminam na mesma frase, ficam
///   caladas. Caiu a rede, a frase muda e o aviso sobe; voltou, sobe de novo.
/// - **"Salvo no seu celular…" espera [pendingDelay].** É o estado de passagem
///   de toda gravação com rede, e anunciar que a internet caiu quando ela não
///   caiu seria mentir. Se ele durar, é porque o envio não aconteceu, e aí a
///   frase é verdade.
class CloudNotices {
  CloudNotices({
    required this.show,
    this.pendingDelay = const Duration(seconds: 3),
  });

  final void Function(String text) show;
  final Duration pendingDelay;

  String? _shown;
  String? _current;
  Timer? _timer;

  /// O estado do dia, a cada notificação da fila. Dia que ela ainda não tocou
  /// nesta sessão vem nulo e não tem o que dizer.
  void update(DaySyncState? state) {
    if (state == null) return;

    final text = noticeText(state);
    // A fila avisa de qualquer dia; o deste não mudou, então nada muda —
    // senão a espera do "Salvo no seu celular…" recomeçaria à toa.
    if (text == _current) return;
    _current = text;

    _timer?.cancel();
    _timer = null;
    if (text == _shown) return;

    if (state.status == SyncStatus.pending) {
      _timer = Timer(pendingDelay, () => _announce(text));
    } else {
      _announce(text);
    }
  }

  void _announce(String text) {
    _timer = null;
    _shown = text;
    show(text);
  }

  void dispose() => _timer?.cancel();
}

/// A frase do aviso: a do estado e, quando o banco recusou com explicação
/// própria, a explicação dele depois.
String noticeText(DaySyncState state) {
  final detail = state.detail;
  return detail == null ? state.message : '${state.message} $detail';
}
