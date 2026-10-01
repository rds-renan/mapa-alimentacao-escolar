import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_controller.dart';
import '../documents/document_card.dart';
import '../documents/document_sharer.dart';
import '../documents/generated.dart';
import '../documents/messages.dart';
import '../documents/notice.dart';
import '../local/connectivity_gateway.dart';
import '../local/documents_repository.dart';
import '../local/local_providers.dart';
import '../theme/theme.dart';
import '../widgets/form_message.dart';
import 'select_maps_page.dart';

/// Os documentos gerados — telas 6 e 2b da E3 (US012, US014, US021), issue
/// #109.
///
/// A tela existe porque a 6, sozinha, é um beco: o documento recém-gerado
/// ficaria inalcançável assim que a merendeira saísse dali (decisão 10 da E3).
/// Aqui as duas são a mesma tela — o recém-gerado é o primeiro cartão da
/// lista, no lugar onde ele estará amanhã também, como na
/// [web](../../../docs/05-web/documentos-gerados.md).
///
/// **A lista é do aparelho; o arquivo não.** A lista abre sem rede com o que
/// já foi sincronizado (CA#3), e abrir e compartilhar o arquivo exigem rede
/// (decisão 6 da E6) — a tela diz isso antes do toque, em vez de deixar o
/// botão falhar em silêncio. Compartilhar é a folha do Android, que na web
/// virou download (decisão 9 da E5).
///
/// Nada aqui abre mapa nenhum (RN#2 da US021): a lista é sobre o arquivo, e
/// os mapas que entraram nele estão bloqueados. O caminho para corrigir um dia
/// é a direção reabri-lo (US023).
class GeneratedDocumentsPage extends ConsumerStatefulWidget {
  const GeneratedDocumentsPage({super.key, this.justGenerated});

  static const path = '/documentos';

  /// O documento que ela acabou de gerar, se é que acabou. Vem na navegação, e
  /// não do servidor: é um fato daquela ida — reabrir a tela amanhã não deve
  /// ressuscitar a tela 6 de hoje.
  final String? justGenerated;

  @override
  ConsumerState<GeneratedDocumentsPage> createState() =>
      _GeneratedDocumentsPageState();
}

class _GeneratedDocumentsPageState
    extends ConsumerState<GeneratedDocumentsPage> {
  String? _profileId;
  late GeneratedDocumentsRepository _repository;
  late DocumentSharer _sharer;
  Stream<List<GeneratedDocumentRecord>>? _stream;
  StreamSubscription<bool>? _connectivitySubscription;

  bool _online = true;

  /// A primeira leitura do servidor ainda não terminou.
  bool _refreshing = true;

  /// A leitura do servidor falhou e não há nada no aparelho para mostrar.
  bool _refreshFailed = false;
  String? _busyId;
  String? _fileError;

  void _setUp(String profileId) {
    if (_profileId == profileId) return;
    _profileId = profileId;

    _repository = ref.read(generatedDocumentsRepositoryProvider(profileId));
    _sharer = ref.read(documentSharerProvider);
    _stream = _repository.watch();

    final connectivity = ref.read(connectivityGatewayProvider);
    unawaited(_checkOnline(connectivity));
    _connectivitySubscription = connectivity.onChange.listen(_setOnline);

    unawaited(_refresh());
  }

  Future<void> _refresh() async {
    setState(() {
      _refreshing = true;
      _refreshFailed = false;
    });

    try {
      await _repository.refresh();
      if (mounted) setState(() => _refreshing = false);
    } catch (_) {
      // Sem rede, a tela mostra o que já está no aparelho; só se não houver
      // nada é que a falha vira aviso.
      if (mounted) {
        setState(() {
          _refreshing = false;
          _refreshFailed = true;
        });
      }
    }
  }

  Future<void> _checkOnline(ConnectivityGateway connectivity) async {
    _setOnline(await connectivity.isOnline());
  }

  void _setOnline(bool online) {
    if (!mounted || online == _online) return;
    setState(() => _online = online);
    // A rede voltou: é a hora de a lista ficar em dia.
    if (online) unawaited(_refresh());
  }

  Future<void> _share(GeneratedDocumentRecord document) async {
    setState(() {
      _busyId = document.id;
      _fileError = null;
    });

    try {
      await _sharer.share(
        filePath: document.filePath!,
        fileName: document.fileName!,
      );
      if (mounted) setState(() => _busyId = null);
    } on DocumentFileFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _busyId = null;
        _fileError = failure.message;
      });
    }
  }

  @override
  void dispose() {
    unawaited(_connectivitySubscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(authControllerProvider).profile;
    if (profile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    _setUp(profile.id);

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(DocumentMessages.title),
            Text(
              DocumentMessages.subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      body: StreamBuilder<List<GeneratedDocumentRecord>>(
        stream: _stream,
        builder: (context, snapshot) {
          final documents = snapshot.data;
          final now = clock.now();

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              kSpacingUnit * 4,
              kSpacingUnit * 3.5,
              kSpacingUnit * 4,
              kSpacingUnit * 6,
            ),
            children: [
              const Notice(
                icon: Icons.info_outline,
                child: Text(DocumentMessages.notice),
              ),
              // Sem rede não se compartilha nada, e o aviso vem antes do
              // toque. A lista em si está aqui: veio do aparelho.
              if (!_online) ...[
                const SizedBox(height: kSpacingUnit * 3.5),
                const Notice(
                  icon: Icons.wifi_off,
                  warning: true,
                  child: Text(DocumentMessages.offline),
                ),
              ],
              if (_fileError != null) ...[
                const SizedBox(height: kSpacingUnit * 3.5),
                FormMessage(_fileError!),
              ],
              const SizedBox(height: kSpacingUnit * 3.5),
              if (documents == null || (documents.isEmpty && _refreshing))
                const _Status(
                  icon: null,
                  message: DocumentMessages.loading,
                  loading: true,
                )
              else if (documents.isEmpty && _refreshFailed)
                _Status(
                  icon: Icons.error_outline,
                  message: DocumentMessages.loadFailed,
                  action: OutlinedButton(
                    onPressed: _refresh,
                    child: const Text(DocumentMessages.retry),
                  ),
                )
              else if (documents.isEmpty)
                _Status(
                  icon: Icons.description_outlined,
                  message:
                      '${DocumentMessages.empty}\n${DocumentMessages.emptyHint}',
                  action: OutlinedButton(
                    onPressed: () => context.pushReplacement(
                      SelectMapsPage.pathFor(DateTime(now.year, now.month)),
                    ),
                    child: const Text(DocumentMessages.generate),
                  ),
                )
              else
                for (final document in documents) ...[
                  DocumentCard(
                    document: document,
                    now: now,
                    justGenerated: document.id == widget.justGenerated,
                    online: _online,
                    busy: _busyId == document.id,
                    onShare: () => unawaited(_share(document)),
                  ),
                  const SizedBox(height: kSpacingUnit * 3),
                ],
            ],
          );
        },
      ),
    );
  }
}

class _Status extends StatelessWidget {
  const _Status({
    required this.icon,
    required this.message,
    this.action,
    this.loading = false,
  });

  final IconData? icon;
  final String message;
  final Widget? action;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: kSpacingUnit * 8),
        child: Column(
          spacing: kSpacingUnit * 3,
          children: [
            if (loading)
              const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else if (icon != null)
              Icon(icon, size: 24, color: muted),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(color: muted),
            ),
            ?action,
          ],
        ),
      ),
    );
  }
}
