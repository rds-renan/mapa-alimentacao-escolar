import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// O destino que ainda não existe — a versão em Dart do
/// `web/src/components/pending-screen.tsx`.
///
/// A visão do mês e o menu (issue #104) ficaram prontos antes das telas para
/// onde apontam, e um caminho que não leva a lugar nenhum é pior do que um
/// que leva a uma tela dizendo de quem ela é: assim a navegação da issue
/// #104 é verificável de ponta a ponta hoje, e cada issue seguinte substitui
/// um arquivo destes.
class PendingScreen extends StatelessWidget {
  const PendingScreen({
    super.key,
    required this.title,
    required this.issue,
    required this.message,
  });

  final String title;
  final int issue;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(kSpacingUnit * 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: kSpacingUnit * 2,
            children: [
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              Text(
                'Esta tela entra na issue #$issue.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
