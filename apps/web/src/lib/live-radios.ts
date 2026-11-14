/**
 * Live radios shown at the top of the radios tab (same list as the app's radio screen,
 * apps/mobile/lib/ui/radio_screen.dart): live sound from the two Holy Mosques (owner, 2026-11-14:
 * audio only, no video) and the Cairo and Saudi Quran radios. No source names are shown.
 */
export interface LiveRadio {
  id: string;
  ar: string;
  en: string;
  url: string;
}

export const LIVE_RADIOS: readonly LiveRadio[] = [
  {
    id: "makkah",
    ar: "بث مباشر من المسجد الحرام بمكة المكرمة",
    en: "Live from Masjid al-Haram, Makkah",
    url: "https://win.holol.com/live/quran/playlist.m3u8",
  },
  {
    id: "madinah",
    ar: "بث مباشر من المسجد النبوي بالمدينة المنورة",
    en: "Live from the Prophet's Mosque, Madinah",
    url: "https://win.holol.com/live/sunnah/playlist.m3u8",
  },
  {
    id: "eg",
    ar: "إذاعة القرآن الكريم من القاهرة",
    en: "Holy Quran Radio, Cairo",
    url: "https://stream.radiojar.com/8s5u5tpdtwzuv",
  },
  {
    id: "sa",
    ar: "إذاعة القرآن الكريم السعودية",
    en: "Holy Quran Radio, Saudi Arabia",
    url: "https://stream.radiojar.com/0tpy1h0kxtzuv",
  },
];

/** HLS streams (.m3u8) need hls.js in browsers without native HLS (Chrome/Firefox on desktop). */
export function isHls(url: string): boolean {
  try {
    return new URL(url).pathname.toLowerCase().endsWith(".m3u8");
  } catch {
    return false;
  }
}
