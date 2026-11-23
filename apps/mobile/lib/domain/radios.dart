// The live Quran radios the app lists first (radios screen, home radio, car screen).

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
