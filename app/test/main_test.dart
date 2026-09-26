import 'package:flutter_test/flutter_test.dart';
import 'package:mae/main.dart';
import 'package:mae/theme/theme.dart';

void main() {
  testWidgets('mostra a tela de conferência de tokens', (tester) async {
    await tester.pumpWidget(const MaeApp());

    expect(find.text('MAE — fundação do app'), findsOneWidget);
  });

  test('os tokens semânticos existem em claro e escuro', () {
    expect(maeLightTheme.extension<MaeColors>(), isNotNull);
    expect(maeDarkTheme.extension<MaeColors>(), isNotNull);
  });
}
