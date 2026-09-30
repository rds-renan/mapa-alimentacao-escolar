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
/// de uma refeição, são seis toques e nenhum teclado: é o desenho da tela 3b,
/// e é o que faz o pior caso (o gênero não existe) caber em dois gestos.
const List<String> unitSuggestions = [
  'quilo',
  'saco',
  'pote',
  'litro',
  'lata',
  'unidade',
];

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

/// "3 bandejas de ovo" — a quantidade como o cartão da refeição a resume.
///
/// O plural é o "s" simples, e é uma aproximação assumida: as seis unidades
/// sugeridas pluralizam assim, e uma unidade esquisita vinda do catálogo sai
/// com um "s" a mais em vez de sair errada de gênero. O documento oficial não
/// passa por aqui — lá o formato é "N unidade" (CA#3 da US003).
String quantityLabel(int quantity, String? unit) {
  final one = (unit ?? '').trim();
  if (one.isEmpty) return '$quantity';

  final many = quantity > 1 && !one.endsWith('s') ? '${one}s' : one;
  return '$quantity $many';
}
