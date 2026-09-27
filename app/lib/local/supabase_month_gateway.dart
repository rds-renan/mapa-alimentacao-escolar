import 'package:supabase_flutter/supabase_flutter.dart';

import 'month_gateway.dart';

/// A implementação de verdade do [MonthGateway], sobre `supabase_flutter`.
/// Não há filtro de escola na consulta — quem recorta é o RLS da E4
/// (decisão 6 da E6), como na web.
class SupabaseMonthGateway implements MonthGateway {
  SupabaseMonthGateway(this._client);

  final SupabaseClient _client;

  @override
  Future<List<RemoteMealMap>> fetchMonth({
    required DateTime firstDay,
    required DateTime lastDay,
  }) async {
    final rows = await _client
        .from('meal_map')
        .select(
          'id, map_date, non_school_day, note, meals_served, locked, '
          'updated_at, meal(id, type, description, acceptance)',
        )
        .gte('map_date', _isoDate(firstDay))
        .lte('map_date', _isoDate(lastDay));

    return rows.map(RemoteMealMap.fromRow).toList();
  }
}

String _isoDate(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}
