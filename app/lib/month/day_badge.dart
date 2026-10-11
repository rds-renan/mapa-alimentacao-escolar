import 'package:flutter/material.dart';

import '../theme/theme.dart';
import 'month.dart';

/// O estado do dia, em cor **e** ícone — nunca só em cor (RNF#1 da US008).
///
/// Quem lê esta lista pode estar na cozinha, com o celular na bancada e a
/// tela lavada de luz: "no documento" e "vazio" partilham o mesmo cinza de
/// propósito, como no desenho da E3, e o que separa os dois é o cadeado.
class DayBadge extends StatelessWidget {
  const DayBadge({super.key, required this.state});

  final DayState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<MaeColors>()!;
    final scheme = theme.colorScheme;

    final (icon, background, border, foreground) = switch (state) {
      DayState.complete => (
        Icons.check_circle,
        tokens.successSubtle,
        tokens.successBorder,
        tokens.success,
      ),
      DayState.pending => (
        Icons.access_time,
        tokens.warningSubtle,
        tokens.warningBorder,
        tokens.warning,
      ),
      DayState.nonSchool => (
        Icons.event_busy,
        tokens.accent,
        tokens.accentBorder,
        tokens.accentForeground,
      ),
      DayState.locked => (
        Icons.lock,
        scheme.surfaceContainerHighest,
        scheme.outline,
        scheme.onSurfaceVariant,
      ),
      DayState.empty => (
        Icons.circle_outlined,
        scheme.surfaceContainerHighest,
        scheme.outline,
        scheme.onSurfaceVariant,
      ),
    };

    return _Pill(
      icon: icon,
      label: dayStateLabels[state]!,
      background: background,
      border: border,
      foreground: foreground,
    );
  }
}

/// O dia reaberto pela direção (CA#2 da US023, issue #152) — o
/// `ReopenedBadge` da web.
///
/// Vem junto da etiqueta de estado, e não no lugar dela: o dia reaberto
/// continua preenchido ou pendente, e o que ele tem de diferente é ser o dia
/// que voltou para a mão dela. Cor **e** ícone, como a do lado, e o cadeado
/// aberto é de propósito o mesmo cadeado do "No documento".
class ReopenedBadge extends StatelessWidget {
  const ReopenedBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<MaeColors>()!;

    return _Pill(
      icon: Icons.lock_open,
      label: reopenedLabel,
      background: tokens.warningSubtle,
      border: tokens.warningBorder,
      foreground: tokens.warning,
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.icon,
    required this.label,
    required this.background,
    required this.border,
    required this.foreground,
  });

  final IconData icon;
  final String label;
  final Color background;
  final Color border;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      // O rótulo já é dito na etiqueta de acessibilidade da linha inteira
      // (DayRow) — repeti-lo aqui faria o leitor de tela anunciar o estado
      // duas vezes.
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: kSpacingUnit * 2.5,
          vertical: kSpacingUnit,
        ),
        decoration: BoxDecoration(
          color: background,
          border: Border.all(color: border),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: foreground),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
