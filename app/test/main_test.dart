import 'package:flutter_test/flutter_test.dart';
import 'package:mae/theme/theme.dart';

void main() {
  test('os tokens semânticos existem em claro e escuro', () {
    expect(maeLightTheme.extension<MaeColors>(), isNotNull);
    expect(maeDarkTheme.extension<MaeColors>(), isNotNull);
  });
}
