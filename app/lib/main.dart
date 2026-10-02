import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'env.dart';
import 'routing/app_router.dart';
import 'supabase.dart';
import 'theme/theme.dart';
import 'theme/theme_preference.dart';
import 'version/version_gate.dart';
import 'version/version_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!Env.isConfigured) {
    throw StateError(
      'Configuração ausente: rode com --dart-define-from-file=env/local.json '
      '(ou env/production.json). O modelo está em env/local.example.json — '
      'veja docs/06-app/fundacao-do-app.md.',
    );
  }

  final build = await loadAppBuild();
  await initSupabase(build: build.current);

  final themePreference = await loadThemePreference();

  runApp(
    ProviderScope(
      overrides: [
        initialThemePreferenceProvider.overrideWithValue(themePreference),
        appBuildProvider.overrideWithValue(build),
      ],
      child: const MaeApp(),
    ),
  );
}

class MaeApp extends ConsumerWidget {
  const MaeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'MAE',
      theme: maeLightTheme,
      darkTheme: maeDarkTheme,
      themeMode: ref.watch(themePreferenceProvider).mode,
      routerConfig: router,
    );
  }
}
