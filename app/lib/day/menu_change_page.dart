import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../local/day.dart';
import '../theme/theme.dart';
import 'food_item_list.dart';
import 'messages.dart';
import 'register.dart';

/// Como a tela 3a foi fechada. Nulo — o botão voltar do Android, o X, o
/// "Confirmar" — é confirmar: o que está escrito já está gravado, e desfazer
/// por acidente seria a surpresa.
enum MenuChangeExit { cancel, remove }

/// Abre a alteração do cardápio de uma refeição por cima do registro.
///
/// [day] é o dia vivo: cada tecla desta tela passa pelo registro, que grava
/// e devolve o dia novo por aqui — a tela não guarda cópia nenhuma.
Future<MenuChangeExit?> showMenuChangePage(
  BuildContext context, {
  required String type,
  required String mapDate,
  required ValueListenable<DayPayload?> day,
  required bool readOnly,
  required FoodItemActions actions,
  required void Function(String reason) onReasonChange,
}) {
  return Navigator.of(context).push<MenuChangeExit>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (context) => ValueListenableBuilder<DayPayload?>(
        valueListenable: day,
        builder: (context, value, _) => MenuChangePage(
          type: type,
          mapDate: mapDate,
          change: value == null ? null : mealOf(value, type)?.menuChange,
          readOnly: readOnly,
          actions: actions,
          onReasonChange: onReasonChange,
        ),
      ),
    ),
  );
}

/// A alteração do cardápio — tela 3a (US002), a versão em Flutter de
/// `web/src/day/menu-change-dialog.tsx` (issue #106).
///
/// O que ela registra aqui é **o que entrou no lugar**, e só: os gêneros com
/// as suas quantidades e o motivo em texto livre. Não há campo para o item
/// que saiu, porque o formulário oficial não o pede em lugar nenhum — e a
/// refeição lá atrás continua sendo o cardápio previsto, que é o que dá
/// sentido à justificativa (decisão 8 da E3, decisão 7 da E4). É por isso que
/// o aviso do alto existe.
///
/// Há no máximo uma alteração por refeição (RN#2 da US002): a justificativa
/// cobre a modificação inteira e os gêneros são uma lista, então duas trocas
/// no mesmo almoço são um registro só.
///
/// Os botões do rodapé não são um "salvar" — não existe salvar neste
/// aplicativo (decisão 3 da E3). Cada tecla daqui já está no aparelho antes
/// de ela confirmar; o que os dois botões decidem é se a alteração **fica**.
class MenuChangePage extends StatelessWidget {
  const MenuChangePage({
    super.key,
    required this.type,
    required this.mapDate,
    required this.change,
    required this.readOnly,
    required this.actions,
    required this.onReasonChange,
  });

