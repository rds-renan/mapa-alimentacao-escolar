import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mae/auth/app_auth_state.dart';
import 'package:mae/auth/auth_controller.dart';
import 'package:mae/auth/auth_messages.dart';
import 'package:mae/auth/profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'fake_auth_gateway.dart';

Profile _cook({String id = 'user-cook@escola.com'}) => Profile(
  id: id,
  name: 'Merendeira',
  email: 'cook@escola.com',
  role: 'cook',
  schoolId: 'school-1',
);

Profile _admin({String id = 'user-admin@escola.com'}) => Profile(
  id: id,
  name: 'Direção',
  email: 'admin@escola.com',
  role: 'admin',
  schoolId: 'school-1',
);

void main() {
  late FakeAuthGateway gateway;
  late ProviderContainer container;

  setUp(() {
    gateway = FakeAuthGateway();
    container = ProviderContainer(
      overrides: [authGatewayProvider.overrideWithValue(gateway)],
    );
    addTearDown(container.dispose);
    addTearDown(gateway.dispose);
  });

  AppAuthState state() => container.read(authControllerProvider);
  AuthController controller() =>
      container.read(authControllerProvider.notifier);

  test('sem sessão guardada, começa deslogada', () async {
    // Garante que o controlador nasceu e a inscrição já rodou.
    controller();
    gateway.emitSession(null);
    await Future<void>.delayed(Duration.zero);

    expect(state().loading, isFalse);
    expect(state().signedIn, isFalse);
  });

  test('perfil de merendeira: entra', () async {
    controller();
    gateway.profileForUser = (_) => _cook();
    gateway.emitSession(_fakeSessionFor('user-cook@escola.com'));
    await Future<void>.delayed(Duration.zero);

    expect(state().signedIn, isTrue);
    expect(state().profile?.role, 'cook');
    expect(gateway.touchLastAccessCalls, 1);
  });

  test('conta desativada (sem linha de perfil): encerra e explica', () async {
    controller();
    gateway.profileForUser = (_) => null;
    gateway.emitSession(_fakeSessionFor('user-cook@escola.com'));
    await Future<void>.delayed(Duration.zero);

    expect(state().signedIn, isFalse);
    expect(state().notice, AuthMessages.accessDisabled);
  });

  test('conta de direção: recusada, aponta para a web', () async {
    controller();
    gateway.profileForUser = (_) => _admin();
    gateway.emitSession(_fakeSessionFor('user-admin@escola.com'));
    await Future<void>.delayed(Duration.zero);

    expect(state().signedIn, isFalse);
    expect(state().notice, AuthMessages.adminNotSupported);
  });

  test('falha de rede ao ler o perfil: mantém a sessão', () async {
    controller();
    gateway.profileForUser = (_) => throw AuthRetryableFetchException();
    gateway.emitSession(_fakeSessionFor('user-cook@escola.com'));
    await Future<void>.delayed(Duration.zero);

    expect(state().profileUnavailable, isTrue);
    expect(state().session, isNotNull);
    expect(state().signedIn, isFalse);
  });

  test('login com credencial errada devolve a mensagem do catálogo', () async {
    gateway.signInError = const AuthApiException(
      'Invalid login credentials',
      statusCode: '400',
      code: 'invalid_credentials',
    );

    final error = await controller().signIn(
      email: 'cook@escola.com',
      password: 'errada',
    );

    expect(error, AuthMessages.invalidCredentials);
  });

  test('pedido de código de recuperação', () async {
    final error = await controller().requestRecoveryCode('cook@escola.com');

    expect(error, isNull);
    expect(gateway.lastRecoveryEmail, 'cook@escola.com');
  });

  test('código errado ou vencido devolve a mensagem do catálogo', () async {
    gateway.verifyRecoveryCodeError = const AuthApiException(
      'Token has expired or is invalid',
      statusCode: '403',
      code: 'otp_expired',
    );

    final error = await controller().confirmRecoveryCode(
      email: 'cook@escola.com',
      code: '000000',
      newPassword: 'senha-nova-boa',
    );

    expect(error, AuthMessages.codeInvalidOrExpired);
  });

  test('código certo troca a senha e derruba as outras sessões', () async {
    final error = await controller().confirmRecoveryCode(
      email: 'cook@escola.com',
      code: '123456',
      newPassword: 'senha-nova-boa',
    );

    expect(error, isNull);
    expect(gateway.lastNewPassword, 'senha-nova-boa');
    expect(gateway.signOutOtherSessionsCalls, 1);
  });

  test('sair encerra a sessão', () async {
    controller();
    gateway.profileForUser = (_) => _cook();
    gateway.emitSession(_fakeSessionFor('user-cook@escola.com'));
    await Future<void>.delayed(Duration.zero);
    expect(state().signedIn, isTrue);

    await controller().signOut();

    expect(state().signedIn, isFalse);
  });
}

Session _fakeSessionFor(String userId) {
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
