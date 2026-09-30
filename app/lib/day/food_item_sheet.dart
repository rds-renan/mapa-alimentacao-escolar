import 'dart:async';

import 'package:flutter/material.dart';

import '../food_items/catalog.dart';
import '../local/app_database.dart';
import '../local/catalog_repository.dart';
import '../theme/theme.dart';
import 'messages.dart';
import 'register.dart';

/// Escolher gênero — folha 3b (US009, US003), a versão em Flutter de
/// `web/src/day/food-item-sheet.tsx` (issue #106).
///
/// Uma folha que sobe sobre o registro, e não uma tela de destino: mandar a
/// merendeira ao catálogo no meio de uma refeição é literalmente sair do
/// fluxo — ela perderia o lugar, e o item cadastrado lá não se prenderia
/// sozinho à refeição (decisão 7 da E3). Por isso o cadastro de um gênero
/// novo mora aqui dentro, no fim da lista: o pior caso vira dois gestos, e o
/// gênero escolhido entra na refeição já com a quantidade em 1.
///
/// **Funciona sem rede, as duas metades.** A lista é a cópia do catálogo no
/// aparelho (issue #102); abrir a folha pede uma atualização por baixo, que
/// falha calada sem sinal. E o gênero cadastrado aqui não nasce agora: nasce
/// no envio, porque `save_meal_map` cria no catálogo o que ainda não
/// existir, na mesma operação que grava o dia.
///
/// Devolve o gênero escolhido, ou nulo se ela fechou sem escolher.
Future<FoodItemChoice?> showFoodItemSheet(
  BuildContext context, {
  required String type,
  required String mapDate,
  required List<String> chosen,
  required CatalogRepository catalog,
}) {
  return showModalBottomSheet<FoodItemChoice>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => FoodItemSheet(
      type: type,
      mapDate: mapDate,
      chosen: chosen,
      catalog: catalog,
    ),
  );
}

class FoodItemSheet extends StatefulWidget {
  const FoodItemSheet({
    super.key,
    required this.type,
    required this.mapDate,
    required this.chosen,
    required this.catalog,
  });

  final String type;
  final String mapDate;

  /// As chaves ([foodItemKey]) que já estão na lista de destino.
  final List<String> chosen;
  final CatalogRepository catalog;

  @override
  State<FoodItemSheet> createState() => _FoodItemSheetState();
}

class _FoodItemSheetState extends State<FoodItemSheet> {
  late final Stream<List<FoodItem>> _items = widget.catalog.watchFoodItems();
  final _search = TextEditingController();
  final _name = TextEditingController();

  /// Falso enquanto ela não mexeu no nome: aí vale o que está na busca — o
  /// caminho comum é buscar, não achar, e cadastrar com o que já digitou.
  bool _nameTyped = false;
  String? _unit;

  @override
  void initState() {
    super.initState();
    // Por baixo e sem esperar: a lista já aparece com o que o aparelho tem,
    // e sem rede a atualização só não acontece.
    unawaited(widget.catalog.refresh().catchError((_) {}));
    _search.addListener(() {
      if (!_nameTyped) _name.text = _search.text;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _search.dispose();
    _name.dispose();
    super.dispose();
  }

  bool get _canAdd => _name.text.trim().isNotEmpty && _unit != null;

  void _choose(FoodItem item) {
    Navigator.of(context)
        .pop((foodItemId: item.id, name: item.name, unit: item.unit));
  }

  void _create() {
    if (!_canAdd) return;
    Navigator.of(context)
        .pop((foodItemId: null, name: _name.text.trim(), unit: _unit));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<MaeColors>()!;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(
            kSpacingUnit * 4,
            0,
            kSpacingUnit * 4,
            kSpacingUnit * 4,
          ),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: kSpacingUnit * 0.5,
                    children: [
                      Text(
                        FoodItemSheetMessages.title,
                        style: theme.textTheme.titleLarge,
                      ),
                      Text(
                        mealSubtitle(widget.type, widget.mapDate),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: FoodItemSheetMessages.close,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: kSpacingUnit * 3),
            TextField(
              controller: _search,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: FoodItemSheetMessages.search,
              ),
            ),
            const SizedBox(height: kSpacingUnit * 2),
            StreamBuilder<List<FoodItem>>(
              stream: _items,
              builder: (context, snapshot) {
                final all = snapshot.data;
                if (all == null) {
                  return const Padding(
                    padding: EdgeInsets.all(kSpacingUnit * 4),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                // O desativado some das sugestões (CA#3 da US009).
                final active = all.where((item) => item.active).toList();
                if (active.isEmpty) {
                  return _Hint(FoodItemSheetMessages.empty);
                }

                final found = active
                    .where((item) => matchesSearch(item.name, _search.text))
                    .toList();
                if (found.isEmpty) {
                  return _Hint(FoodItemSheetMessages.noResults);
                }

                return Column(
                  children: [
                    for (final item in found)
                      _CatalogRow(
                        item: item,
                        already: widget.chosen.contains(foodItemKey(item.name)),
                        onTap: () => _choose(item),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: kSpacingUnit * 3),
            DecoratedBox(
              decoration: BoxDecoration(
                color: tokens.accent,
                border: Border.all(color: tokens.accentBorder),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(kSpacingUnit * 3.5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: kSpacingUnit * 3,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: kSpacingUnit * 0.5,
                      children: [
                        Text(
                          FoodItemSheetMessages.newTitle,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          FoodItemSheetMessages.newHint,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: tokens.accentForeground,
                          ),
                        ),
                      ],
                    ),
                    TextField(
                      controller: _name,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: FoodItemSheetMessages.newNameLabel,
                        hintText: FoodItemSheetMessages.newNamePlaceholder,
                      ),
                      onChanged: (_) => setState(() => _nameTyped = true),
                    ),
                    Text(
                      FoodItemSheetMessages.newUnitLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Wrap(
                      spacing: kSpacingUnit * 2,
                      runSpacing: kSpacingUnit * 2,
                      children: [
                        for (final unit in unitSuggestions)
                          ChoiceChip(
                            label: Text(unit),
                            selected: _unit == unit,
                            onSelected: (_) => setState(() => _unit = unit),
                          ),
                      ],
                    ),
                    FilledButton(
                      onPressed: _canAdd ? _create : null,
                      child: const Text(FoodItemSheetMessages.add),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CatalogRow extends StatelessWidget {
  const _CatalogRow({
    required this.item,
    required this.already,
    required this.onTap,
  });

  final FoodItem item;
  final bool already;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Opacity(
      opacity: already ? 0.5 : 1,
      child: InkWell(
        onTap: already ? null : onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Row(
            spacing: kSpacingUnit * 3,
            children: [
              Expanded(
                child: Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Chip(
                label: Text(
                  already ? FoodItemSheetMessages.alreadyChosen : item.unit,
                ),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: kSpacingUnit * 4),
      child: Text(
        text,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
