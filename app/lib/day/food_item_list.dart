import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../local/day.dart';
import '../theme/theme.dart';
import 'messages.dart';
import 'register.dart';

/// O que os steppers de uma lista fazem. O mesmo trio serve às duas listas
/// da refeição — os gêneros dela e os da troca —, e quem monta diz qual.
class FoodItemActions {
  const FoodItemActions({
    required this.add,
    required this.step,
    required this.setQuantity,
  });

  final VoidCallback add;
  final void Function(String key, int delta) step;
  final void Function(String key, int quantity) setQuantity;
}

/// Os gêneros de uma lista, cada um com o seu stepper (decisão 2 da E3) — a
/// versão em Flutter de `web/src/day/food-item-list.tsx` (issue #106).
///
/// É a mesma peça nos dois lugares em que a lista aparece: os gêneros da
/// refeição, no cartão, e os gêneros da troca, na tela 3a. São duas listas
/// porque alimentam colunas diferentes do documento (decisão 7 da E4) — mas
/// o gesto é um só.
///
/// As quantidades reais são inteiros pequenos ("1 saco de leite em pó", "4
/// quilos de pão"), então o "−" e o "+" resolvem o caso comum num toque. O
/// número no meio é campo de verdade, com teclado numérico (RNF#1 da US003),
/// porque 12 potes não se alcançam a toques. A unidade vem do catálogo e não
/// se edita aqui: é ela que mantém as quantidades comparáveis entre as duas
/// merendeiras (RN#1 da US009).
class FoodItemListView extends StatelessWidget {
  const FoodItemListView({
    super.key,
    required this.items,
    required this.readOnly,
    required this.actions,
  });

  final List<FoodItemPayload> items;
  final bool readOnly;
  final FoodItemActions actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: kSpacingUnit * 2,
      children: [
        for (final item in items)
          _FoodItemRow(
            key: ValueKey(foodItemKey(item.name)),
            item: item,
            readOnly: readOnly,
            actions: actions,
          ),
        if (!readOnly)
          OutlinedButton.icon(
            onPressed: actions.add,
            icon: const Icon(Icons.add),
            label: const Text(DayMessages.addFoodItem),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}

class _FoodItemRow extends StatelessWidget {
  const _FoodItemRow({
    super.key,
    required this.item,
    required this.readOnly,
    required this.actions,
  });

  final FoodItemPayload item;
  final bool readOnly;
  final FoodItemActions actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final key = foodItemKey(item.name);
    final unit = item.unit;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(color: theme.colorScheme.outline),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          kSpacingUnit * 3,
          kSpacingUnit * 1.5,
          kSpacingUnit * 1.5,
          kSpacingUnit * 1.5,
        ),
        child: Row(
          spacing: kSpacingUnit * 2.5,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (unit != null && unit.isNotEmpty)
                    Text(
                      unit,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.remove),
              tooltip: DayMessages.foodItemLess(
                item.name,
                last: item.quantity <= 1,
              ),
              onPressed: readOnly ? null : () => actions.step(key, -1),
            ),
            SizedBox(
              width: 56,
              child: _QuantityField(
                item: item,
                readOnly: readOnly,
                onChange: (quantity) => actions.setQuantity(key, quantity),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: DayMessages.foodItemMore(item.name),
              onPressed: readOnly ? null : () => actions.step(key, 1),
            ),
          ],
        ),
      ),
    );
  }
}

/// O número no meio do stepper.
///
/// Guarda o próprio controlador pelo mesmo motivo do número de refeições:
/// só reescreve quando a quantidade vem de fora (o "−" e o "+"). E deixa o
/// campo ficar vazio enquanto ela apaga para trocar o número — sem isso,
/// apagar devolveria 1 debaixo do dedo e o número seguinte sairia grudado
/// nele. Ao sair do campo vazio, volta a mostrar a quantidade que vale.
class _QuantityField extends StatefulWidget {
  const _QuantityField({
    required this.item,
    required this.readOnly,
    required this.onChange,
  });

  final FoodItemPayload item;
  final bool readOnly;
  final void Function(int quantity) onChange;

  @override
  State<_QuantityField> createState() => _QuantityFieldState();
}

class _QuantityFieldState extends State<_QuantityField> {
  late final _controller = TextEditingController(
    text: '${widget.item.quantity}',
  );
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!_focus.hasFocus) _controller.text = '${widget.item.quantity}';
    });
  }

  @override
  void didUpdateWidget(_QuantityField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final typed = parseQuantity(_controller.text);
    if (typed != widget.item.quantity && !(typed == null && _focus.hasFocus)) {
      _controller.text = '${widget.item.quantity}';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return Semantics(
      label: DayMessages.foodItemQuantity(item.name, item.unit),
      child: TextField(
        controller: _controller,
        focusNode: _focus,
        enabled: !widget.readOnly,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleMedium
            ?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: kSpacingUnit * 2),
        ),
        onChanged: (text) {
          final quantity = parseQuantity(text);
          if (quantity != null) widget.onChange(quantity);
        },
      ),
    );
  }
}
