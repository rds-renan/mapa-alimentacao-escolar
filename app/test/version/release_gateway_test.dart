import 'package:flutter_test/flutter_test.dart';
import 'package:mae/version/release_gateway.dart';

/// A forma de `/releases/latest` da API do GitHub, reduzida ao que o
/// aplicativo lê.
Map<String, dynamic> _release({List<Map<String, dynamic>>? assets}) => {
  'tag_name': 'app-v0.2.0',
  'prerelease': false,
  'assets':
      assets ??
      [
        {
          'name': 'mae-0.2.0.apk',
          'browser_download_url': 'https://github.com/rds-renan/mapa-alimentacao-escolar/releases/download/app-v0.2.0/mae-0.2.0.apk',
          'digest': 'sha256:a7712f3027eb2e8023ba1c04401343c5e92907ee2515198bc7d767a33a136a2f',
        },
      ],
};

void main() {
  test('acha o APK, o nome da versão e a impressão digital', () {
    final release = parseRelease(_release());

    expect(release.name, '0.2.0');
    expect(release.apkUrl.path, endsWith('/mae-0.2.0.apk'));
    expect(
      release.sha256,
      'a7712f3027eb2e8023ba1c04401343c5e92907ee2515198bc7d767a33a136a2f',
    );
  });

  test('sem impressão digital, baixa mesmo assim', () {
    final release = parseRelease(
      _release(
        assets: [
          {
            'name': 'mae-0.2.0.apk',
            'browser_download_url': 'https://example.com/mae-0.2.0.apk',
            'digest': null,
          },
        ],
      ),
    );

    expect(release.sha256, isNull);
  });

  test('ignora o que não é APK', () {
    final release = parseRelease(
      _release(
        assets: [
          {
            'name': 'notas.txt',
            'browser_download_url': 'https://example.com/notas.txt',
          },
          {
            'name': 'mae-0.2.0.apk',
            'browser_download_url': 'https://example.com/mae-0.2.0.apk',
          },
        ],
      ),
    );

    expect(release.apkUrl.toString(), 'https://example.com/mae-0.2.0.apk');
  });

  test('release sem APK não é atualização', () {
    expect(
      () => parseRelease(_release(assets: [])),
      throwsA(isA<FormatException>()),
    );
  });
}
