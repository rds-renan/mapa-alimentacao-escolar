import type { DocumentAvailability } from './generated'
import type { MissingReason, SelectionMode } from './selection'

/*
 * Os textos das duas telas do documento: a seleção de mapas (tela 5) e os
 * documentos gerados (telas 6 e 2b). Valem as três regras do catálogo de
 * avisos da E3: nenhuma mensagem culpa a merendeira, o erro diz primeiro o que não se
 * perdeu, e nada de jargão.
 *
 * Várias frases daqui são da E3, palavra por palavra, e é bom que se saiba
 * quais: o cartão do documento único e o aviso do bloqueio, que estão
 * desenhados na tela 5; o aviso de geração sem internet, do catálogo de avisos
 * dentro da tela; a confirmação antes de gerar, que é a única confirmação do
 * fluxo da merendeira; e, na tela 2b, o aviso do alto, as etiquetas de
 * situação e a nota do documento fora do ar.
 */

export const SELECTION_MESSAGES = {
  title: 'Gerar documento',
  singleDocument:
    'Todos os dias escolhidos saem em um único documento, no padrão da prefeitura.',
  lockWarning:
    'Depois de gerar, os mapas incluídos ficam bloqueados para edição.',
  offline:
    'Gerar o documento precisa de internet. Assim que houver, os mapas sobem e o documento fica pronto em Documentos gerados.',
  generate: 'Gerar documento',
  generating: 'Gerando o documento…',
  backToMonth: 'Voltar para o mês',
  loading: 'Carregando os dias do mês…',
  loadFailed:
    'Não deu para carregar os dias deste mês. O que você já registrou continua guardado — foi só a lista que não veio.',
  retry: 'Tentar de novo',
  empty: 'Nenhum dia para mostrar neste mês.',
  sendNow: 'Enviar agora',
  /*
   * A saída quando o período não fecha. Ela é oferecida de propósito: dias
   * avulsos é caso previsto (CA#1 da US013), e sem essa frase o aviso viraria
   * uma porta trancada.
   */
  pickByHand:
    'Termine esses dias e volte aqui. Se precisar do documento assim mesmo, use "Escolher dias" e marque só os que já estão prontos.',
} as const

export const MODE_LABELS: Record<SelectionMode, string> = {
  month: 'Mês inteiro',
  week: 'Semana',
  days: 'Escolher dias',
}

/**
 * Por que o dia está de fora. São as palavras da tela 5 desenhada na E3 —
 * "Pendente" é a mesma da visão do mês, e é de propósito: uma palavra por
 * conceito, em todas as telas.
 *
 * "Esperando enviar" é o único que a E3 não escreveu. Ela desenhou o estado do
 * envio como faixa dentro do registro do dia, não como estado de um dia na
 * lista — e aqui ele precisa aparecer, porque é o que separa um dia preenchido
 * de um dia que o servidor conhece.
 */
export const MISSING_LABELS: Record<MissingReason, string> = {
  pending: 'Pendente',
  empty: 'Sem registro',
  unsent: 'Esperando enviar',
}

export function selectionLabel(count: number): string {
  if (count === 0) return 'Nenhum mapa selecionado'
  return count === 1 ? '1 mapa selecionado' : `${count} mapas selecionados`
}

/**
 * O aviso de que o período não fecha.
 *
 * A regra do projeto é que mapa pendente não vai para a prefeitura, então o
 * atalho não seleciona "o que dá": ele não seleciona nada e diz o que falta.
 * `scope` é o período em português — "setembro", "a semana 2".
 */
export function missingTitle(scope: string, count: number): string {
  return count === 1
    ? `Ainda falta 1 dia para fechar ${scope}.`
    : `Ainda faltam ${count} dias para fechar ${scope}.`
}

/** "1 dia ainda está esperando para ser enviado." */
export function unsentNotice(count: number): string {
  return count === 1
    ? 'Tem 1 dia salvo neste computador que ainda não subiu. Ele sobe sozinho quando houver internet, e só depois pode entrar no documento.'
    : `Tem ${count} dias salvos neste computador que ainda não subiram. Eles sobem sozinhos quando houver internet, e só depois podem entrar no documento.`
}

// ---------------------------------------------------------------------------
// A confirmação, que é a única do fluxo da merendeira
// ---------------------------------------------------------------------------

export const CONFIRM_MESSAGES = {
  cancel: 'Voltar',
  confirm: 'Gerar',
} as const

export function confirmTitle(period: string): string {
  return `Gerar o documento de ${period}?`
}

export function confirmBody(count: number): string {
  return count === 1
    ? 'O mapa incluído fica bloqueado para edição depois de gerar. Se ainda falta corrigir algo, é agora.'
    : `Os ${count} mapas incluídos ficam bloqueados para edição depois de gerar. Se ainda falta corrigir algum, é agora.`
}

// ---------------------------------------------------------------------------
// A falha
// ---------------------------------------------------------------------------

