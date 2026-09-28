import 'package:flutter/material.dart';

import '../theme/theme.dart';
import 'messages.dart';

/// A aceitação em três botões (US004) — a versão em Flutter de
/// `web/src/day/acceptance-choice.tsx`.
///
/// Um toque, sem lista suspensa e sem digitar nada (RNF#1): a avaliação é
/// conhecimento que ela já tem — sobra, reação das crianças, repetições — e
/// o aplicativo só captura. Os três ocupam a linha inteira em partes iguais
/// porque nenhum é o padrão: escolher "Ruim" tem de ser tão fácil quanto
/// escolher "Ótimo".
///
/// Tocar no que já está escolhido não desmarca. Um registro sem aceitação
/// existe (o dia pode ficar parcial), mas ninguém o faz de propósito com o
/// dedo — desmarcar aqui seria sempre acidente.
class AcceptanceChoice extends StatelessWidget {
  const AcceptanceChoice({
    super.key,
    required this.value,
    required this.disabled,
    required this.onChange,
  });

  final String? value;
  final bool disabled;
  final void Function(String acceptance) onChange;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: kSpacingUnit * 2,
      children: [
        for (final level in acceptanceOrder)
          Expanded(
            child: _AcceptanceButton(
              level: level,
              chosen: value == level,
              disabled: disabled,
              onChange: onChange,
            ),
          ),
      ],
    );
  }
}

class _AcceptanceButton extends StatelessWidget {
  const _AcceptanceButton({
    required this.level,
    required this.chosen,
    required this.disabled,
    required this.onChange,
  });

  final String level;
  final bool chosen;
  final bool disabled;
  final void Function(String acceptance) onChange;

  @override
  Widget build(BuildContext context) {
    final label = acceptanceLabels[level]!;
    final onPressed = disabled ? null : () => onChange(level);

    return Semantics(
      toggled: chosen,
      child: SizedBox(
        height: 50,
        child: chosen
            ? FilledButton(onPressed: onPressed, child: Text(label))
            : OutlinedButton(onPressed: onPressed, child: Text(label)),
      ),
    );
  }
}
