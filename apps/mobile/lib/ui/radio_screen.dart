import 'package:flutter/material.dart';

import '../app_services.dart';
import '../data/mp3quran.dart';
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

/// The two national Quran radios the owner asked for (live streams).
const featuredRadios = [
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
                  for (final r in featuredRadios) _station(context, r.id, ar ? r.nameAr : r.nameEn, r.url, featured: true),
                ],
              ),
              FutureBuilder<Mp3Library>(
                future: _future,
                builder: (context, snap) {
                  final lib = snap.data;
                  if (snap.hasError) {
                    return Padding(padding: const EdgeInsets.all(DesignTokens.spaceLg), child: Text(l.libraryLoadError));
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
