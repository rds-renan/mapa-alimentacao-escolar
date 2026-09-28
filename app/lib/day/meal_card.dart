import 'package:flutter/material.dart';

import '../local/day.dart';
import '../theme/theme.dart';
import 'acceptance_choice.dart';
import 'meal_badge.dart';
import 'messages.dart';
import 'register.dart';

/// O cartão de uma refeição (decisão 5 da E3) — a versão em Flutter de
/// `web/src/day/meal-card.tsx`, sem os gêneros utilizados e a alteração do
/// cardápio: esses dois blocos chegam com a #106.
///
/// As três refeições ficam numa tela só, em cartões que abrem e fecham: uma
/// tela por refeição triplicaria a navegação de um fluxo que precisa caber
/// na rotina, e o registro de um dia comum tem de terminar em menos de dois
/// minutos (RNF#1 da US001). Fechado, o cartão ainda diz o que foi servido e
/// em que pé está — é assim que ela acha, de relance, onde o trabalho
/// parou.
class MealCard extends StatelessWidget {
  const MealCard({
    super.key,
    required this.type,
    required this.meal,
    required this.open,
    required this.readOnly,
    required this.onOpenChange,
    required this.onDescriptionChange,
    required this.onAcceptanceChange,
  });

  final String type;
  final MealPayload? meal;
  final bool open;
  final bool readOnly;
  final void Function(bool open) onOpenChange;
  final void Function(String description) onDescriptionChange;
  final void Function(String acceptance) onAcceptanceChange;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final description = meal?.description ?? '';
    final acceptance = meal?.acceptance;
    final state = mealState(meal);

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          InkWell(
            onTap: () => onOpenChange(!open),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: kSpacingUnit * 3.5,
                vertical: kSpacingUnit * 3,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mealTitles[type]!,
                          style: theme.textTheme.titleMedium,
                        ),
                        if (!open && description.trim().isNotEmpty)
                          Text(
                            description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: kSpacingUnit * 2.5),
                  MealBadge(state: state),
                  const SizedBox(width: kSpacingUnit),
                  Icon(
                    open ? Icons.expand_less : Icons.expand_more,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),

          if (open)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                kSpacingUnit * 3.5,
                0,
                kSpacingUnit * 3.5,
                kSpacingUnit * 4,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: kSpacingUnit * 4,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: kSpacingUnit * 1.5,
                    children: [
                      Text(
                        DayMessages.descriptionLabel,
                        style: theme.textTheme.bodyLarge,
                      ),
                      _DescriptionField(
                        description: description,
                        readOnly: readOnly,
                        onChanged: onDescriptionChange,
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: kSpacingUnit * 1.5,
                    children: [
                      Text(
                        DayMessages.acceptanceLabel,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      AcceptanceChoice(
                        value: acceptance,
                        disabled: readOnly,
                        onChange: onAcceptanceChange,
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _DescriptionField extends StatefulWidget {
  const _DescriptionField({
    required this.description,
    required this.readOnly,
    required this.onChanged,
  });

  final String description;
  final bool readOnly;
  final void Function(String description) onChanged;

  @override
  State<_DescriptionField> createState() => _DescriptionFieldState();
}

class _DescriptionFieldState extends State<_DescriptionField> {
  late final _controller = TextEditingController(text: widget.description);

  @override
  void didUpdateWidget(_DescriptionField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.description != _controller.text) {
      _controller.text = widget.description;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      enabled: !widget.readOnly,
      minLines: 2,
      maxLines: 4,
      decoration: const InputDecoration(
        hintText: DayMessages.descriptionPlaceholder,
      ),
      onChanged: widget.onChanged,
    );
  }
}
