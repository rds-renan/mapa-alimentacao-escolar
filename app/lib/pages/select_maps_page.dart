import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_controller.dart';
import '../documents/check_mark.dart';
import '../documents/day_option_row.dart';
import '../documents/generate_dialogs.dart';
import '../documents/generation_gateway.dart';
import '../documents/messages.dart';
import '../documents/notice.dart';
import '../documents/selection.dart';
import '../local/connectivity_gateway.dart';
import '../local/day.dart';
import '../local/local_providers.dart';
import '../local/month_repository.dart';
import '../local/sync_engine.dart';
import '../month/month.dart';
import '../theme/theme.dart';
import 'generated_documents_page.dart';

/// A seleção de mapas — tela 5 da E3 (US013) e a antessala do único passo
/// irreversível do fluxo da merendeira. Porto de `web/src/pages/SelectMaps.tsx`
/// (issue #108); o porquê de cada regra está em
/// `docs/05-web/selecao-de-mapas.md` e a diferença de plataforma, em
/// `docs/06-app/selecao-de-mapas-e-geracao.md`.
///
/// Os três botões do alto são **modos**, não ações, e a tela abre no
/// primeiro: a prestação de contas é mensal e o mês inteiro tem de sair em
/// poucos toques (RNF#1 da US013) — abrindo assim, são zero.
///
/// A regra que atravessa a tela toda: **mapa pendente não entra em
/// documento.** O atalho que não consegue fechar o período não seleciona
/// nada — mostra o que falta, dia por dia.
class SelectMapsPage extends ConsumerStatefulWidget {
  const SelectMapsPage({super.key, required this.month});

  final DateTime month;

  static const path = '/gerar';
  static const monthParam = 'mes';

  /// "/gerar?mes=2026-09": o mês que a tela-casa estava mostrando.
  static String pathFor(DateTime month) {
    final text = isoDate(firstDayOfMonth(month)).substring(0, 7);
    return '$path?$monthParam=$text';
  }

  /// O mês pedido na rota, ou o de hoje quando falta ou não é um mês.
  static DateTime monthFrom(String? value) {
    final match = RegExp(r'^(\d{4})-(0[1-9]|1[0-2])$').firstMatch(value ?? '');
    if (match == null) {
      final today = clock.now();
      return DateTime(today.year, today.month);
    }

    return DateTime(int.parse(match.group(1)!), int.parse(match.group(2)!));
  }

  @override
  ConsumerState<SelectMapsPage> createState() => _SelectMapsPageState();
}

class _SelectMapsPageState extends ConsumerState<SelectMapsPage> {
  SelectionMode _mode = SelectionMode.month;

  /// A escolha de cada modo mora no seu lugar, e trocar de modo limpa as
  /// duas: são intenções diferentes, e herdar a marcação anterior faria a
  /// tela dizer "22 mapas selecionados" logo depois de ela pedir outra coisa.
  Set<int> _chosenWeeks = {};
  Set<DateTime> _chosenDays = {};

  List<DayPayload> _drafts = const [];
  bool _online = true;
  bool _generating = false;

  String? _profileId;
  late MonthRepository _repository;
  late SyncEngine _engine;
  late GenerationGateway _generation;
  Stream<List<MealMapWithMeals>>? _monthStream;
  StreamSubscription<bool>? _connectivitySubscription;
  int _lastPending = 0;

  DateTime get _month => widget.month;

  /// Liga a tela ao banco da usuária, uma vez só. Fica fora do `initState`
  /// porque o perfil só existe depois de a sessão carregar.
  void _setUp(String profileId) {
    if (_profileId == profileId) return;
    _profileId = profileId;

    _repository = ref.read(monthRepositoryProvider(profileId));
    _engine = ref.read(syncEngineProvider(profileId));
    _generation = ref.read(generationGatewayProvider);
    _monthStream = _repository.watchMonth(_month);

    _engine.stateListenable.addListener(_onSyncChanged);
    _lastPending = _engine.state.pending;
    unawaited(_loadDrafts());

    final connectivity = ref.read(connectivityGatewayProvider);
    unawaited(_checkOnline(connectivity));
    _connectivitySubscription = connectivity.onChange.listen(_setOnline);

    // A cópia local é tão nova quanto o último `refreshMonth`, e aqui o que
    // decide é o identificador do mapa no servidor. Silenciosa: sem rede a
    // lista continua com o que está no aparelho, e gerar já está desabilitado.
    unawaited(_refresh());
  }

  Future<void> _refresh() async {
    try {
      await _repository.refreshMonth(_month);
    } catch (_) {
      // Sem rede, a tela mostra o que já está no aparelho.
    }
  }

  Future<void> _checkOnline(ConnectivityGateway connectivity) async {
    _setOnline(await connectivity.isOnline());
  }

  void _setOnline(bool online) {
    if (mounted && online != _online) setState(() => _online = online);
  }

  Future<void> _loadDrafts() async {
    final prefix = isoDate(firstDayOfMonth(_month)).substring(0, 7);
    final drafts = await _engine.pendingDays(prefix);
    if (mounted) setState(() => _drafts = drafts);
  }

