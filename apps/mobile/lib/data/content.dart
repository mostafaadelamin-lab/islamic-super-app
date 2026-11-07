import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/adhkar.dart';
import '../domain/audio_queue.dart';
import '../domain/hajj.dart';
import '../domain/mushaf_layout.dart';
import '../domain/prayer.dart';
import '../domain/quran.dart';
import '../domain/search.dart';
import '../domain/text.dart';

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
/// cities, maps, reciters, adhkar, Hisn al-Muslim and the Hajj guide.
class AppContent {
  AppContent({
    required this.quran,
    required this.mushaf,
    required this.reciters,
    required this.adhkar,
    required this.hajj,
    required this.integrity,
    required this.prayerConfig,
    required this.cities,
    required this.renderMap,
    required this.normalizer,
    required this.versions,
  }) : search = QuranSearch(quran, normalizer);

  static const quranAsset = 'assets/content/quran.v1.json';
  static const pagesAsset = 'assets/content/pages.v1.json';
  static const integrityAsset = 'assets/content/integrity.v1.json';
  static const mushafLinesAsset = 'assets/content/mushaf-lines.v1.json';
  static const adhkarAsset = 'assets/content/adhkar.v1.json';
  static const hisnAsset = 'assets/content/hisn.json';
  static const hajjAsset = 'assets/content/hajj.v1.json';
  static const recitersAsset = 'assets/schemas/reciters.json';
  static const versionsAsset = 'assets/content/VERSIONS.json';
  static const methodsAsset = 'assets/schemas/methods.json';
  static const citiesAsset = 'assets/schemas/cities.json';
  static const renderAsset = 'assets/schemas/quran-render.json';
  static const normalizationAsset = 'assets/schemas/search-normalization.json';

  final QuranContent quran;
  final MushafLayout mushaf;
  final ReciterCatalog reciters;
  final AdhkarContent adhkar;
  final HajjGuide hajj;
  final Map<String, dynamic> integrity;
  final PrayerConfig prayerConfig;
  final List<City> cities;
  final QuranRenderMap renderMap;
  final SearchNormalizer normalizer;
  final Map<String, dynamic> versions;
  final QuranSearch search;

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
    return AppContent(
      quran: QuranContent.fromJson(quranJson, pagesJson),
      mushaf: MushafLayout.fromJson(await j(mushafLinesAsset)),
      reciters: ReciterCatalog.fromJson(await j(recitersAsset)),
      adhkar: AdhkarContent.fromJson(
        await j(adhkarAsset),
        jsonDecode(await bundle.loadString(hisnAsset)) as List<dynamic>,
      ),
      hajj: HajjGuide.fromJson(await j(hajjAsset)),
      integrity: await j(integrityAsset),
      prayerConfig: PrayerConfig.fromJson(await j(methodsAsset)),
      cities: List.unmodifiable([
        for (final c in citiesJson['cities'] as List<dynamic>) City.fromJson(c as Map<String, dynamic>),
      ]),
      renderMap: QuranRenderMap.fromJson(await j(renderAsset)),
      normalizer: SearchNormalizer.fromJson(await j(normalizationAsset)),
      versions: await j(versionsAsset),
    );
  }
}
