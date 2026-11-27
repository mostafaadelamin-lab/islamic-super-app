import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/step_duas.dart';
import '../domain/declination.dart';
import '../domain/adhkar.dart';
import '../domain/app_links.dart';
import '../domain/audio_queue.dart';
import '../domain/hajj.dart';
import '../domain/hajj_flows.dart';
import '../domain/hajj_guide.dart';
import '../domain/mushaf_layout.dart';
import '../domain/prayer.dart';
import '../domain/quran.dart';
import '../domain/reels.dart';
import '../domain/search.dart';
import '../domain/stories.dart';
import '../domain/text.dart';
import '../domain/hadith.dart';
import '../domain/zakat.dart';

class City {
  const City({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.countryAr,
    required this.lat,
    required this.lng,
    required this.tz,
    required this.method,
  });

  factory City.fromJson(Map<String, dynamic> j) => City(
    id: j['id'] as String,
    nameAr: j['nameAr'] as String,
    nameEn: j['nameEn'] as String,
    countryAr: j['countryAr'] as String? ?? '',
    lat: (j['lat'] as num).toDouble(),
    lng: (j['lng'] as num).toDouble(),
    tz: j['tz'] as String,
    method: j['method'] as String,
  );

  final String id;
  final String nameAr;
  final String nameEn;
  final String countryAr;
  final double lat;
  final double lng;
  final String tz;
  final String method;

  String name(bool arabic) => arabic ? nameAr : nameEn;
}

/// Everything the app bundles: Quran, pages, 15-line layout, prayer config,
/// cities, maps, reciters, adhkar, Hisn al-Muslim, the Hajj guide and the reels list.
class AppContent {
  AppContent({
    required this.quran,
    required this.mushaf,
    required this.reciters,
    required this.adhkar,
    required this.hajj,
    this.hajjGuide = SourcedHajjGuide.empty,
    this.hajjScenes = HajjScenes.empty,
    this.stepDuas = StepDuas.empty,
    required this.integrity,
    required this.prayerConfig,
    required this.cities,
    required this.renderMap,
    required this.normalizer,
    required this.versions,
    this.reels = ReelCatalog.empty,
    this.reelSources = const [],
    this.reelSuggestions = const [],
    this.reelLive = const [],
    this.stories = StoryCatalog.empty,
    this.magneticModel,
    this.links = const AppLinks(),
    this.zakat = ZakatGuide.empty,
    this.hadith = HadithCatalog.empty,
  }) : search = QuranSearch(quran, normalizer);

  static const quranAsset = 'assets/content/quran.v1.json';
  static const pagesAsset = 'assets/content/pages.v1.json';
  static const integrityAsset = 'assets/content/integrity.v1.json';
  static const mushafLinesAsset = 'assets/content/mushaf-lines.v1.json';
  static const adhkarAsset = 'assets/content/adhkar.v1.json';
  static const hisnAsset = 'assets/content/hisn.json';
  static const hisnSectionsAsset = 'assets/content/hisn-sections.json';
  static const hajjAsset = 'assets/content/hajj.v1.json';
  static const dalilHajjAsset = 'assets/content/dalil-hajj.v1.json';
  static const stepDuasAsset = 'assets/content/step-duas.v1.json';
  static const hajjGuideAsset = 'assets/content/hajj-guide.v2.json';
  static const hajjScenesAsset = 'assets/content/hajj-scenes.v1.json';
  static const sceneRolesAsset = 'assets/content/scene-roles.v1.json';
  static const recitersAsset = 'assets/schemas/reciters.json';
  static const timingsAsset = 'assets/schemas/ayah-timings.json';
  static const versionsAsset = 'assets/content/VERSIONS.json';
  static const reelsAsset = 'assets/content/reels.v1.json';
  static const reelSourcesAsset = 'assets/content/reel-sources.v1.json';
  static const reelSuggestionsAsset = 'assets/content/reel-suggestions.v1.json';
  static const storiesAsset = 'assets/content/stories.v1.json';
  static const methodsAsset = 'assets/schemas/methods.json';
  static const wmmAsset = 'assets/schemas/wmm2025.json';
  static const citiesAsset = 'assets/schemas/cities.json';
  static const renderAsset = 'assets/schemas/quran-render.json';
  static const normalizationAsset = 'assets/schemas/search-normalization.json';
  static const linksAsset = 'assets/schemas/app-links.json';
  static const zakatAsset = 'assets/content/zakat.v1.json';
  static const hadithAsset = 'assets/hadith/books.v1.json';

