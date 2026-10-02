import 'package:flutter_test/flutter_test.dart';
import 'package:mae/version/app_installer.dart';
import 'package:mae/version/app_updater.dart';
import 'package:mae/version/messages.dart';

import 'fake_release.dart';

void main() {
  late FakeReleaseGateway releases;
  late FakeAppInstaller installer;
  late AppUpdater updater;

  setUp(() {
    releases = FakeReleaseGateway();
    installer = FakeAppInstaller();
    updater = AppUpdater(releases, installer);
  });

  tearDown(() async {
    updater.dispose();
    await installer.close();
  });

  test(
    'acha a release, baixa mostrando quanto e entrega ao instalador',
    () async {
      await updater.start();
      expect(installer.installed?.name, '0.2.0');

      installer.emit(const InstallProgress(InstallStep.downloading, 40));
      await pumpEventQueue();
      expect(updater.value.phase, UpdatePhase.downloading);
      expect(updater.value.message, 'Baixando… 40%');
      expect(updater.value.busy, isTrue);

      installer.emit(const InstallProgress(InstallStep.installing));
      await pumpEventQueue();
      expect(updater.value.phase, UpdatePhase.installing);
      expect(updater.value.busy, isFalse);
    },
  );

  test('sem achar a release, diz para conferir a internet', () async {
    releases.error = Exception('sem rede');

    await updater.start();

    expect(updater.value.phase, UpdatePhase.failed);
    expect(updater.value.message, updateDownloadFailed);
    expect(installer.installed, isNull);
  });

  test('arquivo com defeito e instalação negada têm frase própria', () async {
    await updater.start();

    installer.emit(const InstallProgress(InstallStep.corrupted));
    await pumpEventQueue();
    expect(updater.value.message, updateCorrupted);

    installer.emit(const InstallProgress(InstallStep.notAllowed));
    await pumpEventQueue();
    expect(updater.value.message, updateNotAllowed);
  });

  test('um segundo toque enquanto baixa não começa outra vez', () async {
    await updater.start();
    installer.emit(const InstallProgress(InstallStep.downloading, 10));
    await pumpEventQueue();

    await updater.start();

    expect(releases.calls, 1);
  });
}
