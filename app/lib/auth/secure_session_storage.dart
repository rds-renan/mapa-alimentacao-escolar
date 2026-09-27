import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Onde a sessão fica guardada no aparelho (issue #101, decisão 9 da E6):
/// `flutter_secure_storage`, que no Android cifra o valor (AES-GCM, com a
/// chave protegida pelo Keystore) em vez de gravar num arquivo de
/// preferências comum — o mínimo para um aparelho que fica aberto na cozinha
/// de uma escola.
///
/// A chave é nossa (`mae.session`), e não a padrão da biblioteca, que deriva
/// do endereço do projeto Supabase: no dia em que o projeto mudasse de
/// endereço, a sessão de quem já tinha o aplicativo instalado sumiria em
/// silêncio. Mesma decisão que a web tomou para o `localStorage`
/// (`docs/05-web/autenticacao-e-sessao.md`).
class SecureSessionStorage extends LocalStorage {
  const SecureSessionStorage();

  static const _key = 'mae.session';
  static const _storage = FlutterSecureStorage(aOptions: AndroidOptions());

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() async => await _storage.read(key: _key) != null;

  @override
  Future<String?> accessToken() => _storage.read(key: _key);

  @override
  Future<void> removePersistedSession() => _storage.delete(key: _key);

  @override
  Future<void> persistSession(String persistSessionString) =>
      _storage.write(key: _key, value: persistSessionString);
}
