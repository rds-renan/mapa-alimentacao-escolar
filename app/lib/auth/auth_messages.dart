/// Os textos da autenticação, num lugar só — os mesmos do catálogo de avisos
/// da E3 (`docs/03-ux/avisos-e-mensagens.md`) que a web já usa em
/// `web/src/auth/messages.ts`, e as frases novas que o código de 6 dígitos
/// exige (issue #101), escritas com as mesmas três regras de lá: nenhuma
/// mensagem culpa a merendeira, o erro diz primeiro o que não se perdeu, e
/// não há jargão nem código de erro na tela.
abstract final class AuthMessages {
  /// Não diz qual dos dois campos está errado. Só a direção cria acesso
  /// (CA#3 da US016), e apontar o campo certo ajudaria justamente quem não
  /// deveria entrar.
  static const invalidCredentials =
      'E-mail ou senha não conferem. Confira e tente de novo.';

  static const emailInvalid =
      'O e-mail precisa ter o formato nome@dominio.com.br.';

  static const connection =
      'Não deu para falar com o sistema agora. Confira a internet e tente de novo.';

  static const tooManyAttempts =
      'Foram muitas tentativas seguidas. Espere um instante e tente de novo.';

  /// Sessão válida, mas a direção desativou o acesso (CA#2 da US016). Quem vê
  /// isto não tem o que fazer dentro do aplicativo.
  static const accessDisabled =
      'Este acesso não está mais ativo. Fale com a direção da escola.';

  /// Conta de direção, recusada pelo aplicativo (decisão 1 da E6): o papel
  /// dela é gerencial, e o caminho é a web.
  static const adminNotSupported =
      'Este acesso é da direção da escola. A administração fica na web — o '
      'aplicativo é só para o registro da merendeira.';

  static const profileUnavailable =
      'Não deu para confirmar o seu acesso agora. Nada foi perdido — é só '
      'tentar de novo.';

  /// A resposta é a mesma para e-mail conhecido e desconhecido, pelo mesmo
  /// motivo do erro de login: dizer "este e-mail não tem acesso" entregaria
  /// quem tem.
  static const codeSent =
      'Se este e-mail tiver acesso ao MAE, o código para criar uma senha '
      'nova já está a caminho. Confira também o lixo eletrônico.';

  static const codeInvalidOrExpired =
      'Este código não confere ou já venceu. Peça outro.';

  static const passwordTooShort =
      'A senha precisa ter pelo menos $minimumPasswordLength caracteres.';

  static const passwordMismatch =
      'As duas senhas não estão iguais. Confira e digite de novo.';

  static const samePassword = 'A senha nova precisa ser diferente da atual.';

  static const passwordChanged = 'Senha trocada. Entrando…';

  /// O mínimo que o Supabase aceita (`minimum_password_length` no
  /// `config.toml`).
  static const int minimumPasswordLength = 8;
}
