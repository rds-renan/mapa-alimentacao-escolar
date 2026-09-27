import 'package:meta/meta.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Session;

import 'profile.dart';

/// O estado da autenticação, num lugar só — a versão em Dart do
/// `AuthContextValue` da web (`web/src/auth/auth-context.ts`).
///
/// `notice` é independente de `session`/`profile` de propósito: quando a
/// conta é desativada ou é de direção, o controlador encerra a sessão e
/// escreve o aviso no mesmo instante — e o evento de sessão nula que o
/// próprio `signOut()` dispara em seguida **não pode apagar esse aviso**. É a
/// mesma armadilha que a web evitou guardando o aviso fora do que o
/// `onAuthStateChange` toca.
@immutable
class AppAuthState {
  const AppAuthState({
    this.loading = true,
    this.session,
    this.profile,
    this.profileUnavailable = false,
    this.notice,
  });

  final bool loading;
  final Session? session;
  final Profile? profile;

  /// A leitura do perfil falhou (quase sempre falta de rede). A sessão
  /// **não** é encerrada aqui — é o caso oposto do CA#2 da US016, e os dois
  /// não podem ser confundidos.
  final bool profileUnavailable;

  final String? notice;

  bool get signedIn => session != null && profile != null;

  AppAuthState copyWith({
    bool? loading,
    Session? session,
    bool clearSession = false,
    Profile? profile,
    bool clearProfile = false,
    bool? profileUnavailable,
    String? notice,
    bool clearNotice = false,
  }) {
    return AppAuthState(
      loading: loading ?? this.loading,
      session: clearSession ? null : (session ?? this.session),
      profile: clearProfile ? null : (profile ?? this.profile),
      profileUnavailable: profileUnavailable ?? this.profileUnavailable,
      notice: clearNotice ? null : (notice ?? this.notice),
    );
  }
}
