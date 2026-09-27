import 'dart:async';

import 'package:mae/auth/auth_gateway.dart';
import 'package:mae/auth/profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Um [AuthGateway] falso, sem servidor nenhum — o que a decisão 4 da E6
/// promete para o `AuthController` ser testável.
class FakeAuthGateway implements AuthGateway {
  final _controller = StreamController<AuthState>.broadcast();

  Session? _session;
  Profile? Function(String userId)? profileForUser;
  Object? signInError;
  Object? requestRecoveryCodeError;
  Object? verifyRecoveryCodeError;
  Object? updatePasswordError;

  int touchLastAccessCalls = 0;
  int signOutOtherSessionsCalls = 0;
  String? lastRecoveryEmail;
  String? lastVerifiedCode;
  String? lastNewPassword;

  @override
  Stream<AuthState> get onAuthStateChange => _controller.stream;

  @override
  Session? get currentSession => _session;

  /// Empurra um evento de sessão, como o `gotrue` faria ao autenticar, sair
  /// ou trocar a senha.
  void emitSession(Session? session) {
    _session = session;
    _controller.add(
      AuthState(
        session == null ? AuthChangeEvent.signedOut : AuthChangeEvent.signedIn,
        session,
      ),
    );
  }

  @override
  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    if (signInError != null) throw signInError!;
    emitSession(_fakeSession('user-$email'));
  }

  @override
  Future<void> signOut() async {
    emitSession(null);
  }

  @override
  Future<Profile?> fetchProfile(String userId) async {
    return profileForUser?.call(userId);
  }

  @override
  Future<void> touchLastAccess() async {
    touchLastAccessCalls++;
  }

  @override
  Future<void> requestRecoveryCode(String email) async {
    lastRecoveryEmail = email;
    if (requestRecoveryCodeError != null) throw requestRecoveryCodeError!;
  }

  @override
  Future<void> verifyRecoveryCode({
    required String email,
    required String code,
  }) async {
    lastVerifiedCode = code;
    if (verifyRecoveryCodeError != null) throw verifyRecoveryCodeError!;
    emitSession(_fakeSession('user-$email'));
  }

  @override
  Future<void> updatePassword(String password) async {
    lastNewPassword = password;
    if (updatePasswordError != null) throw updatePasswordError!;
  }

  @override
  Future<void> signOutOtherSessions() async {
    signOutOtherSessionsCalls++;
  }

  void dispose() => _controller.close();
}

Session _fakeSession(String userId) {
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
