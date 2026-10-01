import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_controller.dart';
import '../pages/food_items_page.dart';
import '../pages/generated_documents_page.dart';
import '../theme/theme_preference.dart';

/// O menu do aplicativo — tela 2a da E3, decisão 9 da mesma etapa.
///
/// A versão em Dart do `web/src/components/app-menu.tsx`: a porta do que
/// **não** é fluxo diário. É a decisão 9 da E3 que dá os quatro itens —
/// documentos gerados, gerenciar gêneros, tema e sair.
///
/// Ele não interrompe registro em andamento (CA#1 da US020): o rascunho do
/// dia mora no aparelho e não depende desta tela estar aberta. E não tem
/// qualquer caminho para a área da direção (RN#1 da US020) — não é omissão
/// de interface, é o que as políticas de RLS da E4 já garantem no banco.
class AppMenu extends ConsumerWidget {
  const AppMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(authControllerProvider).profile;
    final theme = Theme.of(context);

    void navigateTo(String path) {
      Navigator.of(context).pop();
      context.push(path);
    }

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('MAE', style: theme.textTheme.titleLarge),
                  Text(
                    'Mapa da Alimentação Escolar',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(profile?.name ?? '', style: theme.textTheme.titleMedium),
                  Text(
                    profile?.email ?? '',
                    style: theme.textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: Icon(
                Icons.description_outlined,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              title: const Text('Documentos gerados'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => navigateTo(GeneratedDocumentsPage.path),
            ),
            ListTile(
              leading: Icon(
                Icons.list_alt,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              title: const Text('Gerenciar gêneros'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => navigateTo(FoodItemsPage.path),
            ),
            const Divider(height: 1),
            const _ThemeChoice(),
            const Spacer(),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    ref.read(authControllerProvider.notifier).signOut();
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Sair'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// O controle do tema (US024, issue #111): claro, escuro e sistema, os três à
/// vista — o par de `web/src/theme/theme-choice.tsx`, com o rótulo e a dica
/// do desenho da tela 2a.
///
/// `SegmentedButton` é o controle que o Material 3 tem para escolha
/// excludente de poucas opções: a escolha inteira cabe na tela e trocar custa
/// um toque. Sem ícone nas opções, como na web; a marca da escolhida é o
/// fundo, e o `showSelectedIcon` desligado evita o "✓" que espremeria
/// "Sistema" numa barra de 304 px.
class _ThemeChoice extends ConsumerWidget {
  const _ThemeChoice();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final preference = ref.watch(themePreferenceProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.dark_mode_outlined,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 16),
              Text('Tema', style: theme.textTheme.bodyLarge),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<ThemePreference>(
              showSelectedIcon: false,
              segments: [
                for (final option in ThemePreference.values)
                  ButtonSegment(value: option, label: Text(option.label)),
              ],
              selected: {preference},
              onSelectionChanged: (selection) => ref
                  .read(themePreferenceProvider.notifier)
                  .choose(selection.single),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Em Sistema, acompanha o tema do aparelho.',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
