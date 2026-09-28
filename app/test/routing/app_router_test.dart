import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mae/auth/auth_controller.dart';
import 'package:mae/auth/profile.dart';
import 'package:mae/local/app_database.dart';
import 'package:mae/local/local_providers.dart';
import 'package:mae/routing/app_router.dart';
import 'package:mae/theme/theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/fake_auth_gateway.dart';
import '../local/fake_month_gateway.dart';

void main() {
  late FakeAuthGateway gateway;
  late FakeMonthGateway monthGateway;
  late ProviderContainer container;

  setUp(() {
    gateway = FakeAuthGateway();
    monthGateway = FakeMonthGateway();
    container = ProviderContainer(
      overrides: [
        authGatewayProvider.overrideWithValue(gateway),
        monthGatewayProvider.overrideWithValue(monthGateway),
        // A visão do mês abre um arquivo Drift por perfil (decisão 6 da
        // E6); nos testes de widget, sempre um banco em memória, como
        // `month_repository_test.dart` já faz sem Riverpod nenhum.
        appDatabaseProvider.overrideWith(
          (ref, profileId) => AppDatabase(NativeDatabase.memory()),
        ),
      ],
    );
  });

  tearDown(() {
    container.dispose();
    gateway.dispose();
  });

  Future<void> pumpApp(WidgetTester tester) async {
    // Um `pump()` só, e não `pumpAndSettle()`: enquanto ninguém emite sessão
    // nenhuma, o estado fica "carregando" de propósito, e a tela mostra o
    // spinner de carregamento — que nunca se assenta.
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          theme: maeLightTheme,
          routerConfig: container.read(appRouterProvider),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('sem sessão, toda rota leva ao login', (tester) async {
    await pumpApp(tester);
    gateway.emitSession(null);
    await tester.pumpAndSettle();

    expect(find.text('Entrar'), findsWidgets);
  });

  testWidgets('sessão de merendeira leva à casa dela', (tester) async {
    gateway.profileForUser = (_) => const Profile(
      id: 'user-cook@escola.com',
      name: 'Merendeira',
      email: 'cook@escola.com',
      role: 'cook',
      schoolId: 'school-1',
    );

    await pumpApp(tester);
    gateway.emitSession(_session('user-cook@escola.com'));
    await tester.pumpAndSettle();

    // A visão do mês (issue #104) é a casa dela agora — "Gerar documento" é
    // o marco estável do rodapé, o mesmo que a web usa desde a issue #61
    // (`web/src/auth/auth.test.tsx`), porque o título muda com o mês.
    expect(find.text('Gerar documento'), findsOneWidget);

    // A visão do mês observa o banco local por um `Stream` do Drift
    // (decisão 6 da E6). Cancelar essa assinatura agenda um `Timer` de
    // duração zero — inofensivo de verdade, mas o binding de teste explode
    // se ele ainda estiver pendente quando o corpo do teste termina, e a
    // árvore só é desmontada depois disso. Desmontar aqui, dentro do teste,
    // dá a ele a chance de rodar antes dessa checagem.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
  });

  testWidgets('conta de direção não ganha tela: volta para o login com aviso', (
    tester,
  ) async {
    gateway.profileForUser = (_) => const Profile(
      id: 'user-admin@escola.com',
      name: 'Direção',
      email: 'admin@escola.com',
      role: 'admin',
      schoolId: 'school-1',
    );

    await pumpApp(tester);
    gateway.emitSession(_session('user-admin@escola.com'));
    await tester.pumpAndSettle();

    expect(find.text('Entrar'), findsWidgets);
    expect(find.textContaining('A administração fica na web'), findsOneWidget);
  });
}

Session _session(String userId) {
  return Session(
    accessToken: 'token-$userId',
    tokenType: 'bearer',
    user: User(
      id: userId,
      appMetadata: const {},
      userMetadata: const {},
      aud: 'authenticated',
      createdAt: DateTime.now().toIso8601String(),
    ),
  );
}
