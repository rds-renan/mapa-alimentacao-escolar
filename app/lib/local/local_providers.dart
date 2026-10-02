import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../documents/document_sharer.dart';
import '../documents/generation_gateway.dart';
import '../documents/seen_documents.dart';
import '../supabase.dart';
import '../version/version_providers.dart';
import 'app_database.dart';
import 'catalog_gateway.dart';
import 'catalog_repository.dart';
import 'connectivity_gateway.dart';
import 'day_repository.dart';
import 'documents_gateway.dart';
import 'documents_repository.dart';
import 'month_gateway.dart';
import 'month_repository.dart';
import 'supabase_catalog_gateway.dart';
import 'supabase_documents_gateway.dart';
import 'supabase_month_gateway.dart';
import 'supabase_sync_gateway.dart';
import 'sync_engine.dart';
import 'sync_gateway.dart';
import 'sync_queue_store.dart';

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

/// O catálogo de gêneros. Quem o lê primeiro é a folha de escolher gênero
/// (issue #106); a manutenção dele (issue #107) lê pela mesma porta e grava
/// por ela direto no servidor.
final catalogGatewayProvider = Provider<CatalogGateway>((ref) {
  return SupabaseCatalogGateway(supabase);
});

/// A rede do aparelho, para as telas que exigem conexão (a manutenção do
/// catálogo, issue #107) dizerem isso antes de tentar.
final connectivityGatewayProvider = Provider<ConnectivityGateway>((ref) {
  return ConnectivityPlusGateway();
});

final catalogRepositoryProvider = Provider.family<CatalogRepository, String>((
  ref,
  profileId,
) {
  return CatalogRepository(
    ref.watch(appDatabaseProvider(profileId)),
    ref.watch(catalogGatewayProvider),
  );
});

final dayRepositoryProvider = Provider.family<DayRepository, String>((
  ref,
  profileId,
) {
  return DayRepository(ref.watch(appDatabaseProvider(profileId)));
});

/// O portão do envio, substituível por um falso nos testes (decisão 4 da
/// E6), como [monthGatewayProvider].
final syncGatewayProvider = Provider<SyncGateway>((ref) {
  return SupabaseSyncGateway(supabase);
});

/// A fila de envio (issue #103), viva enquanto o [ProviderContainer] existir
/// — mesmo raciocínio do [appDatabaseProvider]: não é `autoDispose`, porque
/// sair da tela do registro não pode parar um envio em andamento, e quem
/// fecha é `ref.onDispose`, ao encerrar o aplicativo (ou o teste).
final syncEngineProvider = Provider.family<SyncEngine, String>((
  ref,
  profileId,
) {
  final engine = SyncEngine(
    SyncQueueStore(ref.watch(appDatabaseProvider(profileId))),
    ref.watch(syncGatewayProvider),
    connectivity: ref.watch(connectivityGatewayProvider),
    version: ref.watch(versionGateProvider),
  );
  engine.start();
  ref.onDispose(engine.stop);
  return engine;
});

/// O pedido de geração do documento (issue #108), substituível por um falso
/// nos testes, como [syncGatewayProvider].
final generationGatewayProvider = Provider<GenerationGateway>((ref) {
  return SupabaseGenerationGateway(supabase);
});

/// A lista dos documentos gerados (issue #109), substituível por um falso nos
/// testes, como [monthGatewayProvider].
final documentsGatewayProvider = Provider<DocumentsGateway>((ref) {
  return SupabaseDocumentsGateway(supabase);
});

final generatedDocumentsRepositoryProvider =
    Provider.family<GeneratedDocumentsRepository, String>((ref, profileId) {
      return GeneratedDocumentsRepository(
        ref.watch(appDatabaseProvider(profileId)),
        ref.watch(documentsGatewayProvider),
      );
    });

/// A folha de compartilhamento do Android, que nos testes é um falso.
final documentSharerProvider = Provider<DocumentSharer>((ref) {
  return PlatformDocumentSharer(ref.watch(documentsGatewayProvider));
});

/// O "já visto" dos documentos gerados (issue #110), um por perfil. Vive
/// enquanto o [ProviderContainer] existir, porque a tela de documentos marca
/// e a tela-casa lê — e as duas precisam ver o mesmo objeto.
final seenDocumentsProvider = Provider.family<SeenDocuments, String>((
  ref,
  profileId,
) {
  final seen = SeenDocuments(profileId);
  ref.onDispose(seen.dispose);
  return seen;
});