export const FAILURE_MESSAGES = {
  title: 'Não deu para gerar o documento',
  /*
   * O caso em que o servidor não respondeu nada — que na escola é quase sempre
   * a internet. É a frase da E3, inteira.
   */
  network:
    'A internet caiu no meio do caminho. Os mapas continuam salvos e nenhum foi bloqueado — dá para tentar de novo quando quiser.',
  /*
   * Quando a recusa vem com explicação própria, a explicação é do servidor e
   * já chega legível. O que ela não traz é o que a regra da E3 exige que venha
   * primeiro — e esta linha, que acompanha qualquer falha, é sempre verdade: o
   * bloqueio só acontece junto com a publicação do documento.
   */
  nothingLocked: 'Os mapas continuam salvos e nenhum foi bloqueado.',
  close: 'Fechar',
  retry: 'Tentar de novo',
} as const

// ---------------------------------------------------------------------------
// Os documentos gerados (telas 6 e 2b)
// ---------------------------------------------------------------------------

/*
 * As duas telas da E3 são uma só aqui, e não por economia.
 *
 * A tela 6 é o beco que a decisão 10 da E3 identificou: ela mostra o documento
 * recém-gerado e, ao ser deixada, some com ele. A 2b existe para isso não
 * acontecer. Juntá-las resolve o beco pela raiz — o documento recém-gerado é o
 * primeiro da lista, no lugar onde ele estará amanhã também — e poupa à
 * merendeira aprender dois lugares para a mesma coisa.
 *
 * O que a tela 6 tinha e a lista não teria fica no cartão do recém-gerado: a
 * confirmação de que saiu, o nome do arquivo e o aviso do bloqueio, que é a
 * consequência que ela precisa ver **uma vez**, no momento em que acontece.
 */

export const DOCUMENT_MESSAGES = {
  title: 'Documentos gerados',
  subtitle: 'O arquivo fica disponível por 7 dias',
  back: 'Voltar para o mês',
  /* O aviso do alto da tela 2b, adaptado num ponto: na web não há notificação
   * fora do aplicativo, então o que a frase promete é a própria lista. */
  notice:
    'Gerar um documento precisa de internet, e os mapas ainda não enviados sobem primeiro. Quando ficar pronto, ele aparece aqui — não é preciso esperar na tela.',
  loading: 'Carregando os documentos…',
  loadFailed:
    'Não deu para carregar a lista de documentos. Os mapas que você registrou continuam guardados — foi só a lista que não veio.',
  retry: 'Tentar de novo',
  empty: 'Você ainda não gerou nenhum documento.',
  emptyHint: 'Quando gerar o primeiro, ele aparece aqui.',
  generate: 'Gerar documento',
  download: 'Baixar',
  share: 'Compartilhar',
  /* A tela 6 chamava este botão de "Baixar no aparelho". Na web o aparelho é
   * o computador da cozinha tanto quanto o celular, e "Baixar" basta. */
  justGenerated: 'Documento gerado',
  expireNote:
    'O arquivo expira sozinho. Se precisar de novo, é só gerar outra vez com os mesmos dias.',
  /* A frase da tela 2b para o documento fora da janela (CA#3 da US021). O "no
   * app" do desenho sai: aqui não é o aparelho que guarda, é o servidor. */
  expiredNote: 'Os mapas desse período continuam guardados.',
  failedNote:
    'A geração não chegou ao fim. Nenhum mapa foi bloqueado e os registros do período continuam guardados — dá para gerar de novo.',
  processingNote: 'Ele aparece aqui assim que ficar pronto.',
  offline:
    'Baixar o documento precisa de internet. A lista continua aqui, e o arquivo também — é só tentar de novo quando houver.',
  linkFailed:
    'Não deu para abrir o arquivo agora. Ele continua no ar até a data que o cartão mostra — dá para tentar de novo.',
} as const

/**
 * A etiqueta de situação do cartão. São as palavras da tela 2b, e as duas que
 * a E3 não desenhou — "Gerando" e "Não saiu" — existem porque o registro da
 * geração sobrevive à falha (decisão 10 da E4) e precisa dizer o que houve.
 */
export const AVAILABILITY_LABELS: Record<DocumentAvailability, string> = {
  processing: 'Gerando',
  available: 'Disponível',
  expiring: 'Sai amanhã',
  expired: 'Fora do ar',
  failed: 'Não saiu',
}

/** "Sai hoje" quando é hoje mesmo: o desenho só previu o "Sai amanhã". */
export function availabilityLabel(
  availability: DocumentAvailability,
  left: number | null
): string {
  if (availability === 'expiring' && left !== null && left <= 0) {
    return 'Sai hoje'
  }
  return AVAILABILITY_LABELS[availability]
}

/** A etiqueta de acessibilidade do botão, que diz de qual documento ele é. */
export function actionLabel(action: string, period: string): string {
  return `${action} o documento de ${period}`
}

/** O aviso do bloqueio, na tela 6: a consequência, vista uma vez. */
export function lockedNotice(count: number): string {
  return count === 1
    ? 'O mapa incluído ficou bloqueado para edição. Precisou corrigir algo? Fale com a direção.'
    : `Os ${count} mapas incluídos ficaram bloqueados para edição. Precisou corrigir algo? Fale com a direção.`
}
