import 'package:flutter/material.dart';

import '../month/month.dart';
import '../theme/theme.dart';
import 'messages.dart';
import 'selection.dart';

/// Uma faixa de aviso da tela 5: ícone e texto, em tom neutro ou de alerta.
class Notice extends StatelessWidget {
  const Notice({
    super.key,
    required this.icon,
    required this.child,
    this.warning = false,
  });

  final IconData icon;
  final Widget child;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<MaeColors>()!;
    final foreground = warning
        ? tokens.warning
        : theme.colorScheme.onSurfaceVariant;

    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: kSpacingUnit * 3.5,
          vertical: kSpacingUnit * 3,
        ),
        decoration: BoxDecoration(
          color: warning
              ? tokens.warningSubtle
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(kRadiusLg),
          border: warning ? Border.all(color: tokens.warningBorder) : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: kSpacingUnit * 2,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Icon(icon, size: 16, color: foreground),
            ),
            Expanded(
              child: DefaultTextStyle.merge(
                style: theme.textTheme.bodySmall?.copyWith(color: foreground),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// O aviso de que o período não fecha — o CA#3 da US012 levado além do que
/// ele pedia.
///
/// A regra do projeto é que mapa pendente não vai para a prefeitura, então o
/// atalho de semana ou de mês **não seleciona nada** quando o período tem
/// buraco. Por isso o aviso nomeia dia por dia: ele é a lista de tarefas que
/// separa a merendeira do documento, e dizer só "há pendências" não serve de
/// nada.
class MissingNotice extends StatelessWidget {
  const MissingNotice({super.key, required this.scope, required this.missing});

  /// O período, em português: "setembro", "a semana 2".
  final String scope;
  final List<DayOption> missing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Notice(
      icon: Icons.warning_amber_rounded,
      warning: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: kSpacingUnit * 2,
        children: [
          Text(
            missingTitle(scope, missing.length),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: theme.extension<MaeColors>()!.warning,
            ),
          ),
          for (final option in missing)
            Text(
              '${dayAndMonth(option.date)} · '
              '${missingLabels[missingReason(option)!]!.toLowerCase()}',
            ),
          const Text(SelectionMessages.pickByHand),
        ],
      ),
    );
  }
}
