import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mae/theme/theme.dart';
import 'package:mae/version/app_installer.dart';
import 'package:mae/version/messages.dart';
import 'package:mae/version/update_notice.dart';
import 'package:mae/version/version_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_release.dart';
import 'fake_version_gateway.dart';

/// O aviso de atualização da tela-casa (issue #113): aparece só abaixo do
/// mínimo, não se dispensa e leva ao instalador.
void main() {
  late FakeVersionGateway versions;
  late FakeReleaseGateway releases;
  late FakeAppInstaller installer;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    versions = FakeVersionGateway(minimum: 1);
    releases = FakeReleaseGateway();
    installer = FakeAppInstaller();
  });

  tearDown(() => installer.close());

  Future<void> pumpNotice(WidgetTester tester, {int? knownMinimum}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appBuildProvider.overrideWithValue((
            current: 3,
            knownMinimum: knownMinimum,
          )),
          versionGatewayProvider.overrideWithValue(versions),
          releaseGatewayProvider.overrideWithValue(releases),
          appInstallerProvider.overrideWithValue(installer),
        ],
        child: MaterialApp(
          theme: maeLightTheme,
          home: const Scaffold(body: UpdateNotice()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('no mínimo, não aparece', (tester) async {
    await pumpNotice(tester);

    expect(versions.calls, 1);
    expect(find.text(updateTitle), findsNothing);
  });

  testWidgets('abaixo do mínimo, aparece ao abrir, sem botão de fechar', (
    tester,
  ) async {
    versions.minimum = 4;
    await pumpNotice(tester);

    expect(find.text(updateTitle), findsOneWidget);
    expect(find.text(updateBody), findsOneWidget);
    expect(find.byType(IconButton), findsNothing);
  });

  testWidgets('sem rede, aparece pelo último mínimo conhecido', (tester) async {
    versions.error = Exception('sem rede');
    await pumpNotice(tester, knownMinimum: 4);

    expect(find.text(updateTitle), findsOneWidget);
  });

  testWidgets('Atualizar baixa mostrando quanto e chama o instalador', (
    tester,
  ) async {
    versions.minimum = 4;
    await pumpNotice(tester);

    await tester.tap(find.text(updateAction));
    await tester.pump();
    expect(installer.installed?.name, '0.2.0');

    installer.emit(const InstallProgress(InstallStep.downloading, 40));
    await tester.pump();
    expect(find.text('Baixando… 40%'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    // Enquanto baixa, o botão não começa outro download.
    final button = tester.widget<ButtonStyleButton>(
      find.ancestor(
        of: find.text(updateAction),
        matching: find.bySubtype<ButtonStyleButton>(),
      ),
    );
    expect(button.onPressed, isNull);

    installer.emit(const InstallProgress(InstallStep.installing));
    await tester.pump();
    expect(find.text(updateInstalling), findsOneWidget);
  });

  testWidgets('sem internet para baixar, diz o que fazer', (tester) async {
    versions.minimum = 4;
    releases.error = Exception('sem rede');
    await pumpNotice(tester);

    await tester.tap(find.text(updateAction));
    await tester.pumpAndSettle();

    expect(find.text(updateDownloadFailed), findsOneWidget);
  });
}
