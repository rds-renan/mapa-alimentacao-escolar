/// Os textos da sincronização. Os três primeiros são os da faixa de
/// salvamento da decisão 3 da E3 — não há botão "Salvar", e é esta faixa que
/// diz à merendeira em que pé está o registro dela. São os textos de
/// `web/src/local/messages.ts`, com "seu celular" onde a web diz "neste
/// aparelho": lá pode ser o computador, aqui é sempre o celular dela.
///
/// Valem aqui as mesmas três regras do catálogo de avisos: nenhuma mensagem
/// culpa a merendeira, o erro diz primeiro o que não se perdeu, e não há
/// jargão ("salvo no aparelho", não "cache local"; "salvo na nuvem", não
/// "enviado" nem "sincronizado"). A frase do dia que subiu já prometeu o
/// documento, e o dia nem sempre estava pronto para ele (issue #125): agora
/// ela diz só onde o registro está.
library;

enum SyncStatus { pending, sent, failed, outdated }

const Map<SyncStatus, String> syncMessages = {
  SyncStatus.pending:
      'Salvo no seu celular. A gente atualiza na nuvem quando a internet '
      'voltar.',
  SyncStatus.sent: 'Salvo na nuvem.',
  SyncStatus.failed:
      'Aguardando internet para salvar na nuvem. Seus dados estão seguros no '
      'aparelho.',
  // O quarto estado, que a E3 não tinha: o aplicativo está abaixo da versão
  // mínima (decisão 12 da E6, issue #113). Prometer "quando houver internet"
  // seria mentir — com internet também não sobe, só depois de atualizar.
  SyncStatus.outdated:
      'Salvo no seu celular. Vai para a nuvem depois que você atualizar o MAE.',
};

/// A falha que não é de internet: o banco recusou o dia — ele já está num
/// documento gerado, ou uma quantidade não vale. A frase de falha de sempre
/// diz "aguardando internet", e aqui seria falsa: a internet está lá, e o dia
/// só sobe depois que ela corrigir. Esta vem antes da explicação do banco,
/// que diz o que corrigir (issue #125).
const rejectedMessage =
    'Ainda não foi para a nuvem. Seus dados estão seguros no aparelho.';

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
