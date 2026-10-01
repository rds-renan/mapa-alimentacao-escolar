import 'package:flutter/material.dart';

import '../theme/theme.dart';
import 'generated.dart';
import 'messages.dart';

/// Um documento na lista — o cartão da tela 2b e, quando é o recém-gerado, a
/// tela 6 inteira dentro dele (issue #109).
///
/// A situação aparece em cor **e** ícone, como o estado do dia na visão do
/// mês (RNF#1 da US008): "Fora do ar" e "Não saiu" são os dois cinzas que
/// precisam se separar sem depender da cor, e quem os separa é o ícone.
class DocumentCard extends StatelessWidget {
  const DocumentCard({
    super.key,
    required this.document,
    required this.now,
    required this.justGenerated,
    required this.online,
    required this.busy,
    required this.onShare,
  });

  final GeneratedDocumentRecord document;

  /// O relógio de quem está olhando. Vem de fora para o teste poder pará-lo.
  final DateTime now;

  /// Este é o documento que ela acabou de gerar: o cartão vira a tela 6.
  final bool justGenerated;
  final bool online;

  /// O arquivo deste documento está sendo buscado agora.
  final bool busy;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<MaeColors>()!;
    final availability = availabilityOf(document, now);
    final open = downloadable(availability);
    final period = periodTitle(document.dates);
    final muted = theme.colorScheme.onSurfaceVariant;
    final mutedStyle = theme.textTheme.bodySmall?.copyWith(color: muted);

    final note = switch (availability) {
      DocumentAvailability.available => expiryLabel(document),
      DocumentAvailability.processing => DocumentMessages.processingNote,
      DocumentAvailability.expired => DocumentMessages.expiredNote,
      DocumentAvailability.failed => DocumentMessages.failedNote,
      DocumentAvailability.expiring => null,
    };

    return Semantics(
      container: true,
      child: Container(
        padding: const EdgeInsets.all(kSpacingUnit * 3.5),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(kRadiusXl),
          border: Border.all(
            color: justGenerated
                ? tokens.successBorder
                : theme.colorScheme.outlineVariant,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: kSpacingUnit * 2.5,
          children: [
            // O cabeçalho da tela 6, e só no recém-gerado: a confirmação de
            // que saiu. Na lista de amanhã seria ruído.
            if (justGenerated)
              Row(
                spacing: kSpacingUnit * 2,
                children: [
                  Icon(Icons.check_circle_outline, color: tokens.success),
                  Expanded(
                    child: Text(
                      DocumentMessages.justGenerated,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: tokens.success,
                      ),
                    ),
                  ),
                ],
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: kSpacingUnit * 2.5,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: kSpacingUnit / 2,
                    children: [
                      Text(
                        period,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: open || availability.isProcessing
                              ? null
                              : muted,
                        ),
                      ),
                      Text(documentSummary(document, now), style: mutedStyle),
                    ],
                  ),
                ),
                _StatusBadge(
                  availability: availability,
                  label: availabilityLabel(
                    availability,
                    daysLeft(document, now),
                  ),
                ),
              ],
            ),
            // O prazo por extenso só quando ainda há folga: quando o cartão
            // já diz "Sai amanhã", repeti-lo seria dizer duas vezes.
            if (note != null) Text(note, style: mutedStyle),
            if (justGenerated && document.fileName != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: kSpacingUnit * 3,
                  vertical: kSpacingUnit * 2.5,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(kRadiusLg),
                ),
                child: Row(
                  spacing: kSpacingUnit * 2.5,
                  children: [
                    Icon(Icons.description_outlined, size: 18, color: muted),
                    Expanded(
                      child: Text(
                        document.fileName!,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (open)
              Semantics(
                label: shareLabel(period),
                excludeSemantics: true,
                button: true,
                enabled: online && !busy,
                child: SizedBox(
                  width: double.infinity,
                  height: kTouchTarget + kSpacingUnit * 2,
                  child:
                      (justGenerated ? FilledButton.icon : OutlinedButton.icon)(
                        onPressed: online && !busy ? onShare : null,
                        icon: busy
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.share_outlined),
                        label: const Text(DocumentMessages.share),
                      ),
                ),
              ),
            // O bloqueio, dito uma vez, no momento em que acontece: a
            // consequência irreversível da geração (RN#1 da US007) e a única
            // coisa da tela 6 que a lista não teria como mostrar depois.
            if (justGenerated) ...[
              _InlineNote(
                icon: Icons.lock_outline,
                text: lockedNotice(document.dates.length),
                background: tokens.warningSubtle,
                foreground: tokens.warning,
                border: tokens.warningBorder,
              ),
              _InlineNote(
                icon: Icons.schedule,
                text: DocumentMessages.expireNote,
                background: theme.colorScheme.surfaceContainerHighest,
                foreground: muted,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

extension on DocumentAvailability {
  bool get isProcessing => this == DocumentAvailability.processing;
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.availability, required this.label});

  final DocumentAvailability availability;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<MaeColors>()!;

    final (icon, background, foreground, border) = switch (availability) {
      DocumentAvailability.processing => (
        Icons.sync,
        tokens.accent,
        tokens.accentForeground,
        tokens.accentBorder,
      ),
      DocumentAvailability.available => (
        Icons.check_circle_outline,
        tokens.successSubtle,
        tokens.success,
        tokens.successBorder,
      ),
      DocumentAvailability.expiring => (
        Icons.schedule,
        tokens.warningSubtle,
        tokens.warning,
        tokens.warningBorder,
      ),
      DocumentAvailability.expired => (
        Icons.block,
        theme.colorScheme.surfaceContainerHighest,
        theme.colorScheme.onSurfaceVariant,
        theme.colorScheme.outlineVariant,
      ),
      DocumentAvailability.failed => (
        Icons.error_outline,
        tokens.destructiveSubtle,
        theme.colorScheme.error,
        tokens.destructiveBorder,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: kSpacingUnit * 2.5,
        vertical: kSpacingUnit,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: kSpacingUnit * 1.5,
        children: [
          Icon(icon, size: 14, color: foreground),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineNote extends StatelessWidget {
  const _InlineNote({
    required this.icon,
    required this.text,
    required this.background,
    required this.foreground,
    this.border,
  });

  final IconData icon;
  final String text;
  final Color background;
  final Color foreground;
  final Color? border;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: kSpacingUnit * 3,
        vertical: kSpacingUnit * 2.5,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(kRadiusLg),
        border: border == null ? null : Border.all(color: border!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: kSpacingUnit * 2,
        children: [
          Icon(icon, size: 16, color: foreground),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(color: foreground),
            ),
          ),
        ],
      ),
    );
  }
}
