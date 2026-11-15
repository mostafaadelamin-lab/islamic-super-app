import 'package:flutter/material.dart';

import 'design_tokens.dart';

/// Material theme built only from the generated design tokens
/// (lib/theme/design_tokens.dart is copied by tool/sync_assets.sh).
class AppTheme {
  AppTheme._();

  /// The colour style the user picked in Settings (owner 2026-11-15: style 1 emerald & gold,
  /// style 2 Madinah night). Set by the app before it builds its themes.
  static String palette = DesignTokens.defaultPalette;

  static Map<String, Map<String, Color>> get _pal =>
      DesignTokens.palettes[palette] ?? DesignTokens.palettes[DesignTokens.defaultPalette]!;

  static Color token(Brightness b, String name) => _pal[b == Brightness.dark ? 'dark' : 'light']![name]!;

  /// Brand colours of the current style that stay the same in light and dark mode
  /// (hero banners, qibla card, splash): heroTop, heroBottom, heroDeep, heroAccent, gold, goldSoft, dial1..3.
  static Color brand(String name) => _pal['brand']![name]!;

  static ThemeData build(Brightness b, {Map<String, Color>? overrides}) {
    Color t(String n) => overrides?[n] ?? token(b, n);
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
  static Color of(BuildContext context, String name) {
    final b = Theme.of(context).brightness;
    final o = context.dependOnInheritedWidgetOfExactType<TokenOverrides>();
    return o?.colors(b)[name] ?? token(b, name);
  }

  /// Mushaf reader colours (owner's reference, 2026-11-13): cream paper, brown frame and ornaments, black text.
  static const mushafLight = <String, Color>{
    'bg': Color(0xFFF6EFE0),
    'surface': Color(0xFFFFFAF1),
    'surface2': Color(0xFFF6EFE0),
    'ink': Color(0xFF2F2418),
    'muted': Color(0xFF7A6750),
    'line': Color(0xFFE3D3B5),
    'primary': Color(0xFF8A5A2B),
    'onPrimary': Color(0xFFFFFFFF),
    'accent': Color(0xFFB98A4E),
    'accentSoft': Color(0xFFEFE3CB),
    'verseHighlight': Color(0xFFF0E3C8),
    'paper': Color(0xFFFBF6EA),
    'paperInk': Color(0xFF141414),
    'frame': Color(0xFFA8773E),
  };
  static const mushafDark = <String, Color>{
    'bg': Color(0xFF15110D),
    'surface': Color(0xFF201A14),
    'surface2': Color(0xFF1A1510),
    'line': Color(0xFF3A2F22),
    'primary': Color(0xFFD2A86A),
    'onPrimary': Color(0xFF15110D),
    'accentSoft': Color(0xFF3A2D1A),
    'verseHighlight': Color(0xFF3A2D1A),
    'paper': Color(0xFF1C1712),
    'paperInk': Color(0xFFECE3D0),
    'frame': Color(0xFF9C7A45),
  };

  /// Text style for Quran text (Amiri Quran) at the user's chosen size.
  static TextStyle quran(BuildContext context, double size) => TextStyle(
    fontFamily: DesignTokens.fontQuran,
    fontSize: size,
    height: 2.0,
    color: Theme.of(context).colorScheme.onSurface,
  );
}

/// Replaces some design tokens below it (used by the Mushaf reader's own colours).
class TokenOverrides extends InheritedWidget {
  const TokenOverrides({super.key, required this.light, required this.dark, required super.child});
  final Map<String, Color> light;
  final Map<String, Color> dark;

  Map<String, Color> colors(Brightness b) => b == Brightness.dark ? dark : light;

  @override
  bool updateShouldNotify(TokenOverrides old) => old.light != light || old.dark != dark;
}

/// The Mushaf reader's colours: a theme and token overrides for everything below it.
class MushafColors extends StatelessWidget {
  const MushafColors({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final o = b == Brightness.dark ? AppTheme.mushafDark : AppTheme.mushafLight;
    return TokenOverrides(
      light: AppTheme.mushafLight,
      dark: AppTheme.mushafDark,
      child: Theme(
        data: AppTheme.build(b, overrides: o),
        child: child,
      ),
    );
  }
}
