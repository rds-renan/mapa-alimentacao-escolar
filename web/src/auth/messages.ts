/*
 * Os textos da autenticação, num lugar só. Saem do catálogo de avisos da E3
 * (docs/03-ux/avisos-e-mensagens.md) e seguem as três regras de lá: nenhuma
 * mensagem culpa a merendeira, o erro diz primeiro o que não se perdeu, e não
 * há jargão nem código de erro na tela.
 */
export const AUTH_MESSAGES = {
  /*
   * Não diz qual dos dois campos está errado. Só a direção cria acesso
   * (CA#3 da US016), e apontar o campo certo ajudaria justamente quem não
   * deveria entrar.
   */
  invalidCredentials: 'E-mail ou senha não conferem. Confira e tente de novo.',

  /*
   * Mostrada no próprio campo, que fica marcado, e ela impede o envio: mandar
   * ao servidor o que já se sabe que não é e-mail só gastaria a espera da
   * pessoa para trazer de volta um erro pior — o de senha, que não é o
   * problema. É o único erro que aponta um campo só, e pode: nenhum servidor
   * foi consultado, então dizer qual está torto não entrega nada a ninguém.
   */
  emailInvalid: 'O e-mail precisa ter o formato nome@dominio.com.br.',

  captchaFailed:
    'Não deu para confirmar que não é um robô. Espere um instante e tente de novo.',

  connection:
    'Não deu para falar com o sistema agora. Confira a internet e tente de novo.',

  tooManyAttempts:
    'Foram muitas tentativas seguidas. Espere um minuto e tente de novo.',

  /*
   * Sessão válida, mas a direção desativou o acesso (CA#2 da US016). Quem vê
   * isto não tem o que fazer dentro do aplicativo.
   */
  accessDisabled:
    'Este acesso não está mais ativo. Fale com a direção da escola.',

  profileUnavailable:
    'Não deu para confirmar o seu acesso agora. Nada foi perdido — é só tentar de novo.',

  resetRequested:
    'Se este e-mail tiver acesso ao MAE, o link para criar uma senha nova já está a caminho. Confira também o lixo eletrônico.',

  resetLinkExpired:
    'Este link não vale mais — eles duram pouco, por segurança. Peça outro e a senha nova se cria na hora.',

  passwordTooShort: 'A senha precisa ter pelo menos 8 caracteres.',

  passwordMismatch:
    'As duas senhas não estão iguais. Confira e digite de novo.',

  passwordChanged: 'Senha trocada. Entrando…',
} as const

/** O mínimo que o Supabase aceita (`minimum_password_length` no config.toml). */
export const MINIMUM_PASSWORD_LENGTH = 8

/*
 * A espera depois de muitos erros de senha, com o tempo que falta. O texto
 * muda de segundos para minutos porque "espere 300 segundos" é uma conta que
 * ninguém deveria ter de fazer.
 */
export function waitMessage(millisecondsLeft: number): string {
  const seconds = Math.max(1, Math.ceil(millisecondsLeft / 1000))

  if (seconds < 60) {
    return `Foram muitas tentativas seguidas. Dá para tentar de novo em ${seconds} ${seconds === 1 ? 'segundo' : 'segundos'}.`
  }

  const minutes = Math.ceil(seconds / 60)
  return `Foram muitas tentativas seguidas. Dá para tentar de novo em ${minutes} ${minutes === 1 ? 'minuto' : 'minutos'}.`
}
