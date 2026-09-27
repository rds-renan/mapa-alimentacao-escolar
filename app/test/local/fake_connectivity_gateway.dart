import 'dart:async';

import 'package:mae/local/connectivity_gateway.dart';

/// Um [ConnectivityGateway] falso — sem canal de plataforma nenhum, para o
/// [SyncEngine] ser testável sem o `connectivity_plus` de verdade.
class FakeConnectivityGateway implements ConnectivityGateway {
  FakeConnectivityGateway({this._online = true});

  bool _online;
  final _controller = StreamController<bool>.broadcast();

  @override
  Future<bool> isOnline() async => _online;

  @override
  Stream<bool> get onChange => _controller.stream;

  /// A rede mudou de estado — o mesmo papel que
  /// `window.dispatchEvent(new Event('online'))` cumpre no teste da web.
  void setOnline(bool online) {
    _online = online;
    _controller.add(online);
  }

  void dispose() {
    unawaited(_controller.close());
  }
}
