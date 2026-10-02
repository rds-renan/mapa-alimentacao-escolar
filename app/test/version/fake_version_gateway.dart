import 'package:mae/version/version_gateway.dart';

/// Um [VersionGateway] falso — o mesmo raciocínio dos outros portões falsos
/// (decisão 4 da E6). Por padrão o mínimo é 1, o do primeiro APK: os testes
/// que não falam de versão não esbarram na trava.
class FakeVersionGateway implements VersionGateway {
  FakeVersionGateway({this.minimum = 1});

  int minimum;

  /// Quando presente, a pergunta falha com ele — sem rede.
  Object? error;

  int calls = 0;

  @override
  Future<int> fetchMinimumBuild() async {
    calls++;
    final error = this.error;
    // ignore: only_throw_errors
    if (error != null) throw error;
    return minimum;
  }
}
