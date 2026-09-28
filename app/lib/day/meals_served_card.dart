import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/theme.dart';
import 'messages.dart';
import 'register.dart';

/// O número de refeições do dia (US005) — a versão em Flutter de
/// `web/src/day/meals-served-card.tsx`.
///
/// Um campo só, do dia inteiro, e não um por refeição: na escola integral as
/// crianças ficam o dia todo, e o número vem das professoras para a direção e
/// da direção para a cozinha — é um número, e é do dia (RN#1).
///
/// O campo é numérico e os dois botões existem para a correção de um a mais
/// ou um a menos, que é o ajuste que acontece; digitar 312 no stepper seria
/// absurdo, e por isso o número no meio é o campo de verdade, com teclado
/// numérico (RNF#1).
class MealsServedCard extends StatelessWidget {
  const MealsServedCard({
    super.key,
    required this.value,
    required this.readOnly,
    required this.onChange,
  });

  final int? value;
  final bool readOnly;
  final void Function(int? value) onChange;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(kSpacingUnit * 3.5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: kSpacingUnit * 3,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: kSpacingUnit,
              children: [
                Text(
                  DayMessages.mealsServedTitle,
                  style: theme.textTheme.titleMedium,
                ),
                Text(
                  DayMessages.mealsServedHint,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            Row(
              spacing: kSpacingUnit * 3,
              children: [
                IconButton.outlined(
                  icon: const Icon(Icons.remove),
                  tooltip: DayMessages.mealsServedLess,
                  onPressed: readOnly || value == null
                      ? null
                      : () => onChange(stepMealsServed(value, -1)),
                ),
                Expanded(
                  child: _MealsServedField(
                    value: value,
                    readOnly: readOnly,
                    onChange: onChange,
                  ),
                ),
                IconButton.outlined(
                  icon: const Icon(Icons.add),
                  tooltip: DayMessages.mealsServedMore,
                  onPressed: readOnly
                      ? null
                      : () => onChange(stepMealsServed(value, 1)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MealsServedField extends StatefulWidget {
  const _MealsServedField({
    required this.value,
    required this.readOnly,
    required this.onChange,
  });

  final int? value;
  final bool readOnly;
  final void Function(int? value) onChange;

  @override
  State<_MealsServedField> createState() => _MealsServedFieldState();
}

class _MealsServedFieldState extends State<_MealsServedField> {
  late final _controller = TextEditingController(text: _text(widget.value));

  static String _text(int? value) => value == null ? '' : '$value';

  @override
  void didUpdateWidget(_MealsServedField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Só reescreve quando o número vem de fora (os botões de − e +, ou a
    // devolução do dia não letivo): o eco do que ela mesma digitou é
    // recomposto de `parseMealsServed`, e pode já bater com o controlador —
    // reescrever do mesmo jeito empurraria o cursor para o fim a cada tecla.
    final text = _text(widget.value);
    if (text != _controller.text) _controller.text = text;
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
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.headlineLarge
          ?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
      decoration: const InputDecoration(border: OutlineInputBorder()),
      onChanged: (text) => widget.onChange(parseMealsServed(text)),
    );
  }
}
