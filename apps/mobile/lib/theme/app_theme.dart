import 'package:flutter/material.dart';

import 'design_tokens.dart';

/// Material theme built only from the generated design tokens
/// (lib/theme/design_tokens.dart is copied by tool/sync_assets.sh).
class AppTheme {
  AppTheme._();

  static Color token(Brightness b, String name) =>
      (b == Brightness.dark ? DesignTokens.dark : DesignTokens.light)[name]!;

  static ThemeData build(Brightness b) {
    Color t(String n) => token(b, n);
    final scheme = ColorScheme(
      brightness: b,
      primary: t('primary'),
      onPrimary: t('onPrimary'),
      primaryContainer: t('verseHighlight'),
      onPrimaryContainer: t('ink'),
      secondary: t('accent'),
      onSecondary: b == Brightness.dark ? t('onPrimary') : t('ink'),
      secondaryContainer: t('accentSoft'),
      onSecondaryContainer: t('ink'),
      tertiary: t('frame'),
      onTertiary: t('onPrimary'),
      error: t('danger'),
      onError: b == Brightness.dark ? t('bg') : t('surface'),
      surface: t('surface'),
      onSurface: t('ink'),
      onSurfaceVariant: t('muted'),
      surfaceContainerLowest: t('surface'),
      surfaceContainerLow: t('surface'),
      surfaceContainer: t('surface2'),
      surfaceContainerHigh: t('surface2'),
      surfaceContainerHighest: t('surface2'),
      outline: t('line'),
      outlineVariant: t('line'),
      inverseSurface: t('ink'),
      onInverseSurface: t('surface'),
      inversePrimary: t('accent'),
    );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: b,
      fontFamily: DesignTokens.fontUi,
      scaffoldBackgroundColor: t('bg'),
      materialTapTargetSize: MaterialTapTargetSize.padded,
    );
    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: t('surface'),
        foregroundColor: t('ink'),
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      cardTheme: CardThemeData(
        color: t('surface'),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          side: BorderSide(color: t('line')),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: t('ink'),
        contentTextStyle: TextStyle(color: t('surface'), fontFamily: DesignTokens.fontUi),
        behavior: SnackBarBehavior.floating,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusSm)),
        filled: true,
        fillColor: t('surface'),
      ),
    );
  }

  /// Text style for Quran text (Amiri Quran) at the user's chosen size.
  static TextStyle quran(BuildContext context, double size) => TextStyle(
    fontFamily: DesignTokens.fontQuran,
    fontSize: size,
    height: 2.0,
    color: Theme.of(context).colorScheme.onSurface,
  );
}
