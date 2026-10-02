import 'package:ota_update/ota_update.dart';

import 'release_gateway.dart';

enum InstallStep {
  /// Baixando o arquivo; [InstallProgress.percent] diz quanto.
  downloading,

  /// O instalador do Android abriu: daqui em diante é com ela e com o
  /// aparelho.
  installing,

  /// Não deu para baixar.
  downloadFailed,

  /// O arquivo chegou diferente do publicado.
  corrupted,

  /// O Android não deixou o MAE instalar.
  notAllowed,
}

class InstallProgress {
  const InstallProgress(this.step, [this.percent]);

  final InstallStep step;
  final int? percent;
}

/// Quem baixa o APK e chama o instalador do Android, isolado para que a tela
/// seja testável sem aparelho.
abstract class AppInstaller {
  Stream<InstallProgress> install(AppRelease release);
}

/// O `ota_update`: baixa para a pasta interna do aplicativo, confere a
/// impressão digital e abre o instalador do próprio Android — sem navegador
/// (decisão 12 da E6). A primeira vez, o Android pede que ela permita ao MAE
/// instalar aplicativos; é o mesmo "Permitir desta fonte" da primeira
/// instalação pelo WhatsApp.
class OtaAppInstaller implements AppInstaller {
  @override
  Stream<InstallProgress> install(AppRelease release) {
    return OtaUpdate()
        .execute(
          release.apkUrl.toString(),
          destinationFilename: 'mae-${release.name}.apk',
          sha256checksum: release.sha256,
        )
        .map(
          (event) => switch (event.status) {
            OtaStatus.DOWNLOADING => InstallProgress(
              InstallStep.downloading,
              int.tryParse(event.value ?? ''),
            ),
            OtaStatus.INSTALLING ||
            OtaStatus.INSTALLATION_DONE ||
            OtaStatus.ALREADY_RUNNING_ERROR => const InstallProgress(
              InstallStep.installing,
            ),
            OtaStatus.CHECKSUM_ERROR => const InstallProgress(
              InstallStep.corrupted,
            ),
            OtaStatus.PERMISSION_NOT_GRANTED_ERROR ||
            OtaStatus.INSTALLATION_ERROR => const InstallProgress(
              InstallStep.notAllowed,
            ),
            OtaStatus.DOWNLOAD_ERROR ||
            OtaStatus.INTERNAL_ERROR ||
            OtaStatus.CANCELED => const InstallProgress(
              InstallStep.downloadFailed,
            ),
          },
        );
  }
}
