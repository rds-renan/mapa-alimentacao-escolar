import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';
import '../food_items/catalog.dart';
import '../food_items/form.dart';
import '../food_items/messages.dart';
import '../local/app_database.dart';
import '../local/catalog_repository.dart';
import '../local/connectivity_gateway.dart';
import '../local/local_providers.dart';
import '../theme/theme.dart';
import '../widgets/form_message.dart';

/// A manutenção do catálogo de gêneros (US009, tela 4 da E3, issue #107) —
/// a versão em Flutter de `web/src/pages/FoodItems.tsx`.
///
/// **Ler funciona sem rede; alterar exige rede, e a tela diz isso.** A lista
/// é a cópia do catálogo no aparelho (issue #102); abrir a tela pede uma
/// atualização por baixo, que falha calada. Cadastrar, editar, desativar e
/// reativar vão direto ao servidor, sem a fila: a fila existe para o mapa do
/// dia, que é o que não pode se perder — manutenção é tarefa ocasional,
/// feita de propósito (decisão 2 da E6).
///
/// Um cartão só cadastra e edita: tocar uma linha carrega o gênero nele.
class FoodItemsPage extends ConsumerStatefulWidget {
  const FoodItemsPage({super.key});

  static const path = '/generos';

  @override
  ConsumerState<FoodItemsPage> createState() => _FoodItemsPageState();
}

class _FoodItemsPageState extends ConsumerState<FoodItemsPage> {
  final _search = TextEditingController();
  final _name = TextEditingController();
  final _unit = TextEditingController();
  final _nameFocus = FocusNode();
  final _cardKey = GlobalKey();

  CatalogRepository? _catalog;
  Stream<List<FoodItem>>? _items;
  ConnectivityGateway? _connectivity;
  StreamSubscription<bool>? _connectivitySubscription;

  bool _online = true;
  String? _editingId;
  bool _saving = false;
  bool _failed = false;
  bool _inactiveOpen = false;

