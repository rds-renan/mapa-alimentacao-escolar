import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mae/theme/theme.dart';

void main() {
  test('os tokens semânticos existem em claro e escuro', () {
    expect(maeLightTheme.extension<MaeColors>(), isNotNull);
    expect(maeDarkTheme.extension<MaeColors>(), isNotNull);
  });

  group('a bolinha do switch desligado', () {
    // Achado no teste manual no aparelho (issue #105): o padrão do Material
    // 3 pinta a bolinha desligada com `colorScheme.outline`, que no tema
    // escuro é a MESMA cor da trilha (`surfaceContainerHighest`) — a
    // bolinha some de vista até o primeiro toque. `switchTheme` em
    // `theme.dart` corrige isso; este teste impede que a correção se perca
    // numa revisão futura do tema.
    void expectVisibleThumb(ThemeData theme) {
      final thumb = theme.switchTheme.thumbColor!.resolve({});
      final track = theme.colorScheme.surfaceContainerHighest;
      expect(thumb, isNotNull);
      expect(thumb, isNot(track));
    }

    test('claro', () => expectVisibleThumb(maeLightTheme));
    test('escuro', () => expectVisibleThumb(maeDarkTheme));
  });
}
