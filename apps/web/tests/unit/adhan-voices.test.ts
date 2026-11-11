import { describe, expect, it } from "vitest";
import {
  adhanVoiceSrc,
  DEFAULT_ADHAN_VOICE,
  DEFAULT_FAJR_VOICE,
  isAdhanVoiceId,
  normalizeArabic,
} from "@/lib/adhan-voices";
import { DEFAULT_ADHAN, voiceForPrayer } from "@/lib/adhan-alerts";

describe("adhan voices", () => {
  it("defaults to Ali Mulla (Makkah Haram), with Al-Daghriri for Fajr", () => {
    expect(DEFAULT_ADHAN_VOICE).toBe("mulla");
    expect(DEFAULT_FAJR_VOICE).toBe("daghriri_fajr");
    expect(voiceForPrayer(DEFAULT_ADHAN, "fajr")).toBe("daghriri_fajr");
    expect(voiceForPrayer(DEFAULT_ADHAN, "maghrib")).toBe("mulla");
    expect(adhanVoiceSrc("rifaat")).toBe("/audio/adhan_rifaat.mp3");
    expect(adhanVoiceSrc("haram")).toBe("/audio/adhan_haram.mp3");
    expect(adhanVoiceSrc("haram_fajr")).toBe("/audio/adhan_haram_fajr.mp3");
  });

  it("accepts only the bundled, openly licensed voices", () => {
    expect(isAdhanVoiceId("madinah")).toBe(true);
    expect(isAdhanVoiceId("iw426698")).toBe(false);
    expect(isAdhanVoiceId("../x")).toBe(false);
    expect(adhanVoiceSrc("nobody", true)).toBe("/audio/adhan_daghriri_fajr.mp3");
    expect(isAdhanVoiceId("afasy_fajr")).toBe(true);
    expect(adhanVoiceSrc("fakhry")).toBe("/audio/adhan_fakhry.mp3");
  });

  it("search folds Arabic letter forms and diacritics", () => {
    expect(normalizeArabic("أحمد")).toBe(normalizeArabic("احمد"));
    expect(normalizeArabic("حمزة")).toBe("حمزه");
    expect(normalizeArabic("مُوسى")).toBe("موسي");
  });
});
