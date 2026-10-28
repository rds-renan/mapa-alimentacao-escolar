import 'package:flutter/material.dart';

import '../food_items/catalog.dart';
import '../local/day.dart';
import '../month/month.dart' show dayHasFoodItems;
import '../theme/theme.dart';
import 'food_item_list.dart';
import 'meal_badge.dart';
import 'messages.dart';
import 'register.dart';

/// Os gêneros do dia (decisão 14 da E4) — a versão em Flutter de
/// `web/src/day/day-food-items-card.tsx`.
///
/// Vêm depois das três refeições porque é a ordem em que ela trabalha:
/// primeiro o que foi servido, depois o que saiu da despensa para servir. É
/// um cartão só, e não um por refeição, porque é como ela confere — pelo dia
/// — e é como o documento imprime, numa célula por dia.
///
/// A alteração do cardápio é o último bloco, porque também é gênero: o que
/// entrou no lugar do previsto. Enquanto não houver troca, ela é só um botão
/// — registrada, vira um resumo do que entrou e do motivo, dentro do próprio
/// cartão, porque é isso que sai impresso e ela precisa conferir sem abrir a
/// tela 3a às cegas (decisão 8 da E3). Por ser resumo e não botão, uma
/// segunda alteração não tem por onde nascer: é no máximo uma por dia.
///
/// O cartão não fecha, ao contrário dos das refeições: é o que ela mais mexe
/// depois de abrir o dia, e fechado ele esconderia justamente a lista que
/// ela está montando.
class DayFoodItemsCard extends StatelessWidget {
  const DayFoodItemsCard({
    super.key,
    required this.day,
    required this.readOnly,
    required this.foodItems,
    required this.onOpenMenuChange,
  });

  final DayPayload day;
  final bool readOnly;
  final FoodItemActions foodItems;
  final VoidCallback onOpenMenuChange;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final change = day.menuChange;

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          kSpacingUnit * 3.5,
          kSpacingUnit * 3,
          kSpacingUnit * 3.5,
          kSpacingUnit * 4,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: kSpacingUnit * 4,
          children: [
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      DayMessages.foodItemsTitle,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                ),
                MealBadge(
                  state: dayHasFoodItems(day)
                      ? MealState.complete
                      : MealState.empty,
                  labels: foodItemsStateLabels,
                ),
              ],
            ),
            FoodItemListView(
              items: day.foodItems,
              readOnly: readOnly,
              actions: foodItems,
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
