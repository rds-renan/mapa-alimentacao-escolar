import 'package:mae/local/sync_gateway.dart';

/// Um [SyncGateway] falso, sem servidor nenhum — o mesmo raciocínio do
/// `FakeMonthGateway` (decisão 4 da E6).
///
/// As respostas são enfileiradas com [enqueueSaved]/[enqueueError] e saem na
/// ordem em que entraram, uma por chamada — o mesmo papel que
/// `rpc.mockResolvedValueOnce` cumpre no teste da web.
class FakeSyncGateway implements SyncGateway {
  final List<Object> _responses = [];
  final List<Map<String, dynamic>> calls = [];

  /// Roda antes de a chamada responder, uma vez só. É como o teste da web
  /// simula "ela continuou digitando enquanto o envio estava no ar":
  /// chamando `engine.save()` de dentro da implementação falsa do RPC.
  Future<void> Function()? beforeRespond;

  void enqueueSaved(Map<String, dynamic> response) {
    _responses.add(response);
  }

  void enqueueError(Object error) {
    _responses.add(error);
  }

  @override
  Future<Map<String, dynamic>> saveMealMap(Map<String, dynamic> payload) async {
    calls.add(payload);

    final hook = beforeRespond;
    if (hook != null) {
      beforeRespond = null;
      await hook();
    }

    if (_responses.isEmpty) {
      throw StateError('FakeSyncGateway sem resposta enfileirada');
    }

    final response = _responses.removeAt(0);
    if (response is Map<String, dynamic>) return response;
    // ignore: only_throw_errors
    throw response;
  }
}
