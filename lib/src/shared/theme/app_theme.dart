import 'package:flutter/material.dart';

/// Tema visual central do iPoupei.
///
/// As cores de produto continuam em [AppColors] para compatibilidade, mas
/// superfícies, texto, componentes e modos claro/escuro devem nascer daqui.
class AppTheme {
  AppTheme._();

  static const Color _brand = Color(0xFF087F78);
  static const Color _lightBackground = Color(0xFFF6F7F9);
  static const Color _darkBackground = Color(0xFF0D0F12);
  static const Color _darkSurface = Color(0xFF15181C);
  static const Color _darkSurfaceRaised = Color(0xFF1B1F24);

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final generated = ColorScheme.fromSeed(
      seedColor: _brand,
      brightness: brightness,
      dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
    );

    final colors = generated.copyWith(
      primary: isDark ? const Color(0xFF6ED5CC) : _brand,
      onPrimary: isDark ? const Color(0xFF003733) : Colors.white,
      surface: isDark ? _darkSurface : Colors.white,
      surfaceContainerLowest: isDark
          ? _darkBackground
          : const Color(0xFFFFFFFF),
      surfaceContainerLow: isDark ? _darkSurface : const Color(0xFFFFFFFF),
      surfaceContainer: isDark ? _darkSurfaceRaised : const Color(0xFFF0F2F5),
      surfaceContainerHigh: isDark
          ? const Color(0xFF22272D)
          : const Color(0xFFE8EBEF),
      outline: isDark ? const Color(0xFF65707B) : const Color(0xFF747E88),
      outlineVariant: isDark
          ? const Color(0xFF2B3138)
          : const Color(0xFFDDE1E6),
      onSurface: isDark ? const Color(0xFFF3F5F7) : const Color(0xFF171A1F),
      onSurfaceVariant: isDark
          ? const Color(0xFFB6BEC7)
          : const Color(0xFF5D6670),
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colors,
      scaffoldBackgroundColor: isDark ? _darkBackground : _lightBackground,
      canvasColor: isDark ? _darkBackground : _lightBackground,
      visualDensity: VisualDensity.standard,
      splashFactory: InkSparkle.splashFactory,
    );

    final textTheme = base.textTheme.copyWith(
      headlineSmall: base.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
      ),
      titleLarge: base.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.25,
      ),
      titleMedium: base.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: base.textTheme.bodyLarge?.copyWith(height: 1.35),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(height: 1.35),
      labelLarge: base.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
      ),
    );

    final cardShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: BorderSide(color: colors.outlineVariant),
    );
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    );

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: isDark ? _darkBackground : _lightBackground,
        foregroundColor: colors.onSurface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge?.copyWith(color: colors.onSurface),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: colors.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shape: cardShape,
      ),
      dialogTheme: DialogThemeData(
        elevation: 0,
        backgroundColor: colors.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: colors.outlineVariant),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        elevation: 0,
        backgroundColor: colors.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceContainer,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: colors.primary, width: 1.5),
        ),
        errorBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: colors.error),
        ),
        focusedErrorBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: colors.error, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          minimumSize: const Size(64, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          side: BorderSide(color: colors.outlineVariant),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        height: 72,
        backgroundColor: colors.surfaceContainerLow,
        indicatorColor: colors.primaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return textTheme.labelMedium?.copyWith(
            color: states.contains(WidgetState.selected)
                ? colors.primary
                : colors.onSurfaceVariant,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          );
        }),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        backgroundColor: colors.surfaceContainerLow,
        selectedItemColor: colors.primary,
        unselectedItemColor: colors.onSurfaceVariant,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
      dividerTheme: DividerThemeData(
        color: colors.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark
            ? const Color(0xFFF1F3F5)
            : const Color(0xFF20242A),
        contentTextStyle: TextStyle(
          color: isDark ? const Color(0xFF171A1F) : Colors.white,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
