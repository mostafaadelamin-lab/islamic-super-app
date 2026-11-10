// Muezzin recordings the user can choose for the adhan alert. Every entry is a
// freely licensed recording (sources and licences in assets/audio/ADHAN_AUDIO.md);
// none is taken from another adhan app. The same list is in
// apps/web/src/lib/adhan-voices.ts.

class AdhanVoice {
  const AdhanVoice({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.raw,
    required this.asset,
    required this.credit,
  });

  /// Stable id kept in the settings.
  final String id;
  final String nameAr;
  final String nameEn;

  /// Android res/raw name (alarm + notification sound).
  final String raw;

  /// Full recording for the in-app "listen" button.
  final String asset;

  /// Author, source and licence, shown under the list.
  final String credit;

  String name(bool arabic) => arabic ? nameAr : nameEn;
}

const adhanVoices = <AdhanVoice>[
  AdhanVoice(
    id: 'v1',
    nameAr: 'الصوت الأول (هادئ)',
    nameEn: 'Voice 1 (calm)',
    raw: 'adhan',
    asset: 'assets/audio/adhan.m4a',
    credit: '"Beautiful adhan", Adam-synagda, Wikimedia Commons, CC0',
  ),
  AdhanVoice(
    id: 'v2',
    nameAr: 'الصوت الثاني (أقصر)',
    nameEn: 'Voice 2 (shorter)',
    raw: 'adhan_v2',
    asset: 'assets/audio/adhan_v2.m4a',
    credit: '"The Adhan - Muslim Call to Prayer - Aaqib Azeez", Atcovi, Wikimedia Commons, CC BY-SA 4.0',
  ),
];

const defaultAdhanVoice = 'v1';

AdhanVoice adhanVoiceById(String? id) => adhanVoices.firstWhere((v) => v.id == id, orElse: () => adhanVoices.first);
