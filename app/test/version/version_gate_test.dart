import 'package:flutter_test/flutter_test.dart';
import 'package:mae/version/version_gate.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_version_gateway.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('no mínimo ou acima, não trava', () async {
    final gate = VersionGate(
      currentBuild: 3,
      gateway: FakeVersionGateway(minimum: 3),
    );
    addTearDown(gate.dispose);

    expect(await gate.check(), isFalse);
    expect(gate.minimumBuild, 3);
  });

  test(
    'abaixo do mínimo trava, avisa quem escuta e guarda no aparelho',
    () async {
      final gate = VersionGate(
        currentBuild: 3,
        gateway: FakeVersionGateway(minimum: 4),
      );
      addTearDown(gate.dispose);
      var notified = 0;
      gate.addListener(() => notified++);

      expect(await gate.check(), isTrue);
      expect(notified, 1);

      // A gravação no aparelho vem depois, sem segurar a conferência.
      await pumpEventQueue();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt(minimumBuildKey), 4);
    },
  );

  test('sem rede, vale o último mínimo conhecido', () async {
    final gate = VersionGate(
      currentBuild: 3,
      knownMinimum: 4,
      gateway: FakeVersionGateway()..error = Exception('sem rede'),
    );
    addTearDown(gate.dispose);

    expect(gate.outdated, isTrue);
    expect(await gate.check(), isTrue);
  });

  test('sem rede e sem mínimo conhecido, segue — a recusa do banco continua '
      'de guarda', () async {
    final gate = VersionGate(
      currentBuild: 3,
      gateway: FakeVersionGateway()..error = Exception('sem rede'),
    );
    addTearDown(gate.dispose);

    expect(await gate.check(), isFalse);
  });

  test('o mínimo que desceu destrava', () async {
    final gate = VersionGate(
      currentBuild: 3,
      knownMinimum: 4,
      gateway: FakeVersionGateway(minimum: 2),
    );
    addTearDown(gate.dispose);

    expect(await gate.check(), isFalse);
  });

  test(
    'a recusa do banco trava na hora, antes de saber o mínimo exato',
    () async {
      final versions = FakeVersionGateway()..error = Exception('sem rede');
      final gate = VersionGate(currentBuild: 3, gateway: versions);
      addTearDown(gate.dispose);

      gate.reportRejected();

      expect(gate.outdated, isTrue);
      expect(versions.calls, 1);
    },
  );

  test('duas conferências ao mesmo tempo fazem uma pergunta só', () async {
    final versions = FakeVersionGateway(minimum: 1);
    final gate = VersionGate(currentBuild: 3, gateway: versions);
    addTearDown(gate.dispose);

    await Future.wait([gate.check(), gate.check()]);

    expect(versions.calls, 1);
  });
}
