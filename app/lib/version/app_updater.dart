import 'dart:async';

import 'package:flutter/foundation.dart';

import 'app_installer.dart';
import 'messages.dart';
import 'release_gateway.dart';

enum UpdatePhase { idle, searching, downloading, installing, failed }

@immutable
class UpdateState {
  const UpdateState(this.phase, {this.percent, this.message});

  static const idle = UpdateState(UpdatePhase.idle);

  final UpdatePhase phase;
  final int? percent;

  /// O que dizer a ela, quando há o que dizer.
  final String? message;

  /// Enquanto procura ou baixa, um segundo toque só atrapalharia.
  bool get busy =>
      phase == UpdatePhase.searching || phase == UpdatePhase.downloading;
}

/// A atualização pedida pela tela-casa: acha a release mais recente e entrega
/// o arquivo ao instalador do Android (decisão 12 da E6). O aplicativo é
/// substituído pelo instalador e reabre na versão nova; nada do aparelho é
/// tocado aqui.
class AppUpdater extends ValueNotifier<UpdateState> {
  AppUpdater(this._releases, this._installer) : super(UpdateState.idle);

  final ReleaseGateway _releases;
  final AppInstaller _installer;

  StreamSubscription<InstallProgress>? _subscription;

  Future<void> start() async {
    if (value.busy) return;
    value = const UpdateState(UpdatePhase.searching, message: updateSearching);

    final AppRelease release;
    try {
      release = await _releases.latest();
    } catch (_) {
      value = const UpdateState(
        UpdatePhase.failed,
        message: updateDownloadFailed,
      );
      return;
    }

    await _subscription?.cancel();
    _subscription = _installer
        .install(release)
        .listen(
          _onProgress,
          onError: (Object _) => value = const UpdateState(
            UpdatePhase.failed,
            message: updateDownloadFailed,
          ),
        );
  }

  void _onProgress(InstallProgress progress) {
    value = switch (progress.step) {
      InstallStep.downloading => UpdateState(
        UpdatePhase.downloading,
        percent: progress.percent,
        message: updateDownloading(progress.percent),
      ),
      InstallStep.installing => const UpdateState(
        UpdatePhase.installing,
        message: updateInstalling,
      ),
      InstallStep.downloadFailed => const UpdateState(
        UpdatePhase.failed,
        message: updateDownloadFailed,
      ),
      InstallStep.corrupted => const UpdateState(
        UpdatePhase.failed,
        message: updateCorrupted,
      ),
      InstallStep.notAllowed => const UpdateState(
        UpdatePhase.failed,
        message: updateNotAllowed,
      ),
    };
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}
