import 'package:flutter/material.dart';

import '../app_services.dart';
import '../data/settings.dart';
import '../theme/design_tokens.dart';
import 'l10n_ext.dart';
import 'r_icon.dart';
import 'review_notice.dart';

/// «إعدادات الأذكار» (owner 2026-11-27; their screenshot of another app was a layout reference only):
/// the view, the page background (our own colours), tashkeel on/off and the text size.

class AdhkarBg {
  const AdhkarBg(this.id, this.colors, {this.dark = false});
  final String id;
  final List<Color> colors;
  final bool dark;
}

/// '' = the app's own colours.
const adhkarBackgrounds = <AdhkarBg>[
  AdhkarBg('', []),
  AdhkarBg('night', [Color(0xFF181C22), Color(0xFF0B0D10)], dark: true),
  AdhkarBg('azure', [Color(0xFF1E4A7C), Color(0xFF0E2747)], dark: true),
  AdhkarBg('emerald', [Color(0xFF21735A), Color(0xFF0F3D30)], dark: true),
  AdhkarBg('sand', [Color(0xFFFFF7E6), Color(0xFFF1DDB4)]),
  AdhkarBg('sky', [Color(0xFFE6F4FA), Color(0xFFBFE2F0)]),
  AdhkarBg('lavender', [Color(0xFFF1ECFA), Color(0xFFD9CDEF)]),
  AdhkarBg('sunset', [Color(0xFFFBE3CF), Color(0xFFE8B9A8)]),
];

AdhkarBg? adhkarBgOf(String id) => adhkarBackgrounds.where((b) => b.id == id && id.isNotEmpty).firstOrNull;

String adhkarBgName(BuildContext context, String id) {
  final l = context.l10n;
  return switch (id) {
    'night' => l.adhkarBgNight,
    'azure' => l.adhkarBgAzure,
    'emerald' => l.adhkarBgEmerald,
    'sand' => l.adhkarBgSand,
    'sky' => l.adhkarBgSky,
    'lavender' => l.adhkarBgLavender,
    'sunset' => l.adhkarBgSunset,
    _ => l.adhkarBgApp,
  };
}

final _harakat = RegExp('[ً-ٰٟۖ-ۭ]');
final _quran = RegExp('﴿[^﴾]*﴾');

/// The dhikr as shown: without tashkeel when the user turned it off. Quran verses (between ﴿ ﴾) always keep
/// their tashkeel, and the stored text never changes.
String dhikrShown(String text, {required bool tashkeel}) {
  if (tashkeel) return text;
  final out = StringBuffer();
  var at = 0;
  for (final m in _quran.allMatches(text)) {
    out
      ..write(text.substring(at, m.start).replaceAll(_harakat, ''))
      ..write(m.group(0));
    at = m.end;
  }
  out.write(text.substring(at).replaceAll(_harakat, ''));
  return out.toString();
}

/// The dhikr text style at the user's size.
TextStyle dhikrStyle(BuildContext context, {double size = 18}) =>
    duaStyle(context, size: size * context.services.settings.adhkarScale);

/// Paints the chosen background behind an adhkar page and gives it matching colours.
class AdhkarLook extends StatelessWidget {
  const AdhkarLook({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final settings = context.services.settings;
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        final bg = adhkarBgOf(settings.adhkarBg);
        if (bg == null) return child;
        final base = Theme.of(context);
        final scheme = ColorScheme.fromSeed(
          seedColor: bg.colors.first,
          brightness: bg.dark ? Brightness.dark : Brightness.light,
        );
        final theme = base.copyWith(
          colorScheme: scheme,
          scaffoldBackgroundColor: Colors.transparent,
          appBarTheme: base.appBarTheme.copyWith(
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            foregroundColor: scheme.onSurface,
          ),
          cardTheme: base.cardTheme.copyWith(color: scheme.surface.withValues(alpha: bg.dark ? 0.35 : 0.7)),
          textTheme: base.textTheme.apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface),
          iconTheme: base.iconTheme.copyWith(color: scheme.onSurface),
        );
        return DecoratedBox(
          key: Key('adhkarBg-${bg.id}'),
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: bg.colors),
          ),
          child: Theme(data: theme, child: child),
        );
      },
    );
  }
}

/// The ⚙ button in the adhkar pages' top bar.
class AdhkarSettingsButton extends StatelessWidget {
  const AdhkarSettingsButton({super.key, this.view = true});

  /// Offer the one-card / list choice (adhkar and Hisn al-Muslim).
  final bool view;

