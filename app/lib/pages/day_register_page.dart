import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';
import '../day/food_item_list.dart';
import '../day/food_item_sheet.dart';
import '../day/meal_card.dart';
import '../day/meals_served_card.dart';
import '../day/menu_change_page.dart';
import '../day/messages.dart';
import '../day/non_school_day_card.dart';
import '../day/register.dart';
import '../local/day.dart';
import '../local/day_repository.dart';
import '../local/local_providers.dart';
import '../local/sync_engine.dart';
import '../month/month.dart' show mealOrder;
import '../theme/theme.dart';
import '../widgets/conflict_notice.dart';
import '../widgets/sync_banner.dart';

/// O registro do dia (issues #105 e #106) — a tela central do produto
/// (US001, com a US002 a US007 dentro dela). É a versão em Flutter de
/// `web/src/pages/DayRegister.tsx`.
///
/// Não há botão de salvar (decisão 3 da E3): cada tecla vira rascunho no
/// aparelho na hora — [SyncEngine.save] —, e quem leva ao servidor é a fila
/// da issue #103. Ao contrário da web, não há setas de dia anterior/próximo
/// dia no cabeçalho: no aplicativo quem volta à visão do mês é o botão do
/// aparelho (CA#5), e o `AppBar` já lhe dá a seta equivalente de graça.
class DayRegisterPage extends ConsumerStatefulWidget {
  const DayRegisterPage({super.key, required this.mapDate});

  static const path = '/dia/:mapDate';

  static String pathFor(String mapDate) => '/dia/$mapDate';

  final String mapDate;

  @override
  ConsumerState<DayRegisterPage> createState() => _DayRegisterPageState();
}

class _DayRegisterPageState extends ConsumerState<DayRegisterPage> {
  SyncEngine? _engine;

  DayRepository? _repository;
  Stream<ConfirmedDay?>? _dayStream;

  /// O rascunho local, ainda não confirmado (issue #103). Nulo quer dizer
  /// "sem rascunho" — e aí quem tem o dia é o banco já convergido, lido por
  /// [DayRepository.watchDay].
  DayPayload? _draft;
  bool _draftLoaded = false;

  /// Qual cartão já foi aberto. A escolha é uma vez só, ao abrir a tela: se
  /// recalculada a cada tecla, o cartão se fecharia sozinho na hora em que a
  /// refeição ficasse pronta, no meio da digitação dela.
  String? _openMeal;
  bool _openMealChosen = false;

  /// O que o dia tinha antes de ela marcar "dia não letivo" — desmarcar
  /// devolve (CA#3 da US006).
  SchoolDayContent? _preserved;

  /// O dia que está na tela, atualizado já no gesto — e não só no próximo
  /// `build` — para dois toques seguidos no stepper não partirem do mesmo
  /// dia velho.
  DayPayload? _shown;

  /// O mesmo dia, para a tela 3a, que é outra rota e não se reconstrói com
  /// esta: cada tecla dela passa por [_change] e volta por aqui.
  final _live = ValueNotifier<DayPayload?>(null);

  String? _profileId;

  /// A última data de conflito já tratada (recarregada), para não relê-la a
  /// cada notificação da fila enquanto ela continuar visível.
  String? _handledConflictAt;

  void _attachEngine(SyncEngine engine) {
    if (identical(_engine, engine)) return;
    _engine?.stateListenable.removeListener(_onSyncChange);
    _engine = engine;
    engine.stateListenable.addListener(_onSyncChange);
    unawaited(_loadDraft());
  }

  void _ensureDayStream(DayRepository repository) {
    if (identical(_repository, repository)) return;
    _repository = repository;
    _dayStream = repository.watchDay(widget.mapDate);
  }

  Future<void> _loadDraft() async {
    final engine = _engine;
    if (engine == null) return;

    final stored = await engine.load(widget.mapDate);
    if (!mounted || !identical(_engine, engine)) return;
    setState(() {
      _draft = stored;
      _draftLoaded = true;
    });
    if (stored != null) {
      _shown = stored;
      _live.value = stored;
    }
  }

  /// A convergência nunca se resolve em silêncio (CA#3 da US011): perdido o
  /// conflito, o rascunho some do aparelho, e é preciso reler o que ficou —
  /// senão a tela continuaria com o texto que perdeu.
  void _onSyncChange() {
    final engine = _engine;
    if (engine == null) return;

    final conflicts = engine.state.conflicts.where(
      (one) => one.mapDate == widget.mapDate,
    );
    final conflict = conflicts.isEmpty ? null : conflicts.first;

    if (conflict != null && conflict.updatedAt != _handledConflictAt) {
      _handledConflictAt = conflict.updatedAt;
      unawaited(_loadDraft());
    }

    setState(() {});
  }

