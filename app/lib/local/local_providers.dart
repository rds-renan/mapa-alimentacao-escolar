import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../supabase.dart';
import 'app_database.dart';
import 'month_gateway.dart';
import 'month_repository.dart';
import 'supabase_month_gateway.dart';

/// O banco local, um por perfil (decisão 6 da E6).
///
/// Quem abre `AppDatabase(openLocalDatabaseConnection(profileId))` pela
/// primeira vez é a tela que precisa dele, como a issue #102 já previa — e é
/// esta. Não é `autoDispose`: sair não fecha o arquivo — não é esse o
/// momento (`AuthController.signOut` nunca chega perto daqui, autenticação e
/// sessão #101) —, e um único perfil por sessão do aplicativo é o único caso
/// que existe hoje. `ref.onDispose` fecha a conexão quando o próprio
/// `ProviderContainer` cai — na prática, ao encerrar o aplicativo — e é o que
/// os testes de widget usam para não deixar um banco em memória aberto atrás
/// do outro entre um teste e o seguinte.
final appDatabaseProvider = Provider.family<AppDatabase, String>((
  ref,
  profileId,
) {
  final db = AppDatabase(openLocalDatabaseConnection(profileId));
  ref.onDispose(db.close);
  return db;
});

/// O portão para o Supabase, substituível por um falso nos testes — o mesmo
/// raciocínio do `authGatewayProvider` (decisão 4 da E6).
final monthGatewayProvider = Provider<MonthGateway>((ref) {
  return SupabaseMonthGateway(supabase);
});

final monthRepositoryProvider = Provider.family<MonthRepository, String>((
  ref,
  profileId,
) {
  return MonthRepository(
    ref.watch(appDatabaseProvider(profileId)),
    ref.watch(monthGatewayProvider),
  );
});
