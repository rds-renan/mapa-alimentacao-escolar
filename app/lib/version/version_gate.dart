import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'version_gateway.dart';

/// Onde o último mínimo conhecido fica guardado. Um valor só para o
/// aparelho, não por perfil: a versão é do aplicativo instalado, não de quem
/// está nele.
const minimumBuildKey = 'mae.minimum_build';

/// O versionCode deste APK — o número depois do "+" no pubspec — e o último
/// mínimo que o aparelho conheceu. Lidos uma vez, em `main`, antes da
/// primeira tela, como a preferência de tema.
Future<({int current, int? knownMinimum})> loadAppBuild() async {
  final info = await PackageInfo.fromPlatform();

  int? knownMinimum;
  try {
    final prefs = await SharedPreferences.getInstance();
    knownMinimum = prefs.getInt(minimumBuildKey);
  } catch (_) {
    // Sem ler, o aparelho não sabe de mínimo nenhum e pergunta na abertura.
  }

  // Um APK sem número legível não saiu da Action; vale como o mais antigo
  // possível, e o banco o recusa.
  return (
    current: int.tryParse(info.buildNumber) ?? 0,
    knownMinimum: knownMinimum,
  );
}

/// A trava de versão mínima, do lado do aplicativo (decisão 12 da E6, issue
/// #113).
///
/// Confere ao abrir (a tela-casa chama [check]) e antes de cada envio da fila
/// ([SyncEngine]). Abaixo do mínimo, a fila para de enviar e a tela-casa
/// oferece a atualização — mas ela continua registrando: tudo fica guardado no
/// aparelho e sobe pelo aplicativo novo, que abre o mesmo banco local.
///
/// O último mínimo conhecido fica guardado no aparelho. É o que mantém a
/// trava sem rede: aberto em casa, à noite, o aplicativo já sabe que está
/// velho, e a faixa do dia diz a verdade ("depois que você atualizar"), não
/// "quando houver internet".
///
/// A conferência daqui é conveniência, não a trava: quem recusa de verdade é a
/// `save_meal_map`, pelo cabeçalho `x-mae-app-build`. Quando ela recusa,
/// [reportRejected] põe o aplicativo no mesmo estado.
class VersionGate extends ChangeNotifier {
  VersionGate({
    required this.currentBuild,
    required this._gateway,
    int? knownMinimum,
  }) : _minimum = knownMinimum;

  final int currentBuild;
  final VersionGateway _gateway;

  int? _minimum;
  int? get minimumBuild => _minimum;

  bool get outdated => _minimum != null && currentBuild < _minimum!;

  Future<bool>? _checking;

  /// Pergunta ao banco e devolve se este aplicativo está abaixo do mínimo.
  /// Sem resposta, vale o último mínimo conhecido — e sem nenhum, o
  /// aplicativo segue: a recusa do banco continua de guarda.
  Future<bool> check() =>
      _checking ??= _check().whenComplete(() => _checking = null);

  Future<bool> _check() async {
    try {
      _remember(await _gateway.fetchMinimumBuild());
    } catch (_) {
      // Ver acima.
    }
    return outdated;
  }

  /// O banco recusou pelo cabeçalho. O mínimo exato vem na pergunta seguinte;
  /// até lá, basta saber que é maior do que este aplicativo.
  void reportRejected() {
    if (!outdated) _remember(currentBuild + 1);
    unawaited(check());
  }

  void _remember(int minimum) {
    if (minimum == _minimum) return;
    _minimum = minimum;
    notifyListeners();
    unawaited(_store(minimum));
  }

  Future<void> _store(int minimum) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(minimumBuildKey, minimum);
    } catch (_) {
      // Sem gravar, vale o que está na memória até fechar o aplicativo.
    }
  }
}
