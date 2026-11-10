/**
 * Muezzin recordings the user can choose for the adhan. Every entry is a freely licensed recording
 * (sources and licences in apps/mobile/assets/audio/ADHAN_AUDIO.md); none is taken from another adhan app.
 * Same list as apps/mobile/lib/domain/adhan_voices.dart.
 */
export interface AdhanVoice {
  id: string;
  nameAr: string;
  nameEn: string;
  /** Path under public/. */
  file: string;
  /** Author, source and licence. */
  credit: string;
}

export const ADHAN_VOICES: readonly AdhanVoice[] = [
  {
    id: "v1",
    nameAr: "الصوت الأول (هادئ)",
    nameEn: "Voice 1 (calm)",
    file: "/audio/adhan.mp3",
    credit: '"Beautiful adhan", Adam-synagda, Wikimedia Commons, CC0',
  },
];

export const DEFAULT_ADHAN_VOICE = "v1";

export function adhanVoiceById(id: unknown): AdhanVoice {
  return ADHAN_VOICES.find((v) => v.id === id) ?? ADHAN_VOICES[0]!;
}
