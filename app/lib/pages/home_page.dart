import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_controller.dart';
import '../local/local_providers.dart';
import '../local/month_repository.dart';
import '../month/day_row.dart';
import '../month/month.dart';
import '../theme/theme.dart';
import '../widgets/app_menu.dart';
import 'day_register_page.dart';
import 'select_maps_page.dart';

/// A tela-casa da merendeira: a visão do mês (US008), ao lado do menu do
/// aplicativo (US020) — telas 2 e 2a da E3, issue #104.
///
/// Responde a uma pergunta só, que hoje ela responde de cabeça e de caderno:
/// **o que ainda falta antes de gerar o mapa?** É uma lista vertical, não um
/// calendário em grade — num calendário cabe o número do dia e mais nada, e
/// o que decide o que ela vai fazer é a linha ao lado dele.
///
/// Ao contrário da web (decisão 2 da E5), esta tela **não promete rede**: o
/// que ela mostra é sempre o banco local, que já é a cópia convergida do
/// servidor (issue #102). Abrir uma rede que não responde não degrada a
/// leitura — só atrasa o quanto essa cópia está em dia, e é por isso que não
/// há estado de "carregando" nem de "falhou": só o que já está no aparelho.
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  static const path = '/';

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  late DateTime _month;

  MonthRepository? _streamRepository;
  DateTime? _streamMonth;
  Stream<List<MealMapWithMeals>>? _monthStream;

  @override
  void initState() {
    super.initState();
    final today = clock.now();
    _month = DateTime(today.year, today.month);
  }

  void _goToMonth(int months) {
    setState(() => _month = shiftMonth(_month, months));
  }

  /// Garante a leitura do mês aberto e, ao trocar de mês (ou abrir a tela),
  /// busca a atualização no servidor por baixo — sem bloquear quem já está
  /// vendo o que tinha (mesmo raciocínio de [MonthRepository.refreshMonth]).
  /// Uma falha de rede aqui é silenciosa de propósito: a lista já mostra o
  /// que está no aparelho, e a rede só melhora o que já apareceu, nunca
  /// condiciona a tela a aparecer (CA#3 da issue #104).
  void _ensureMonthStream(MonthRepository repository) {
    if (identical(_streamRepository, repository) && _streamMonth == _month) {
      return;
    }

    _streamRepository = repository;
    _streamMonth = _month;
    _monthStream = repository.watchMonth(_month);
    unawaited(repository.refreshMonth(_month).catchError((_) {}));
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);

    if (auth.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (auth.profileUnavailable) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(kSpacingUnit * 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: kSpacingUnit * 4,
              children: [
                const Text(
                  'Não deu para confirmar o seu acesso agora. Nada foi '
                  'perdido — é só tentar de novo.',
                  textAlign: TextAlign.center,
                ),
                FilledButton(
                  onPressed: () =>
                      ref.read(authControllerProvider.notifier).retryProfile(),
                  child: const Text('Tentar de novo'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final profile = auth.profile;
    if (profile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final repository = ref.watch(monthRepositoryProvider(profile.id));
    _ensureMonthStream(repository);

    final theme = Theme.of(context);
    final today = dateOnly(clock.now());

    return Scaffold(
      drawer: const AppMenu(),
      body: SafeArea(
        child: Column(
          children: [
            _MonthHeader(
              month: _month,
              onPrevious: () => _goToMonth(-1),
              onNext: () => _goToMonth(1),
            ),
            Expanded(
              child: StreamBuilder<List<MealMapWithMeals>>(
                stream: _monthStream,
                builder: (context, snapshot) {
                  final rows = snapshot.data ?? const <MealMapWithMeals>[];
                  final byDate = {
                    for (final row in rows)
                      dateOnly(row.mealMap.mapDate): DayRecord.fromLocal(row),
                  };
                  final days = listedDays(_month, byDate.keys.toSet());
                  final weeks = groupIntoWeeks(days);
                  final progress = monthProgress(days, byDate);

                  if (days.isEmpty) {
                    return Center(
                      child: Text(
                        'Nenhum dia para mostrar neste mês.',
                        style: theme.textTheme.bodyLarge,
                      ),
                    );
                  }

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(
                      kSpacingUnit * 4,
                      kSpacingUnit * 3.5,
                      kSpacingUnit * 4,
                      kSpacingUnit * 6,
                    ),
                    children: [
                      _ProgressCard(progress: progress),
                      for (final week in weeks) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            kSpacingUnit,
                            kSpacingUnit * 3.5,
                            kSpacingUnit,
                            kSpacingUnit * 2,
                          ),
                          child: Text(
                            week.label,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        _WeekCard(
                          week: week,
                          byDate: byDate,
                          today: today,
                          onTapDay: (date) => context.push(
                            DayRegisterPage.pathFor(isoDate(date)),
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _GenerateDocumentButton(month: _month),
    );
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({
    required this.month,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime month;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(bottom: BorderSide(color: theme.colorScheme.outline)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu),
            tooltip: 'Abrir o menu',
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Mês anterior',
            onPressed: onPrevious,
          ),
          Expanded(
            child: Semantics(
              liveRegion: true,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    monthLabel(month),
                    style: theme.textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Próximo mês',
            onPressed: onNext,
          ),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.progress});

  final MonthProgress progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final done = progress.schoolDays == 0
        ? 0.0
        : progress.done / progress.schoolDays;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(kSpacingUnit * 3.5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: kSpacingUnit * 2.5,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Andamento do mês', style: theme.textTheme.titleMedium),
                Text(
                  progressLabel(progress.done, progress.schoolDays),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            Semantics(
              label: 'Dias prontos no mês',
              value: '${progress.done} de ${progress.schoolDays}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: done,
                  minHeight: 6,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                ),
              ),
            ),
            Text(
              progressBreakdown(progress.counts),
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekCard extends StatelessWidget {
  const _WeekCard({
    required this.week,
    required this.byDate,
    required this.today,
    required this.onTapDay,
  });

  final Week week;
  final Map<DateTime, DayRecord> byDate;
  final DateTime today;
  final void Function(DateTime date) onTapDay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < week.days.length; i++) ...[
            if (i > 0) Divider(height: 1, color: theme.colorScheme.outline),
            DayRow(
              date: week.days[i],
              record: byDate[week.days[i]],
              isToday: week.days[i] == today,
              onTap: () => onTapDay(week.days[i]),
            ),
          ],
        ],
      ),
    );
  }
}

/// O segundo dos dois caminhos da tela-casa: a seleção de mapas (issue
/// #108), já com o mês que ela estava vendo.
class _GenerateDocumentButton extends StatelessWidget {
  const _GenerateDocumentButton({required this.month});

  final DateTime month;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(
        kSpacingUnit * 4,
        kSpacingUnit * 3,
        kSpacingUnit * 4,
        kSpacingUnit * 4,
      ),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: () => context.push(SelectMapsPage.pathFor(month)),
          icon: const Icon(Icons.description),
          label: const Text('Gerar documento'),
        ),
      ),
    );
  }
}
