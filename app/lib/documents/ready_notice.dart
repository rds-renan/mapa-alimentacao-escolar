import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../local/local_providers.dart';
import '../theme/theme.dart';
import 'generated.dart';
import 'messages.dart';
import 'seen_documents.dart';

/// O aviso de documento pronto, no alto da tela-casa — o que ficou no lugar
/// da notificação do sistema da E3 (issue #110, decisão 10 da E6).
///
/// Ao abrir, busca a lista de documentos por baixo e, se há algum pronto que
/// ela ainda não viu, mostra o mais novo em destaque. O caso real não é a
/// geração demorar — ela responde em menos de um segundo —, e sim o
/// aplicativo morrer durante o pedido, ou ela sair antes de compartilhar.
/// Nos dois o documento existe e o aviso o encontra na próxima abertura.
///
/// Sem rede, avisa do que já está no aparelho: a lista é a cópia local (issue
/// #109) e a busca só a melhora. Falha da busca é silenciosa, como a da visão
/// do mês — o aviso é um bônus, e nunca condiciona a tela a abrir.
///
/// Sai de duas maneiras: ela toca em "Compartilhar", que leva à tela do
/// documento (que o marca como visto ao listá-lo), ou dispensa no X.
class DocumentReadyNotice extends ConsumerStatefulWidget {
  const DocumentReadyNotice({
    super.key,
    required this.profileId,
    required this.onShare,
  });

  final String profileId;

  /// Leva à tela do documento, com o identificador do mais novo.
  final void Function(String documentId) onShare;

  @override
  ConsumerState<DocumentReadyNotice> createState() =>
      _DocumentReadyNoticeState();
}

class _DocumentReadyNoticeState extends ConsumerState<DocumentReadyNotice> {
  late final SeenDocuments _seen;
  late final Stream<List<GeneratedDocumentRecord>> _stream;

  @override
  void initState() {
    super.initState();
    _seen = ref.read(seenDocumentsProvider(widget.profileId));
    final repository = ref.read(
      generatedDocumentsRepositoryProvider(widget.profileId),
    );
    _stream = repository.watch();

    unawaited(_seen.load());
    unawaited(repository.refresh().catchError((_) {}));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _seen,
      builder: (context, _) {
        if (!_seen.loaded) return const SizedBox.shrink();

        return StreamBuilder<List<GeneratedDocumentRecord>>(
          stream: _stream,
          builder: (context, snapshot) {
            final unseen = unseenReady(
              snapshot.data ?? const [],
              _seen.ids,
              clock.now(),
            );
            if (unseen.isEmpty) return const SizedBox.shrink();

            final newest = unseen.first;

            return Padding(
              padding: const EdgeInsets.fromLTRB(
                kSpacingUnit * 4,
                kSpacingUnit * 3.5,
                kSpacingUnit * 4,
                0,
              ),
              child: _ReadyCard(
                title: ReadyNoticeMessages.title(unseen.length),
                body: ReadyNoticeMessages.body(
                  periodTitle(newest.dates),
                  newest.dates.length,
                  count: unseen.length,
                ),
                onShare: () => widget.onShare(newest.id),
                onDismiss: () =>
                    unawaited(_seen.markSeen([for (final d in unseen) d.id])),
              ),
            );
          },
        );
      },
    );
  }
}

class _ReadyCard extends StatelessWidget {
  const _ReadyCard({
    required this.title,
    required this.body,
    required this.onShare,
    required this.onDismiss,
  });

  final String title;
  final String body;
  final VoidCallback onShare;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<MaeColors>()!;

    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          kSpacingUnit * 3.5,
          kSpacingUnit * 3,
          kSpacingUnit,
          kSpacingUnit * 3,
        ),
        decoration: BoxDecoration(
          color: tokens.accent,
          borderRadius: BorderRadius.circular(kRadiusXl),
          border: Border.all(color: tokens.accentBorder),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: kSpacingUnit * 2.5,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: kSpacingUnit),
              child: Icon(
                Icons.description_outlined,
                size: 20,
                color: tokens.accentForeground,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: kSpacingUnit,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: tokens.accentForeground,
                    ),
                  ),
                  Text(
                    body,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: tokens.accentForeground,
                    ),
                  ),
                  const SizedBox(height: kSpacingUnit),
                  FilledButton.icon(
                    onPressed: onShare,
                    icon: const Icon(Icons.share_outlined, size: 18),
                    label: const Text(ReadyNoticeMessages.share),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, kTouchTarget),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              tooltip: ReadyNoticeMessages.dismiss,
              color: tokens.accentForeground,
              onPressed: onDismiss,
            ),
          ],
        ),
      ),
    );
  }
}
