import 'dart:async';

import 'package:mae/version/app_installer.dart';
import 'package:mae/version/release_gateway.dart';

class FakeReleaseGateway implements ReleaseGateway {
  Object? error;
  int calls = 0;

  @override
  Future<AppRelease> latest() async {
    calls++;
    final error = this.error;
    // ignore: only_throw_errors
    if (error != null) throw error;
    return AppRelease(
      name: '0.2.0',
      apkUrl: Uri.parse('https://example.com/mae-0.2.0.apk'),
    );
  }
}

/// O instalador falso: a tela recebe o andamento que o teste mandar.
class FakeAppInstaller implements AppInstaller {
  final _progress = StreamController<InstallProgress>.broadcast();
  AppRelease? installed;

  void emit(InstallProgress progress) => _progress.add(progress);

  Future<void> close() => _progress.close();

  @override
  Stream<InstallProgress> install(AppRelease release) {
    installed = release;
    return _progress.stream;
  }
}
