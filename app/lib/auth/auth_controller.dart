import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthException, AuthState;

import '../supabase.dart';
import 'app_auth_state.dart';
import 'auth_error_mapping.dart';
import 'auth_gateway.dart';
import 'auth_messages.dart';
import 'supabase_auth_gateway.dart';

/// O portão para o Supabase, substituível por um falso nos testes (decisão 4
/// da E6) — é o que torna o [AuthController] testável sem servidor.
final authGatewayProvider = Provider<AuthGateway>((ref) {
  return SupabaseAuthGateway(supabase);
});

final authControllerProvider = NotifierProvider<AuthController, AppAuthState>(
  AuthController.new,
);

/// A sessão e o perfil de quem está usando o aplicativo — a versão em Dart do
/// `AuthProvider` da web (`web/src/auth/auth-provider.tsx`). O que está aqui
/// é conveniência de interface: quem decide o que a merendeira lê e escreve
/// são as políticas de RLS da E4 (decisão 5 da E6).
class AuthController extends Notifier<AppAuthState> {
  StreamSubscription<AuthState>? _subscription;

  AuthGateway get _gateway => ref.read(authGatewayProvider);

  @override
  AppAuthState build() {
    final gateway = ref.watch(authGatewayProvider);
    _subscription = gateway.onAuthStateChange.listen(_handleAuthChange);
    ref.onDispose(() {
      unawaited(_subscription?.cancel());
    });
    return const AppAuthState();
  }

  void _handleAuthChange(AuthState data) {
    final session = data.session;

    if (session == null) {
      state = state.copyWith(
        clearSession: true,
        clearProfile: true,
        profileUnavailable: false,
        loading: false,
      );
      return;
    }

    state = state.copyWith(session: session);
    unawaited(_loadProfile(session.user.id));
  }

  Future<void> _loadProfile(String userId) async {
    state = state.copyWith(loading: true, profileUnavailable: false);

    try {
      final profile = await _gateway.fetchProfile(userId);

      // A sessão pode ter trocado enquanto esta chamada esperava resposta.
      if (state.session?.user.id != userId) return;

      if (profile == null) {
        /*
         * A linha não aparece: o acesso foi desativado pela direção (CA#2 da
         * US016) e a política de RLS deixou de enxergá-la. Não há aplicativo
         * nenhum para mostrar — a sessão é encerrada e o login explica.
         */
        await _forceSignOut(AuthMessages.accessDisabled);
        return;
      }

      if (!profile.isCook) {
        // O aplicativo é só da merendeira (decisão 1 da E6).
        await _forceSignOut(AuthMessages.adminNotSupported);
        return;
      }

      state = state.copyWith(profile: profile, loading: false);

      // Carimbo, não passo do caminho — não se espera por ele.
      unawaited(_gateway.touchLastAccess());
    } catch (_) {
      if (state.session?.user.id != userId) return;

      /*
       * A leitura falhou — quase sempre falta de rede. A sessão é mantida de
       * propósito: deslogar quem está sem sinal numa escola sem sinal de
       * operadora seria transformar instabilidade de rede em perda de
       * acesso.
       */
      state = state.copyWith(profileUnavailable: true, loading: false);
    }
  }

  Future<void> _forceSignOut(String notice) async {
    await _gateway.signOut();
    state = state.copyWith(
      notice: notice,
      clearSession: true,
      clearProfile: true,
      loading: false,
    );
  }

  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(clearNotice: true);

    try {
      await _gateway.signInWithPassword(email: email, password: password);
      return null;
    } on AuthException catch (error) {
      return messageForSignIn(error);
    }
  }

  Future<void> signOut() async {
    /*
     * Sair encerra a sessão. Sair NÃO apaga o que está esperando envio
     * (decisão da issue #60 na web) — o aplicativo ainda não tem fila local
     * (issues #102 e #103), então não há nada aqui para apagar, e é assim
     * que deve continuar: nenhuma limpeza de dado entra neste método.
     */
    await _gateway.signOut();
    state = state.copyWith(clearNotice: true);
  }

  /// Tenta ler o perfil de novo depois de uma falha de rede.
  void retryProfile() {
    final userId = state.session?.user.id;
    if (userId != null) unawaited(_loadProfile(userId));
  }

  /// "Esqueci minha senha", primeiro passo: só o e-mail. A resposta é a
  /// mesma para e-mail conhecido e desconhecido — dizer que ele não tem
  /// acesso entregaria quem tem.
  Future<String?> requestRecoveryCode(String email) async {
    try {
      await _gateway.requestRecoveryCode(email);
      return null;
    } on AuthException catch (error) {
      return messageForRecoveryRequest(error);
    }
  }

  /// Segundo passo, na mesma tela: o código de 6 dígitos e a senha nova.
  /// Trocada a senha, as outras sessões caem — a desta fica, e vira a sessão
  /// normal do aplicativo (o mesmo caminho de `_handleAuthChange` decide se
  /// o perfil pode continuar).
  Future<String?> confirmRecoveryCode({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      await _gateway.verifyRecoveryCode(email: email, code: code);
    } on AuthException catch (error) {
      return messageForVerifyCode(error);
    }

    try {
      await _gateway.updatePassword(newPassword);
    } on AuthException catch (error) {
      return messageForUpdatePassword(error);
    }

    unawaited(_gateway.signOutOtherSessions());
    return null;
  }
}
