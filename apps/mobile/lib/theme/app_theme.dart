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
    final ui = DesignTokens.fontUi;
    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: t('bg'),
        foregroundColor: t('ink'),
        elevation: 0,
        scrolledUnderElevation: 0.5,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: ui,
          fontSize: DesignTokens.fontSizeLg,
          fontWeight: FontWeight.w600,
          color: t('ink'),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: t('surface'),
        surfaceTintColor: Colors.transparent,
        indicatorColor: t('accentSoft'),
        elevation: 0,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontFamily: ui,
            fontSize: DesignTokens.fontSizeXs,
            fontWeight: states.contains(WidgetState.selected) ? FontWeight.w600 : FontWeight.w400,
            color: states.contains(WidgetState.selected) ? t('primary') : t('muted'),
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(color: states.contains(WidgetState.selected) ? t('primary') : t('muted')),
        ),
      ),
      listTileTheme: ListTileThemeData(iconColor: t('primary')),
      dividerTheme: DividerThemeData(color: t('line'), space: 1),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusPill)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: t('surface2'),
        selectedColor: t('accentSoft'),
        side: BorderSide(color: t('line')),
        labelStyle: TextStyle(fontFamily: ui, color: t('ink')),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusPill)),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: t('primary'),
        thumbColor: t('accent'),
        inactiveTrackColor: t('line'),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: t('surface'),
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(DesignTokens.radiusLg)),
        ),
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

  /// A design token for the current brightness (e.g. 'paper', 'frame').
  static Color of(BuildContext context, String name) => token(Theme.of(context).brightness, name);

  /// Text style for Quran text (Amiri Quran) at the user's chosen size.
  static TextStyle quran(BuildContext context, double size) => TextStyle(
    fontFamily: DesignTokens.fontQuran,
    fontSize: size,
    height: 2.0,
    color: Theme.of(context).colorScheme.onSurface,
  );
}
