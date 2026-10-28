import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mae/auth/auth_controller.dart';
import 'package:mae/auth/auth_messages.dart';
import 'package:mae/local/local_providers.dart';
import 'package:mae/pages/forgot_password_page.dart';
import 'package:mae/theme/theme.dart';

import '../auth/fake_auth_gateway.dart';
import '../auth/fake_profile_cache.dart';
import '../local/fake_connectivity_gateway.dart';

void main() {
  late FakeAuthGateway gateway;

  setUp(() => gateway = FakeAuthGateway());
  tearDown(() => gateway.dispose());

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authGatewayProvider.overrideWithValue(gateway),
          profileCacheProvider.overrideWithValue(FakeProfileCache()),
          connectivityGatewayProvider.overrideWithValue(
            FakeConnectivityGateway(),
          ),
        ],
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

  testWidgets(
    'com o código já na mão, vai direto aos campos sem pedir outro código',
    (tester) async {
      await pumpPage(tester);

      await tester.enterText(find.byType(TextField).first, 'cook@escola.com');
      await tester.tap(find.text('Já tenho um código'));
      await tester.pumpAndSettle();

      // Pedir de novo mandaria outro código e invalidaria o do e-mail.
      expect(gateway.lastRecoveryEmail, isNull);
      expect(find.text('Código de 6 dígitos'), findsOneWidget);
      expect(find.text(AuthMessages.codeSent), findsNothing);

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(1), '123456');
      await tester.enterText(textFields.at(2), 'senha-nova-boa');
      await tester.enterText(textFields.at(3), 'senha-nova-boa');
      await tester.tap(find.text('Trocar a senha'));
      await tester.pumpAndSettle();

      expect(gateway.lastVerifiedCode, '123456');
      expect(gateway.lastNewPassword, 'senha-nova-boa');
    },
  );

  testWidgets('"Já tenho um código" também confere o e-mail', (tester) async {
    await pumpPage(tester);

    await tester.enterText(find.byType(TextField).first, 'cook');
    await tester.tap(find.text('Já tenho um código'));
    await tester.pump();

    expect(find.text(AuthMessages.emailInvalid), findsOneWidget);
    expect(find.text('Código de 6 dígitos'), findsNothing);
  });

  testWidgets('do código antigo, dá para voltar e pedir um novo', (
    tester,
  ) async {
    await pumpPage(tester);

    await tester.enterText(find.byType(TextField).first, 'cook@escola.com');
    await tester.tap(find.text('Já tenho um código'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pedir um código novo'));
    await tester.pumpAndSettle();

    expect(find.text('Enviar o código'), findsOneWidget);
    expect(find.text('Código de 6 dígitos'), findsNothing);
  });
}
