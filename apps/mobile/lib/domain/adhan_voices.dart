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
  // The owner's picks (2026-11-11). Sources are kept in ADHAN_AUDIO.md only,
  // never shown in the app, so these have no [credit].
  AdhanVoice(
    id: 'mulla',
    nameAr: 'الشيخ علي بن أحمد ملا',
    nameEn: 'Sheikh Ali Ahmed Mulla',
    place: 'المسجد الحرام، مكة المكرمة',
    raw: 'adhan_mulla',
    asset: 'assets/audio/adhan_mulla.m4a',
  ),
  AdhanVoice(
    id: 'makkah',
    nameAr: 'أذان مكة المكرمة',
    nameEn: 'Adhan of Makkah',
    place: 'مكة المكرمة',
    raw: 'adhan_makkah',
    asset: 'assets/audio/adhan_makkah.m4a',
  ),
  AdhanVoice(
    id: 'bukhari',
    nameAr: 'الشيخ عصام بخاري',
    nameEn: 'Sheikh Essam Bukhari',
    place: 'المسجد النبوي، المدينة المنورة',
    raw: 'adhan_bukhari',
    asset: 'assets/audio/adhan_bukhari.m4a',
  ),
  AdhanVoice(
    id: 'mismail',
    nameAr: 'الشيخ مصطفى إسماعيل',
    nameEn: 'Sheikh Mustafa Ismail',
    place: 'مصر',
    raw: 'adhan_mismail',
    asset: 'assets/audio/adhan_mismail.m4a',
  ),
  AdhanVoice(
    id: 'banna',
    nameAr: 'الشيخ محمود علي البنا',
    nameEn: 'Sheikh Mahmoud Ali Al-Banna',
    place: 'القاهرة',
    raw: 'adhan_banna',
    asset: 'assets/audio/adhan_banna.m4a',
  ),
  AdhanVoice(
    id: 'rifaat',
    nameAr: 'الشيخ محمد رفعت',
    nameEn: 'Sheikh Muhammad Rifaat',
    place: 'القاهرة',
    raw: 'adhan_rifaat',
    asset: 'assets/audio/adhan_rifaat.m4a',
  ),
  AdhanVoice(
    id: 'abdulbasit',
    nameAr: 'الشيخ عبد الباسط عبد الصمد',
    nameEn: 'Sheikh Abdul Basit Abdul Samad',
    place: 'مصر',
    raw: 'adhan_abdulbasit',
    asset: 'assets/audio/adhan_abdulbasit.m4a',
  ),
  AdhanVoice(
    id: 'daghriri_fajr',
    nameAr: 'أذان الفجر: الشيخ حمد الدغريري',
    nameEn: 'Fajr adhan: Sheikh Hamad Al-Daghriri',
    place: 'المسجد الحرام، مكة المكرمة',
    fajr: true,
    raw: 'adhan_daghriri_fajr',
    asset: 'assets/audio/adhan_daghriri_fajr.m4a',
  ),
  AdhanVoice(
    id: 'afasy_fajr',
    nameAr: 'أذان الفجر: الشيخ مشاري راشد العفاسي',
    nameEn: 'Fajr adhan: Sheikh Mishary Alafasy',
    fajr: true,
    raw: 'adhan_afasy_fajr',
    asset: 'assets/audio/adhan_afasy_fajr.m4a',
  ),
  AdhanVoice(
    id: 'abdulbasit_fajr',
    nameAr: 'أذان الفجر: الشيخ عبد الباسط عبد الصمد',
    nameEn: 'Fajr adhan: Sheikh Abdul Basit Abdul Samad',
    place: 'مصر',
    fajr: true,
    raw: 'adhan_abdulbasit_fajr',
    asset: 'assets/audio/adhan_abdulbasit_fajr.m4a',
  ),
  AdhanVoice(
    id: 'haram',
    nameAr: 'أذان المسجد الحرام بمكة المكرمة',
    nameEn: 'Adhan of the Grand Mosque, Makkah',
    place: 'مكة المكرمة',
    raw: 'adhan_haram',
    asset: 'assets/audio/adhan_haram.m4a',
    credit: '"Adhan, Great Mosque of Mecca - Jan 21, 2013", Seyfula Islam, Wikimedia Commons, CC BY 3.0',
  ),
  AdhanVoice(
    id: 'madinah',
    nameAr: 'أذان المسجد النبوي بالمدينة المنورة',
    nameEn: "Adhan of the Prophet's Mosque, Madinah",
    place: 'المدينة المنورة',
    raw: 'adhan_madinah',
    asset: 'assets/audio/adhan_madinah.m4a',
    credit: '"Call to prayer from the prophet\'s mosque", ejaz215, Wikimedia Commons, CC BY 3.0',
  ),
  AdhanVoice(
    id: 'fakhry',
    nameAr: 'صباح فخري',
    nameEn: 'Sabah Fakhri',
    place: 'حلب، سوريا',
    raw: 'adhan_fakhry',
    asset: 'assets/audio/adhan_fakhry.m4a',
    credit: '"Call to prayer by Sabah Fakhry", Wikimedia Commons, public domain',
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
    nameAr: 'عاقب عزيز',
    nameEn: 'Aaqib Azeez',
    raw: 'adhan_v2',
    asset: 'assets/audio/adhan_v2.m4a',
    credit: '"The Adhan - Muslim Call to Prayer - Aaqib Azeez", Atcovi, Wikimedia Commons, CC BY-SA 4.0',
  ),
  AdhanVoice(
    id: 'haram_fajr',
    nameAr: 'أذان الفجر (المركز الإسلامي في مالمو)',
    nameEn: 'Fajr adhan (Islamic Center, Malmö)',
    fajr: true,
    raw: 'adhan_haram_fajr',
    asset: 'assets/audio/adhan_haram_fajr.m4a',
    credit:
        '"Eid al-Fitr Fajr azan at Malmö Mosque - 19 August 2012", Islamic Center Malmö, Wikimedia Commons, CC BY 3.0',
  ),
];

const defaultAdhanVoice = 'mulla';
const defaultFajrVoice = 'daghriri_fajr';

/// Whether [id] names a bundled voice or a recording of the collection.
/// Only the bundled, openly licensed recordings are valid now (the earlier
/// downloadable collection was removed on the owner's request, 2026-11-10).
bool isAdhanVoiceId(String? id) => id != null && bundledAdhanVoices.any((v) => v.id == id);

AdhanVoice? bundledAdhanVoice(String? id) {
  for (final v in bundledAdhanVoices) {
    if (v.id == id) return v;
  }
  return null;
}

/// Download address of a recording of the collection.
Uri adhanDownloadUri(int remoteId) => throw UnsupportedError('no downloadable muezzin collection');

int? remoteAdhanId(String id) => null;
