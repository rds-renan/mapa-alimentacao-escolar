import 'package:flutter/material.dart';

import '../theme/theme.dart';
import 'messages.dart';

/// O dia não letivo (US006) — a versão em Flutter de
/// `web/src/day/non-school-day-card.tsx`.
///
/// Fica no alto da tela do registro: conselho de classe, feriado e recesso
/// são dias do mapa como os outros, só que com uma observação no lugar das
/// refeições. Marcar recolhe o resto da tela e deixa só o motivo — um dia é
/// letivo ou não letivo, nunca os dois (RN#1).
///
/// A observação é o que falta para o dia poder subir, e a linha embaixo do
/// campo diz isso enquanto ela não escreveu — não é acusação de campo vazio:
/// o que já estava digitado continua guardado, e o dia sobe assim que o
/// motivo existir.
class NonSchoolDayCard extends StatelessWidget {
  const NonSchoolDayCard({
    super.key,
    required this.nonSchoolDay,
    required this.note,
    required this.readOnly,
    required this.onToggle,
    required this.onNoteChange,
  });

  final bool nonSchoolDay;
  final String? note;
  final bool readOnly;
  final void Function(bool nonSchoolDay) onToggle;
  final void Function(String note) onNoteChange;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final missing = nonSchoolDay && (note == null || note!.trim().isEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: kSpacingUnit * 3,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(kSpacingUnit * 3.5),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: kSpacingUnit,
                    children: [
                      Text(
                        DayMessages.nonSchoolDayTitle,
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        DayMessages.nonSchoolDayHint,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: nonSchoolDay,
                  onChanged: readOnly ? null : onToggle,
                ),
              ],
            ),
          ),
        ),

        if (nonSchoolDay)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(kSpacingUnit * 3.5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: kSpacingUnit * 2,
                children: [
                  Text(DayMessages.noteLabel, style: theme.textTheme.bodyLarge),
                  _NoteField(
                    note: note ?? '',
                    readOnly: readOnly,
                    onChanged: onNoteChange,
                  ),
                  if (missing)
                    Text(
                      DayMessages.noteMissing,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// O campo em si, com o seu próprio controlador — recriá-lo a cada
/// reconstrução do cartão (o autosave reconstrói a tela inteira a cada
/// tecla) empurraria o cursor para o fim a cada letra digitada no meio do
/// texto.
class _NoteField extends StatefulWidget {
  const _NoteField({
    required this.note,
    required this.readOnly,
    required this.onChanged,
  });

  final String note;
  final bool readOnly;
  final void Function(String note) onChanged;

  @override
  State<_NoteField> createState() => _NoteFieldState();
}

class _NoteFieldState extends State<_NoteField> {
  late final _controller = TextEditingController(text: widget.note);

  @override
  void didUpdateWidget(_NoteField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Só reescreve quando o valor vem de fora (a devolução do dia não
    // letivo, CA#3 da US006): o eco do que ela mesma digitou já bate com o
    // controlador, e sobrescrever aqui empurraria o cursor.
    if (widget.note != _controller.text) _controller.text = widget.note;
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
      minLines: 4,
      maxLines: 4,
      decoration: const InputDecoration(hintText: DayMessages.notePlaceholder),
      onChanged: widget.onChanged,
    );
  }
}
