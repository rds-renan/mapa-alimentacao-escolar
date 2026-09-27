import 'package:connectivity_plus/connectivity_plus.dart';

/// O que a fila precisa saber sobre a rede do aparelho, isolado atrás de uma
/// interface — o mesmo raciocínio do [SyncGateway] e do `AuthGateway`
/// (decisão 4 da E6): torna o [SyncEngine] testável sem depender do canal de
/// plataforma que o `connectivity_plus` usa.
abstract class ConnectivityGateway {
  /// A rede está disponível agora? É a pergunta que evita a tentativa que já
  /// se sabe perdida — falha do mesmo jeito, e a faixa diria "ainda não deu
  /// para enviar" quando a frase certa é "salvo no aparelho".
  Future<bool> isOnline();

  /// Dispara sempre que a conectividade muda. A fila escuta para reenviar
  /// sozinha assim que a rede volta (CA#1 da US011) — sem que a merendeira
  /// precise reabrir o aplicativo ou pedir de novo.
  Stream<bool> get onChange;
}

/// A implementação de verdade, sobre `connectivity_plus` — a resposta que a
/// decisão 8 da E6 deixou em aberto para esta issue: um pacote soube dizer
/// "a rede voltou" sem que a fila precisasse ficar tentando às cegas.
class ConnectivityPlusGateway implements ConnectivityGateway {
  ConnectivityPlusGateway([Connectivity? connectivity])
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  @override
  Future<bool> isOnline() async {
    return _hasConnection(await _connectivity.checkConnectivity());
  }

  @override
  Stream<bool> get onChange =>
      _connectivity.onConnectivityChanged.map(_hasConnection);

  bool _hasConnection(List<ConnectivityResult> results) =>
      results.any((result) => result != ConnectivityResult.none);
}
