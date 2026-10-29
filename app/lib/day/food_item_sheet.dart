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
/// merendeira ao catálogo no meio do registro é literalmente sair do
/// fluxo — ela perderia o lugar, e o item cadastrado lá não se prenderia
/// sozinho ao dia (decisão 7 da E3). Por isso o cadastro de um gênero
/// novo mora aqui dentro, no fim da lista, e o gênero escolhido entra no dia
/// já com a quantidade em 1.
///
/// **Ela marca vários e adiciona de uma vez** (issue #173). Na medição da E7,
/// o que mais pesava no registro era repetir "Adicionar gênero → escolher →
/// voltar" para cada item. Por isso o toque na linha só marca, e o botão fixo
/// no rodapé põe todos os marcados no dia. O gênero cadastrado aqui entra
/// marcado, junto com os outros, e assim só um botão fecha a folha.
///
/// **Funciona sem rede, as duas metades.** A lista é a cópia do catálogo no
/// aparelho (issue #102); abrir a folha pede uma atualização por baixo, que
/// falha calada sem sinal. E o gênero cadastrado aqui não nasce agora: nasce
/// no envio, porque `save_meal_map` cria no catálogo o que ainda não
/// existir, na mesma operação que grava o dia.
///
/// Devolve os gêneros marcados, na ordem em que ela marcou, ou nulo se ela
/// fechou sem adicionar.
Future<List<FoodItemChoice>?> showFoodItemSheet(
  BuildContext context, {
  required String mapDate,
  required List<String> chosen,
  required CatalogRepository catalog,
}) {
  return showModalBottomSheet<List<FoodItemChoice>>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) =>
        FoodItemSheet(mapDate: mapDate, chosen: chosen, catalog: catalog),
  );
}

class FoodItemSheet extends StatefulWidget {
  const FoodItemSheet({
    super.key,
    required this.mapDate,
    required this.chosen,
    required this.catalog,
  });

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

  /// O que ela marcou, pela chave ([foodItemKey]) e na ordem em que marcou:
  /// os do catálogo e os cadastrados aqui, que ainda não têm identificador.
  final _marked = <String, FoodItemChoice>{};

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

  bool get _canCreate => _name.text.trim().isNotEmpty && _unit != null;

  void _toggle(FoodItem item) {
    final key = foodItemKey(item.name);
    setState(() {
      if (_marked.remove(key) == null) {
        _marked[key] = (foodItemId: item.id, name: item.name, unit: item.unit);
      }
    });
  }

  /// O gênero novo entra marcado e o cadastro volta ao começo, pronto para o
  /// próximo. Se o nome já existe no catálogo, quem fica marcado é o do
  /// catálogo: a gravação juntaria os dois pelo nome de qualquer jeito, e
  /// assim a unidade que vale é a que já está lá.
  void _create(List<FoodItem> active) {
    if (!_canCreate) return;

    final name = _name.text.trim();
    final key = foodItemKey(name);
    final existing = active
        .where((item) => foodItemKey(item.name) == key)
        .firstOrNull;

    setState(() {
      if (!widget.chosen.contains(key)) {
        _marked[key] = existing != null
            ? (
                foodItemId: existing.id,
                name: existing.name,
                unit: existing.unit,
              )
            : (foodItemId: null, name: name, unit: _unit);
      }
      _nameTyped = false;
      _unit = null;
    });
    _search.clear();
    _name.clear();
  }

  void _add() {
    if (_marked.isEmpty) return;
    Navigator.of(context).pop(_marked.values.toList());
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: StreamBuilder<List<FoodItem>>(
          stream: _items,
          builder: (context, snapshot) {
            // O desativado some das sugestões (CA#3 da US009).
            final active = snapshot.data?.where((item) => item.active).toList();

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Flexible(child: _list(context, active)),
                // Fixo embaixo, fora da rolagem: com a lista comprida, ela
                // não precisa descer até o fim para adicionar o que marcou.
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    kSpacingUnit * 4,
                    kSpacingUnit * 2,
                    kSpacingUnit * 4,
                    kSpacingUnit * 4,
                  ),
                  child: FilledButton(
                    onPressed: _marked.isEmpty ? null : _add,
                    child: Text(FoodItemSheetMessages.add(_marked.length)),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _list(BuildContext context, List<FoodItem>? active) {
    final theme = Theme.of(context);
    final tokens = theme.extension<MaeColors>()!;
    final created = _marked.values.where((item) => item.foodItemId == null);

    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: kSpacingUnit * 4),
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
                    dayTitle(widget.mapDate),
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
        // Os que ela cadastrou aqui ficam no alto, marcados, seja qual for a
        // busca: ainda não estão no catálogo, e é aqui que ela os desmarca.
        for (final item in created)
          _ChoiceRow(
            name: item.name,
            unit: item.unit ?? '',
            marked: true,
            onTap: () => setState(() => _marked.remove(foodItemKey(item.name))),
          ),
        ..._catalogRows(active),
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
                // Com o fundo da superfície, apagado ou não: sem ele, o
                // contorno some no azul do cartão.
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: theme.colorScheme.surface,
                    disabledBackgroundColor: theme.colorScheme.surface,
                    side: BorderSide(color: tokens.accentBorder),
                  ),
                  onPressed: _canCreate ? () => _create(active ?? []) : null,
                  child: const Text(FoodItemSheetMessages.create),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: kSpacingUnit * 2),
      ],
    );
  }

  List<Widget> _catalogRows(List<FoodItem>? active) {
    if (active == null) {
      return const [
        Padding(
          padding: EdgeInsets.all(kSpacingUnit * 4),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }
    if (active.isEmpty) return const [_Hint(FoodItemSheetMessages.empty)];

    final found = active
        .where((item) => matchesSearch(item.name, _search.text))
        .toList();
    if (found.isEmpty) return const [_Hint(FoodItemSheetMessages.noResults)];

    return [
      for (final item in found)
        if (widget.chosen.contains(foodItemKey(item.name)))
          _ChoiceRow(name: item.name, unit: item.unit, already: true)
        else
          _ChoiceRow(
            name: item.name,
            unit: item.unit,
            marked: _marked.containsKey(foodItemKey(item.name)),
            onTap: () => _toggle(item),
          ),
    ];
  }
}

/// Uma linha da lista: a caixa de marcar, o nome e a unidade. O gênero que
/// já está no dia aparece marcado e apagado, com "já está aqui" no lugar da
/// unidade, e não se mexe.
class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow({
    required this.name,
    required this.unit,
    this.marked = false,
    this.already = false,
    this.onTap,
  });

  final String name;
  final String unit;
  final bool marked;
  final bool already;
  final VoidCallback? onTap;

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
            spacing: kSpacingUnit * 2,
            children: [
              Checkbox(
                value: already || marked,
                onChanged: already ? null : (_) => onTap?.call(),
              ),
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Chip(
                label: Text(
                  already ? FoodItemSheetMessages.alreadyChosen : unit,
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
