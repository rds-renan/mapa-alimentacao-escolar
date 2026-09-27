import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth/secure_session_storage.dart';
import 'env.dart';

/// Cliente único do Supabase. Só a URL do projeto e a chave publicável, que
/// é pública por construção: o que a merendeira pode ler e escrever é
/// decidido pelas políticas de RLS no banco, não por esta chave.
///
/// A sessão persiste em armazenamento seguro do aparelho, não no padrão da
/// biblioteca (issue #101) — ver [SecureSessionStorage].
Future<void> initSupabase() async {
  await Supabase.initialize(
    url: Env.supabaseUrl,
    publishableKey: Env.supabasePublishableKey,
    authOptions: const FlutterAuthClientOptions(
      localStorage: SecureSessionStorage(),
    ),
  );
}

SupabaseClient get supabase => Supabase.instance.client;
