import 'package:supabase_flutter/supabase_flutter.dart';

import '../env.dart';
import 'auth_gateway.dart';
import 'profile.dart';

/// Para onde o link do e-mail de senha nova aponta, quando é o aplicativo
/// quem pede o código (issue #101). A merendeira nunca abre esse link — o
/// dela é o código —, mas o e-mail é o mesmo que a web dispara, e o link
/// precisa continuar levando a algum lugar que funcione: a tela de senha
/// nova da própria web (`web/src/routes.ts`, `ROUTES.newPassword`).
const _webRecoveryPath = '/nova-senha';

/// A implementação de verdade do [AuthGateway], sobre `supabase_flutter`.
class SupabaseAuthGateway implements AuthGateway {
  SupabaseAuthGateway(this._client);

  final SupabaseClient _client;

  @override
  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;

  @override
  Session? get currentSession => _client.auth.currentSession;

  @override
  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) {
    return _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  @override
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } on AuthException {
      /*
       * Se a revogação no servidor não for possível — sem rede, que é o
       * comum aqui —, a sessão sai do aparelho do mesmo jeito: ficar presa
       * dentro do aplicativo por falta de internet seria o pior desfecho
       * (mesma decisão da web na issue #59).
       */
      await _client.auth.signOut(scope: SignOutScope.local);
    }
  }

  @override
  Future<Profile?> fetchProfile(String userId) async {
    final row = await _client
        .from('profile')
        .select('id, name, email, role, school_id')
        .eq('id', userId)
        .maybeSingle();

    return row == null ? null : Profile.fromRow(row);
  }

  @override
  Future<void> touchLastAccess() async {
    try {
      await _client.rpc('touch_last_access');
    } catch (_) {
      // Carimbo, não passo do caminho: se a rede não estiver lá, o
      // aplicativo abre igual (mesmo raciocínio da web na issue #68).
    }
  }

  @override
  Future<void> requestRecoveryCode(String email) {
    return _client.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: '${Env.webUrl}$_webRecoveryPath',
    );
  }

  @override
  Future<void> verifyRecoveryCode({
    required String email,
    required String code,
  }) async {
    await _client.auth.verifyOTP(
      email: email.trim(),
      token: code.trim(),
      type: OtpType.recovery,
    );
  }

  @override
  Future<void> updatePassword(String password) async {
    await _client.auth.updateUser(UserAttributes(password: password));
  }

  @override
  Future<void> signOutOtherSessions() {
    return _client.auth.signOut(scope: SignOutScope.others);
  }
}
