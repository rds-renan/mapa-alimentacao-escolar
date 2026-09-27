/*
 * A conferência da forma do e-mail: alguma coisa, arroba, domínio, ponto e o
 * fim do domínio. Não existe validação que prove que um endereço recebe
 * mensagem — só mandando se descobre —, então isto não serve para recusar
 * ninguém: serve para o campo avisar que espera um e-mail, e não qualquer
 * coisa. Mesma expressão de `web/src/lib/email.ts`.
 */
final _emailFormat = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');

bool isValidEmail(String value) => _emailFormat.hasMatch(value.trim());
