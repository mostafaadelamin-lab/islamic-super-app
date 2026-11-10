// Muezzin recordings for the adhan. A few are bundled with the app (they work
// from the first launch, without internet); the rest of the owner's chosen
// collection (assets/content/adhan_catalog.json, built by
// tools/adhan_catalog.py) is downloaded when the user picks one and kept on
// the phone. The Fajr adhan has its own recording ("as-salatu khayrun min
// an-nawm"), chosen separately. Sources: assets/audio/ADHAN_AUDIO.md.
// The same rules are in apps/web/src/lib/adhan-voices.ts.

class AdhanVoice {
  const AdhanVoice({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    this.place = '',
    this.fajr = false,
    this.raw,
    this.asset,
    this.remoteId,
    this.credit,
  });

  /// Stable id kept in the settings: a bundled name, or "iw" + [remoteId].
  final String id;
  final String nameAr;
  final String nameEn;

  /// Mosque / city / country words, may be empty.
  final String place;

  /// A Fajr adhan (with "as-salatu khayrun min an-nawm").
  final bool fajr;

  /// Bundled: Android res/raw name (alarm + notification sound).
  final String? raw;

  /// Bundled: full recording for the in-app "listen" button.
  final String? asset;

  /// Downloadable: the id of the recording in the collection.
  final int? remoteId;

  /// Author, source and licence when the licence asks for credit.
  final String? credit;

  bool get bundled => remoteId == null;
  String name(bool arabic) => arabic ? nameAr : nameEn;

  factory AdhanVoice.fromCatalog(Map<String, dynamic> j) {
    final id = j['id'] as int;
    final name = j['muezzin'] as String;
    return AdhanVoice(
      id: 'iw$id',
      nameAr: name,
      nameEn: name,
      place: (j['place'] as String?) ?? '',
      fajr: j['fajr'] == true,
      remoteId: id,
    );
  }
}

const bundledAdhanVoices = <AdhanVoice>[
  AdhanVoice(
    id: 'haram',
    nameAr: 'محمد رمضان سعد (الحرم المكي)',
    nameEn: 'Mohamed Ramadan Saad (Makkah Haram)',
    raw: 'adhan_haram',
    asset: 'assets/audio/adhan_haram.m4a',
  ),
  AdhanVoice(
    id: 'haram_fajr',
    nameAr: 'حمد الدغريري (فجر الحرم المكي)',
    nameEn: 'Hamad Al-Daghriri (Fajr, Makkah Haram)',
    fajr: true,
    raw: 'adhan_haram_fajr',
    asset: 'assets/audio/adhan_haram_fajr.m4a',
  ),
  AdhanVoice(
    id: 'v1',
    nameAr: 'صوت هادئ',
    nameEn: 'Calm voice',
    raw: 'adhan',
    asset: 'assets/audio/adhan.m4a',
    credit: '"Beautiful adhan", Adam-synagda, Wikimedia Commons, CC0',
  ),
  AdhanVoice(
    id: 'v2',
    nameAr: 'صوت أقصر',
    nameEn: 'Shorter voice',
    raw: 'adhan_v2',
    asset: 'assets/audio/adhan_v2.m4a',
    credit: '"The Adhan - Muslim Call to Prayer - Aaqib Azeez", Atcovi, Wikimedia Commons, CC BY-SA 4.0',
  ),
];

const defaultAdhanVoice = 'haram';
const defaultFajrVoice = 'haram_fajr';
final _remoteId = RegExp(r'^iw(\d{1,9})$');

/// Whether [id] names a bundled voice or a recording of the collection.
bool isAdhanVoiceId(String? id) => id != null && (bundledAdhanVoices.any((v) => v.id == id) || _remoteId.hasMatch(id));

AdhanVoice? bundledAdhanVoice(String? id) {
  for (final v in bundledAdhanVoices) {
    if (v.id == id) return v;
  }
  return null;
}

/// Download address of a recording of the collection.
Uri adhanDownloadUri(int remoteId) =>
    Uri.https('audio.islamweb.net', '/audio/downloadmp3.php', {'audioid': '$remoteId'});

int? remoteAdhanId(String id) {
  final m = _remoteId.firstMatch(id);
  return m == null ? null : int.parse(m.group(1)!);
}
