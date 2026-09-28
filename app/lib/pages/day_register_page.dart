import 'package:flutter/material.dart';

import '../widgets/pending_screen.dart';

/// O registro do dia (issue #105). Por enquanto, só o destino do toque num
/// dia da visão do mês.
class DayRegisterPage extends StatelessWidget {
  const DayRegisterPage({super.key, required this.mapDate});

  static const path = '/dia/:mapDate';

  static String pathFor(String mapDate) => '/dia/$mapDate';

  final String mapDate;

  @override
  Widget build(BuildContext context) {
    return PendingScreen(
      title: 'Registro do dia',
      issue: 105,
      message: 'A visão do mês já sabe abrir cada dia — este é o dia $mapDate.',
    );
  }
}
