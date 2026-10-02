import 'dart:convert';
import 'dart:io';

/// A versão publicada mais recente, como o aplicativo precisa dela para se
/// atualizar.
class AppRelease {
  const AppRelease({required this.name, required this.apkUrl, this.sha256});

  /// O nome da versão, sem o prefixo da tag: `0.2.0`.
  final String name;

  final Uri apkUrl;

  /// A impressão digital do arquivo, quando o GitHub a informa. Com ela, o
  /// arquivo que chegou com defeito é recusado antes de chegar ao instalador.
  final String? sha256;
}

/// De onde vem a versão nova (decisão 11 da E6: GitHub Releases, sem loja).
abstract class ReleaseGateway {
  /// Lança quando não deu para perguntar ou a resposta não traz um APK.
  Future<AppRelease> latest();
}

/// A release mais recente do repositório, pela API do GitHub. `latest` deixa
/// de fora as pré-releases — as tags de ensaio, com hífen —, então nenhuma
/// delas chega a um aparelho por aqui (docs/06-app/release-e-distribuicao.md).
///
/// O repositório é público: a pergunta não leva credencial, e o limite de
/// sessenta por hora por endereço é muito mais do que uma merendeira tocando
/// em "Atualizar" consome.
class GitHubReleaseGateway implements ReleaseGateway {
  GitHubReleaseGateway({HttpClient Function()? client})
    : _client = client ?? HttpClient.new;

  static final latestUrl = Uri.parse(
    'https://api.github.com/repos/rds-renan/mapa-alimentacao-escolar/releases/latest',
  );

  final HttpClient Function() _client;

  @override
  Future<AppRelease> latest() async {
    final client = _client()..connectionTimeout = const Duration(seconds: 15);
    try {
      final request = await client.getUrl(latestUrl);
      request.headers
        ..set(HttpHeaders.acceptHeader, 'application/vnd.github+json')
        ..set(HttpHeaders.userAgentHeader, 'mae-app');
      final response = await request.close().timeout(
        const Duration(seconds: 30),
      );
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode != HttpStatus.ok) {
        throw HttpException('GitHub respondeu ${response.statusCode}');
      }

      return parseRelease(jsonDecode(body) as Map<String, dynamic>);
    } finally {
      client.close();
    }
  }
}

/// A resposta de `/releases/latest` reduzida ao que importa: o primeiro `.apk`
/// anexado. A Action anexa um só (`mae-<versão>.apk`).
AppRelease parseRelease(Map<String, dynamic> json) {
  final tag = json['tag_name'] as String? ?? '';
  final assets = (json['assets'] as List<dynamic>? ?? const [])
      .cast<Map<String, dynamic>>();

  final apk = assets.where(
    (asset) => (asset['name'] as String? ?? '').endsWith('.apk'),
  );
  if (apk.isEmpty) {
    throw const FormatException('A release mais recente não tem APK anexado.');
  }

  final digest = apk.first['digest'] as String?;

  return AppRelease(
    name: tag.startsWith('app-v') ? tag.substring('app-v'.length) : tag,
    apkUrl: Uri.parse(apk.first['browser_download_url'] as String),
    sha256: digest != null && digest.startsWith('sha256:')
        ? digest.substring('sha256:'.length)
        : null,
  );
}
