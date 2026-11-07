import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/theme/app_theme.dart';
import 'package:rattil/theme/design_tokens.dart';
import 'package:rattil/ui/home_screen.dart';

double _lum(Color c) {
  double ch(double v) => v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * ch(c.r) + 0.7152 * ch(c.g) + 0.0722 * ch(c.b);
}

double contrast(Color a, Color b) {
  final la = _lum(a), lb = _lum(b);
  final hi = la > lb ? la : lb, lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  test('design tokens are copied verbatim (generated file untouched)', () {
    expect(DesignTokens.fontSizeQuranMin, 18.0);
    expect(DesignTokens.fontSizeQuranMax, 40.0);
    expect(DesignTokens.minTouchTarget, 48.0);
  });

  for (final b in Brightness.values) {
    test('${b.name}: every text/background pair the UI uses is >= 4.5:1', () {
      final t = AppTheme.build(b);
      final s = t.colorScheme;
      final pairs = <String, (Color, Color)>{
        'onSurface/surface': (s.onSurface, s.surface),
        'onSurface/scaffold': (s.onSurface, t.scaffoldBackgroundColor),
        'onSurface/surfaceContainer': (s.onSurface, s.surfaceContainer),
        'onSurfaceVariant/surface': (s.onSurfaceVariant, s.surface),
        'onSurfaceVariant/surfaceContainer': (s.onSurfaceVariant, s.surfaceContainer),
        'onSurfaceVariant/scaffold': (s.onSurfaceVariant, t.scaffoldBackgroundColor),
        'onSurfaceVariant/primaryContainer': (s.onSurfaceVariant, s.primaryContainer),
        'onPrimary/primary': (s.onPrimary, s.primary),
        'onPrimaryContainer/primaryContainer': (s.onPrimaryContainer, s.primaryContainer),
        'onSecondaryContainer/secondaryContainer': (s.onSecondaryContainer, s.secondaryContainer),
        'primary/surface': (s.primary, s.surface),
        'error/surface': (s.error, s.surface),
        'onError/error': (s.onError, s.error),
        'onInverseSurface/inverseSurface': (s.onInverseSurface, s.inverseSurface),
        'paperInk/paper': (AppTheme.token(b, 'paperInk'), AppTheme.token(b, 'paper')),
        'onSurface/paper': (s.onSurface, AppTheme.token(b, 'paper')),
        'paperInk/surface2 (Mushaf header)': (AppTheme.token(b, 'paperInk'), AppTheme.token(b, 'surface2')),
        'paperInk/accentSoft (surah band)': (AppTheme.token(b, 'paperInk'), AppTheme.token(b, 'accentSoft')),
        'paperInk/verseHighlight (playing ayah)': (AppTheme.token(b, 'paperInk'), AppTheme.token(b, 'verseHighlight')),
        'primary/accentSoft (nav label)': (s.primary, AppTheme.token(b, 'accentSoft')),
        'hero text/top': (HeroColors.text, HeroColors.top),
        'hero text/bottom': (HeroColors.text, HeroColors.bottom),
        'hero accent/top': (HeroColors.accent, HeroColors.top),
      };
      for (final e in pairs.entries) {
        expect(contrast(e.value.$1, e.value.$2), greaterThanOrEqualTo(4.5), reason: e.key);
      }
    });
  }
}
