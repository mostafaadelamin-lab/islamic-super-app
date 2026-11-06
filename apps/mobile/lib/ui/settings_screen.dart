import 'package:flutter/material.dart';

import '../app_services.dart';
import '../data/settings.dart';
import '../domain/quran.dart';
import 'about_screen.dart';
import 'account_screen.dart';
import 'l10n_ext.dart';
import 'widgets.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.services;
    final settings = s.settings;
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.navSettings)),
      body: ListenableBuilder(
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
              children: [
                ListTile(
                  key: const Key('accountTile'),
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.sync),
                  title: Text(l.settingsAccount),
                  subtitle: Text(l.settingsAccountHint),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () =>
                      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const AccountScreen())),
                ),
                ListTile(
                  key: const Key('aboutTile'),
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.info_outline),
                  title: Text(l.settingsAbout),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const AboutScreen())),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
