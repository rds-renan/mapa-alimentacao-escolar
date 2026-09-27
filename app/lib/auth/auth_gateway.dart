import 'package:supabase_flutter/supabase_flutter.dart' show AuthState, Session;

import 'profile.dart';

/// O que a autenticação precisa do Supabase, isolado atrás de uma interface.
/// É o que torna o [AuthController] testável sem falar com um servidor de
/// verdade — o mesmo raciocínio da decisão 4 da E6 sobre os provedores serem
/// substituíveis por um falso nos testes.
///
/// [AuthState] aqui é o tipo do `gotrue`, o evento de mudança de sessão — não
/// confundir com o estado próprio do aplicativo (`AppAuthState`).
abstract class AuthGateway {
  /// Emite a cada mudança de sessão, e também a que já estava guardada no
  /// aparelho, logo na inscrição — é isso que faz a sessão sobreviver ao
  /// fechar do aplicativo (RNF#2 da US016).
  Stream<AuthState> get onAuthStateChange;

  Session? get currentSession;

  Future<void> signInWithPassword({
    required String email,
    required String password,
  });

  Future<void> signOut();

  /// `null` quando a linha não aparece: o acesso foi desativado e a política
  /// de RLS deixou de enxergá-la (CA#2 da US016).
  Future<Profile?> fetchProfile(String userId);

  /// `touch_last_access()`, a cada abertura do aplicativo — RPC no aparelho
  /// aberto pela merendeira, não no login em si (issue #68 na web).
  Future<void> touchLastAccess();

  /// Pede o código de 6 dígitos por e-mail. A mesma chamada serve o convite
  /// da direção (decisão 9 da E6).
  Future<void> requestRecoveryCode(String email);

  /// Troca o código pela sessão de recuperação.
  Future<void> verifyRecoveryCode({
    required String email,
    required String code,
  });

  Future<void> updatePassword(String password);

  /// Derruba as outras sessões depois da troca de senha — a desta continua.
  Future<void> signOutOtherSessions();
}
