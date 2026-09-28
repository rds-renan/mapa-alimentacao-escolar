import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_controller.dart';
import '../pages/food_items_page.dart';
import '../pages/generated_documents_page.dart';

/// O menu do aplicativo — tela 2a da E3, decisão 9 da mesma etapa.
///
/// A versão em Dart do `web/src/components/app-menu.tsx`: a porta do que
/// **não** é fluxo diário. É a decisão 9 da E3 que dá os quatro itens —
/// documentos gerados, gerenciar gêneros, tema e sair —, mas dois deles
/// ainda não têm destino nem controle nesta issue: a mesma situação em que a
/// web esteve entre as issues #61 e #71.
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
            /*
             * O tema escuro é da issue #111. O aplicativo já segue o tema do
             * aparelho (`ThemeMode.system`, em `main.dart`) — o que falta é
             * o controle entre claro, escuro e sistema, como a web tem.
             * Fica aqui à vista e inerte, no mesmo espírito da web entre as
             * issues #61 e #71: tirá-lo do desenho e recolocá-lo depois
             * custaria mais do que deixá-lo explicado.
             */
            Opacity(
              opacity: 0.5,
              child: ListTile(
                leading: const Icon(Icons.dark_mode_outlined),
                title: const Text('Tema escuro'),
                trailing: Text('issue #111', style: theme.textTheme.labelSmall),
              ),
            ),
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
