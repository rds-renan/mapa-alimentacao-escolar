import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';
import '../theme/theme.dart';

/// A tela-casa da merendeira: a visão do mês, ainda não desenhada (issue
/// #104). O que existe aqui é só o suficiente para a autenticação ter
/// destino — o mesmo papel que `MonthView.tsx` cumpriu na web entre as
/// issues #59 e #61.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  static const path = '/';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);

    if (auth.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (auth.profileUnavailable) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(kSpacingUnit * 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: kSpacingUnit * 4,
              children: [
                const Text(
                  'Não deu para confirmar o seu acesso agora. Nada foi '
                  'perdido — é só tentar de novo.',
                  textAlign: TextAlign.center,
                ),
                FilledButton(
                  onPressed: () =>
                      ref.read(authControllerProvider.notifier).retryProfile(),
                  child: const Text('Tentar de novo'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final profile = auth.profile;

    return Scaffold(
      appBar: AppBar(
        title: Text(profile == null ? 'MAE' : 'Olá, ${profile.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: () =>
                ref.read(authControllerProvider.notifier).signOut(),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(kSpacingUnit * 6),
          child: Text(
            'A visão do mês entra na issue #104. Por enquanto, o que existe '
            'é o caminho até aqui: entrar, continuar entrando amanhã sem '
            'redigitar a senha e sair.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ),
    );
  }
}
