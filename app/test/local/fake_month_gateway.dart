import 'package:mae/local/month_gateway.dart';

/// Um [MonthGateway] falso, sem servidor nenhum — o mesmo raciocínio do
/// `FakeAuthGateway` (decisão 4 da E6).
class FakeMonthGateway implements MonthGateway {
  List<RemoteMealMap> maps = const [];
  Object? fetchError;
  int fetchCalls = 0;
  DateTime? lastFirstDay;
  DateTime? lastLastDay;

  @override
  Future<List<RemoteMealMap>> fetchMonth({
    required DateTime firstDay,
    required DateTime lastDay,
  }) async {
    fetchCalls++;
    lastFirstDay = firstDay;
    lastLastDay = lastDay;
    if (fetchError != null) throw fetchError!;
    return maps;
  }
}
