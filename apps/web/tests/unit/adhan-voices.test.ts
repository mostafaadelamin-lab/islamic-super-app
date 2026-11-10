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
  it("defaults to the Makkah Haram adhan, with its own Fajr adhan", () => {
    expect(DEFAULT_ADHAN_VOICE).toBe("haram");
    expect(DEFAULT_FAJR_VOICE).toBe("haram_fajr");
    expect(voiceForPrayer(DEFAULT_ADHAN, "fajr")).toBe("haram_fajr");
    expect(voiceForPrayer(DEFAULT_ADHAN, "maghrib")).toBe("haram");
    expect(adhanVoiceSrc("haram")).toBe("/audio/adhan_haram.mp3");
    expect(adhanVoiceSrc("haram_fajr")).toBe("/audio/adhan_haram_fajr.mp3");
  });

  it("accepts only the bundled, openly licensed voices", () => {
    expect(isAdhanVoiceId("madinah")).toBe(true);
    expect(isAdhanVoiceId("iw426698")).toBe(false);
    expect(isAdhanVoiceId("../x")).toBe(false);
    expect(adhanVoiceSrc("nobody", true)).toBe("/audio/adhan_haram_fajr.mp3");
    expect(adhanVoiceSrc("fakhry")).toBe("/audio/adhan_fakhry.mp3");
  });

  it("search folds Arabic letter forms and diacritics", () => {
    expect(normalizeArabic("أحمد")).toBe(normalizeArabic("احمد"));
    expect(normalizeArabic("حمزة")).toBe("حمزه");
    expect(normalizeArabic("مُوسى")).toBe("موسي");
  });
});
