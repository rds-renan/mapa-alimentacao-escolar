import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mae/auth/auth_controller.dart';
import 'package:mae/auth/auth_messages.dart';
import 'package:mae/pages/forgot_password_page.dart';
import 'package:mae/theme/theme.dart';

import '../auth/fake_auth_gateway.dart';

void main() {
  late FakeAuthGateway gateway;

  setUp(() => gateway = FakeAuthGateway());
  tearDown(() => gateway.dispose());

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authGatewayProvider.overrideWithValue(gateway)],
        child: MaterialApp(
          theme: maeLightTheme,
          home: const ForgotPasswordPage(),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets(
    'pede o código e, na mesma tela, mostra os campos de código e senha',
    (tester) async {
      await pumpPage(tester);

      await tester.enterText(find.byType(TextField).first, 'cook@escola.com');
      await tester.tap(find.text('Enviar o código'));
      await tester.pumpAndSettle();

      expect(gateway.lastRecoveryEmail, 'cook@escola.com');
      expect(find.text('Código de 6 dígitos'), findsOneWidget);
      expect(find.text('Trocar a senha'), findsOneWidget);
    },
  );

  testWidgets('as duas senhas precisam ser iguais', (tester) async {
    await pumpPage(tester);

    await tester.enterText(find.byType(TextField).first, 'cook@escola.com');
    await tester.tap(find.text('Enviar o código'));
    await tester.pumpAndSettle();

    final textFields = find.byType(TextField);
    await tester.enterText(textFields.at(1), '123456');
    await tester.enterText(textFields.at(2), 'senha-nova-boa');
    await tester.enterText(textFields.at(3), 'outra-coisa');
    await tester.tap(find.text('Trocar a senha'));
    await tester.pump();

    expect(find.text(AuthMessages.passwordMismatch), findsOneWidget);
  });
}
