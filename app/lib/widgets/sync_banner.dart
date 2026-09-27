import 'package:flutter/material.dart';

import '../local/sync_engine.dart';
import '../local/sync_messages.dart';
import '../theme/theme.dart';

/// A faixa de salvamento da decisão 3 da E3: não há botão "Salvar", e é esta
/// faixa que diz em que pé está o registro. Três estados, três frases fixas
/// — a versão em Dart de `web/src/local/sync-banner.tsx`, ainda sem tela que
/// a monte (chega com a #105).
///
/// `status.detail` é a frase que o servidor mandou quando a recusa tem
/// explicação própria — quantidade inválida, mapa já dentro de um documento
/// gerado. Ela vem pronta para ser lida por quem vai lê-la.
class SyncBanner extends StatelessWidget {
  const SyncBanner({super.key, required this.status});

  /// Dia que ela ainda não tocou nesta sessão não tem o que dizer: afirmar
  /// "enviado" antes da primeira tecla seria a faixa mentindo.
  final DaySyncState? status;

  @override
  Widget build(BuildContext context) {
    final status = this.status;
    if (status == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final tokens = theme.extension<MaeColors>()!;
    final appearance = switch (status.status) {
      SyncStatus.pending => (
        icon: Icons.smartphone,
        background: theme.colorScheme.surfaceContainerHighest,
        foreground: theme.colorScheme.onSurfaceVariant,
        border: theme.colorScheme.outline,
      ),
      SyncStatus.sent => (
        icon: Icons.check_circle_outline,
        background: tokens.successSubtle,
        foreground: tokens.success,
        border: tokens.successBorder,
      ),
      SyncStatus.failed => (
        icon: Icons.error_outline,
        background: tokens.warningSubtle,
        foreground: tokens.warning,
        border: tokens.warningBorder,
      ),
    };

    return Semantics(
      // `liveRegion`, não um alerta: a faixa muda sozinha o tempo todo, e um
      // alerta interromperia quem usa leitor de tela a cada mudança de
      // estado. É o mesmo `role="status"` (não `role="alert"`) da web.
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: appearance.background,
          border: Border(bottom: BorderSide(color: appearance.border)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: kSpacingUnit * 4,
            vertical: kSpacingUnit * 2.5,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(appearance.icon, size: 16, color: appearance.foreground),
              const SizedBox(width: kSpacingUnit * 2),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: appearance.foreground,
                    ),
                    children: [
                      TextSpan(text: status.message),
                      if (status.detail != null)
                        TextSpan(text: ' ${status.detail}'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
