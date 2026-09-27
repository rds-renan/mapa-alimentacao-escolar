import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mae/auth/auth_controller.dart';
import 'package:mae/auth/auth_messages.dart';
import 'package:mae/pages/sign_in_page.dart';
import 'package:mae/theme/theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/fake_auth_gateway.dart';

void main() {
  late FakeAuthGateway gateway;

  setUp(() => gateway = FakeAuthGateway());
  tearDown(() => gateway.dispose());

  Future<void> pumpSignIn(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authGatewayProvider.overrideWithValue(gateway)],
        child: MaterialApp(theme: maeLightTheme, home: const SignInPage()),
      ),
    );
    await tester.pump();
  }

  testWidgets(
    'e-mail em formato inválido barra o envio sem chamar o servidor',
    (tester) async {
      await pumpSignIn(tester);

      await tester.enterText(find.byType(TextField).first, 'nao-e-email');
      await tester.tap(find.text('Entrar'));
      await tester.pump();

      expect(find.text(AuthMessages.emailInvalid), findsOneWidget);
    },
  );

  testWidgets('credencial errada mostra a mensagem que não aponta o campo', (
    tester,
  ) async {
    gateway.signInError = const AuthApiException(
      'Invalid login credentials',
      statusCode: '400',
      code: 'invalid_credentials',
    );
    await pumpSignIn(tester);

    await tester.enterText(find.byType(TextField).first, 'cook@escola.com');
    await tester.enterText(find.byType(TextField).last, 'errada');
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    expect(find.text(AuthMessages.invalidCredentials), findsOneWidget);
  });
}