  @override
  void dispose() {
    _engine?.stateListenable.removeListener(_onSyncChange);
    _live.dispose();
    super.dispose();
  }

  void _change(DayPayload day) {
    final touched = touch(day);
    _shown = touched;
    _live.value = touched;
    setState(() => _draft = touched);
    unawaited(_engine!.save(touched));
  }

  /// O que os steppers de uma lista fazem. O mesmo trio serve às duas listas
  /// da refeição — os gêneros dela e os da troca —, e é o [list] que diz
  /// qual.
  FoodItemActions _foodItemActions(String type, FoodItemList list) {
    return FoodItemActions(
      add: () => unawaited(_addFoodItem(type, list)),
      step: (key, delta) =>
          _change(stepFoodItemQuantity(_shown!, type, list, key, delta)),
      setQuantity: (key, quantity) =>
          _change(setFoodItemQuantity(_shown!, type, list, key, quantity)),
    );
  }

  /// Abre a folha 3b e põe o gênero escolhido na lista. Aberta de dentro da
  /// tela 3a, a folha sobe por cima dela: as duas estão no mesmo
  /// `Navigator`.
  Future<void> _addFoodItem(String type, FoodItemList list) async {
    final day = _shown;
    final profileId = _profileId;
    if (day == null || profileId == null) return;

    final choice = await showFoodItemSheet(
      context,
      type: type,
      mapDate: widget.mapDate,
      chosen: [
        for (final item in foodItemsOf(mealOf(day, type), list))
          foodItemKey(item.name),
      ],
      catalog: ref.read(catalogRepositoryProvider(profileId)),
    );
    if (choice == null || !mounted) return;

    _change(addFoodItem(_shown!, type, list, choice));
  }

  /// A tela 3a. A alteração como estava ao abrir é o que o "Cancelar"
  /// devolve — sem isso ele não teria como desfazer, porque o que ela digita
  /// lá já foi para o aparelho na hora.
  Future<void> _openMenuChange(String type, {required bool readOnly}) async {
    final day = _shown;
    if (day == null) return;

    final before = mealOf(day, type)?.menuChange;
    _live.value = day;

    final exit = await showMenuChangePage(
      context,
      type: type,
      mapDate: widget.mapDate,
      day: _live,
      readOnly: readOnly,
      actions: _foodItemActions(type, FoodItemList.menuChange),
      onReasonChange: (reason) =>
          _change(setMenuChangeReason(_shown!, type, reason)),
    );
    if (!mounted) return;

    final now = _shown!;
    final current = mealOf(now, type)?.menuChange;

    switch (exit) {
      case MenuChangeExit.cancel:
        if (!identical(current, before)) {
          _change(setMenuChange(now, type, before));
        }
      case MenuChangeExit.remove:
        _change(setMenuChange(now, type, null));
      // Confirmar é fechar — o que está escrito já está gravado. O que ele
      // decide é o que fica: a alteração aberta e fechada sem nada dentro
      // sai do dia, em vez de virar um registro vazio que o servidor
      // recusaria para sempre.
      case null:
        if (current != null && menuChangeIsEmpty(current)) {
          _change(setMenuChange(now, type, null));
        }
    }
  }

  void _toggleNonSchoolDay(DayPayload day, bool on) {
    if (on) _preserved = schoolDayContent(day);
    _change(setNonSchoolDay(day, on, restored: _preserved ?? nothingToRestore));
  }

  void _chooseOpenMealOnce(DayPayload day) {
    if (_openMealChosen) return;
    _openMealChosen = true;
    final first = firstUnfinishedMeal(day);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _openMeal = first);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final profile = auth.profile;

