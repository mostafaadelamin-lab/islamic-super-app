import 'dart:async';

import 'package:flutter/material.dart';

import '../app_services.dart';
import '../data/content.dart';
import '../data/location.dart';
import '../theme/design_tokens.dart';
import 'adaptive.dart';
import 'city_picker_screen.dart';
import 'l10n_ext.dart';
import 'locate.dart';
import 'r_icon.dart';
import 'settings_screen.dart' show enableAdhanAlerts;
import 'widgets.dart';

/// One slide of the welcome tour.
class TourSlide {
  const TourSlide(this.icon, this.title, this.body);
  final RIconData icon;
  final String title;
  final String body;
}

/// First run (owner 2026-11-14): a short tour of the main features, then the
/// setup of what the adhan needs (location, notifications and, on Android,
/// exact alarms, battery and "adhan when silent"). Shown once; "Skip" and
/// "Start" both finish it. Settings has the tour and the setup again.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onDone, this.replay = false});

  /// Called when the user finishes or skips.
  final VoidCallback onDone;

  /// Opened again from Settings: the tour only, closed by Start / Skip.
  final bool replay;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pages = PageController();
  int _index = 0;

  List<TourSlide> _slides(BuildContext context) {
    final l = context.l10n;
    return [
      TourSlide(RIcons.star, l.tourWelcomeTitle, l.tourWelcomeBody),
      TourSlide(RIcons.quran, l.tourQuranTitle, l.tourQuranBody),
      TourSlide(RIcons.prayer, l.tourPrayerTitle, l.tourPrayerBody),
      TourSlide(RIcons.dua, l.tourAdhkarTitle, l.tourAdhkarBody),
      TourSlide(RIcons.headphones, l.tourListenTitle, l.tourListenBody),
    ];
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _go(int i) => _pages.animateToPage(i, duration: const Duration(milliseconds: 280), curve: Curves.easeOutCubic);

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final slides = _slides(context);
    final count = slides.length + (widget.replay ? 0 : 1);
    final last = _index == count - 1;
    final onSetup = !widget.replay && last;
    return Scaffold(
      key: const Key('onboarding'),
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Padding(
                padding: const EdgeInsets.all(DesignTokens.spaceSm),
                child: onSetup
                    ? const SizedBox(height: 48)
                    : TextButton(key: const Key('tourSkip'), onPressed: widget.onDone, child: Text(l.tourSkip)),
              ),
            ),
            Expanded(
              child: PageView(
                key: const Key('tourPages'),
                controller: _pages,
                onPageChanged: (i) => setState(() => _index = i),
                children: [
                  for (final (i, s) in slides.indexed)
                    _SlideView(slide: s, semanticsLabel: l.tourPage(context.num(i + 1), context.num(count))),
                  if (!widget.replay) const _SetupPage(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                DesignTokens.spaceLg,
                DesignTokens.spaceSm,
                DesignTokens.spaceLg,
                DesignTokens.spaceLg,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 96,
                    child: _index > 0
                        ? TextButton(
                            key: const Key('tourBack'),
                            onPressed: () => _go(_index - 1),
                            child: Text(l.tourBack),
                          )
                        : null,
                  ),
                  Expanded(
                    child: _Dots(count: count, index: _index),
                  ),
                  SizedBox(
                    width: 96,
                    child: last
                        ? FilledButton(
                            key: const Key('tourStart'),
                            onPressed: widget.onDone,
                            child: Text(widget.replay ? l.setupDone : l.setupStart),
                          )
                        : FilledButton(
                            key: const Key('tourNext'),
                            onPressed: () => _go(_index + 1),
                            child: Text(l.tourNext),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index});
  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < count; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == index ? 20 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: i == index ? c.primary : c.outlineVariant,
                borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
              ),
            ),
        ],
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide, required this.semanticsLabel});
  final TourSlide slide;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.colorScheme;
    return Semantics(
      label: semanticsLabel,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceXl),
          child: ReadableWidth(
            maxWidth: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 132,
                  height: 132,
                  decoration: BoxDecoration(color: c.primaryContainer, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: RIcon(slide.icon, size: 64, color: c.onPrimaryContainer),
                ),
                const SizedBox(height: DesignTokens.spaceXl),
                Text(slide.title, style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
                const SizedBox(height: DesignTokens.spaceMd),
                Text(slide.body, style: theme.textTheme.bodyLarge, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SetupPage extends StatelessWidget {
  const _SetupPage();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    return ReadableWidth(
      child: ListView(
        key: const Key('setupPage'),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceXl),
            child: Text(l.setupTitle, style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              DesignTokens.spaceXl,
              DesignTokens.spaceSm,
              DesignTokens.spaceXl,
              DesignTokens.spaceSm,
            ),
            child: Text(l.setupIntro, style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
          ),
          const DeviceSetupPanel(),
        ],
      ),
    );
  }
}

