import '../month/month.dart';
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
