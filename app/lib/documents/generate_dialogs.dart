import 'package:flutter/material.dart';

import 'messages.dart';

/// A confirmação antes de gerar — **a única do fluxo da merendeira**
/// (decisão da E3). Existe porque o bloqueio dos mapas é irreversível para
/// ela: desfazer passa a ser assunto da direção, com justificativa (US023).
/// Confirmar tudo é o caminho mais curto para ela deixar de ler as
/// confirmações, e é por isso que esta é a única.
///
/// Devolve `true` ao confirmar. Não fecha com um toque fora; o botão voltar
/// do Android fecha como "Voltar" (devolve nulo), que também não gera nada.
Future<bool> confirmGeneration(
  BuildContext context, {
  required String period,
  required int count,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: Text(ConfirmMessages.title(period)),
      content: Text(ConfirmMessages.body(count)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text(ConfirmMessages.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text(ConfirmMessages.confirm),
        ),
      ],
    ),
  );

  return confirmed ?? false;
}

/// O diálogo de falha obedece à regra de linguagem da E3: o erro diz primeiro
/// o que **não** se perdeu. Aqui isso é informação operacional e verificável
/// — o bloqueio acontece junto com a publicação do documento, então geração
/// que falhou não bloqueou nada. Devolve `true` para "Tentar de novo".
Future<bool> showGenerationFailure(
  BuildContext context, {
  required String message,
}) async {
  // A frase da rede já afirma que nada foi bloqueado; a do servidor, não. A
  // linha só entra quando falta, para não dizer duas vezes a mesma coisa.
  final reassures = message.contains('bloquead');

  final retry = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: const Text(FailureMessages.title),
      content: Text(
        reassures ? message : '$message ${FailureMessages.nothingLocked}',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text(FailureMessages.close),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text(FailureMessages.retry),
        ),
      ],
    ),
  );

  return retry ?? false;
}
