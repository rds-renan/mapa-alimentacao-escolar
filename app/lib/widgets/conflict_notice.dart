import 'package:flutter/material.dart';

import '../local/sync_engine.dart';
import '../theme/theme.dart';

/// O aviso de que o dia foi registrado em outro aparelho depois da edição
/// que estava subindo — a versão em Dart de
/// `web/src/local/conflict-notice.tsx`, ainda sem tela que a monte (chega
/// com a #105).
///
/// Existe porque a convergência **nunca** se resolve em silêncio: prevalece
/// a edição mais recente, por decisão, e a usuária é avisada de que aquilo
/// aconteceu (CA#3 da US011). Ele não some sozinho — some quando ela diz que
/// leu, por [onDismiss].
class ConflictNotice extends StatelessWidget {
  const ConflictNotice({
    super.key,
    required this.conflicts,
    required this.onDismiss,
  });

  final List<Conflict> conflicts;
  final void Function(String mapDate) onDismiss;

  @override
  Widget build(BuildContext context) {
    if (conflicts.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final tokens = theme.extension<MaeColors>()!;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.accent,
        border: Border(bottom: BorderSide(color: tokens.accentBorder)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: kSpacingUnit * 4,
          vertical: kSpacingUnit * 3,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (index, conflict) in conflicts.indexed)
              Padding(
                padding: EdgeInsets.only(
                  top: index == 0 ? 0 : kSpacingUnit * 2,
                ),
                child: Semantics(
                  liveRegion: true,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: tokens.accentForeground,
                      ),
                      const SizedBox(width: kSpacingUnit * 2),
                      Expanded(
                        child: Text(
                          conflict.message,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: tokens.accentForeground,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => onDismiss(conflict.mapDate),
                        child: const Text('Entendi'),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
