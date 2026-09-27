import 'package:flutter/material.dart';

import '../theme/theme.dart';

enum FormMessageKind { error, success }

/// A mensagem que fica dentro da tela, no lugar onde a coisa aconteceu, e
/// permanece enquanto valer — a primeira família do catálogo de avisos da E3
/// (`docs/03-ux/avisos-e-mensagens.md`), como `web/src/components/form-message.tsx`
/// já faz na web. `Semantics(liveRegion: true)` é o que faz o leitor de tela
/// anunciá-la sem que a merendeira precise procurar o texto.
class FormMessage extends StatelessWidget {
  const FormMessage(this.text, {super.key, this.kind = FormMessageKind.error});

  final String text;
  final FormMessageKind kind;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<MaeColors>()!;
    final isError = kind == FormMessageKind.error;
    final color = isError
        ? Theme.of(context).colorScheme.error
        : tokens.success;

    return Semantics(
      liveRegion: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: kSpacingUnit * 2,
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: color,
            size: 18,
          ),
          Expanded(
            child: Text(text, style: TextStyle(color: color, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