  final String type;
  final String mapDate;
  final MenuChangePayload? change;
  final bool readOnly;
  final FoodItemActions actions;
  final void Function(String reason) onReasonChange;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<MaeColors>()!;
    final items = change?.foodItems ?? const <FoodItemPayload>[];
    final reason = change?.reason ?? '';
    final started = !menuChangeIsEmpty(change);
    final missingItems = started && items.isEmpty;
    final missingReason = started && reason.trim().isEmpty;
    final hintStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    /// A sugestão preenche o campo vazio e troca a sugestão anterior — é o
    /// que "reduzir digitação" quer dizer (RNF#1 da US002). O que ela
    /// escreveu com as próprias palavras não é apagado por um toque: aí a
    /// sugestão entra depois do que já está lá.
    void suggest(String text) {
      final current = reason.trim();
      final preset = MenuChangeMessages.reasonSuggestions.contains(current);
      onReasonChange(current.isEmpty || preset ? text : '$current $text');
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(MenuChangeMessages.title),
            Text(
              mealSubtitle(type, mapDate),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: MenuChangeMessages.close,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(kSpacingUnit * 4),
        children: [
          _Note(
            icon: Icons.info_outline,
            text: MenuChangeMessages.notice(type),
            background: tokens.accent,
            border: tokens.accentBorder,
            foreground: tokens.accentForeground,
          ),
          const SizedBox(height: kSpacingUnit * 4),
          Text(
            MenuChangeMessages.itemsLabel,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: kSpacingUnit * 2),
          FoodItemListView(items: items, readOnly: readOnly, actions: actions),
          if (missingItems) ...[
            const SizedBox(height: kSpacingUnit * 2),
            Text(MenuChangeMessages.itemsMissing, style: hintStyle),
          ],
          const SizedBox(height: kSpacingUnit * 4),
          Text(
            MenuChangeMessages.reasonLabel,
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: kSpacingUnit * 2),
          _ReasonField(
            reason: reason,
            readOnly: readOnly,
            onChanged: onReasonChange,
          ),
          if (missingReason) ...[
            const SizedBox(height: kSpacingUnit * 2),
            Text(MenuChangeMessages.reasonMissing, style: hintStyle),
          ],
          if (!readOnly) ...[
            const SizedBox(height: kSpacingUnit * 2),
            Wrap(
              spacing: kSpacingUnit * 2,
              runSpacing: kSpacingUnit * 2,
              children: [
                for (final one in MenuChangeMessages.reasonSuggestions)
                  ActionChip(label: Text(one), onPressed: () => suggest(one)),
              ],
            ),
          ],
          const SizedBox(height: kSpacingUnit * 4),
          _Note(
            icon: Icons.info_outline,
            text: MenuChangeMessages.document,
            background: theme.colorScheme.surfaceContainerHighest,
            border: theme.colorScheme.surfaceContainerHighest,
            foreground: theme.colorScheme.onSurfaceVariant,
          ),
          // A saída de quem registrou uma alteração por engano. Não está no
          // desenho da E3 e entrou na web pelo mesmo motivo: sem ela, o único
          // caminho de volta seria tirar os gêneros um a um e apagar o
          // motivo — três gestos e nenhuma pista de que o conjunto deles é
          // "não houve troca".
          if (started && !readOnly) ...[
            const SizedBox(height: kSpacingUnit * 4),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                ),
                onPressed: () =>
                    Navigator.of(context).pop(MenuChangeExit.remove),
                child: const Text(MenuChangeMessages.remove),
              ),
            ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(
          kSpacingUnit * 4,
          kSpacingUnit * 3,
          kSpacingUnit * 4,
          kSpacingUnit * 3,
        ),
        child: Row(
          spacing: kSpacingUnit * 2.5,
          children: [
            if (!readOnly)
              Expanded(
                child: OutlinedButton(
                  onPressed: () =>
                      Navigator.of(context).pop(MenuChangeExit.cancel),
                  child: const Text(MenuChangeMessages.cancel),
                ),
              ),
            Expanded(
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  readOnly
                      ? MenuChangeMessages.done
                      : MenuChangeMessages.confirm,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({
    required this.icon,
    required this.text,
    required this.background,
    required this.border,
    required this.foreground,
  });

  final IconData icon;
  final String text;
  final Color background;
  final Color border;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: kSpacingUnit * 3.5,
          vertical: kSpacingUnit * 3,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: kSpacingUnit * 2,
          children: [
            Icon(icon, size: 16, color: foreground),
            Expanded(
              child: Text(
                text,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: foreground),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// O motivo. Guarda o próprio controlador, como o cardápio previsto: só
/// reescreve quando o texto vem de fora (uma sugestão tocada), senão o
/// cursor pularia para o fim a cada letra.
class _ReasonField extends StatefulWidget {
  const _ReasonField({
    required this.reason,
    required this.readOnly,
    required this.onChanged,
  });

  final String reason;
  final bool readOnly;
  final void Function(String reason) onChanged;

  @override
  State<_ReasonField> createState() => _ReasonFieldState();
}

class _ReasonFieldState extends State<_ReasonField> {
  late final _controller = TextEditingController(text: widget.reason);

  @override
  void didUpdateWidget(_ReasonField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reason != _controller.text) _controller.text = widget.reason;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      enabled: !widget.readOnly,
      minLines: 3,
      maxLines: 5,
      textCapitalization: TextCapitalization.sentences,
      decoration: const InputDecoration(
        hintText: MenuChangeMessages.reasonPlaceholder,
      ),
      onChanged: widget.onChanged,
    );
  }
}
