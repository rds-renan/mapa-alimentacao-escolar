import 'package:supabase_flutter/supabase_flutter.dart';

import 'env.dart';

/// Cliente único do Supabase. Só a URL do projeto e a chave publicável, que
/// é pública por construção: o que a merendeira pode ler e escrever é
/// decidido pelas políticas de RLS no banco, não por esta chave.
Future<void> initSupabase() async {
  await Supabase.initialize(
    url: Env.supabaseUrl,
    publishableKey: Env.supabasePublishableKey,
  );
}

SupabaseClient get supabase => Supabase.instance.client;