  @override
  void initState() {
    super.initState();
    for (final controller in [_search, _name, _unit]) {
      controller.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    unawaited(_connectivitySubscription?.cancel());
    _search.dispose();
    _name.dispose();
    _unit.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  void _attach(CatalogRepository catalog, ConnectivityGateway connectivity) {
    if (!identical(_catalog, catalog)) {
      _catalog = catalog;
      _items = catalog.watchFoodItems();
      // Por baixo e sem esperar: a lista já aparece com o que o aparelho
      // tem, e sem rede a atualização só não acontece.
      unawaited(catalog.refresh().catchError((_) {}));
    }

    if (!identical(_connectivity, connectivity)) {
      unawaited(_connectivitySubscription?.cancel());
      _connectivity = connectivity;
      unawaited(
        connectivity.isOnline().then((online) {
          if (mounted && identical(_connectivity, connectivity)) {
            setState(() => _online = online);
          }
        }),
      );
      _connectivitySubscription = connectivity.onChange.listen((online) {
        if (mounted) setState(() => _online = online);
      });
    }
  }

  FoodItemDraft get _draft =>
      FoodItemDraft(id: _editingId, name: _name.text, unit: _unit.text);

  void _load(FoodItem item) {
    _name.text = item.name;
    _unit.text = item.unit;
    setState(() {
      _editingId = item.id;
      _failed = false;
    });

    // A lista fica abaixo do cartão: sem trazê-lo à vista, tocar um gênero
    // lá embaixo pareceria não fazer nada.
    final card = _cardKey.currentContext;
    if (card != null) {
      unawaited(Scrollable.ensureVisible(card, alignment: 0.05));
    }
    _nameFocus.requestFocus();
  }

  void _clear() {
    _name.clear();
    _unit.clear();
    setState(() {
      _editingId = null;
      _failed = false;
    });
  }

  /// Roda uma gravação e, se não passar, deixa o que está no formulário
  /// como está — é só tentar de novo.
  Future<bool> _write(Future<void> Function() action) async {
    setState(() {
      _saving = true;
      _failed = false;
    });
    try {
      await action();
      return true;
    } catch (_) {
      if (mounted) setState(() => _failed = true);
      return false;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _submit(String schoolId) async {
    final draft = _draft;
    final saved = await _write(
      () => _catalog!.save(
        id: draft.id,
        schoolId: schoolId,
        name: draft.name,
        unit: draft.unit,
      ),
    );
    if (saved && mounted) _clear();
  }

  Future<void> _toggle(FoodItem item) async {
    final done = await _write(
      () => _catalog!.setActive(item.id, active: !item.active),
    );
    if (!done || !mounted) return;

    _clear();
    // Depois de desativar, a seção abre sozinha: é para lá que ela vai
    // olhar se tiver sido engano.
    if (item.active) setState(() => _inactiveOpen = true);
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(authControllerProvider).profile;
    // A guarda de rota só deixa chegar aqui com perfil; sem ele não há banco
    // local de quem ler (um por perfil, decisão 6 da E6).
    if (profile == null) return const Scaffold();

    _attach(
      ref.watch(catalogRepositoryProvider(profile.id)),
      ref.watch(connectivityGatewayProvider),
    );

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(CatalogMessages.title),
            Text(
              CatalogMessages.subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      body: StreamBuilder<List<FoodItem>>(
        stream: _items,
        builder: (context, snapshot) {
          final items = snapshot.data ?? const <FoodItem>[];
          final found = sections(items, _search.text);

          return ListView(
            padding: const EdgeInsets.all(kSpacingUnit * 4),
            children: [
              if (!_online) ...[
                const _OfflineNotice(),
                const SizedBox(height: kSpacingUnit * 4),
              ],
              _FormCard(
                key: _cardKey,
                name: _name,
                unit: _unit,
                nameFocus: _nameFocus,
                editing: _editingId == null
                    ? null
                    : items.where((one) => one.id == _editingId).firstOrNull,
                duplicate: duplicateOf(_draft, items),
                warnUnitChange: unitChanged(_draft, items),
                canSave:
                    _online &&
                    !_saving &&
                    canSave(_draft) &&
                    duplicateOf(_draft, items) == null,
                canToggle: _online && !_saving,
                saving: _saving,
                failed: _failed,
                onSuggestion: (unit) => _unit.text = unit,
                onSubmit: () => _submit(profile.schoolId),
                onCancel: _clear,
                onToggle: _toggle,
              ),
              const SizedBox(height: kSpacingUnit * 5),
              TextField(
                controller: _search,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: CatalogMessages.search,
                ),
              ),
              const SizedBox(height: kSpacingUnit * 4),
              Text(
                CatalogMessages.listTitle,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: kSpacingUnit * 2),
              if (items.isEmpty)
                const _Hint(CatalogMessages.empty)
              else if (found.active.isEmpty && found.inactive.isEmpty)
                const _Hint(CatalogMessages.noResults)
              else
                for (final item in found.active)
                  _ItemRow(item: item, onTap: () => _load(item)),
              if (found.inactive.isNotEmpty)
                Theme(
                  data: theme.copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    key: ValueKey('inactive-$_inactiveOpen'),
                    initiallyExpanded: _inactiveOpen,
                    onExpansionChanged: (open) => _inactiveOpen = open,
                    tilePadding: EdgeInsets.zero,
                    title: Text(
                      CatalogMessages.inactiveTitle(found.inactive.length),
                    ),
                    children: [
                      for (final item in found.inactive)
                        _ItemRow(item: item, onTap: () => _load(item)),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _OfflineNotice extends StatelessWidget {
  const _OfflineNotice();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(kSpacingUnit * 3.5),
          child: Row(
            spacing: kSpacingUnit * 3,
            children: [
              const Icon(Icons.wifi_off),
              Expanded(child: Text(CatalogMessages.offline)),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({
    super.key,
    required this.name,
    required this.unit,
    required this.nameFocus,
    required this.editing,
    required this.duplicate,
    required this.warnUnitChange,
    required this.canSave,
    required this.canToggle,
    required this.saving,
    required this.failed,
    required this.onSuggestion,
    required this.onSubmit,
    required this.onCancel,
    required this.onToggle,
  });

  final TextEditingController name;
  final TextEditingController unit;
  final FocusNode nameFocus;

  /// O gênero da lista que está no cartão, ou nulo quando é um novo.
  final FoodItem? editing;
  final FoodItem? duplicate;
  final bool warnUnitChange;
  final bool canSave;
  final bool canToggle;
  final bool saving;
  final bool failed;
  final ValueChanged<String> onSuggestion;
  final VoidCallback onSubmit;
  final VoidCallback onCancel;
  final ValueChanged<FoodItem> onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<MaeColors>()!;
    final item = editing;
    final current = unit.text.trim();

    final submit = FilledButton(
      onPressed: canSave ? onSubmit : null,
      child: Text(
        saving
            ? CatalogMessages.saving
            : item == null
            ? CatalogMessages.add
            : CatalogMessages.save,
      ),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.accent,
        border: Border.all(color: tokens.accentBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(kSpacingUnit * 3.5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: kSpacingUnit * 3,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item == null
                        ? CatalogMessages.newTitle
                        : CatalogMessages.editTitle,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (item != null)
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: CatalogMessages.cancelEdit,
                    onPressed: onCancel,
                  ),
              ],
            ),
            TextField(
              controller: name,
              focusNode: nameFocus,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: CatalogMessages.nameLabel,
                hintText: CatalogMessages.namePlaceholder,
              ),
            ),
            if (duplicate case final same?)
              FormMessage(
                CatalogMessages.duplicate(same.name, active: same.active),
              ),
            TextField(
              controller: unit,
              decoration: const InputDecoration(
                labelText: CatalogMessages.unitLabel,
                hintText: CatalogMessages.unitPlaceholder,
              ),
            ),
            Wrap(
              spacing: kSpacingUnit * 2,
              runSpacing: kSpacingUnit * 2,
              children: [
                for (final suggestion in unitSuggestions)
                  ChoiceChip(
                    label: Text(suggestion),
                    selected: current == suggestion,
                    onSelected: (_) => onSuggestion(suggestion),
                  ),
              ],
            ),
            if (warnUnitChange)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: kSpacingUnit * 2,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  Expanded(
                    child: Text(
                      CatalogMessages.unitChanged,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            if (failed) const FormMessage(CatalogMessages.saveFailed),
            if (item == null)
              submit
            else
              Row(
                spacing: kSpacingUnit * 2.5,
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: canToggle ? () => onToggle(item) : null,
                      child: Text(
                        item.active
                            ? CatalogMessages.deactivate
                            : CatalogMessages.reactivate,
                      ),
                    ),
                  ),
                  Expanded(child: submit),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item, required this.onTap});

  final FoodItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: CatalogMessages.edit(item.name),
      button: true,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Row(
            spacing: kSpacingUnit * 3,
            children: [
              Expanded(
                child: Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Chip(
                label: Text(item.unit),
                visualDensity: VisualDensity.compact,
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: kSpacingUnit * 4),
      child: Text(
        text,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