  final QuranContent quran;
  final MushafLayout mushaf;
  final ReciterCatalog reciters;
  final AdhkarContent adhkar;
  final HajjGuide hajj;

  /// What is said at each place of Umrah and Hajj (Hisn al-Muslim and Quran references, resolved).
  final StepDuas stepDuas;

  /// The sourced Hajj & Umrah guide (owner 2026-11-16) and its 3D pictures.
  final SourcedHajjGuide hajjGuide;
  final HajjScenes hajjScenes;
  final Map<String, dynamic> integrity;
  final PrayerConfig prayerConfig;
  final List<City> cities;
  final QuranRenderMap renderMap;
  final SearchNormalizer normalizer;
  final Map<String, dynamic> versions;

  /// Curated YouTube reels (approved + pending; screens filter by review status).
  final ReelCatalog reels;

  /// Trusted channels whose newest Shorts are shown automatically.
  final List<ReelSource> reelSources;
  final List<ReelSource> reelSuggestions;

  /// Official live streams from the Haramain.
  final List<LiveChannel> reelLive;

  /// Quranic stories (verse ranges) and narrated series (audio only).
  final StoryCatalog stories;

  /// World Magnetic Model for the qibla compass (magnetic -> true north).
  final WorldMagneticModel? magneticModel;
  final QuranSearch search;

  /// Contact, website and store links (Help & contact, share, rate).
  final AppLinks links;

  /// Zakat rules and fatwas of Dar al-Ifta al-Misriyya (pending a shar'i review).
  final ZakatGuide zakat;

  /// The nine hadith books (list only; the texts are read by HadithLibrary when opened).
  final HadithCatalog hadith;

  PrayerCalculator get calculator => PrayerCalculator(prayerConfig);

  City? city(String id) {
    for (final c in cities) {
      if (c.id == id) return c;
    }
    return null;
  }

  static Future<AppContent> load(AssetBundle bundle) async {
    Future<Map<String, dynamic>> j(String key) async =>
        jsonDecode(await bundle.loadString(key)) as Map<String, dynamic>;
    final quranJson = await j(quranAsset);
    final pagesJson = await j(pagesAsset);
    final citiesJson = await j(citiesAsset);
    final quran = QuranContent.fromJson(quranJson, pagesJson);
    final adhkar = AdhkarContent.fromJson(
      await j(adhkarAsset),
      jsonDecode(await bundle.loadString(hisnAsset)) as List<dynamic>,
      await j(hisnSectionsAsset),
    );
    return AppContent(
      quran: quran,
      mushaf: MushafLayout.fromJson(await j(mushafLinesAsset)),
      reciters: ReciterCatalog.fromJson(await j(recitersAsset))..addTimings(await j(timingsAsset)),
      adhkar: adhkar,
      stepDuas: StepDuas.fromJson(await j(stepDuasAsset), adhkar.hisn),
      hajjGuide: SourcedHajjGuide.fromJson(await j(hajjGuideAsset)),
      hajjScenes: HajjScenes.fromJson(await j(hajjScenesAsset), await j(sceneRolesAsset)),
      hajj: HajjGuide.fromJson(await j(hajjAsset), official: OfficialHajjGuide.fromJson(await j(dalilHajjAsset))),
      integrity: await j(integrityAsset),
      prayerConfig: PrayerConfig.fromJson(await j(methodsAsset)),
      cities: List.unmodifiable([
        for (final c in citiesJson['cities'] as List<dynamic>) City.fromJson(c as Map<String, dynamic>),
      ]),
      renderMap: QuranRenderMap.fromJson(await j(renderAsset)),
      normalizer: SearchNormalizer.fromJson(await j(normalizationAsset)),
      versions: await j(versionsAsset),
      reels: ReelCatalog.fromJson(await j(reelsAsset)),
      reelSources: ReelSource.listFromJson(await j(reelSourcesAsset)),
      reelLive: LiveChannel.listFromJson(await j(reelSourcesAsset)),
      reelSuggestions: ReelSource.listFromJson(await j(reelSuggestionsAsset)),
      stories: StoryCatalog.fromJson(await j(storiesAsset), [for (final s in quran.surahs) s.ayahCount]),
      magneticModel: WorldMagneticModel.fromJson(await j(wmmAsset)),
      links: AppLinks.fromJson(await j(linksAsset)),
      zakat: ZakatGuide.fromJson(await j(zakatAsset)),
      hadith: HadithCatalog.fromJson(await j(hadithAsset)),
    );
  }
}
