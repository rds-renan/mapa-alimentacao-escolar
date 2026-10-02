import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/theme.dart';
import 'app_updater.dart';
import 'messages.dart';
import 'version_providers.dart';

/// O aviso de atualização no alto da tela-casa (issue #113).
///
/// Aparece quando o aplicativo está abaixo da versão mínima e não se
/// dispensa: enquanto ele estiver ali, nada do que ela registra vai para a
/// nuvem. Mas não tranca a tela — o registro continua, guardado no aparelho
/// (decisão 12 da E6), porque sem rede ela não teria como atualizar e ficaria
/// sem registrar justamente no caso que o aplicativo existe para resolver.
///
/// Confere a versão uma vez ao aparecer: é o "ao abrir" da decisão.
class UpdateNotice extends ConsumerStatefulWidget {
  const UpdateNotice({super.key});

  @override
  ConsumerState<UpdateNotice> createState() => _UpdateNoticeState();
}

class _UpdateNoticeState extends ConsumerState<UpdateNotice> {
  @override
  void initState() {
    super.initState();
    unawaited(ref.read(versionGateProvider).check());
  }

  @override
  Widget build(BuildContext context) {
    final gate = ref.watch(versionGateProvider);
    final updater = ref.watch(appUpdaterProvider);

    return ListenableBuilder(
      listenable: Listenable.merge([gate, updater]),
      builder: (context, _) {
        if (!gate.outdated) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.fromLTRB(
            kSpacingUnit * 4,
            kSpacingUnit * 3.5,
            kSpacingUnit * 4,
            0,
          ),
          child: _UpdateCard(
            state: updater.value,
            onUpdate: () => unawaited(updater.start()),
          ),
        );
      },
    );
  }
}

class _UpdateCard extends StatelessWidget {
  const _UpdateCard({required this.state, required this.onUpdate});

  final UpdateState state;
  final VoidCallback onUpdate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<MaeColors>()!;
    final percent = state.percent;

    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        padding: const EdgeInsets.all(kSpacingUnit * 3.5),
        decoration: BoxDecoration(
          color: tokens.warningSubtle,
          borderRadius: BorderRadius.circular(kRadiusXl),
          border: Border.all(color: tokens.warningBorder),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: kSpacingUnit * 2.5,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: kSpacingUnit),
              child: Icon(
                Icons.system_update_outlined,
                size: 20,
                color: tokens.warning,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: kSpacingUnit,
                children: [
                  Text(
                    updateTitle,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: tokens.warning,
                    ),
                  ),
                  Text(
                    updateBody,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: tokens.warning,
                    ),
                  ),
                  if (state.phase == UpdatePhase.downloading)
                    Padding(
                      padding: const EdgeInsets.only(top: kSpacingUnit),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: percent == null ? null : percent / 100,
                          minHeight: 6,
                        ),
                      ),
                    ),
                  if (state.message != null)
                    Text(
                      state.message!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: tokens.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  const SizedBox(height: kSpacingUnit),
                  FilledButton.icon(
                    onPressed: state.busy ? null : onUpdate,
                    icon: const Icon(Icons.download, size: 18),
                    label: const Text(updateAction),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, kTouchTarget),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
