import '../month/month.dart';
import 'generated.dart';
import 'selection.dart';

/// Os textos da seleção de mapas (tela 5) e da confirmação. Valem as regras
/// do catálogo de avisos da E3: nenhuma mensagem culpa a merendeira, o erro
/// diz primeiro o que não se perdeu, e nada de jargão — e o que a E6 acrescentou
/// a elas: sem "servidor", curto, e só o que é verdade.
abstract final class SelectionMessages {
  static const title = 'Gerar documento';
  static const singleDocument =
      'Todos os dias escolhidos saem em um único documento, no padrão da '
      'prefeitura.';
  static const lockWarning =
      'Depois de gerar, os mapas incluídos ficam bloqueados para edição.';

  /// Não é a frase da E3. A da E3 ("assim que houver, os mapas sobem e o
  /// documento fica pronto") promete uma geração que acontece sozinha, e
  /// essa fila não existe (decisão 7 da E6) — a merendeira precisa tocar de
  /// novo.
  static const offline =
      'Sem internet não dá para gerar o documento. Quando voltar, é só tocar '
      'em Gerar documento.';
  static const generate = 'Gerar documento';
  static const generating = 'Gerando o documento…';
  static const empty = 'Nenhum dia para mostrar neste mês.';
  static const sendNow = 'Enviar agora';

  /// A saída quando o período não fecha. Dias avulsos é caso previsto (CA#1
  /// da US013), e sem esta frase o aviso viraria uma porta trancada.
  static const pickByHand =
      'Termine esses dias e volte aqui. Se precisar do documento assim '
      'mesmo, use "Escolher dias" e marque só os que já estão prontos.';

  static String subtitle(DateTime month) =>
      'Escolha os mapas de ${monthLabel(month).toLowerCase()}';
}

const modeLabels = {
  SelectionMode.month: 'Mês inteiro',
  SelectionMode.week: 'Semana',
  SelectionMode.days: 'Escolher dias',
};

/// Por que o dia está de fora. "Pendente" é a mesma palavra da visão do mês,
/// de propósito: uma palavra por conceito, em todas as telas.
const missingLabels = {
  MissingReason.pending: 'Pendente',
  MissingReason.empty: 'Sem registro',
  MissingReason.unsent: 'Esperando enviar',
};

String selectionLabel(int count) {
  if (count == 0) return 'Nenhum mapa selecionado';
  return count == 1 ? '1 mapa selecionado' : '$count mapas selecionados';
}

/// O aviso de que o período não fecha. `scope` é o período em português:
/// "setembro", "a semana 2".
String missingTitle(String scope, int count) => count == 1
    ? 'Ainda falta 1 dia para fechar $scope.'
    : 'Ainda faltam $count dias para fechar $scope.';

String unsentNotice(int count) => count == 1
    ? 'Tem 1 dia salvo neste aparelho que ainda não subiu. Ele sobe sozinho '
          'quando houver internet, e só depois pode entrar no documento.'
    : 'Tem $count dias salvos neste aparelho que ainda não subiram. Eles '
          'sobem sozinhos quando houver internet, e só depois podem entrar no '
          'documento.';

String weekMissingLabel(int count) =>
    count == 1 ? 'falta 1 dia' : 'faltam $count dias';

/// A única confirmação do fluxo da merendeira — as palavras são as da E3.
abstract final class ConfirmMessages {
  static const cancel = 'Voltar';
  static const confirm = 'Gerar';

  static String title(String period) => 'Gerar o documento de $period?';

  static String body(int count) => count == 1
      ? 'O mapa incluído fica bloqueado para edição depois de gerar. Se ainda '
            'falta corrigir algo, é agora.'
      : 'Os $count mapas incluídos ficam bloqueados para edição depois de '
            'gerar. Se ainda falta corrigir algum, é agora.';
}

abstract final class FailureMessages {
  static const title = 'Não deu para gerar o documento';

  /// O servidor não respondeu nada — que na escola é quase sempre a internet.
  static const network =
      'A internet caiu no meio do caminho. Os mapas continuam salvos e '
      'nenhum foi bloqueado — dá para tentar de novo quando quiser.';

