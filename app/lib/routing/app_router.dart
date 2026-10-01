import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_controller.dart';
import '../pages/day_register_page.dart';
import '../pages/food_items_page.dart';
import '../pages/forgot_password_page.dart';
import '../pages/generated_documents_page.dart';
import '../pages/home_page.dart';
import '../pages/select_maps_page.dart';
import '../pages/sign_in_page.dart';

/// A navegação (decisão 5 da E6): sem sessão, toda rota leva ao login; com
/// sessão de merendeira, a casa é a visão do mês. Vale repetir o que a
/// decisão já diz — **a guarda é conveniência de interface, não controle de
/// acesso**; quem decide o que a merendeira lê e escreve são as políticas de
/// RLS da E4.
///
/// A conta de direção nunca ganha rota própria: o [AuthController] a
/// derruba e devolve um aviso, e ela aparece de volta em [SignInPage] como
/// qualquer outra sessão encerrada (CA#2/CA#4 da issue #101).
final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = _GoRouterRefreshNotifier();
  final subscription = ref.listen(authControllerProvider, (_, _) {
    refresh.notify();
  });
  ref.onDispose(() {
    subscription.close();
    refresh.dispose();
  });

  return GoRouter(
    initialLocation: HomePage.path,
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      if (auth.loading) return null;

      final onAuthRoute =
          state.matchedLocation == SignInPage.path ||
          state.matchedLocation == ForgotPasswordPage.path;

      if (auth.signedIn) {
        return onAuthRoute ? HomePage.path : null;
      }

      return onAuthRoute ? null : SignInPage.path;
    },
    routes: [
      GoRoute(path: HomePage.path, builder: (_, _) => const HomePage()),
      GoRoute(path: SignInPage.path, builder: (_, _) => const SignInPage()),
      GoRoute(
        path: ForgotPasswordPage.path,
        builder: (_, _) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: DayRegisterPage.path,
        builder: (_, state) =>
            DayRegisterPage(mapDate: state.pathParameters['mapDate']!),
      ),
      GoRoute(
        path: FoodItemsPage.path,
        builder: (_, _) => const FoodItemsPage(),
      ),
      GoRoute(
        path: SelectMapsPage.path,
        builder: (_, state) => SelectMapsPage(
          month: SelectMapsPage.monthFrom(
            state.uri.queryParameters[SelectMapsPage.monthParam],
          ),
        ),
      ),
      GoRoute(
        path: GeneratedDocumentsPage.path,
        builder: (_, state) =>
            GeneratedDocumentsPage(justGenerated: state.extra as String?),
      ),
    ],
  );
});

class _GoRouterRefreshNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}
