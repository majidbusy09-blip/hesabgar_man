import 'package:flutter/material.dart';
import 'app_theme_presets.dart';

class AppTheme {
  AppTheme._();

  static const String fontFamily = 'Vazirmatn';

  /// ساخت ThemeData از رنگ seed و secondary
  static ThemeData fromColors({
    required Color seed,
    required Color secondary,
    required bool isDark,
  }) {
    final brightness = isDark ? Brightness.dark : Brightness.light;
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      secondary: secondary,
      brightness: brightness,
    );

    final bg = isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA);
    final surface = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textPrimary = isDark ? const Color(0xFFF5F5F5) : const Color(0xFF1A1A1A);
    final textSecondary = isDark ? const Color(0xFFAAAAAA) : const Color(0xFF6B6B6B);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: fontFamily,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: textPrimary,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: scheme.primary,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 12,
        selectedLabelStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return scheme.primary;
          return null;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return scheme.primary.withValues(alpha: 0.4);
          }
          return null;
        }),
      ),
    );
  }

  static ThemeData fromPreset(AppThemePreset preset) {
    return fromColors(
      seed: preset.seed,
      secondary: preset.secondary,
      isDark: preset.isDark,
    );
  }

  // سازگاری با کد قدیمی
  static ThemeData get light => fromPreset(AppThemePresets.byId('default'));
  static ThemeData get dark => fromColors(
        seed: const Color(0xFF2A9D8F),
        secondary: const Color(0xFFE76F51),
        isDark: true,
      );
}
