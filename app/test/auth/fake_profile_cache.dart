import 'package:mae/auth/profile.dart';
import 'package:mae/auth/profile_cache.dart';

/// Um [ProfileCache] em memória — sem o cofre do Android, que nos testes não
/// existe.
class FakeProfileCache implements ProfileCache {
  final profiles = <String, Profile>{};

  @override
  Future<Profile?> read(String userId) async => profiles[userId];

  @override
  Future<void> write(Profile profile) async => profiles[profile.id] = profile;

  @override
  Future<void> clear(String userId) async => profiles.remove(userId);
}
