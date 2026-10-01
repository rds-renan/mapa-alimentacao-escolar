import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mae/theme/theme_preference.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A preferência de tema (US024, issue #111): o que se guarda no aparelho e
/// como o aplicativo a lê.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('ThemePreference.parse', () {
    test('lê as três escolhas', () {
      expect(ThemePreference.parse('light'), ThemePreference.light);
      expect(ThemePreference.parse('dark'), ThemePreference.dark);
      expect(ThemePreference.parse('system'), ThemePreference.system);
    });

    test('nada guardado ou lixo voltam a "Sistema"', () {
      expect(ThemePreference.parse(null), ThemePreference.system);
      expect(ThemePreference.parse('roxo'), ThemePreference.system);
    });

    test('cada escolha vira o ThemeMode do Flutter', () {
      expect(ThemePreference.light.mode, ThemeMode.light);
      expect(ThemePreference.dark.mode, ThemeMode.dark);
      expect(ThemePreference.system.mode, ThemeMode.system);
    });
  });

  group('loadThemePreference', () {
    test('aparelho sem nada guardado nasce em "Sistema"', () async {
      expect(await loadThemePreference(), ThemePreference.system);
    });

    test('lê o que foi guardado na sessão anterior (CA#1)', () async {
      SharedPreferences.setMockInitialValues({themePreferenceKey: 'dark'});

      expect(await loadThemePreference(), ThemePreference.dark);
    });

    test('lixo no armazenamento volta ao padrão, sem quebrar', () async {
      SharedPreferences.setMockInitialValues({themePreferenceKey: 'lixo'});

      expect(await loadThemePreference(), ThemePreference.system);
    });
  });

  group('ThemePreferenceController', () {
    test('começa pela escolha lida antes do primeiro quadro', () {
      final container = ProviderContainer(
        overrides: [
          initialThemePreferenceProvider.overrideWithValue(
            ThemePreference.dark,
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(themePreferenceProvider), ThemePreference.dark);
    });

    test('escolher vale na hora e persiste entre sessões', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container
          .read(themePreferenceProvider.notifier)
          .choose(ThemePreference.dark);

      expect(container.read(themePreferenceProvider), ThemePreference.dark);
      // Outra sessão do aplicativo lê do aparelho.
      expect(await loadThemePreference(), ThemePreference.dark);
    });

    test('voltar para "Sistema" também é guardado', () async {
      SharedPreferences.setMockInitialValues({themePreferenceKey: 'dark'});
      final container = ProviderContainer(
        overrides: [
          initialThemePreferenceProvider.overrideWithValue(
            ThemePreference.dark,
          ),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(themePreferenceProvider.notifier)
          .choose(ThemePreference.system);

      expect(await loadThemePreference(), ThemePreference.system);
    });
  });
}
