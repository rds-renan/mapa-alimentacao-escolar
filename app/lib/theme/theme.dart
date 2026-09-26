/// Tema do MAE — tokens da decisão 6 da E3
/// (`docs/03-ux/decisoes-de-design.md`), os mesmos que `web/src/index.css`
/// leva ao shadcn/ui. O que atravessa as duas plataformas é o valor, não o
/// componente: aqui eles viram `ThemeData`, em claro e escuro, e o que o
/// `ThemeData` não tem campo para guardar (os tons "subtle"/"border" dos
/// estados semânticos) entra em [MaeColors], uma extensão de tema própria.
library;

import 'package:flutter/material.dart';

// Espaçamento: grade de 4 px, como as telas foram desenhadas.
const double kSpacingUnit = 4;

// Raios: 10 px é o raio dominante das telas; os demais derivam dele.
const double kRadiusSm = 6;
const double kRadiusMd = 8; // botão, campo
const double kRadiusLg = 10;
const double kRadiusXl = 12; // cartão
const double kRadius2xl = 16;

// Alvo de toque mínimo.
const double kTouchTarget = 44;

/// Os tokens semânticos sem campo correspondente no [ColorScheme] do
/// Material 3 — os tons "subtle" (fundo) e "border" de cada estado, o
/// destaque suave que a web chama de `accent`, e o toque (hover) do
/// primário.
@immutable
class MaeColors extends ThemeExtension<MaeColors> {
  const MaeColors({
    required this.primaryHover,
    required this.accent,
    required this.accentForeground,
    required this.accentBorder,
    required this.success,
    required this.successSubtle,
    required this.successBorder,
    required this.warning,
    required this.warningSubtle,
    required this.warningBorder,
    required this.destructiveSubtle,
    required this.destructiveBorder,
  });

  final Color primaryHover;
  final Color accent;
  final Color accentForeground;
  final Color accentBorder;
  final Color success;
  final Color successSubtle;
  final Color successBorder;
  final Color warning;
  final Color warningSubtle;
  final Color warningBorder;
  final Color destructiveSubtle;
  final Color destructiveBorder;

  static const light = MaeColors(
    primaryHover: Color(0xFF2C5F7E),
    accent: Color(0xFFEAF2F8),
    accentForeground: Color(0xFF2C5F7E),
    accentBorder: Color(0xFFD3E3EE),
    success: Color(0xFF15803D),
    successSubtle: Color(0xFFF0FDF4),
    successBorder: Color(0xFFDCFCE7),
    warning: Color(0xFFA16207),
    warningSubtle: Color(0xFFFEFCE8),
    warningBorder: Color(0xFFFEF08A),
    destructiveSubtle: Color(0xFFFEF2F2),
    destructiveBorder: Color(0xFFFECACA),
  );

  static const dark = MaeColors(
    primaryHover: Color(0xFF9FC9E2),
    accent: Color(0xFF1D3A4D),
    accentForeground: Color(0xFF9FC9E2),
    accentBorder: Color(0xFF2C5F7E),
    success: Color(0xFF4ADE80),
    successSubtle: Color(0xFF10241A),
    successBorder: Color(0xFF166534),
    warning: Color(0xFFFDE047),
    warningSubtle: Color(0xFF262012),
    warningBorder: Color(0xFF854D0E),
    destructiveSubtle: Color(0xFF2A1516),
    destructiveBorder: Color(0xFF7F1D1D),
  );

  @override
  MaeColors copyWith({
    Color? primaryHover,
    Color? accent,
    Color? accentForeground,
    Color? accentBorder,
    Color? success,
    Color? successSubtle,
    Color? successBorder,
    Color? warning,
    Color? warningSubtle,
    Color? warningBorder,
    Color? destructiveSubtle,
    Color? destructiveBorder,
  }) {
    return MaeColors(
      primaryHover: primaryHover ?? this.primaryHover,
      accent: accent ?? this.accent,
      accentForeground: accentForeground ?? this.accentForeground,
      accentBorder: accentBorder ?? this.accentBorder,
      success: success ?? this.success,
      successSubtle: successSubtle ?? this.successSubtle,
      successBorder: successBorder ?? this.successBorder,
      warning: warning ?? this.warning,
      warningSubtle: warningSubtle ?? this.warningSubtle,
      warningBorder: warningBorder ?? this.warningBorder,
      destructiveSubtle: destructiveSubtle ?? this.destructiveSubtle,
      destructiveBorder: destructiveBorder ?? this.destructiveBorder,
    );
  }

