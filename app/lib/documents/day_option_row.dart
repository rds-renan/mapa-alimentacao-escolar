import 'package:flutter/material.dart';

import '../month/month.dart';
import '../theme/theme.dart';
import 'check_mark.dart';
import 'messages.dart';
import 'selection.dart';

/// Uma linha da tela 5: o dia, se ele entra, e o que ele é.
///
/// A linha diz sempre o **porquê** quando o dia não pode entrar —
/// "pendente", "sem registro", "falta ir para a nuvem". Sem isso a lista teria
/// dias apagados e a merendeira ficaria com a pergunta que este produto
/// existe para responder: o que falta antes de gerar?
///
/// O dia já incluído em outro documento aparece marcado como tal e continua
/// selecionável: o bloqueio é sobre editar, não sobre sair de novo.
class DayOptionRow extends StatelessWidget {
  const DayOptionRow({
    super.key,
    required this.option,
    required this.selected,
    required this.readOnly,
    required this.onToggle,
  });

  final DayOption option;
  final bool selected;

  /// A escolha está num período inteiro: a linha mostra, mas não decide.
  final bool readOnly;
  final VoidCallback onToggle;

  /// O rótulo da direita: o que falta no dia, ou o que ele tem. O dia
  /// pronto mostra quantas refeições descreve, como a E3 desenhou.
  String get _label {
    final reason = missingReason(option);
    if (reason != null) return missingLabels[reason]!;
    if (option.state == DayState.complete) {
      return option.meals == 1 ? '1 refeição' : '${option.meals} refeições';
    }

    return dayStateLabels[option.state]!;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<MaeColors>()!;
    final enabled = !readOnly && option.eligible;
    final missing = missingReason(option) != null;

    return Semantics(
      label: '${dayAndMonth(option.date)}, ${_label.toLowerCase()}',
      checked: selected,
      enabled: enabled,
      inMutuallyExclusiveGroup: false,
      child: InkWell(
        onTap: enabled ? onToggle : null,
        child: Opacity(
          opacity: !option.eligible ? 0.6 : 1,
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.symmetric(
              horizontal: kSpacingUnit * 3.5,
              vertical: kSpacingUnit * 2,
            ),
            child: ExcludeSemantics(
              child: Row(
                spacing: kSpacingUnit * 3,
                children: [
                  CheckMark(selected: selected),
                  Expanded(
                    child: Text(
                      '${weekdayAbbrev(option.date)}, ${option.date.day}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Text(
                    _label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: missing
                          ? tokens.warning
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
