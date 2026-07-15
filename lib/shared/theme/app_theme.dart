import 'package:flutter/material.dart';

import 'nox_colors.dart';

/// Tema visual do NoxPass — "Cofre à noite".
///
/// Dark-first, com neutros de viés violeta e acento periwinkle. As cores são
/// os tokens exatos da direção visual aprovada (não derivadas por semente),
/// para bater pixel a pixel com o mockup. Tokens fora do [ColorScheme] vivem
/// em [NoxColors]; nada de cores hardcoded espalhadas pela UI.
abstract final class AppTheme {
  /// Cor-semente da marca (usada só onde o Material exige uma referência).
  static const Color seed = Color(0xFF6A5AE0);

  static ThemeData light() => _base(Brightness.light);
  static ThemeData dark() => _base(Brightness.dark);

  // --- Grounds (fundo do "scaffold") por brilho ---
  static const Color _bgDark = Color(0xFF0E0E15);
  static const Color _bgLight = Color(0xFFF4F4FA);

  static ColorScheme _scheme(Brightness b) {
    final isDark = b == Brightness.dark;
    return ColorScheme(
      brightness: b,
      primary: isDark ? const Color(0xFF9B8CFF) : const Color(0xFF6A5AE0),
      onPrimary: isDark ? const Color(0xFF0E0E15) : Colors.white,
      primaryContainer: isDark ? const Color(0xFF262634) : const Color(0xFFEAE7FB),
      onPrimaryContainer: isDark ? const Color(0xFFD8D0FF) : const Color(0xFF2A2170),
      secondary: isDark ? const Color(0xFF7C6CF6) : const Color(0xFF574AC7),
      onSecondary: isDark ? const Color(0xFF0E0E15) : Colors.white,
      secondaryContainer: isDark ? const Color(0xFF262634) : const Color(0xFFEAE7FB),
      onSecondaryContainer: isDark ? const Color(0xFFD8D0FF) : const Color(0xFF2A2170),
      tertiary: isDark ? const Color(0xFF57C99A) : const Color(0xFF2FA878),
      onTertiary: isDark ? const Color(0xFF0E0E15) : Colors.white,
      error: isDark ? const Color(0xFFFF6B6B) : const Color(0xFFE0574F),
      onError: isDark ? const Color(0xFF0E0E15) : Colors.white,
      surface: isDark ? const Color(0xFF16161F) : Colors.white,
      onSurface: isDark ? const Color(0xFFECECF3) : const Color(0xFF16161F),
      onSurfaceVariant: isDark ? const Color(0xFF9A9AAE) : const Color(0xFF5B5B70),
      surfaceContainerLowest: isDark ? _bgDark : const Color(0xFFEDEDF5),
      surfaceContainerLow: isDark ? const Color(0xFF16161F) : const Color(0xFFFAFAFE),
      surfaceContainer: isDark ? const Color(0xFF1E1E2A) : const Color(0xFFFAFAFE),
      surfaceContainerHigh: isDark ? const Color(0xFF1E1E2A) : const Color(0xFFF0F0F7),
      surfaceContainerHighest: isDark ? const Color(0xFF262634) : const Color(0xFFF0F0F7),
      outline: isDark ? const Color(0xFF2A2A3A) : const Color(0xFFE6E6F0),
      outlineVariant: isDark ? const Color(0xFF2A2A3A) : const Color(0xFFE6E6F0),
    );
  }

  static ThemeData _base(Brightness brightness) {
    final colors = _scheme(brightness);
    final nox = NoxColors.of(brightness);
    final bg = brightness == Brightness.dark ? _bgDark : _bgLight;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colors,
      scaffoldBackgroundColor: bg,
      extensions: [nox],
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: colors.onSurface,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: colors.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          side: BorderSide(color: nox.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: nox.surface2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(color: nox.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(color: nox.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(color: colors.primary, width: 1.6),
        ),
        labelStyle: TextStyle(color: nox.textDim),
        floatingLabelStyle: TextStyle(color: colors.primary),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: colors.surface,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: nox.border),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: nox.surface3,
        side: BorderSide.none,
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: colors.onSurface,
        ),
        shape: const StadiumBorder(),
      ),
      searchBarTheme: SearchBarThemeData(
        elevation: const WidgetStatePropertyAll(0),
        backgroundColor: WidgetStatePropertyAll(nox.surface2),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            side: BorderSide(color: nox.border),
            borderRadius: BorderRadius.circular(13),
          ),
        ),
        hintStyle: WidgetStatePropertyAll(TextStyle(color: nox.textFaint)),
        textStyle: WidgetStatePropertyAll(TextStyle(color: colors.onSurface)),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
        iconColor: nox.textDim,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: nox.surface3,
        contentTextStyle: TextStyle(color: colors.onSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.white
              : nox.textFaint,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? colors.primary
              : nox.surface3,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: colors.primary,
        inactiveTrackColor: nox.surface3,
        thumbColor: colors.primary,
        overlayColor: colors.primary.withValues(alpha: 0.14),
      ),
      dividerTheme: DividerThemeData(
        color: nox.border,
        thickness: 1,
        space: 1,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colors.primary,
        circularTrackColor: nox.surface3,
      ),
    );
  }
}