  void _onSyncChanged() {
    final pending = _engine.state.pending;
    if (pending == _lastPending) return;

    final settled = pending < _lastPending;
    _lastPending = pending;
    unawaited(_loadDrafts());

    // Um dia saiu da fila: o servidor passou a tê-lo, e é aqui que o
    // identificador dele chega à cópia local — nada mais escreve em
    // `meal_maps` ao confirmar um envio (nota da #105).
    if (settled) unawaited(_refresh());
  }

  Future<void> _sendNow() async {
    await _engine.flush();
    await _refresh();
  }

  @override
  void dispose() {
    if (_profileId != null) {
      _engine.stateListenable.removeListener(_onSyncChanged);
    }
    unawaited(_connectivitySubscription?.cancel());
    super.dispose();
  }

  void _changeMode(Set<SelectionMode> next) {
    setState(() {
      _mode = next.first;
      _chosenWeeks = {};
      _chosenDays = {};
    });
  }

  void _toggle<T>(Set<T> set, T value) {
    setState(() {
      if (!set.remove(value)) set.add(value);
    });
  }

  Future<void> _requestGeneration(List<DayOption> chosen) async {
    final confirmed = await confirmGeneration(
      context,
      period: periodLabel(chosen.map((option) => option.date)),
      count: chosen.length,
    );
    if (confirmed && mounted) {
      await _generate([for (final option in chosen) option.id!]);
    }
  }

