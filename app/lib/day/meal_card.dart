import 'package:flutter/material.dart';

import '../food_items/catalog.dart';
import '../local/day.dart';
import '../theme/theme.dart';
import 'acceptance_choice.dart';
import 'food_item_list.dart';
import 'meal_badge.dart';
import 'messages.dart';
import 'register.dart';

/// O cartão de uma refeição (decisão 5 da E3) — a versão em Flutter de
/// `web/src/day/meal-card.tsx`.
///
/// As três refeições ficam numa tela só, em cartões que abrem e fecham: uma
/// tela por refeição triplicaria a navegação de um fluxo que precisa caber
/// na rotina, e o registro de um dia comum tem de terminar em menos de dois
/// minutos (RNF#1 da US001). Fechado, o cartão ainda diz o que foi servido e
/// em que pé está — é assim que ela acha, de relance, onde o trabalho
/// parou.
///
/// Os gêneros utilizados são opcionais (RN#3 da US001) e ficam abaixo da
/// aceitação; a alteração do cardápio é o último bloco (issue #106). Enquanto
/// não houver troca, ela é só um botão — registrada, vira um resumo do que
/// entrou e do motivo, dentro do próprio cartão, porque é isso que sai
/// impresso e ela precisa conferir sem abrir a tela 3a às cegas (decisão 8
/// da E3). Por ser resumo e não botão, uma segunda alteração não tem por onde
/// nascer: é no máximo uma por refeição (RN#2 da US002).
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
    required this.foodItems,
    required this.onOpenMenuChange,
  });

  final String type;
  final MealPayload? meal;
  final bool open;
  final bool readOnly;
  final void Function(bool open) onOpenChange;
  final void Function(String description) onDescriptionChange;
  final void Function(String acceptance) onAcceptanceChange;
  final FoodItemActions foodItems;
  final VoidCallback onOpenMenuChange;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final description = meal?.description ?? '';
    final acceptance = meal?.acceptance;
    final state = mealState(meal);
    final change = meal?.menuChange;

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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: kSpacingUnit * 2,
                    children: [
                      Row(
                        spacing: kSpacingUnit * 2,
                        children: [
                          Text(
                            DayMessages.foodItemsLabel,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          _OptionalTag(),
                        ],
                      ),
                      FoodItemListView(
                        items: meal?.foodItems ?? const [],
                        readOnly: readOnly,
                        actions: foodItems,
                      ),
                    ],
                  ),
                  if (change != null)
                    _MenuChangeSummary(change: change, onOpen: onOpenMenuChange)
                  else if (!readOnly)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: onOpenMenuChange,
                        icon: const Icon(Icons.swap_horiz),
                        label: const Text(DayMessages.menuChange),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _OptionalTag extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outline),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: kSpacingUnit * 2,
          vertical: kSpacingUnit * 0.5,
        ),
        child: Text(
          DayMessages.foodItemsOptional,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

/// A alteração registrada, dentro do cartão: os gêneros que entraram e o
/// motivo, tocáveis para editar (decisão 8 da E3).
///
/// Faltando o motivo ou o gênero, a linha de baixo diz o que falta, com as
/// mesmas palavras da tela 3a: o dia fica guardado no aparelho até isso se
/// resolver, e essa é a única pista disso no cartão fechado.
class _MenuChangeSummary extends StatelessWidget {
  const _MenuChangeSummary({required this.change, required this.onOpen});

  final MenuChangePayload change;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<MaeColors>()!;
    final items = change.foodItems
        .map(
          (item) =>
              '${quantityLabel(item.quantity, item.unit)} de '
              '${item.name.toLowerCase()}',
        )
        .join(' · ');
    final missing = menuChangeIsComplete(change)
        ? null
        : change.foodItems.isEmpty
        ? MenuChangeMessages.itemsMissing
        : MenuChangeMessages.reasonMissing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: kSpacingUnit * 1.5,
      children: [
        Text(
          DayMessages.menuChange,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        Material(
          color: tokens.accent,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: tokens.accentBorder),
            borderRadius: BorderRadius.circular(8),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onOpen,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: kSpacingUnit * 3,
                  vertical: kSpacingUnit * 2.5,
                ),
                child: Row(
                  spacing: kSpacingUnit * 2.5,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: kSpacingUnit * 0.5,
                        children: [
                          if (items.isNotEmpty)
                            Text(
                              items,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          if (change.reason.trim().isNotEmpty)
                            Text(
                              change.reason,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: tokens.accentForeground,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: theme.colorScheme.primary),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (missing != null)
          Text(
            missing,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
      ],
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
