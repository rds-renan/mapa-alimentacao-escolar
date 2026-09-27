import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// O contorno das telas que existem antes de entrar: login e "esqueci minha
/// senha" — a versão em Flutter de `web/src/components/entry-screen.tsx`.
class EntryScaffold extends StatelessWidget {
  const EntryScaffold({super.key, required this.child, this.footer});

  final Widget child;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: kSpacingUnit * 6),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: kSpacingUnit * 8,
                      children: [const _Brand(), child],
                    ),
                  ),
                ),
              ),
              if (footer != null)
                Padding(
                  padding: EdgeInsets.only(bottom: kSpacingUnit * 4),
                  child: footer,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('MAE', style: Theme.of(context).textTheme.headlineLarge),
        Text(
          'Mapa da Alimentação Escolar',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}
