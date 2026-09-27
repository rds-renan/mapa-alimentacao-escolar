/// O que o app lê do ambiente, por `--dart-define-from-file` (veja
/// `docs/06-app/fundacao-do-app.md`). Os valores entram em tempo de
/// compilação, então nunca ficam no código nem no APK como texto solto.
abstract final class Env {
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  static const String supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  /// O endereço da web, sem barra no fim. Usado só para montar o link de
  /// volta do e-mail de senha nova (issue #101): a merendeira nunca abre o
  /// navegador a partir do aplicativo, mas o e-mail é o mesmo dos dois
  /// lugares, e o link nele precisa apontar para algum lugar que funcione.
  static const String webUrl = String.fromEnvironment('WEB_URL');

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty &&
      supabasePublishableKey.isNotEmpty &&
      webUrl.isNotEmpty;
}
