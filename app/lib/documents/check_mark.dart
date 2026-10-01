import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// A caixa de marcar da tela 5.
///
/// Não é o `Checkbox` do Material de propósito: ele, desabilitado, vira
/// cinza mesmo marcado — e nos modos "Mês inteiro" e "Semana" todas as
/// linhas são só para ver (a escolha é do período), com os dias marcados
/// precisando continuar legíveis como marcados. A linha inteira é o toque e
/// diz o estado pela semântica; a caixa é só o desenho.
class CheckMark extends StatelessWidget {
  const CheckMark({super.key, required this.selected, this.size = 24});

  final bool selected;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: selected ? scheme.primary : scheme.surface,
          borderRadius: BorderRadius.circular(kRadiusSm),
          // `onSurfaceVariant` e não `outline`: no tema escuro o `outline`
          // tem a mesma cor da trilha de quem fica atrás (ver a nota do
          // `switchTheme` em `theme.dart`).
          border: Border.all(
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
            width: 2,
          ),
        ),
        child: selected
            ? Icon(Icons.check, size: size - 8, color: scheme.onPrimary)
            : null,
      ),
    );
  }
}