/// Settings > "Permissions and background": the same steps as the first run.
class PermissionsScreen extends StatelessWidget {
  const PermissionsScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.l10n.settingsPermissions)),
    body: ReadableWidth(
      child: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              DesignTokens.spaceXl,
              DesignTokens.spaceMd,
              DesignTokens.spaceXl,
              DesignTokens.spaceSm,
            ),
            child: Text(context.l10n.setupIntro, style: Theme.of(context).textTheme.bodyMedium),
          ),
          const DeviceSetupPanel(),
        ],
      ),
    ),
  );
}

/// The setup steps with their state. The state is read again when the user
/// comes back from a system settings screen.
class DeviceSetupPanel extends StatefulWidget {
  const DeviceSetupPanel({super.key});

  @override
  State<DeviceSetupPanel> createState() => _DeviceSetupPanelState();
}

class _DeviceSetupPanelState extends State<DeviceSetupPanel> with WidgetsBindingObserver {
  bool _locating = false;
  String? _locationError;
  bool _notifications = false;
  bool _exact = true;
  bool _battery = true;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_refresh());
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    final d = context.services.deviceSetup;
    final n = await d.notificationsAllowed();
    final e = await d.exactAlarmsAllowed();
    final b = await d.batteryUnrestricted();
    if (!mounted) return;
    setState(() {
      _notifications = n;
      _exact = e;
      _battery = b;
      _loaded = true;
    });
  }

  Future<void> _useLocation() async {
    final s = context.services;
    final l = context.l10n;
    setState(() {
      _locating = true;
      _locationError = null;
    });
    final r = await locateAndSave(s, keepMethod: true).catchError((Object _) => const LocationUnavailable());
    if (!mounted) return;
    setState(() {
      _locating = false;
      _locationError = switch (r) {
        LocationFound() => null,
        LocationDenied() => l.setupLocationDenied,
        LocationUnavailable() => l.setupLocationUnavailable,
      };
    });
    if (r is LocationFound && !s.settings.autoLocation) await s.settings.setAutoLocation(true);
  }

  Future<void> _chooseCity() async {
    final s = context.services;
    final c = await Navigator.of(
      context,
    ).push<City>(MaterialPageRoute(builder: (_) => CityPickerScreen(selectedId: s.settings.cityId)));
    if (c == null) return;
    await s.settings.setAutoLocation(false);
    await s.settings.setCity(c.id, c.method);
    if (mounted) setState(() => _locationError = null);
  }

  Future<void> _enableAdhan() async {
    await enableAdhanAlerts(context);
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.services;
    final d = s.deviceSetup;
    final settings = s.settings;
    final l = context.l10n;
    final small = Theme.of(context).textTheme.bodySmall;
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        final located = settings.cityId == 'gps' || !settings.cityNeverChosen;
        final adhanOn = settings.adhanEnabled && _notifications;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Step(
              key: const Key('setupLocation'),
              icon: RIcons.location,
              title: l.setupLocationTitle,
              body: l.setupLocationBody,
              done: located && _locationError == null,
              actions: [
                FilledButton.tonalIcon(
                  key: const Key('setupLocationUse'),
                  onPressed: _locating ? null : _useLocation,
                  icon: _locating
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const RIcon(RIcons.myLocation),
                  label: Text(l.setupLocationUse),
                ),
                OutlinedButton.icon(
                  key: const Key('setupLocationCity'),
                  onPressed: _chooseCity,
                  icon: const RIcon(RIcons.city),
                  label: Text(l.setupLocationCity),
                ),
              ],
              note: _locationError,
            ),
            _Step(
              key: const Key('setupNotifications'),
              icon: RIcons.bell,
              title: l.setupNotifTitle,
              body: l.setupNotifBody,
              done: _loaded && adhanOn,
              actions: [
                if (!adhanOn)
                  FilledButton.tonalIcon(
                    key: const Key('setupNotifAction'),
                    onPressed: _enableAdhan,
                    icon: const RIcon(RIcons.bell),
                    label: Text(l.setupNotifAction),
                  ),
                if (_loaded && settings.adhanEnabled && !_notifications)
                  OutlinedButton(
                    key: const Key('setupNotifSettings'),
                    onPressed: d.openNotificationSettings,
                    child: Text(l.setupOpenSettings),
                  ),
              ],
            ),
            if (d.isAndroid && _loaded && !_exact)
              _Step(
                key: const Key('setupExact'),
                icon: RIcons.alarm,
                title: l.setupExactTitle,
                body: l.setupExactBody,
                done: false,
                actions: [
                  FilledButton.tonal(
                    key: const Key('setupExactAction'),
                    onPressed: d.openExactAlarmSettings,
                    child: Text(l.setupOpenSettings),
                  ),
                ],
              ),
            if (d.isAndroid)
              _Step(
                key: const Key('setupBattery'),
                icon: RIcons.settings,
                title: l.setupBatteryTitle,
                body: l.setupBatteryBody,
                done: _loaded && _battery,
                actions: [
                  if (!_battery)
                    FilledButton.tonal(
                      key: const Key('setupBatteryAction'),
                      onPressed: d.openBatterySettings,
                      child: Text(l.setupBatteryAction),
                    ),
                  OutlinedButton(
                    key: const Key('setupAppPage'),
                    onPressed: d.openAppSettings,
                    child: Text(l.setupAppPage),
                  ),
                ],
                note: l.setupBatteryOem,
              ),
            if (d.isAndroid)
              SectionCard(
                children: [
                  SwitchListTile(
                    key: const Key('setupSilent'),
                    contentPadding: EdgeInsets.zero,
                    secondary: const RIcon(RIcons.bellOff),
                    title: Text(l.adhanPlayOnSilent),
                    subtitle: Text(l.adhanPlayOnSilentHint),
                    value: settings.adhanPlayOnSilent,
                    onChanged: settings.setAdhanPlayOnSilent,
                  ),
                ],
              )
            else if (d.isIos)
              SectionCard(
                key: const Key('setupSilentIos'),
                title: l.setupSilentTitle,
                children: [Text(l.setupSilentIos, style: small)],
              ),
            const SizedBox(height: DesignTokens.spaceLg),
          ],
        );
      },
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    required this.done,
    required this.actions,
    this.note,
  });

  final RIconData icon;
  final String title;
  final String body;
  final bool done;
  final List<Widget> actions;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.colorScheme;
    return SectionCard(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RIcon(icon, color: c.primary),
            const SizedBox(width: DesignTokens.spaceMd),
            Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
            if (done)
              Semantics(
                label: context.l10n.setupDone,
                child: RIcon(RIcons.checkCircle, color: c.primary, key: const Key('stepDone')),
              ),
          ],
        ),
        const SizedBox(height: DesignTokens.spaceSm),
        Text(body, style: theme.textTheme.bodyMedium),
        if (actions.isNotEmpty) ...[
          const SizedBox(height: DesignTokens.spaceSm),
          Wrap(spacing: DesignTokens.spaceSm, runSpacing: DesignTokens.spaceXs, children: actions),
        ],
        if (note != null) ...[
          const SizedBox(height: DesignTokens.spaceSm),
          Text(note!, style: theme.textTheme.bodySmall),
        ],
      ],
    );
  }
}
