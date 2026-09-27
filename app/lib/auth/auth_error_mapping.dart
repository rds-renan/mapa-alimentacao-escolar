import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;

import 'auth_messages.dart';

/*
 * Traduz o erro do `gotrue` para uma frase do catálogo — o mesmo papel que
 * `messageFor` cumpre em `web/src/auth/auth-provider.ts`. Erro de rede não
 * tem `code` (nem `statusCode`); o resto é falha do sistema, e em nenhum dos
 * dois casos há o que a merendeira possa corrigir no formulário.
 */

String messageForSignIn(AuthException error) {
  switch (error.code) {
    case 'invalid_credentials':
      return AuthMessages.invalidCredentials;
    case 'over_request_rate_limit':
    case 'over_email_send_rate_limit':
      return AuthMessages.tooManyAttempts;
    default:
      return error.statusCode == '429'
          ? AuthMessages.tooManyAttempts
          : AuthMessages.connection;
  }
}

String messageForRecoveryRequest(AuthException error) {
  switch (error.code) {
    case 'over_request_rate_limit':
    case 'over_email_send_rate_limit':
      return AuthMessages.tooManyAttempts;
    default:
      return error.statusCode == '429'
          ? AuthMessages.tooManyAttempts
          : AuthMessages.connection;
  }
}

String messageForVerifyCode(AuthException error) {
  switch (error.code) {
    case 'otp_expired':
    case 'otp_disabled':
      return AuthMessages.codeInvalidOrExpired;
    case 'over_request_rate_limit':
    case 'over_email_send_rate_limit':
      return AuthMessages.tooManyAttempts;
    default:
      return error.statusCode == '429'
          ? AuthMessages.tooManyAttempts
          : AuthMessages.connection;
  }
}

String messageForUpdatePassword(AuthException error) {
  switch (error.code) {
    case 'weak_password':
      return AuthMessages.passwordTooShort;
    case 'same_password':
      return AuthMessages.samePassword;
    default:
      return error.statusCode == '429'
          ? AuthMessages.tooManyAttempts
          : AuthMessages.connection;
  }
}
