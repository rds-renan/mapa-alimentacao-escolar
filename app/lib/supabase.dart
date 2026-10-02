import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth/secure_session_storage.dart';
import 'env.dart';

/// Cliente único do Supabase. Só a URL do projeto e a chave publicável, que
/// é pública por construção: o que a merendeira pode ler e escrever é
/// decidido pelas políticas de RLS no banco, não por esta chave.
///
/// A sessão persiste em armazenamento seguro do aparelho, não no padrão da
/// biblioteca (issue #101) — ver [SecureSessionStorage].
///
/// Toda chamada leva o versionCode deste APK no cabeçalho `x-mae-app-build`:
/// é por ele que a `save_meal_map` recusa o aplicativo abaixo da versão
/// mínima (decisão 12 da E6, issue #113). A web não manda o cabeçalho.
Future<void> initSupabase({required int build}) async {
  await Supabase.initialize(
    url: Env.supabaseUrl,
    publishableKey: Env.supabasePublishableKey,
    headers: {appBuildHeader: '$build'},
    authOptions: const FlutterAuthClientOptions(
      localStorage: SecureSessionStorage(),
    ),
  );
}

/// O cabeçalho da versão. Mudar o nome aqui é mudar em
/// `internal.reject_outdated_app`, no banco.
const appBuildHeader = 'x-mae-app-build';

SupabaseClient get supabase => Supabase.instance.client;
