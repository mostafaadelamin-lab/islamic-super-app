"use client";
import { t, type Locale } from "@/lib/i18n";
import { localizeDigits } from "@/lib/digits";
import { audioStore, RECITERS, REPEAT_CHOICES } from "@/lib/audio";
import { useStore } from "@/hooks/useStore";

export function AudioSettings({ locale }: { locale: Locale }) {
  const prefs = useStore(audioStore);
  return (
    <section className="card" aria-labelledby="audio-h">
      <h2 id="audio-h" className="card-title">
        {t(locale, "audio.settings")}
      </h2>
      <div className="field">
        <label htmlFor="reciter">{t(locale, "audio.reciter")}</label>
        <select
          id="reciter"
          value={prefs.reciter}
          onChange={(e) => audioStore.set((p) => ({ ...p, reciter: e.target.value }))}
        >
          {RECITERS.map((r) => (
            <option key={r.folder} value={r.folder}>
              {locale === "ar" ? r.ar : r.en}
            </option>
          ))}
        </select>
      </div>
      <div className="field">
        <label htmlFor="repeat">{t(locale, "audio.repeat")}</label>
        <select
          id="repeat"
          value={prefs.repeat}
          onChange={(e) => audioStore.set((p) => ({ ...p, repeat: Number(e.target.value) }))}
        >
          {REPEAT_CHOICES.map((n) => (
            <option key={n} value={n}>
              {t(locale, "audio.times", { n: localizeDigits(n, locale) })}
            </option>
          ))}
        </select>
      </div>
      <label className="check">
        <input
          type="checkbox"
          checked={prefs.follow}
          onChange={(e) => audioStore.set((p) => ({ ...p, follow: e.target.checked }))}
        />
        {t(locale, "audio.follow")}
      </label>
      <p className="muted small">{t(locale, "audio.onlineNote")}</p>
    </section>
  );
}
