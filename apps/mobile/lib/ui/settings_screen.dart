import 'package:flutter/material.dart';

import 'package:url_launcher/url_launcher.dart';

import '../app_services.dart';
import '../data/printed_mushaf.dart';
import '../data/content.dart';
import '../domain/hijri.dart';
import '../domain/prayer_schedule.dart';
import '../theme/design_tokens.dart';
import 'about_screen.dart';
import 'city_picker_screen.dart';
import 'contact_screen.dart';
import 'help_screen.dart';
import 'locate.dart';
import 'prayer_model.dart';
import 'prayer_screen.dart';
import 'l10n_ext.dart';
import 'muezzin_screen.dart';
import 'onboarding_screen.dart';
import 'widgets.dart';
import 'adaptive.dart';
import 'r_icon.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _push(BuildContext context, Widget page) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    final s = context.services;
    final settings = s.settings;
    final l = context.l10n;
    // The owner's list (2026-11-11): language, prayer times, location services, rate, share,
    // FAQ, contact, our apps. Reading, adhan and recitation choices live on their own screens.
    return Scaffold(
      appBar: AppBar(title: Text(l.navSettings)),
      body: ReadableWidth(
        child: ListenableBuilder(
          listenable: settings,
          builder: (context, _) {
            final pv = PrayerView.compute(s);
            final links = s.content.links;
            final store = links.storeFor(Theme.of(context).platform);
            return ListView(
              key: const Key('settingsList'),
              children: [
                SectionCard(
                  title: l.settingsLanguage,
                  children: [
                    SegmentedButton<String>(
                      key: const Key('languageSelector'),
                      segments: [
                        ButtonSegment(value: 'ar', label: Text(l.settingsLanguageAr)),
                        ButtonSegment(value: 'en', label: Text(l.settingsLanguageEn)),
                      ],
                      selected: {settings.locale.languageCode},
                      onSelectionChanged: (v) => settings.setLocale(v.single),
                    ),
                  ],
                ),
                SectionCard(
                  title: l.settingsTheme,
                  children: [
                    Text(l.settingsPalette, style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: DesignTokens.spaceSm),
                    Row(
                      children: [
                        for (final id in DesignTokens.paletteIds) ...[
                          if (id != DesignTokens.paletteIds.first) const SizedBox(width: DesignTokens.spaceSm),
                          Expanded(
                            child: PaletteChoice(
                              id: id,
                              label: id == 'madinah' ? l.settingsPaletteMadinah : l.settingsPaletteEmerald,
                              selected: settings.palette == id,
                              onTap: () => settings.setPalette(id),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: DesignTokens.spaceLg),
                    SegmentedButton<ThemeMode>(
                      key: const Key('themeSelector'),
                      segments: [
                        ButtonSegment(value: ThemeMode.system, label: Text(l.settingsThemeSystem)),
                        ButtonSegment(value: ThemeMode.light, label: Text(l.settingsThemeLight)),
                        ButtonSegment(value: ThemeMode.dark, label: Text(l.settingsThemeDark)),
                      ],
                      selected: {settings.themeMode},
                      onSelectionChanged: (v) => settings.setThemeMode(v.single),
                    ),
                  ],
                ),
                const MushafLookCard(),
                SectionCard(
                  title: l.settingsPrayerTimes,
                  children: [
                    SwitchListTile(
                      key: const Key('prayerAuto'),
                      contentPadding: EdgeInsets.zero,
                      secondary: const RIcon(RIcons.prayer),
                      title: Text(settings.prayerAuto ? l.settingsAuto : l.settingsManual),
                      subtitle: Text(settings.prayerAuto ? l.settingsPrayerAutoHint : l.settingsPrayerManualHint),
                      value: settings.prayerAuto,
                      onChanged: settings.setPrayerAuto,
                    ),
                    if (!settings.prayerAuto)
                      ListTile(
                        key: const Key('prayerManualTile'),
                        contentPadding: EdgeInsets.zero,
                        leading: const RIcon(RIcons.edit),
                        title: Text(l.prayerEditTimes),
                        trailing: const RIcon(RIcons.chevronForward),
                        onTap: () => _push(context, const PrayerScreen(settingsMode: true)),
                      ),
                  ],
                ),
                AutoLocationCard(placeLabel: placeLabel(s, pv.city, arabic: context.isArabic)),
                if (!settings.autoLocation)
                  SectionCard(
                    children: [
                      ListTile(
                        key: const Key('settingsCityTile'),
                        contentPadding: EdgeInsets.zero,
                        leading: const RIcon(RIcons.city),
                        title: Text(l.prayerCity),
                        subtitle: Text(pv.city.name(context.isArabic)),
                        trailing: const RIcon(RIcons.chevronForward),
                        onTap: () async {
                          final c = await Navigator.of(
                            context,
                          ).push<City>(MaterialPageRoute(builder: (_) => CityPickerScreen(selectedId: pv.city.id)));
                          if (c != null) await settings.setCity(c.id, c.method);
                        },
                      ),
                    ],
                  ),
                SectionCard(
                  children: [
                    ListTile(
                      key: const Key('permissionsTile'),
                      contentPadding: EdgeInsets.zero,
                      leading: const RIcon(RIcons.bell),
                      title: Text(l.settingsPermissions),
                      subtitle: Text(l.settingsPermissionsHint),
                      trailing: const RIcon(RIcons.chevronForward),
                      onTap: () => _push(context, const PermissionsScreen()),
                    ),
                    ListTile(
                      key: const Key('tourTile'),
                      contentPadding: EdgeInsets.zero,
                      leading: const RIcon(RIcons.info),
                      title: Text(l.settingsTour),
                      trailing: const RIcon(RIcons.chevronForward),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (c) => OnboardingScreen(replay: true, onDone: () => Navigator.of(c).pop()),
                        ),
                      ),
                    ),
                  ],
                ),
                SectionCard(
                  children: [
                    if (store != null)
                      ListTile(
                        key: const Key('rateTile'),
                        contentPadding: EdgeInsets.zero,
                        leading: const RIcon(RIcons.star),
                        title: Text(l.helpRate),
                        trailing: const RIcon(RIcons.chevronForward),
                        onTap: () => launchUrl(Uri.parse(store), mode: LaunchMode.externalApplication),
                      ),
                    ListTile(
                      key: const Key('shareTile'),
                      contentPadding: EdgeInsets.zero,
                      leading: const RIcon(RIcons.share),
                      title: Text(l.helpShareApp),
                      onTap: () => s.sharer.shareText(shareAppText(l, links)),
                    ),
                    ListTile(
                      key: const Key('faqTile'),
                      contentPadding: EdgeInsets.zero,
                      leading: const RIcon(RIcons.help),
                      title: Text(l.helpFaq),
                      trailing: const RIcon(RIcons.chevronForward),
                      onTap: () => _push(context, const HelpScreen()),
                    ),
                    ListTile(
                      key: const Key('contactTile'),
                      contentPadding: EdgeInsets.zero,
                      leading: const RIcon(RIcons.mail),
                      title: Text(l.helpContact),
                      trailing: const RIcon(RIcons.chevronForward),
                      onTap: () => _push(context, const ContactScreen()),
                    ),
                    ListTile(
                      key: const Key('ourAppsTile'),
                      contentPadding: EdgeInsets.zero,
                      leading: const RIcon(RIcons.list),
                      title: Text(l.settingsOurApps),
                      subtitle: Text(l.settingsOurAppsSoon),
                    ),
                    ListTile(
                      key: const Key('aboutTile'),
                      contentPadding: EdgeInsets.zero,
                      leading: const RIcon(RIcons.info),
                      title: Text(l.settingsAbout),
                      trailing: const RIcon(RIcons.chevronForward),
                      onTap: () => _push(context, const AboutScreen()),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Turns adhan alerts on after asking for the notification permission; shows
/// a snack bar and returns false when the user refuses.
Future<bool> enableAdhanAlerts(BuildContext context) async {
  final s = context.services;
  final l = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  final ok = await s.adhan.backend.requestPermission();
  if (!ok) {
    messenger.showSnackBar(SnackBar(content: Text(l.adhanDenied)));
    return false;
  }
  await s.settings.setAdhanEnabled(true);
  return true;
}

/// Adhan notifications: master switch (asks for permission), one switch per
/// prayer, the sound (adhan / phone tone / silent), listen and test buttons.
class AdhanSettingsCard extends StatelessWidget {
  const AdhanSettingsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.services;
    final settings = s.settings;
    final l = context.l10n;
    final small = Theme.of(context).textTheme.bodySmall;
    return SectionCard(
      title: l.adhanSettings,
      children: [
        SwitchListTile(
          key: const Key('adhanSwitch'),
          contentPadding: EdgeInsets.zero,
          title: Text(l.adhanEnable),
          value: settings.adhanEnabled,
          onChanged: (v) async {
            if (v) {
              await enableAdhanAlerts(context);
            } else {
              await settings.setAdhanEnabled(false);
            }
          },
        ),
        // Muezzin, sound and test stay visible even before the alerts are
        // switched on, so the choices are easy to find.
        ...[
          for (final p in obligatoryPrayers)
            SwitchListTile(
              key: Key('adhanSwitch-$p'),
              contentPadding: const EdgeInsetsDirectional.only(start: 16),
              title: Text(context.prayerName(p)),
              value: settings.adhanEnabled && settings.adhanFor(p),
              onChanged: settings.adhanEnabled ? (v) => settings.setAdhanFor(p, v) : null,
            ),
          const SizedBox(height: DesignTokens.spaceSm),
          Text(l.adhanSound, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: DesignTokens.spaceXs),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<String>(
              key: const Key('adhanSound'),
              showSelectedIcon: false,
              segments: [
                ButtonSegment(value: 'adhan', label: Text(l.adhanSoundAdhan), icon: const RIcon(RIcons.prayer)),
                ButtonSegment(value: 'tone', label: Text(l.adhanSoundTone), icon: const RIcon(RIcons.bell)),
                ButtonSegment(value: 'silent', label: Text(l.adhanSoundSilent), icon: const RIcon(RIcons.bellOff)),
              ],
              selected: {settings.adhanSound},
              onSelectionChanged: (v) => settings.setAdhanSound(v.first),
            ),
          ),
          // Owner (2026-11-14): the adhan may ring when the phone is silent. Android only:
          // iOS lets no app sound a notification with the silent switch on.
          if (Theme.of(context).platform == TargetPlatform.android)
            SwitchListTile(
              key: const Key('adhanPlayOnSilent'),
              contentPadding: EdgeInsets.zero,
              title: Text(l.adhanPlayOnSilent),
              subtitle: Text(l.adhanPlayOnSilentHint, style: small),
              value: settings.adhanPlayOnSilent,
              onChanged: settings.setAdhanPlayOnSilent,
            ),
          // Owner (2026-11-21): the whole adhan on every iPhone. iOS cuts a notification sound at 30 s, so it
          // rings as parts back to back; iOS 26+ can ring it as an alarm instead (AlarmKit).
          if (Theme.of(context).platform == TargetPlatform.iOS && settings.adhanSound == 'adhan') ...[
            const SizedBox(height: DesignTokens.spaceXs),
            Text(l.adhanIosFullHint, key: const Key('adhanIosFullHint'), style: small),
            const _IosAlarmSwitch(),
          ],
          const SizedBox(height: DesignTokens.spaceMd),
          _VoiceRow(fajr: false, id: settings.adhanVoice),
          _VoiceRow(fajr: true, id: settings.adhanFajrVoice),
          const SizedBox(height: DesignTokens.spaceSm),
          Wrap(
            spacing: DesignTokens.spaceSm,
            runSpacing: DesignTokens.spaceXs,
            children: [
              ListenableBuilder(
                listenable: s.adhanPreview,
                builder: (context, _) => FilledButton.tonalIcon(
                  key: const Key('adhanPreview'),
                  onPressed: () => s.adhanPreview.toggle(settings.adhanVoice),
                  icon: RIcon(s.adhanPreview.playing ? RIcons.stop : RIcons.play),
                  label: Text(s.adhanPreview.playing ? l.adhanPreviewStop : l.adhanPreview),
                ),
              ),
              OutlinedButton.icon(
                key: const Key('adhanTest'),
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  await s.adhan.test();
                  messenger.showSnackBar(SnackBar(content: Text(l.adhanTestScheduled)));
                },
                icon: const RIcon(RIcons.alarm),
                label: Text(l.adhanTest),
              ),
            ],
          ),
          if (Theme.of(context).platform == TargetPlatform.iOS) ...[
            Text(l.adhanIosNote, style: small),
            const SizedBox(height: DesignTokens.spaceXs),
            Text(l.setupSilentIos, key: const Key('adhanSilentIosNote'), style: small),
          ],
        ],
        const SizedBox(height: DesignTokens.spaceXs),
        Text(l.adhanNote, style: small),
        // The recordings' credits moved to the About page (owner, 2026-11-17).
      ],
    );
  }
}

/// The chosen muezzin for the adhan (or the Fajr adhan); opens the full list.
class _VoiceRow extends StatelessWidget {
  const _VoiceRow({required this.fajr, required this.id});
  final bool fajr;
  final String id;

  @override
  Widget build(BuildContext context) {
    final s = context.services;
    final l = context.l10n;
    return ListTile(
      key: Key(fajr ? 'adhanFajrVoice' : 'adhanVoice'),
      contentPadding: EdgeInsets.zero,
      leading: RIcon(fajr ? RIcons.sunrise : RIcons.prayer),
      title: Text(fajr ? l.adhanFajrVoice : l.adhanVoice),
      subtitle: FutureBuilder(
        future: s.adhanVoices.voice(id),
        builder: (context, snap) => Text(snap.data?.name(context.isArabic) ?? ''),
      ),
      trailing: const RIcon(RIcons.chevronForward),
      onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => MuezzinScreen(fajr: fajr))),
    );
  }
}

/// Hijri date correction (± days), shown with the prayer settings.
class HijriOffsetCard extends StatelessWidget {
  const HijriOffsetCard({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.services.settings;
    final l = context.l10n;
    return SectionCard(
      title: l.settingsHijriOffset,
      children: [
        Row(
          children: [
            IconButton(
              key: const Key('hijriOffsetMinus'),
              tooltip: '${l.settingsHijriOffset} −',
              icon: const RIcon(RIcons.minus),
              onPressed: settings.hijriOffset > -hijriOffsetMax
                  ? () => settings.setHijriOffset(settings.hijriOffset - 1)
                  : null,
            ),
            Expanded(
              child: Builder(
                builder: (context) {
                  final h = hijriFor(DateTime.now(), arabic: context.isArabic, offsetDays: settings.hijriOffset);
                  final o = settings.hijriOffset;
                  return Text(
                    '${l.homeHijriDate(context.num(h.day), h.monthName, context.num(h.year))}'
                    '  (\u2066${o > 0 ? '+' : ''}${context.num(o)}\u2069)',
                    key: const Key('hijriOffsetPreview'),
                    textAlign: TextAlign.center,
                  );
                },
              ),
            ),
            IconButton(
              key: const Key('hijriOffsetPlus'),
              tooltip: '${l.settingsHijriOffset} +',
              icon: const RIcon(RIcons.plus),
              onPressed: settings.hijriOffset < hijriOffsetMax
                  ? () => settings.setHijriOffset(settings.hijriOffset + 1)
                  : null,
            ),
          ],
        ),
        Text(l.settingsHijriOffsetHint, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

/// One colour style in Settings: a small preview (brand colour, gold, light and dark backgrounds) and its name.
class PaletteChoice extends StatelessWidget {
  const PaletteChoice({super.key, required this.id, required this.label, required this.selected, required this.onTap});
  final String id;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = DesignTokens.palettes[id]!;
    final cs = Theme.of(context).colorScheme;
    Widget dot(Color c) => Container(
      width: 22,
      height: 22,
      margin: const EdgeInsetsDirectional.only(end: 4),
      decoration: BoxDecoration(
        color: c,
        shape: BoxShape.circle,
        border: Border.all(color: cs.outline),
      ),
    );
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        key: Key('palette.$id'),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(DesignTokens.spaceMd),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
            border: Border.all(color: selected ? cs.primary : cs.outline, width: selected ? 2 : 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 36,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                  gradient: LinearGradient(colors: [p['brand']!['heroTop']!, p['brand']!['heroDeep']!]),
                ),
                alignment: AlignmentDirectional.centerStart,
                padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceSm),
                child: Container(width: 28, height: 6, color: p['brand']!['gold']),
              ),
              const SizedBox(height: DesignTokens.spaceSm),
              Row(children: [dot(p['light']!['bg']!), dot(p['dark']!['bg']!), dot(p['light']!['accent']!)]),
              const SizedBox(height: DesignTokens.spaceSm),
              Row(
                children: [
                  if (selected) ...[RIcon(RIcons.checkCircle, color: cs.primary, size: 18), const SizedBox(width: 4)],
                  Expanded(child: Text(label, style: Theme.of(context).textTheme.labelLarge)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "شكل المصحف المطبوع" switch + download of all the page fonts for offline reading.
class MushafLookCard extends StatelessWidget {
  const MushafLookCard({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.services.settings;
    final l = context.l10n;
    final pm = PrintedMushaf.instance;
    return ListenableBuilder(
      listenable: Listenable.merge([settings, pm]),
      builder: (context, _) => SectionCard(
        title: l.settingsMushafSection,
        children: [
          SwitchListTile(
            key: const Key('mushafPrinted'),
            contentPadding: EdgeInsets.zero,
            secondary: const RIcon(RIcons.quran),
            title: Text(l.settingsMushafPrinted),
            subtitle: Text(l.settingsMushafPrintedHint),
            value: settings.mushafPrinted,
            onChanged: settings.setMushafPrinted,
          ),
          if (settings.mushafPrinted)
            pm.bulkDone != null
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: DesignTokens.spaceSm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l.settingsMushafPrintedProgress(context.num(pm.bulkDone!), context.num(PrintedMushaf.pages)),
                        ),
                        const SizedBox(height: DesignTokens.spaceXs),
                        LinearProgressIndicator(value: pm.bulkDone! / PrintedMushaf.pages),
                      ],
                    ),
                  )
                : FutureBuilder<int>(
                    future: pm.savedCount(),
                    builder: (context, snap) {
                      final all = snap.data == PrintedMushaf.pages;
                      return ListTile(
                        key: const Key('mushafPrintedDownload'),
                        contentPadding: EdgeInsets.zero,
                        leading: RIcon(all ? RIcons.checkCircle : RIcons.download),
                        title: Text(all ? l.settingsMushafPrintedSaved : l.settingsMushafPrintedDownload),
                        subtitle: pm.bulkFailed ? Text(l.settingsMushafPrintedFailed) : null,
                        onTap: all ? null : pm.downloadAll,
                      );
                    },
                  ),
        ],
      ),
    );
  }
}

/// iOS 26+: ring the whole adhan as a system alarm (asks for the alarm permission when turned on). Hidden on
/// older iOS.
class _IosAlarmSwitch extends StatefulWidget {
  const _IosAlarmSwitch();

  @override
  State<_IosAlarmSwitch> createState() => _IosAlarmSwitchState();
}

class _IosAlarmSwitchState extends State<_IosAlarmSwitch> {
  String? _state;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_state != null) return;
    _state = 'loading';
    final parts = context.services.adhan.parts;
    if (parts == null) {
      _state = 'unavailable';
      return;
    }
    parts.alarmState().then((v) {
      if (mounted) setState(() => _state = v);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_state == null || _state == 'loading' || _state == 'unavailable') return const SizedBox.shrink();
    final s = context.services;
    final l = context.l10n;
    final on = s.settings.adhanIosAlarm && _state == 'authorized';
    return SwitchListTile(
      key: const Key('adhanIosAlarm'),
      contentPadding: EdgeInsets.zero,
      title: Text(l.adhanIosAlarm),
      subtitle: Text(l.adhanIosAlarmHint, style: Theme.of(context).textTheme.bodySmall),
      value: on,
      onChanged: (v) async {
        final messenger = ScaffoldMessenger.of(context);
        if (!v) {
          await s.settings.setAdhanIosAlarm(false);
          await s.adhan.sync(force: true);
          return;
        }
        final st = await s.adhan.parts!.requestAlarms();
        if (mounted) setState(() => _state = st);
        if (st == 'authorized') {
          await s.settings.setAdhanIosAlarm(true);
          await s.adhan.sync(force: true);
        } else {
          messenger.showSnackBar(SnackBar(content: Text(l.adhanIosAlarmDenied)));
        }
      },
    );
  }
}
