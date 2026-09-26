import 'package:flutter/material.dart';

import 'env.dart';
import 'supabase.dart';
import 'theme/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!Env.isConfigured) {
    throw StateError(
      'Configuração ausente: rode com --dart-define-from-file=env/local.json '
      '(ou env/production.json). O modelo está em env/local.example.json — '
      'veja docs/06-app/fundacao-do-app.md.',
    );
  }

  await initSupabase();

  runApp(const MaeApp());
}

class MaeApp extends StatelessWidget {
  const MaeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MAE',
      theme: maeLightTheme,
      darkTheme: maeDarkTheme,
      themeMode: ThemeMode.system,
      home: const _ConferenciaDeTokens(),
    );
  }
}

/// Tela provisória: mostra a paleta, a escala tipográfica e os controles nos
/// dois temas, para conferir a olho que os tokens da E3 fecham antes de
/// existir tela de verdade. Sai quando a autenticação entrar (issue #101),
/// como a página equivalente saiu na web.
class _ConferenciaDeTokens extends StatelessWidget {
  const _ConferenciaDeTokens();

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<MaeColors>()!;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('MAE — fundação do app')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(kSpacingUnit * 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: kSpacingUnit * 4,
          children: [
            Text('Título de tela (17 px)', style: textTheme.titleLarge),
            Text('Título de cartão (16 px)', style: textTheme.titleMedium),
            Text('Corpo (14 px)', style: textTheme.bodyLarge),
            Text('Apoio (13 px)', style: textTheme.bodyMedium),
            Text('Rótulo auxiliar (12 px)', style: textTheme.bodySmall),
            Text('Metadado (11 px)', style: textTheme.labelSmall),
            Wrap(
              spacing: kSpacingUnit * 2,
              runSpacing: kSpacingUnit * 2,
              children: [
                FilledButton(onPressed: () {}, child: const Text('Confirmar')),
                OutlinedButton(onPressed: () {}, child: const Text('Cancelar')),
                TextButton(onPressed: () {}, child: const Text('Detalhes')),
              ],
            ),
            const SizedBox(
              width: 240,
              child: TextField(
                decoration: InputDecoration(labelText: 'Entrada de texto'),
              ),
            ),
            Wrap(
              spacing: kSpacingUnit * 2,
              runSpacing: kSpacingUnit * 2,
              children: [
                _Selo(
                  'sucesso',
                  tokens.success,
                  tokens.successSubtle,
                  tokens.successBorder,
                ),
                _Selo(
                  'atenção',
                  tokens.warning,
                  tokens.warningSubtle,
                  tokens.warningBorder,
                ),
                _Selo(
                  'erro',
                  Theme.of(context).colorScheme.error,
                  tokens.destructiveSubtle,
                  tokens.destructiveBorder,
                ),
                _Selo(
                  'destaque',
                  tokens.accentForeground,
                  tokens.accent,
                  tokens.accentBorder,
                ),
              ],
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(kSpacingUnit * 4),
                child: Text(
                  'Cartão (raio de ${kRadiusXl.toInt()} px)',
                  style: textTheme.bodyLarge,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Selo extends StatelessWidget {
  const _Selo(this.texto, this.foreground, this.background, this.border);

  final String texto;
  final Color foreground;
  final Color background;
  final Color border;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: kSpacingUnit * 3,
        vertical: kSpacingUnit * 2,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(kRadiusMd),
        border: Border.all(color: border),
      ),
      child: Text(texto, style: TextStyle(color: foreground)),
    );
  }
}