  @override
  MaeColors lerp(ThemeExtension<MaeColors>? other, double t) {
    if (other is! MaeColors) return this;
    return MaeColors(
      primaryHover: Color.lerp(primaryHover, other.primaryHover, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentForeground: Color.lerp(
        accentForeground,
        other.accentForeground,
        t,
      )!,
      accentBorder: Color.lerp(accentBorder, other.accentBorder, t)!,
      success: Color.lerp(success, other.success, t)!,
      successSubtle: Color.lerp(successSubtle, other.successSubtle, t)!,
      successBorder: Color.lerp(successBorder, other.successBorder, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningSubtle: Color.lerp(warningSubtle, other.warningSubtle, t)!,
      warningBorder: Color.lerp(warningBorder, other.warningBorder, t)!,
      destructiveSubtle: Color.lerp(
        destructiveSubtle,
        other.destructiveSubtle,
        t,
      )!,
      destructiveBorder: Color.lerp(
        destructiveBorder,
        other.destructiveBorder,
        t,
      )!,
    );
  }
}

ThemeData get maeLightTheme => _buildTheme(
  brightness: Brightness.light,
  colorScheme: const ColorScheme.light(
    primary: Color(0xFF397BA1),
    onPrimary: Color(0xFFFFFFFF),
    secondary: Color(0xFFF4F4F5),
    onSecondary: Color(0xFF18181B),
    surface: Color(0xFFFFFFFF), // cartão
    onSurface: Color(0xFF09090B),
    surfaceContainerHighest: Color(0xFFF4F4F5), // muted
    onSurfaceVariant: Color(0xFF71717A), // muted-foreground
    error: Color(0xFFDC2626),
    onError: Color(0xFFFFFFFF),
    outline: Color(0xFFE4E4E7), // border / input
    outlineVariant: Color(0xFFE4E4E7),
  ),
  scaffoldBackgroundColor: const Color(0xFFFAFAFA),
  tokens: MaeColors.light,
);

ThemeData get maeDarkTheme => _buildTheme(
  brightness: Brightness.dark,
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFF7FB3D0),
    onPrimary: Color(0xFF09090B),
    secondary: Color(0xFF27272A),
    onSecondary: Color(0xFFFAFAFA),
    surface: Color(0xFF18181B), // cartão
    onSurface: Color(0xFFFAFAFA),
    surfaceContainerHighest: Color(0xFF27272A), // muted
    onSurfaceVariant: Color(0xFFA1A1AA), // muted-foreground
    error: Color(0xFFF87171),
    onError: Color(0xFF09090B),
    outline: Color(0xFF27272A), // border
    outlineVariant: Color(0xFF3F3F46), // input
  ),
  scaffoldBackgroundColor: const Color(0xFF09090B),
  tokens: MaeColors.dark,
);

ThemeData _buildTheme({
  required Brightness brightness,
  required ColorScheme colorScheme,
  required Color scaffoldBackgroundColor,
  required MaeColors tokens,
}) {
  final buttonShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(kRadiusMd),
  );
  final fieldShape = OutlineInputBorder(
    borderRadius: BorderRadius.circular(kRadiusMd),
    borderSide: BorderSide(color: colorScheme.outline),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: scaffoldBackgroundColor,
    textTheme: _textTheme(colorScheme.onSurface),
    extensions: [tokens],
    visualDensity: VisualDensity.standard,
    cardTheme: CardThemeData(
      color: colorScheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kRadiusXl),
        side: BorderSide(color: colorScheme.outline),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surface,
      border: fieldShape,
      enabledBorder: fieldShape,
      focusedBorder: fieldShape.copyWith(
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
      constraints: const BoxConstraints(minHeight: kTouchTarget),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(kTouchTarget),
        shape: buttonShape,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(kTouchTarget),
        shape: buttonShape,
        side: BorderSide(color: colorScheme.outline),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(kTouchTarget, kTouchTarget),
        shape: buttonShape,
      ),
    ),
    iconTheme: IconThemeData(color: colorScheme.onSurface, size: 24),
    dividerTheme: DividerThemeData(color: colorScheme.outline, thickness: 1),
  );
}

/// Escala tipográfica das telas da E3 (11 a 30 px), mapeada para os papéis
/// do `TextTheme` do Material 3 — os nomes não coincidem com os da web
/// porque o Flutter nomeia por papel (título, corpo, rótulo), não por
/// tamanho.
TextTheme _textTheme(Color onSurface) {
  TextStyle style(double size, double height, {FontWeight? weight}) {
    return TextStyle(
      color: onSurface,
      fontSize: size,
      height: height,
      fontWeight: weight,
    );
  }

  return TextTheme(
    displayLarge: style(
      30,
      1.2,
      weight: FontWeight.w600,
    ), // número em destaque no painel
    headlineLarge: style(
      22,
      1.3,
      weight: FontWeight.w600,
    ), // título de seção na administração
    titleLarge: style(
      17,
      1.4,
      weight: FontWeight.w600,
    ), // título de tela no celular
    titleMedium: style(
      16,
      1.5,
      weight: FontWeight.w500,
    ), // título de cartão, entrada de texto
    bodyLarge: style(14, 1.5), // corpo
    bodyMedium: style(13, 1.45), // apoio
    bodySmall: style(12, 1.45), // rótulo auxiliar
    labelSmall: style(11, 1.45), // metadado, legenda
  );
}