  /// A geração não é cancelada por ela sair da tela: o `Future` não depende
  /// do widget, o registro é do servidor, e o documento aparece em
  /// Documentos gerados de qualquer jeito. O que **não** acontece é navegar
  /// por cima do que ela estiver fazendo se terminar com ela em outro lugar.
  Future<void> _generate(List<String> ids) async {
    setState(() => _generating = true);

    try {
      final document = await _generation.generate(ids);
      // Os mapas acabaram de ficar bloqueados, e a cópia local ainda não
      // sabe. Antes de sair, porque é a tela do mês que ela vai ver.
      await _refresh();
      if (!mounted) return;

      setState(() => _generating = false);
      context.pushReplacement(GeneratedDocumentsPage.path, extra: document.id);
    } on GenerationFailure catch (failure) {
      if (!mounted) return;
      setState(() => _generating = false);

      final retry = await showGenerationFailure(
        context,
        message: failure.message,
      );
      if (retry && mounted) await _generate(ids);
    }
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
            const Text(SelectionMessages.title),
            Text(
              SelectionMessages.subtitle(_month),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      body: StreamBuilder<List<MealMapWithMeals>>(
        stream: _monthStream,
        builder: (context, snapshot) {
          final rows = snapshot.data ?? const <MealMapWithMeals>[];
          final byDate = <DateTime, DayRecord>{
            for (final row in rows)
              dateOnly(row.mealMap.mapDate): DayRecord.fromLocal(row),
          };
          for (final draft in _drafts) {
            final date = dateOnly(DateTime.parse(draft.mapDate));
            byDate[date] =
                byDate[date]?.withDraft(draft) ?? DayRecord.fromDraft(draft);
          }

          final days = listedDays(_month, byDate.keys.toSet());
          final options = toOptions(days, byDate);
          final byDay = {for (final option in options) option.date: option};
          final weeks = [
            for (final week in groupIntoWeeks(days))
              (week: week, options: [for (final d in week.days) byDay[d]!]),
          ];

          final chosen = switch (_mode) {
            SelectionMode.month =>
              closable(options) ? eligibleOf(options) : <DayOption>[],
            SelectionMode.week => [
              for (final entry in weeks)
                if (_chosenWeeks.contains(entry.week.number))
                  ...eligibleOf(entry.options),
            ],
            SelectionMode.days => eligibleOf(
              options,
            ).where((option) => _chosenDays.contains(option.date)).toList(),
          };
          final chosenDates = {for (final option in chosen) option.date};

          final missing = missingDays(options);
          final unsent = options.where((option) => option.unsent).length;
          final canGenerate = chosen.isNotEmpty && _online && !_generating;

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    kSpacingUnit * 4,
                    kSpacingUnit * 3.5,
                    kSpacingUnit * 4,
                    kSpacingUnit * 6,
                  ),
                  children: [
                    SegmentedButton<SelectionMode>(
                      showSelectedIcon: false,
                      segments: [
                        for (final mode in SelectionMode.values)
                          ButtonSegment(
                            value: mode,
                            label: Text(
                              modeLabels[mode]!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      selected: {_mode},
                      onSelectionChanged: _changeMode,
                    ),
                    const SizedBox(height: kSpacingUnit * 3.5),
                    const Notice(
                      icon: Icons.info_outline,
                      child: Text(SelectionMessages.singleDocument),
                    ),
                    // O aviso do que falta só aparece no modo que tenta fechar
                    // o mês. Nos outros seria ruído: a semana diz o que falta
                    // no próprio cabeçalho, e "Escolher dias" é justamente o
                    // modo em que o buraco é escolha dela (CA#1 da US013).
                    if (_mode == SelectionMode.month &&
                        !closable(options) &&
                        missing.isNotEmpty) ...[
                      const SizedBox(height: kSpacingUnit * 3.5),
                      MissingNotice(scope: monthName(_month), missing: missing),
                    ],
                    if (unsent > 0) ...[
                      const SizedBox(height: kSpacingUnit * 3.5),
                      Notice(
                        icon: Icons.upload_outlined,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: kSpacingUnit * 2,
                          children: [
                            Text(unsentNotice(unsent)),
                            OutlinedButton(
                              onPressed: _sendNow,
                              child: const Text(SelectionMessages.sendNow),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (weeks.isEmpty) ...[
                      const SizedBox(height: kSpacingUnit * 3.5),
                      Text(
                        SelectionMessages.empty,
                        style: theme.textTheme.bodyLarge,
                      ),
                    ],
                    for (final entry in weeks) ...[
                      _WeekHeader(
                        label: entry.week.label,
                        selectable: _mode == SelectionMode.week,
                        selected: _chosenWeeks.contains(entry.week.number),
                        missing: missingDays(entry.options).length,
                        onToggle: () =>
                            _toggle(_chosenWeeks, entry.week.number),
                      ),
                      Card(
                        margin: EdgeInsets.zero,
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: [
                            for (var i = 0; i < entry.options.length; i++) ...[
                              if (i > 0)
                                Divider(
                                  height: 1,
                                  color: theme.colorScheme.outline,
                                ),
                              DayOptionRow(
                                option: entry.options[i],
                                selected: chosenDates.contains(
                                  entry.options[i].date,
                                ),
                                readOnly: _mode != SelectionMode.days,
                                onToggle: () =>
                                    _toggle(_chosenDays, entry.options[i].date),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: kSpacingUnit * 3.5),
                    const Notice(
                      icon: Icons.lock_outline,
                      warning: true,
                      child: Text(SelectionMessages.lockWarning),
                    ),
                  ],
                ),
              ),
              _Footer(
                online: _online,
                generating: _generating,
                count: chosen.length,
                onGenerate: canGenerate
                    ? () => _requestGeneration(chosen)
                    : null,
              ),
            ],
          );
        },
      ),
    );
  }
}

/// O cabeçalho de cada semana. No modo "Semana" ele é a caixa de marcar —
/// o desenho da E3 tem um botão "Semana" só, e um botão só não diz **qual**
/// semana; marcar no cabeçalho é onde a pergunta tem resposta.
class _WeekHeader extends StatelessWidget {
  const _WeekHeader({
    required this.label,
    required this.selectable,
    required this.selected,
    required this.missing,
    required this.onToggle,
  });

  final String label;
  final bool selectable;
  final bool selected;
  final int missing;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<MaeColors>()!;
    final closes = missing == 0;
    final style = theme.textTheme.bodySmall?.copyWith(
      fontWeight: FontWeight.w600,
    );

    if (!selectable) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          kSpacingUnit,
          kSpacingUnit * 3.5,
          kSpacingUnit,
          kSpacingUnit * 2,
        ),
        child: Text(label, style: style),
      );
    }

    return Semantics(
      label: closes ? label : '$label, ${weekMissingLabel(missing)}',
      checked: selected,
      enabled: closes,
      child: InkWell(
        onTap: closes ? onToggle : null,
        child: Opacity(
          opacity: closes ? 1 : 0.6,
          child: Container(
            constraints: const BoxConstraints(minHeight: kTouchTarget),
            margin: const EdgeInsets.only(top: kSpacingUnit * 2),
            padding: const EdgeInsets.symmetric(horizontal: kSpacingUnit),
            child: ExcludeSemantics(
              child: Row(
                spacing: kSpacingUnit * 2.5,
                children: [
                  CheckMark(selected: selected, size: 20),
                  Expanded(child: Text(label, style: style)),
                  if (!closes)
                    Text(
                      weekMissingLabel(missing),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: tokens.warning,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// O rodapé: a contagem (ou, sem rede, a explicação da espera) e o botão.
/// Sem rede o aviso toma o lugar da contagem e o botão fica desabilitado —
/// explicar a espera, em vez de deixar o toque falhar em silêncio (catálogo
/// de avisos da E3). Não existe fila de geração (decisão 10 da E3).
class _Footer extends StatelessWidget {
  const _Footer({
    required this.online,
    required this.generating,
    required this.count,
    required this.onGenerate,
  });

  final bool online;
  final bool generating;
  final int count;
  final VoidCallback? onGenerate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: theme.colorScheme.outline)),
      ),
      child: SafeArea(
        minimum: const EdgeInsets.fromLTRB(
          kSpacingUnit * 4,
          kSpacingUnit * 3,
          kSpacingUnit * 4,
          kSpacingUnit * 4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: kSpacingUnit * 2,
          children: [
            if (online)
              Text(
                selectionLabel(count),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              const Notice(
                icon: Icons.wifi_off,
                warning: true,
                child: Text(SelectionMessages.offline),
              ),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onGenerate,
                icon: generating
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.description),
                label: Text(
                  generating
                      ? SelectionMessages.generating
                      : SelectionMessages.generate,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
