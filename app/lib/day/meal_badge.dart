import 'package:flutter/material.dart';

import '../theme/theme.dart';
import 'messages.dart';
import 'register.dart';

/// O estado da refeição, no cabeçalho do cartão — a versão em Flutter de
/// `web/src/day/meal-badge.tsx`. Mesmo raciocínio do [DayBadge] da visão do
/// mês: cor **e** rótulo, nunca só a cor.
class MealBadge extends StatelessWidget {
  const MealBadge({super.key, required this.state});

  final MealState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<MaeColors>()!;
    final scheme = theme.colorScheme;

    final (background, border, foreground) = switch (state) {
      MealState.complete => (
        tokens.successSubtle,
        tokens.successBorder,
        tokens.success,
      ),
      MealState.pending => (
        tokens.warningSubtle,
        tokens.warningBorder,
        tokens.warning,
      ),
      MealState.empty => (
        scheme.surfaceContainerHighest,
        scheme.outline,
        scheme.onSurfaceVariant,
      ),
    };

    return Semantics(
      // O nome da refeição já anuncia o cartão inteiro; o estado é dito
      // aqui, e não repetido pelo leitor de tela em separado.
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
        child: Text(
          mealStateLabels[state]!,
          style: theme.textTheme.labelSmall?.copyWith(
            color: foreground,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
