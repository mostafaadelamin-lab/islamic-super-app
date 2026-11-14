import 'package:flutter/material.dart';

import '../app_services.dart';
import '../data/mp3quran.dart';
import '../data/settings.dart';
import '../domain/mp3quran.dart';
import '../domain/stories.dart';
import '../theme/design_tokens.dart';
import 'adaptive.dart';
import 'audio_widgets.dart';
import 'home_screen.dart' show QuranRadioCard;
import 'l10n_ext.dart';
import 'library_screen.dart' show PlayTile;
import 'r_icon.dart';
import 'stories_screen.dart' show NarrationBar;
import 'widgets.dart';

/// A live Quran radio station shown at the top of the radios screen.
class FeaturedRadio {
  const FeaturedRadio({required this.id, required this.nameAr, required this.nameEn, required this.url});
  final String id;
  final String nameAr;
  final String nameEn;
  final String url;
}

/// Live audio from the two Holy Mosques (owner, 2026-11-14: sound only, no video). The streams
/// are HLS; the players keep only the sound. No source names are shown in the app.
const haramainRadios = [
  FeaturedRadio(
    id: 'radio-makkah',
    nameAr: 'بث مباشر من المسجد الحرام بمكة المكرمة',
    nameEn: 'Live from Masjid al-Haram, Makkah',
    url: 'https://win.holol.com/live/quran/playlist.m3u8',
  ),
  FeaturedRadio(
    id: 'radio-madinah',
    nameAr: 'بث مباشر من المسجد النبوي بالمدينة المنورة',
    nameEn: "Live from the Prophet's Mosque, Madinah",
    url: 'https://win.holol.com/live/sunnah/playlist.m3u8',
  ),
];

/// The default home station (owner, 2026-11-11: Cairo Quran radio).
const defaultRadioId = 'radio-eg';

/// The live radios at the top of the radios screen and in the home radio's list: the two Holy
/// Mosques, then the two national Quran radios the owner asked for.
const featuredRadios = [
  ...haramainRadios,
  FeaturedRadio(
    id: 'radio-eg',
    nameAr: 'إذاعة القرآن الكريم من القاهرة',
    nameEn: 'Holy Quran Radio, Cairo',
    url: 'https://stream.radiojar.com/8s5u5tpdtwzuv',
  ),
  FeaturedRadio(
    id: 'radio-sa',
    nameAr: 'إذاعة القرآن الكريم السعودية',
    nameEn: 'Holy Quran Radio, Saudi Arabia',
    url: 'https://stream.radiojar.com/0tpy1h0kxtzuv',
  ),
];

/// The live station the home radio card plays (Cairo Quran radio by default).
Episode homeStation(SettingsController settings, bool arabic) {
  final id = settings.radioStation;
  for (final r in featuredRadios) {
    if (r.id == id) {
      return Episode(id: r.id, titleAr: r.nameAr, titleEn: r.nameEn, url: r.url, status: ReviewStatus.approved);
    }
  }
  final url = settings.radioStationUrl;
  if (url == null) {
    final r = featuredRadios.firstWhere((r) => r.id == defaultRadioId);
    return Episode(id: r.id, titleAr: r.nameAr, titleEn: r.nameEn, url: r.url, status: ReviewStatus.approved);
  }
  final name = settings.radioStationName ?? id;
  return Episode(id: id, titleAr: name, titleEn: name, url: url, status: ReviewStatus.approved);
}

/// Quran radios: the app's own whole-Mushaf radio, the Egyptian and Saudi
/// Quran radios, then every other live Quran radio (no source names shown).
class RadioScreen extends StatefulWidget {
  const RadioScreen({super.key});

  @override
  State<RadioScreen> createState() => _RadioScreenState();
}

class _RadioScreenState extends State<RadioScreen> {
  Future<Mp3Library>? _future;
  String _query = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= context.services.mp3quran.load(Mp3QuranClient.apiLanguage(context.isArabic));
  }

  Widget _station(BuildContext context, String id, String title, String url, {bool featured = false}) {
    final scheme = Theme.of(context).colorScheme;
    return PlayTile(
      key: Key(id),
      series: 'radio',
      remember: false,
      title: title,
      subtitle: context.l10n.libraryLive,
      leading: featured
          ? CircleAvatar(
              backgroundColor: scheme.primaryContainer,
              child: RIcon(RIcons.radio, color: scheme.primary),
            )
          : null,
      episode: Episode(id: id, titleAr: title, titleEn: title, url: url, status: ReviewStatus.approved),
      // Playing a station also makes it the home radio's station (owner: choose among all radios).
      onPlay: () => context.services.settings.setRadioStation(id, name: title, url: url),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final s = context.services;
    final ar = context.isArabic;
    return Scaffold(
      appBar: AppBar(title: Text(l.radiosTitle)),
      bottomNavigationBar: const Column(mainAxisSize: MainAxisSize.min, children: [NarrationBar(), MiniPlayer()]),
      body: ReadableWidth(
        child: ListenableBuilder(
          listenable: s.narration,
          builder: (context, _) => ListView(
            key: const Key('radioList'),
            children: [
              const QuranRadioCard(),
              SectionCard(
                title: l.radiosFeatured,
                children: [
                  for (final r in featuredRadios)
                    _station(context, r.id, ar ? r.nameAr : r.nameEn, r.url, featured: true),
                ],
              ),
              FutureBuilder<Mp3Library>(
                future: _future,
                builder: (context, snap) {
                  final lib = snap.data;
                  if (snap.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(DesignTokens.spaceLg),
                      child: Text(l.libraryLoadError),
                    );
                  }
                  if (lib == null) {
                    return const Padding(
                      padding: EdgeInsets.all(DesignTokens.spaceXl),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final featuredUrls = {for (final f in featuredRadios) f.url};
                  final list = [
                    for (final r in lib.filterRadios(_query, s.content.normalizer.normalize))
                      if (!featuredUrls.contains(r.url)) r,
                  ];
                  return SectionCard(
                    title: l.radiosMore,
                    children: [
                      TextField(
                        key: const Key('radioSearch'),
                        decoration: InputDecoration(labelText: l.librarySearch, prefixIcon: const RIcon(RIcons.search)),
                        onChanged: (v) => setState(() => _query = v),
                      ),
                      for (final r in list) _station(context, 'radio-${r.id}', r.name, r.url),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
