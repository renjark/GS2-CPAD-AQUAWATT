import 'package:flutter/material.dart';

/// Espaçamentos padronizados.
class AppSpacing {
  const AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
}

/// Temas claro, escuro e de alto contraste (identidade AquaWatt: azul-água).
class AppTheme {
  const AppTheme._();

  static const Color seed = Color(0xFF0B6BA8);

  static ThemeData light() =>
      _build(ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.light));

  static ThemeData dark() =>
      _build(ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark));

  static ThemeData highContrast() => _build(const ColorScheme.dark(
        primary: Color(0xFFFFD60A),
        onPrimary: Colors.black,
        secondary: Color(0xFF7DF9FF),
        onSecondary: Colors.black,
        tertiary: Color(0xFFFFB86B),
        onTertiary: Colors.black,
        error: Color(0xFFFF8A8A),
        onError: Colors.black,
        surface: Colors.black,
        onSurface: Colors.white,
        onSurfaceVariant: Colors.white,
        outline: Colors.white,
        outlineVariant: Colors.white,
        primaryContainer: Color(0xFF3D3300),
        onPrimaryContainer: Colors.white,
        secondaryContainer: Color(0xFF003D4D),
        onSecondaryContainer: Colors.white,
        tertiaryContainer: Color(0xFF5C3A00),
        onTertiaryContainer: Colors.white,
        errorContainer: Color(0xFF7A0000),
        onErrorContainer: Colors.white,
      ));

  static ThemeData _build(ColorScheme scheme) => ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: scheme.surface,
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
        ),
      );
}