  @override
  Widget build(BuildContext context) => IconButton(
    key: const Key('adhkarSettings'),
    tooltip: context.l10n.adhkarSettingsTitle,
    icon: const RIcon(RIcons.settings),
    onPressed: () => showAdhkarSettings(context, view: view),
  );
}

Future<void> showAdhkarSettings(BuildContext context, {bool view = true}) {
  // The sheet keeps the app's own colours, whatever background the page behind has.
  final appTheme = Theme.of(Navigator.of(context, rootNavigator: true).context);
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: appTheme.colorScheme.surfaceContainerLow,
    // The page behind stays visible, so every change shows on it at once.
    barrierColor: Colors.black26,
    builder: (_) => Theme(
      data: appTheme,
      child: AdhkarSettingsSheet(view: view),
    ),
  );
}

class AdhkarSettingsSheet extends StatelessWidget {
  const AdhkarSettingsSheet({super.key, this.view = true});
  final bool view;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final settings = context.services.settings;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) => SafeArea(
        child: SingleChildScrollView(
          key: const Key('adhkarSettingsSheet'),
          padding: const EdgeInsets.fromLTRB(DesignTokens.spaceLg, 0, DesignTokens.spaceLg, DesignTokens.spaceLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: Text(l.adhkarSettingsTitle, style: theme.textTheme.titleLarge)),
                  IconButton(
                    key: const Key('adhkarSettingsClose'),
                    tooltip: l.adhkarMineCancel,
                    icon: const RIcon(RIcons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              if (view) ...[
                Text(l.adhkarSettingsView, style: theme.textTheme.titleSmall),
                const SizedBox(height: DesignTokens.spaceXs),
                SegmentedButton<bool>(
                  key: const Key('adhkarSettingsViewMode'),
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(value: true, label: Text(l.adhkarCards)),
                    ButtonSegment(value: false, label: Text(l.adhkarList)),
                  ],
                  selected: {settings.adhkarCards},
                  onSelectionChanged: (v) => settings.setAdhkarCards(v.single),
                ),
                const SizedBox(height: DesignTokens.spaceMd),
              ],
              Text(l.adhkarSettingsBg, style: theme.textTheme.titleSmall),
              const SizedBox(height: DesignTokens.spaceXs),
              GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: DesignTokens.spaceSm,
                crossAxisSpacing: DesignTokens.spaceSm,
                childAspectRatio: 0.95,
                children: [
                  for (final b in adhkarBackgrounds)
                    () {
                      final on = settings.adhkarBg == b.id;
                      return InkWell(
                        key: Key('adhkarBgPick-${b.id.isEmpty ? 'app' : b.id}'),
                        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                        onTap: () => settings.setAdhkarBg(b.id),
                        child: Column(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                                  color: b.colors.isEmpty ? scheme.surface : null,
                                  gradient: b.colors.isEmpty
                                      ? null
                                      : LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: b.colors,
                                        ),
                                  border: Border.all(
                                    color: on ? scheme.secondary : scheme.outlineVariant,
                                    width: on ? 3 : 1,
                                  ),
                                ),
                                child: on
                                    ? Align(
                                        alignment: AlignmentDirectional.bottomStart,
                                        child: Padding(
                                          padding: const EdgeInsets.all(4),
                                          child: RIcon(RIcons.checkCircle, size: 20, color: scheme.secondary),
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(adhkarBgName(context, b.id), style: theme.textTheme.labelSmall, maxLines: 1),
                          ],
                        ),
                      );
                    }(),
                ],
              ),
              const SizedBox(height: DesignTokens.spaceSm),
              SwitchListTile(
                key: const Key('adhkarSettingsTashkeel'),
                contentPadding: EdgeInsets.zero,
                title: Text(l.adhkarSettingsTashkeel, style: theme.textTheme.titleSmall),
                subtitle: Text(l.adhkarSettingsTashkeelHint),
                value: settings.adhkarTashkeel,
                onChanged: settings.setAdhkarTashkeel,
              ),
              Text(l.adhkarSettingsSize, style: theme.textTheme.titleSmall),
              Row(
                children: [
                  Text('أ', style: duaStyle(context, size: 14)),
                  Expanded(
                    child: Slider(
                      key: const Key('adhkarSettingsScale'),
                      min: SettingsController.adhkarScaleMin,
                      max: SettingsController.adhkarScaleMax,
                      divisions: 10,
                      value: settings.adhkarScale,
                      label: '${(settings.adhkarScale * 100).round()}%',
                      onChanged: settings.setAdhkarScale,
                    ),
                  ),
                  Text('أ', style: duaStyle(context, size: 26)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
