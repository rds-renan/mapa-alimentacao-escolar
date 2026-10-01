import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A escolha de tema (US024, issue #111): claro, escuro ou o do aparelho.
///
/// Três opções e não uma chave, pelo mesmo motivo da web: "Sistema" é o
/// padrão de quem nunca abriu o controle, e o celular dela já escurece
/// sozinho ao anoitecer — a hora em que o mapa costuma ser preenchido.
enum ThemePreference {
  light('Claro', ThemeMode.light),
  dark('Escuro', ThemeMode.dark),
  system('Sistema', ThemeMode.system);

  const ThemePreference(this.label, this.mode);

  final String label;
  final ThemeMode mode;

  /// Valor guardado. `MainActivity.kt` lê `light` e `dark` direto do arquivo
  /// do `shared_preferences` para vestir a abertura — mudar aqui é mudar lá.
  String get stored => name;

  /// Lixo ou ausência voltam ao padrão: uma preferência de cor não pode
  /// derrubar o aplicativo.
  static ThemePreference parse(String? value) =>
      values.firstWhere((option) => option.name == value, orElse: () => system);
}

/// A chave no aparelho — uma só, porque a escolha é do aparelho e não da
/// conta: duas merendeiras no mesmo celular não disputam a preferência, e
/// sair não a apaga (decisão 12 da E4).
const themePreferenceKey = 'mae.theme';

/// Lê a escolha guardada. Armazenamento que falha vale "Sistema".
Future<ThemePreference> loadThemePreference() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return ThemePreference.parse(prefs.getString(themePreferenceKey));
  } catch (_) {
    return ThemePreference.system;
  }
}

/// A escolha lida **antes** do primeiro quadro (`main.dart` a sobrescreve).
/// Sem isso o aplicativo abriria no tema do aparelho e trocaria um instante
/// depois — o lampejo claro que a issue pede para não existir.
final initialThemePreferenceProvider = Provider<ThemePreference>(
  (ref) => ThemePreference.system,
);

final themePreferenceProvider =
    NotifierProvider<ThemePreferenceController, ThemePreference>(
      ThemePreferenceController.new,
    );

class ThemePreferenceController extends Notifier<ThemePreference> {
  @override
  ThemePreference build() => ref.read(initialThemePreferenceProvider);

  /// Vale na hora; a gravação vem depois e, se falhar, vale até fechar o
  /// aplicativo.
  Future<void> choose(ThemePreference preference) async {
    state = preference;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(themePreferenceKey, preference.stored);
    } catch (_) {
      // Ver acima.
    }
  }
}
