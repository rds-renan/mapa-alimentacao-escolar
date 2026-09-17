/*
 * Os textos da sincronização. Os três primeiros são, palavra por palavra, os
 * da faixa de salvamento da decisão 3 da E3 — não há botão "Salvar", e é esta
 * faixa que diz à merendeira em que pé está o registro dela.
 *
 * Valem aqui as mesmas três regras do catálogo de avisos: nenhuma mensagem
 * culpa a merendeira, o erro diz primeiro o que não se perdeu, e não há jargão
 * ("salvo no aparelho", não "cache local"; "enviado", não "sincronizado").
 */

export type SyncStatus = 'pending' | 'sent' | 'failed'

export const SYNC_MESSAGES: Record<SyncStatus, string> = {
  pending: 'Salvo no aparelho. Envia sozinho quando houver internet.',
  sent: 'Enviado. Este mapa já está disponível para gerar o documento.',
  failed: 'Ainda não deu para enviar. Nada foi perdido, vamos tentar de novo.',
}

/*
 * O texto que a E3 não previu.
 *
 * O catálogo da E3 desenhou a faixa com três estados, e nenhum deles é o
 * conflito: as duas merendeiras se revezam no mesmo mapa, e o dia pode ter sido
 * registrado em outro aparelho depois da edição que está subindo. A decisão 5
 * da E5 manda prevalecer a edição mais recente e **sinalizar** — nunca resolver
 * calado (CA#3 da US011).
 *
 * A frase foge da regra "diz primeiro o que não se perdeu" porque aqui alguma
 * coisa se perdeu de verdade, e dourar isso seria pior: ela precisa conferir a
 * tela. O que a regra preserva é o resto — não culpa ninguém e não chama aquilo
 * de "conflito de sincronização".
 */
export function conflictMessage(mapDate: string): string {
  return `O dia ${formatDate(mapDate)} foi registrado em outro aparelho depois da sua edição, e o que vale é o registro mais recente. Confira se está como você deixou.`
}

/*
 * O aviso antes de sair com mapa por enviar.
 *
 * Sair apaga o que está guardado no aparelho, e isto é decisão de produto, não
 * descuido: um dia parado aqui na web pode ficar meses esperando alguém que
 * talvez não volte, e chegar ao servidor num formato que já não existe. Então a
 * escolha é dela, não do sistema — a frase diz o que se perde, e o botão que
 * apaga diz que apaga.
 */
export function pendingOnSignOutMessage(pending: number): string {
  return pending === 1
    ? 'Ainda tem 1 dia salvo neste computador que não foi enviado. Se sair agora, ele se perde.'
    : `Ainda tem ${pending} dias salvos neste computador que não foram enviados. Se sair agora, eles se perdem.`
}

/** AAAA-MM-DD como a merendeira lê: 10/09. */
function formatDate(mapDate: string): string {
  const [, month, day] = mapDate.split('-')
  return month && day ? `${day}/${month}` : mapDate
}
