/// O catálogo de gêneros do jeito que o registro do dia precisa dele — porto
/// de `web/src/food-items/catalog.ts` (issue #106): as unidades para sugerir,
/// a busca e o resumo de uma quantidade.
///
/// Mora fora de `day/` porque não é do dia — é o catálogo, e a manutenção
/// dele (issue #107) lê pela mesma porta. O que é do dia é a folha que o
/// consulta sem tirar a merendeira do registro (decisão 7 da E3).
library;

import '../local/day.dart' show normalizedName;

/// As unidades que a folha oferece ao cadastrar um gênero no meio do
/// registro.
///
/// A unidade é texto curto no banco e a lista **não** é fechada (decisão 8
/// da E4) — mas quem abre o leque é a manutenção do catálogo. Aqui, no meio
/// do registro, é um toque e nenhum teclado.
///
/// São só "kg" e "un" desde a E7 (issue #175): é como vem na nota fiscal do
/// fornecedor, onde elas conferem o que recebem, e são as duas que usam.
/// Qualquer outra elas digitam no catálogo, que aceita texto livre.
const List<String> unitSuggestions = ['kg', 'un'];

/// O Dart não tem a normalização Unicode do `String.normalize('NFD')` do
/// JavaScript, então os acentos saem por tabela. Cobrem o português, que é
/// o que se escreve num catálogo de cozinha escolar.
const Map<String, String> _plain = {
  'á': 'a', 'à': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', //
  'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e', //
  'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i', //
  'ó': 'o', 'ò': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o', //
  'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u', //
  'ç': 'c', 'ñ': 'n',
};

/// A busca ignora acento e caixa: "feijao" acha "Feijão". Quem digita é
/// quem está com as duas mãos ocupadas na cozinha, e errar o til não pode
/// custar o resultado.
String _fold(String text) =>
    normalizedName(text).split('').map((one) => _plain[one] ?? one).join();

bool matchesSearch(String name, String search) =>
    _fold(name).contains(_fold(search));

/// "3 kg de arroz" — a quantidade como o cartão do dia a resume.
///
/// Sem plural desde a E7 (issue #175): a unidade sai como está no catálogo,
/// como na nota fiscal e no documento oficial. "kg" e "un" não têm plural, e
/// o "s" simples de antes daria "3 kgs".
String quantityLabel(int quantity, String? unit) {
  final one = (unit ?? '').trim();
  return one.isEmpty ? '$quantity' : '$quantity $one';
}
