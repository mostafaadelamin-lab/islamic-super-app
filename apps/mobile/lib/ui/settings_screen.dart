import 'package:flutter/material.dart';

import '../app_services.dart';
import '../data/settings.dart';
import '../domain/adhan_voices.dart';
import '../domain/hijri.dart';
import '../domain/prayer_schedule.dart';
import '../domain/quran.dart';
import '../theme/design_tokens.dart';
import 'about_screen.dart';
import 'account_screen.dart';
import 'audio_widgets.dart';
import 'l10n_ext.dart';
import 'muezzin_screen.dart';
import 'widgets.dart';
import 'adaptive.dart';
import 'r_icon.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.services;
    final settings = s.settings;
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.navSettings)),
      body: ReadableWidth(
        child: ListenableBuilder(
          listenable: settings,
          builder: (context, _) => ListView(
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
              SectionCard(
                title: l.settingsFontSize,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          key: const Key('fontSizeSlider'),
                          min: SettingsController.minFontSize,
                          max: SettingsController.maxFontSize,
                          divisions: (SettingsController.maxFontSize - SettingsController.minFontSize).round(),
                          value: settings.quranFontSize,
                          label: context.num(settings.quranFontSize.round()),
                          semanticFormatterCallback: (v) => '${l.settingsFontSize}: ${context.num(v.round())}',
                          onChanged: settings.setQuranFontSize,
                        ),
                      ),
                      Text(context.num(settings.quranFontSize.round()), key: const Key('fontSizeValue')),
                    ],
                  ),
                  Text(l.settingsFontPreview, style: Theme.of(context).textTheme.labelMedium),
                  QuranText(s.content.quran.text(const AyahRef(1, 1)), key: const Key('fontPreview'), ayahNumber: 1),
                ],
              ),
              SectionCard(
                children: [
                  SwitchListTile(
                    key: const Key('translationSwitch'),
                    contentPadding: EdgeInsets.zero,
                    title: Text(l.quranShowTranslation),
                    value: settings.showTranslation,
                    onChanged: settings.setShowTranslation,
                  ),
                ],
              ),
              SectionCard(
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
                            final h = hijriFor(
                              DateTime.now(),
                              arabic: context.isArabic,
                              offsetDays: settings.hijriOffset,
                            );
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
              ),
              SectionCard(title: l.audioTitle, children: const [RecitationSettings()]),
              const AdhanSettingsCard(),
              SectionCard(
                children: [
                  ListTile(
                    key: const Key('accountTile'),
                    contentPadding: EdgeInsets.zero,
                    leading: const RIcon(RIcons.refresh),
                    title: Text(l.settingsAccount),
                    subtitle: Text(l.settingsAccountHint),
                    trailing: const RIcon(RIcons.chevronForward),
                    onTap: () =>
                        Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const AccountScreen())),
                  ),
                  ListTile(
                    key: const Key('aboutTile'),
                    contentPadding: EdgeInsets.zero,
                    leading: const RIcon(RIcons.info),
                    title: Text(l.settingsAbout),
                    trailing: const RIcon(RIcons.chevronForward),
                    onTap: () =>
                        Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const AboutScreen())),
                  ),
                ],
              ),
            ],
          ),
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
        if (settings.adhanEnabled) ...[
          for (final p in obligatoryPrayers)
            SwitchListTile(
              key: Key('adhanSwitch-$p'),
              contentPadding: const EdgeInsetsDirectional.only(start: 16),
              title: Text(context.prayerName(p)),
              value: settings.adhanFor(p),
              onChanged: (v) => settings.setAdhanFor(p, v),
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
          if (Theme.of(context).platform == TargetPlatform.iOS) Text(l.adhanIosNote, style: small),
        ],
        const SizedBox(height: DesignTokens.spaceXs),
        Text(l.adhanNote, style: small),
        Text(l.adhanCredit, key: const Key('adhanCredit'), style: small),
        for (final v in bundledAdhanVoices)
          if (v.credit != null) Text('• ${v.name(context.isArabic)}: ${v.credit}', style: small),
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