    if (profile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    _profileId = profile.id;
    _attachEngine(ref.watch(syncEngineProvider(profile.id)));
    _ensureDayStream(ref.watch(dayRepositoryProvider(profile.id)));
    final engine = _engine!;

    return StreamBuilder<ConfirmedDay?>(
      stream: _dayStream,
      builder: (context, snapshot) {
        final confirmed = snapshot.data;
        final locked = confirmed?.locked ?? false;

        DayPayload? day;
        if (_draft != null) {
          day = _draft;
        } else if (confirmed != null) {
          day = confirmed.day;
        } else if (_draftLoaded &&
            snapshot.connectionState != ConnectionState.waiting) {
          day = emptyDay(widget.mapDate);
        }
        if (day != null && !identical(day, _shown)) _shown = day;

        return Scaffold(
          appBar: AppBar(title: Text(dayTitle(widget.mapDate))),
          body: Column(
            children: [
              SyncBanner(status: engine.state.days[widget.mapDate]),
              ConflictNotice(
                conflicts: engine.state.conflicts
                    .where((one) => one.mapDate == widget.mapDate)
                    .toList(),
                onDismiss: engine.dismissConflict,
              ),
              if (locked) const _LockedBanner(),
              Expanded(
                child: day == null
                    ? Center(
                        child: Text(
                          DayMessages.loading,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      )
                    : _DayForm(
                        day: day,
                        readOnly: locked,
                        openMeal: _openMeal,
                        onMealOpenChange: (type, open) =>
                            setState(() => _openMeal = open ? type : null),
                        onToggleNonSchoolDay: (on) =>
                            _toggleNonSchoolDay(day!, on),
                        onNoteChange: (note) => _change(setNote(day!, note)),
                        onDescriptionChange: (type, description) =>
                            _change(setDescription(day!, type, description)),
                        onAcceptanceChange: (type, acceptance) =>
                            _change(setAcceptance(day!, type, acceptance)),
                        onMealsServedChange: (value) =>
                            _change(setMealsServed(day!, value)),
                        foodItemActions: (type) =>
                            _foodItemActions(type, FoodItemList.meal),
                        onOpenMenuChange: (type) =>
                            _openMenuChange(type, readOnly: locked),
                        onReady: () => _chooseOpenMealOnce(day!),
                      ),
              ),
            ],
          ),
          bottomNavigationBar: day == null
              ? null
              : SafeArea(
                  minimum: const EdgeInsets.fromLTRB(
                    kSpacingUnit * 4,
                    kSpacingUnit * 3,
                    kSpacingUnit * 4,
                    kSpacingUnit * 3,
                  ),
                  child: _AutosaveFooter(progress: dayProgress(day)),
                ),
        );
      },
    );
  }
}

class _LockedBanner extends StatelessWidget {
  const _LockedBanner();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border(bottom: BorderSide(color: theme.colorScheme.outline)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: kSpacingUnit * 4,
          vertical: kSpacingUnit * 2.5,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.lock,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: kSpacingUnit * 2),
            Expanded(
              child: Text(
                DayMessages.locked,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayForm extends StatelessWidget {
  const _DayForm({
    required this.day,
    required this.readOnly,
    required this.openMeal,
    required this.onMealOpenChange,
    required this.onToggleNonSchoolDay,
    required this.onNoteChange,
    required this.onDescriptionChange,
    required this.onAcceptanceChange,
    required this.onMealsServedChange,
    required this.foodItemActions,
    required this.onOpenMenuChange,
    required this.onReady,
  });

  final DayPayload day;
  final bool readOnly;
  final String? openMeal;
  final void Function(String type, bool open) onMealOpenChange;
  final void Function(bool on) onToggleNonSchoolDay;
  final void Function(String note) onNoteChange;
  final void Function(String type, String description) onDescriptionChange;
  final void Function(String type, String acceptance) onAcceptanceChange;
  final void Function(int? value) onMealsServedChange;
  final FoodItemActions Function(String type) foodItemActions;
  final void Function(String type) onOpenMenuChange;
  final VoidCallback onReady;

  @override
  Widget build(BuildContext context) {
    onReady();

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        kSpacingUnit * 4,
        kSpacingUnit * 3.5,
        kSpacingUnit * 4,
        kSpacingUnit * 6,
      ),
      children: [
        NonSchoolDayCard(
          nonSchoolDay: day.nonSchoolDay,
          note: day.note,
          readOnly: readOnly,
          onToggle: onToggleNonSchoolDay,
          onNoteChange: onNoteChange,
        ),

        if (!day.nonSchoolDay) ...[
          for (final type in mealOrder) ...[
            const SizedBox(height: kSpacingUnit * 3),
            MealCard(
              type: type,
              meal: mealOf(day, type),
              open: openMeal == type,
              readOnly: readOnly,
              onOpenChange: (open) => onMealOpenChange(type, open),
              onDescriptionChange: (description) =>
                  onDescriptionChange(type, description),
              onAcceptanceChange: (acceptance) =>
                  onAcceptanceChange(type, acceptance),
              foodItems: foodItemActions(type),
              onOpenMenuChange: () => onOpenMenuChange(type),
            ),
          ],
          const SizedBox(height: kSpacingUnit * 3),
          MealsServedCard(
            value: day.mealsServed,
            readOnly: readOnly,
            onChange: onMealsServedChange,
          ),
        ],
      ],
    );
  }
}

class _AutosaveFooter extends StatelessWidget {
  const _AutosaveFooter({required this.progress});

  final DayProgress progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: kSpacingUnit * 2,
      children: [
        Text(
          DayMessages.autosave,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Semantics(
          label: DayMessages.progress,
          value: '${progress.done} de ${progress.total}',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress.total == 0 ? 0 : progress.done / progress.total,
              minHeight: 6,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
          ),
        ),
      ],
    );
  }
}
