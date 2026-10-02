/// Os textos da sincronização. Os três primeiros são, palavra por palavra,
/// os da faixa de salvamento da decisão 3 da E3 — não há botão "Salvar", e é
/// esta faixa que diz à merendeira em que pé está o registro dela. Mesmos
/// textos de `web/src/local/messages.ts`.
///
/// Valem aqui as mesmas três regras do catálogo de avisos: nenhuma mensagem
/// culpa a merendeira, o erro diz primeiro o que não se perdeu, e não há
/// jargão ("salvo no aparelho", não "cache local"; "enviado", não
/// "sincronizado").
library;

enum SyncStatus { pending, sent, failed, outdated }

const Map<SyncStatus, String> syncMessages = {
  SyncStatus.pending:
      'Salvo no aparelho. Envia sozinho quando houver internet.',
  SyncStatus.sent:
      'Enviado. Este mapa já está disponível para gerar o documento.',
  SyncStatus.failed:
      'Ainda não deu para enviar. Nada foi perdido, vamos tentar de novo.',
  // O quarto estado, que a E3 não tinha: o aplicativo está abaixo da versão
  // mínima (decisão 12 da E6, issue #113). Prometer "quando houver internet"
  // seria mentir — com internet também não sobe, só depois de atualizar.
  SyncStatus.outdated:
      'Salvo no aparelho. Vai para a nuvem depois que você atualizar o MAE.',
};

/// O texto que a E3 não previu.
///
/// O catálogo da E3 desenhou a faixa com três estados, e nenhum deles é o
/// conflito: as duas merendeiras se revezam no mesmo mapa, e o dia pode ter
/// sido registrado em outro aparelho depois da edição que está subindo. A
/// decisão 5 da E5 (e a mesma regra aqui) manda prevalecer a edição mais
/// recente e **sinalizar** — nunca resolver calado (CA#3 da US011).
///
/// A frase foge da regra "diz primeiro o que não se perdeu" porque aqui
/// alguma coisa se perdeu de verdade, e dourar isso seria pior: ela precisa
/// conferir a tela. O que a regra preserva é o resto — não culpa ninguém e
/// não chama aquilo de "conflito de sincronização".
String conflictMessage(String mapDate) {
  return 'O dia ${_formatDate(mapDate)} foi registrado em outro aparelho '
      'depois da sua edição, e o que vale é o registro mais recente. '
      'Confira se está como você deixou.';
}

/// AAAA-MM-DD como a merendeira lê: 10/09.
String _formatDate(String mapDate) {
  final parts = mapDate.split('-');
  return parts.length == 3 ? '${parts[2]}/${parts[1]}' : mapDate;
}
