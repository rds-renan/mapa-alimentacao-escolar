import 'package:flutter/material.dart';

import '../widgets/pending_screen.dart';

/// Os documentos ainda dentro da janela de 7 dias (issue #109).
class GeneratedDocumentsPage extends StatelessWidget {
  const GeneratedDocumentsPage({super.key});

  static const path = '/documentos';

  @override
  Widget build(BuildContext context) {
    return const PendingScreen(
      title: 'Documentos gerados',
      issue: 109,
      message:
          'Aqui ficam os documentos ainda dentro dos 7 dias, com o período '
          'de cada um e a ação de compartilhar de novo.',
    );
  }
}