  /// Acompanha qualquer recusa: é sempre verdade, porque o bloqueio só
  /// acontece junto com a publicação do documento.
  static const nothingLocked =
      'Os mapas continuam salvos e nenhum foi bloqueado.';
  static const close = 'Fechar';
  static const retry = 'Tentar de novo';
}

/// Os textos da lista de documentos gerados (tela 2b, e a 6 dentro do
/// cartão do recém-gerado) — as frases da web, com o que o aplicativo muda:
/// o arquivo se compartilha pela folha do Android, e não se baixa, e a lista
/// abre sem rede (decisão 6 da E6).
abstract final class DocumentMessages {
  static const title = 'Documentos gerados';
  static const subtitle = 'O arquivo fica disponível por 7 dias';
  static const back = 'Voltar';

  /// O aviso do alto. A frase da E3 prometia uma notificação do sistema, que
  /// não existe (decisão 10 da E6): o que vale é o que de fato acontece.
  static const notice =
      'Gerar e compartilhar o documento precisa de internet. A lista abre '
      'sem ela, com o que já veio.';
  static const loading = 'Carregando os documentos…';
  static const loadFailed =
      'Não deu para carregar a lista de documentos. Os mapas que você '
      'registrou continuam guardados — foi só a lista que não veio.';
  static const retry = 'Tentar de novo';
  static const empty = 'Você ainda não gerou nenhum documento.';
  static const emptyHint = 'Quando gerar o primeiro, ele aparece aqui.';
  static const generate = 'Gerar documento';
  static const share = 'Compartilhar';
  static const justGenerated = 'Documento gerado';
  static const expireNote =
      'O arquivo expira sozinho. Se precisar de novo, é só gerar outra vez '
      'com os mesmos dias.';

  /// A frase da tela 2b para o documento fora da janela (CA#3 da US021).
  static const expiredNote = 'Os mapas desse período continuam guardados.';
  static const failedNote =
      'A geração não chegou ao fim. Nenhum mapa foi bloqueado e os registros '
      'do período continuam guardados — dá para gerar de novo.';
  static const processingNote = 'Ele aparece aqui assim que ficar pronto.';
  static const offline =
      'Compartilhar o documento precisa de internet. A lista continua aqui — '
      'é só tentar de novo quando houver.';
  static const fileFailed =
      'Não deu para abrir o arquivo agora. Ele continua no ar até a data que '
      'o cartão mostra — dá para tentar de novo.';
}

/// O aviso de documento pronto ao abrir o aplicativo (issue #110). Substitui
/// a notificação do sistema da E3: a frase "O documento ficou pronto" é a
/// dela, e o resto segue as mesmas regras do catálogo.
abstract final class ReadyNoticeMessages {
  static const single = 'O documento ficou pronto';
  static const share = 'Compartilhar';
  static const dismiss = 'Dispensar o aviso';

  static String title(int count) =>
      count == 1 ? single : '$count documentos ficaram prontos';

  /// "1 a 12 de setembro · 10 mapas". Com mais de um documento, o aviso
  /// fala do mais novo e diz que ele é o mais novo.
  static String body(String period, int maps, {required int count}) {
    final summary = '$period · ${mapCountLabel(maps)}';
    return count == 1 ? summary : 'O mais recente é de $summary.';
  }
}

const availabilityLabels = {
  DocumentAvailability.processing: 'Gerando',
  DocumentAvailability.available: 'Disponível',
  DocumentAvailability.expiring: 'Sai amanhã',
  DocumentAvailability.expired: 'Fora do ar',
  DocumentAvailability.failed: 'Não saiu',
};

/// "Sai hoje" quando é hoje mesmo: o desenho só previu o "Sai amanhã".
String availabilityLabel(DocumentAvailability availability, int? daysLeft) {
  if (availability == DocumentAvailability.expiring &&
      daysLeft != null &&
      daysLeft <= 0) {
    return 'Sai hoje';
  }
  return availabilityLabels[availability]!;
}

String lockedNotice(int count) => count == 1
    ? 'O mapa incluído ficou bloqueado para edição. Precisou corrigir algo? '
          'Fale com a direção.'
    : 'Os $count mapas incluídos ficaram bloqueados para edição. Precisou '
          'corrigir algo? Fale com a direção.';

/// A etiqueta de acessibilidade do botão, que diz de qual documento ele é.
String shareLabel(String period) =>
    '${DocumentMessages.share} o documento de $period';
