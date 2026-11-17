// Muezzin recordings for the adhan. Only the defaults (Sheikh Ali Mulla of the
// Makkah Haram and Sheikh Al-Daghriri's Fajr adhan from the Haram) are bundled
// with the app, so they work from the first launch without internet; every
// other muezzin is downloaded once when the user picks or plays it and is kept
// on the phone (offline afterwards). Since 1.2.1, to keep the app small. The Fajr adhan has its own recording ("as-salatu khayrun min
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
    this.remote,
    this.mirror,
    this.credit,
  });

  /// Stable id kept in the settings.
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

  /// Downloadable: the recording's name on the website ([adhanAudioBase]/`remote`.mp3).
  final String? remote;

  /// Downloadable: a second address of the same recording (the original source), tried when the website
  /// does not answer.
  final String? mirror;

  /// Author, source and licence when the licence asks for credit.
  final String? credit;

  bool get bundled => asset != null;
  String name(bool arabic) => arabic ? nameAr : nameEn;

  /// Where a downloadable recording is fetched from, in order.
  List<Uri> get downloadUris => [
    if (remote != null) Uri.parse('$adhanAudioBase/$remote.mp3'),
    if (mirror != null) Uri.parse(mirror!),
  ];
}

const allAdhanVoices = <AdhanVoice>[
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
    remote: 'adhan_makkah',
    mirror: 'https://audio.islamweb.net/audio/downloadmp3.php?audioid=122647',
  ),
  AdhanVoice(
    id: 'bukhari',
    nameAr: 'الشيخ عصام بخاري',
    nameEn: 'Sheikh Essam Bukhari',
    place: 'المسجد النبوي، المدينة المنورة',
    remote: 'adhan_bukhari',
    mirror: 'https://audio.islamweb.net/audio/downloadmp3.php?audioid=5',
  ),
  AdhanVoice(
    id: 'mismail',
    nameAr: 'الشيخ مصطفى إسماعيل',
    nameEn: 'Sheikh Mustafa Ismail',
    place: 'مصر',
    remote: 'adhan_mismail',
    mirror: 'https://audio.islamweb.net/audio/downloadmp3.php?audioid=176760',
  ),
  AdhanVoice(
    id: 'banna',
    nameAr: 'الشيخ محمود علي البنا',
    nameEn: 'Sheikh Mahmoud Ali Al-Banna',
    place: 'القاهرة',
    remote: 'adhan_banna',
    mirror: 'https://audio.islamweb.net/audio/downloadmp3.php?audioid=122666',
  ),
  AdhanVoice(
    id: 'rifaat',
    nameAr: 'الشيخ محمد رفعت',
    nameEn: 'Sheikh Muhammad Rifaat',
    place: 'القاهرة',
    remote: 'adhan_rifaat',
    mirror: 'https://audio.islamweb.net/audio/downloadmp3.php?audioid=122665',
  ),
  AdhanVoice(
    id: 'abdulbasit',
    nameAr: 'الشيخ عبد الباسط عبد الصمد',
    nameEn: 'Sheikh Abdul Basit Abdul Samad',
    place: 'مصر',
    remote: 'adhan_abdulbasit',
    mirror: 'https://audio.islamweb.net/audio/downloadmp3.php?audioid=88633',
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
    remote: 'adhan_afasy_fajr',
    mirror: 'https://audio.islamweb.net/audio/downloadmp3.php?audioid=206932',
  ),
  AdhanVoice(
    id: 'abdulbasit_fajr',
    nameAr: 'أذان الفجر: الشيخ عبد الباسط عبد الصمد',
    nameEn: 'Fajr adhan: Sheikh Abdul Basit Abdul Samad',
    place: 'مصر',
    fajr: true,
    remote: 'adhan_abdulbasit_fajr',
    mirror: 'https://audio.islamweb.net/audio/downloadmp3.php?audioid=404627',
  ),
  AdhanVoice(
    id: 'haram',
    nameAr: 'أذان المسجد الحرام بمكة المكرمة',
    nameEn: 'Adhan of the Grand Mosque, Makkah',
    place: 'مكة المكرمة',
    remote: 'adhan_haram',
    credit: '"Adhan, Great Mosque of Mecca - Jan 21, 2013", Seyfula Islam, Wikimedia Commons, CC BY 3.0',
  ),
  AdhanVoice(
    id: 'madinah',
    nameAr: 'أذان المسجد النبوي بالمدينة المنورة',
    nameEn: "Adhan of the Prophet's Mosque, Madinah",
    place: 'المدينة المنورة',
    remote: 'adhan_madinah',
    credit: '"Call to prayer from the prophet\'s mosque", ejaz215, Wikimedia Commons, CC BY 3.0',
  ),
  AdhanVoice(
    id: 'fakhry',
    nameAr: 'صباح فخري',
    nameEn: 'Sabah Fakhri',
    place: 'حلب، سوريا',
    remote: 'adhan_fakhry',
    mirror: 'https://upload.wikimedia.org/wikipedia/commons/2/27/Call_to_prayer_by_Sabah_Fakhry.mp3',
    credit: '"Call to prayer by Sabah Fakhry", Wikimedia Commons, public domain',
  ),
  AdhanVoice(
    id: 'v1',
    nameAr: 'صوت هادئ',
    nameEn: 'Calm voice',
    remote: 'adhan',
    credit: '"Beautiful adhan", Adam-synagda, Wikimedia Commons, CC0',
  ),
  AdhanVoice(
    id: 'v2',
    nameAr: 'عاقب عزيز',
    nameEn: 'Aaqib Azeez',
    remote: 'adhan_v2',
    mirror: 'https://upload.wikimedia.org/wikipedia/commons/7/7d/The_Adhan_-_Muslim_Call_to_Prayer_-_Aaqib_Azeez.mp3',
    credit: '"The Adhan - Muslim Call to Prayer - Aaqib Azeez", Atcovi, Wikimedia Commons, CC BY-SA 4.0',
  ),
  AdhanVoice(
    id: 'haram_fajr',
    nameAr: 'أذان الفجر (المركز الإسلامي في مالمو)',
    nameEn: 'Fajr adhan (Islamic Center, Malmö)',
    fajr: true,
    remote: 'adhan_haram_fajr',
    credit:
        '"Eid al-Fitr Fajr azan at Malmö Mosque - 19 August 2012", Islamic Center Malmö, Wikimedia Commons, CC BY 3.0',
  ),
];

const defaultAdhanVoice = 'mulla';
const defaultFajrVoice = 'daghriri_fajr';

/// The website folder that serves the downloadable recordings (the same files the website plays).
const adhanAudioBase = 'https://rattilwasalli.com/audio';

/// Whether [id] names one of the muezzins above (bundled or downloadable).
bool isAdhanVoiceId(String? id) => id != null && allAdhanVoices.any((v) => v.id == id);

AdhanVoice? findAdhanVoice(String? id) {
  for (final v in allAdhanVoices) {
    if (v.id == id) return v;
  }
  return null;
}
