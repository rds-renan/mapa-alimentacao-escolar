import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../supabase.dart';
import 'app_installer.dart';
import 'app_updater.dart';
import 'release_gateway.dart';
import 'version_gate.dart';
import 'version_gateway.dart';

/// O versionCode deste APK e o último mínimo conhecido, lidos em `main`
/// ([loadAppBuild]). O padrão só existe para os testes que não falam de
/// versão: um aplicativo no mínimo, que nunca soube de mínimo nenhum.
final appBuildProvider = Provider<({int current, int? knownMinimum})>(
  (ref) => (current: 1, knownMinimum: null),
);

/// O portão para o Supabase, substituível por um falso nos testes (decisão 4
/// da E6).
final versionGatewayProvider = Provider<VersionGateway>((ref) {
  return SupabaseVersionGateway(supabase);
});

/// A trava (issue #113). Uma só para o aplicativo: a fila consulta e a
/// tela-casa mostra o mesmo objeto.
final versionGateProvider = Provider<VersionGate>((ref) {
  final build = ref.watch(appBuildProvider);
  final gate = VersionGate(
    currentBuild: build.current,
    knownMinimum: build.knownMinimum,
    gateway: ref.watch(versionGatewayProvider),
  );
  ref.onDispose(gate.dispose);
  return gate;
});

final releaseGatewayProvider = Provider<ReleaseGateway>((ref) {
  return GitHubReleaseGateway();
});

final appInstallerProvider = Provider<AppInstaller>((ref) {
  return OtaAppInstaller();
});

final appUpdaterProvider = Provider<AppUpdater>((ref) {
  final updater = AppUpdater(
    ref.watch(releaseGatewayProvider),
    ref.watch(appInstallerProvider),
  );
  ref.onDispose(updater.dispose);
  return updater;
});
