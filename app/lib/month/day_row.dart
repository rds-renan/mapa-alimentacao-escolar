import 'package:flutter/material.dart';

import '../theme/theme.dart';
import 'day_badge.dart';
import 'month.dart';

/// Uma linha da lista: o dia, o que ele tem (ou o que falta nele) e o
/// estado.
///
/// A linha inteira é o toque — não um botão dentro dela (CA#2 da US008).
/// Dia bloqueado também abre: ele é somente leitura, não inalcançável — é
/// exatamente o dia que ela vai querer conferir depois de gerar o
/// documento.
class DayRow extends StatelessWidget {
  const DayRow({
    super.key,
    required this.date,
    required this.record,
    required this.isToday,
    required this.onTap,
  });

  final DateTime date;
  final DayRecord? record;
  final bool isToday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<MaeColors>()!;
    final state = dayState(record);
    final summary = daySummary(record, isToday: isToday);
    final reopened = record?.reopened ?? false;

    return Semantics(
      label:
          '${dayAndMonth(date)}, ${dayStateLabels[state]!.toLowerCase()}'
          '${reopened ? ', ${reopenedLabel.toLowerCase()} para correção' : ''}. '
          '$summary',
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 58),
          padding: const EdgeInsets.symmetric(
            horizontal: kSpacingUnit * 3.5,
            vertical: kSpacingUnit * 2,
          ),
          color: isToday ? tokens.accent : null,
          child: ExcludeSemantics(
            child: Row(
              children: [
                SizedBox(
                  width: 42,
                  child: Column(
                    children: [
                      Text(
                        weekdayAbbrev(date),
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: isToday
                              ? tokens.accentForeground
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        '${date.day}',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: isToday ? tokens.accentForeground : null,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: kSpacingUnit * 3),
                Expanded(
                  child: Text(
                    summary,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: state == DayState.empty
                          ? theme.colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.75,
                            )
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                // Os dois selos um abaixo do outro, e não lado a lado: em
                // largura de celular, lado a lado eles espremem o texto do
                // dia — o achado da web na issue #153.
                if (reopened)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    spacing: kSpacingUnit,
                    children: [
                      const ReopenedBadge(),
                      DayBadge(state: state),
                    ],
                  )
                else
                  DayBadge(state: state),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
