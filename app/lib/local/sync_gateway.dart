/// O que o envio de um dia precisa do Supabase, isolado atrás de uma
/// interface — o mesmo raciocínio do [CatalogGateway] e do [MonthGateway]
/// (decisão 4 da E6): torna o [SyncEngine] testável sem servidor.
///
/// A recusa chega como exceção — `PostgrestException`, com o `code` (SQLSTATE)
/// e a `message` que a tabela de erros de
/// `docs/05-web/gravacao-do-dia.md` descreve — e qualquer outra exceção é
/// falha de rede, tratada como tal por quem chama.
abstract class SyncGateway {
  /// Manda o dia inteiro numa chamada só e devolve o que `save_meal_map`
  /// respondeu, ainda em formato de fio (chaves em snake_case).
  Future<Map<String, dynamic>> saveMealMap(Map<String, dynamic> payload);
}
