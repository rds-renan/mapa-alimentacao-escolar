import 'package:flutter/material.dart';

import '../widgets/pending_screen.dart';

/// A manutenção do catálogo de gêneros (issue #107).
class FoodItemsPage extends StatelessWidget {
  const FoodItemsPage({super.key});

  static const path = '/generos';

  @override
  Widget build(BuildContext context) {
    return const PendingScreen(
      title: 'Gerenciar gêneros',
      issue: 107,
      message:
          'Aqui ficam os gêneros da cozinha, cada um com a sua unidade '
          'padrão.',
    );
  }
}
