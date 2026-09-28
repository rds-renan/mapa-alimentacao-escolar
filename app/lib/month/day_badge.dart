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
              dayStateLabels[state]!,
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
