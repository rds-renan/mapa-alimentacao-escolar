/// O que o app lê do ambiente, por `--dart-define-from-file` (veja
/// `docs/06-app/fundacao-do-app.md`). Os valores entram em tempo de
/// compilação, então nunca ficam no código nem no APK como texto solto.
abstract final class Env {
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  static const String supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;
}
