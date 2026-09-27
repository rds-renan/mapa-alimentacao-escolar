import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mae/auth/auth_controller.dart';
import 'package:mae/auth/profile.dart';
import 'package:mae/routing/app_router.dart';
import 'package:mae/theme/theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/fake_auth_gateway.dart';

void main() {
  late FakeAuthGateway gateway;
  late ProviderContainer container;

  setUp(() {
    gateway = FakeAuthGateway();
    container = ProviderContainer(
      overrides: [authGatewayProvider.overrideWithValue(gateway)],
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

    expect(find.text('Olá, Merendeira'), findsOneWidget);
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
