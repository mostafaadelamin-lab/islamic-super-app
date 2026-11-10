import { describe, expect, it } from "vitest";
import {
  adhanVoiceSrc,
  DEFAULT_ADHAN_VOICE,
  DEFAULT_FAJR_VOICE,
  isAdhanVoiceId,
  normalizeArabic,
  remoteAdhanId,
  voiceFromCatalog,
} from "@/lib/adhan-voices";
import { DEFAULT_ADHAN, voiceForPrayer } from "@/lib/adhan-alerts";
import catalog from "../../../mobile/assets/content/adhan_catalog.json";

describe("adhan voices", () => {
  it("defaults to the Makkah Haram adhan, with its own Fajr adhan", () => {
    expect(DEFAULT_ADHAN_VOICE).toBe("haram");
    expect(DEFAULT_FAJR_VOICE).toBe("haram_fajr");
    expect(voiceForPrayer(DEFAULT_ADHAN, "fajr")).toBe("haram_fajr");
    expect(voiceForPrayer(DEFAULT_ADHAN, "maghrib")).toBe("haram");
    expect(adhanVoiceSrc("haram")).toBe("/audio/adhan_haram.mp3");
    expect(adhanVoiceSrc("haram_fajr")).toBe("/audio/adhan_haram_fajr.mp3");
  });

  it("accepts collection ids only in the iw<number> form", () => {
    expect(isAdhanVoiceId("iw426698")).toBe(true);
    expect(isAdhanVoiceId("iw")).toBe(false);
    expect(isAdhanVoiceId("../x")).toBe(false);
    expect(remoteAdhanId("iw122646")).toBe(122646);
    expect(adhanVoiceSrc("iw5")).toBe("https://audio.islamweb.net/audio/downloadmp3.php?audioid=5");
    expect(adhanVoiceSrc("nobody", true)).toBe("/audio/adhan_haram_fajr.mp3");
  });

  it("catalogue: unique ids, Arabic names, Fajr adhans marked", () => {
    const ids = new Set(catalog.map((e) => e.id));
    expect(ids.size).toBe(catalog.length);
    expect(catalog.filter((e) => e.fajr).length).toBeGreaterThan(30);
    expect(catalog.every((e) => /[؀-ۿ]/.test(e.muezzin))).toBe(true);
    expect(voiceFromCatalog(catalog[0]!).id).toMatch(/^iw\d+$/);
  });

  it("search folds Arabic letter forms and diacritics", () => {
    expect(normalizeArabic("أحمد")).toBe(normalizeArabic("احمد"));
    expect(normalizeArabic("حمزة")).toBe("حمزه");
    expect(normalizeArabic("مُوسى")).toBe("موسي");
  });
});
