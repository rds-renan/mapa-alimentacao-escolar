import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'profile.dart';

/// O perfil da última leitura bem-sucedida, guardado no aparelho, um por
/// usuária (issue #164).
///
/// A sessão já sobrevivia ao fechar do aplicativo (`SecureSessionStorage`),
/// mas o perfil só vinha da rede, a cada abertura — e sem perfil não há
/// mês. Quem abria o MAE de manhã, na cozinha, sem sinal, caía no login com
/// a sessão guardada o tempo todo. É este perfil que vale enquanto a rede
/// não responde; com rede, o `AuthController` relê o de verdade e é ele que
/// decide se a conta continua (CA#2 da US016).
///
/// Mesmo cofre da sessão, e não `shared_preferences`: nome e e-mail são dado
/// pessoal, e o aparelho fica aberto na cozinha da escola.
abstract class ProfileCache {
  Future<Profile?> read(String userId);

  Future<void> write(Profile profile);

  Future<void> clear(String userId);
}

class SecureProfileCache implements ProfileCache {
  const SecureProfileCache();

  static const _storage = FlutterSecureStorage(aOptions: AndroidOptions());

  static String _key(String userId) => 'mae.profile.$userId';

  /// Lixo ou falha de leitura valem "nada guardado": o pior caso é o de antes
  /// desta issue — o aviso de acesso no lugar do mês —, nunca o aplicativo
  /// fora do ar.
  @override
  Future<Profile?> read(String userId) async {
    try {
      final stored = await _storage.read(key: _key(userId));
      if (stored == null) return null;

      final profile = Profile.fromRow(
        jsonDecode(stored) as Map<String, dynamic>,
      );
      return profile.id == userId ? profile : null;
    } catch (_) {
      return null;
    }
  }

  /// Sem gravar, vale a memória até fechar o aplicativo.
  @override
  Future<void> write(Profile profile) async {
    try {
      await _storage.write(
        key: _key(profile.id),
        value: jsonEncode(profile.toRow()),
      );
    } catch (_) {
      // Ver acima.
    }
  }

  @override
  Future<void> clear(String userId) async {
    try {
      await _storage.delete(key: _key(userId));
    } catch (_) {
      // Sem apagar, o que sobra é um perfil que só serve à mesma sessão — e
      // ela acabou de ser encerrada.
    }
  }
}
