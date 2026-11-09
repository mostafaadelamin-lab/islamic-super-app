"use client";
import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { t, type Locale } from "@/lib/i18n";
import { localizeDigits } from "@/lib/digits";
import { renderQuranText } from "@/lib/quran-render";
import {
  clampFontSize,
  clampHijriOffset,
  FONT_MAX,
  FONT_MIN,
  HIJRI_OFFSET_MAX,
  prefsStore,
  type ThemePref,
} from "@/lib/settings";
import { hijriDate } from "@/lib/dates";
import { useStore } from "@/hooks/useStore";

const THEMES: { value: ThemePref; key: string }[] = [
  { value: "system", key: "settings.themeSystem" },
  { value: "light", key: "settings.themeLight" },
  { value: "dark", key: "settings.themeDark" },
];

export function DisplaySettings({ locale, preview }: { locale: Locale; preview: string }) {
  const prefs = useStore(prefsStore);
  const router = useRouter();
  // The preview uses today's date, so it is rendered on the client only (no hydration mismatch).
  const [now, setNow] = useState<Date | null>(null);
  useEffect(() => setNow(new Date()), []);
  return (
    <section className="card" aria-labelledby="display-h">
      <h2 id="display-h" style={{ marginTop: 0 }}>
        {t(locale, "settings.display")}
      </h2>
      <div className="field">
        <label htmlFor="language">{t(locale, "settings.language")}</label>
        <select
          id="language"
          value={locale}
          onChange={(e) => {
            const next = e.target.value === "en" ? "en" : "ar";
            prefsStore.set((p) => ({ ...p, locale: next }));
            router.push(`/${next}/settings/`);
          }}
        >
          <option value="ar" lang="ar">
            العربية
          </option>
          <option value="en" lang="en">
            English
          </option>
        </select>
      </div>
      <fieldset className="field" style={{ border: 0, padding: 0 }}>
        <legend className="label">{t(locale, "settings.theme")}</legend>
        <div className="row">
          {THEMES.map((th) => (
            <label className="check" key={th.value}>
              <input
                type="radio"
                name="theme"
                value={th.value}
                checked={prefs.theme === th.value}
                onChange={() => prefsStore.set((p) => ({ ...p, theme: th.value }))}
              />
              {t(locale, th.key)}
            </label>
          ))}
        </div>
      </fieldset>
      <div className="field">
        <label htmlFor="font-size">
          {t(locale, "settings.fontSize")}:{" "}
          <output htmlFor="font-size">{localizeDigits(prefs.fontSize, locale)}</output>
        </label>
        <div className="row">
          <button
            type="button"
            className="btn"
            aria-label={`${t(locale, "settings.fontSize")} −`}
            disabled={prefs.fontSize <= FONT_MIN}
            onClick={() => prefsStore.set((p) => ({ ...p, fontSize: clampFontSize(p.fontSize - 1) }))}
          >
            −
          </button>
          <input
            id="font-size"
            type="range"
            min={FONT_MIN}
            max={FONT_MAX}
            step={1}
            value={prefs.fontSize}
            onChange={(e) =>
              prefsStore.set((p) => ({ ...p, fontSize: clampFontSize(Number(e.target.value)) }))
            }
          />
          <button
            type="button"
            className="btn"
            aria-label={`${t(locale, "settings.fontSize")} +`}
            disabled={prefs.fontSize >= FONT_MAX}
            onClick={() => prefsStore.set((p) => ({ ...p, fontSize: clampFontSize(p.fontSize + 1) }))}
          >
            +
          </button>
        </div>
        <p className="quran reader" lang="ar" dir="rtl" data-testid="font-preview">
          <span className="sr-only">{t(locale, "settings.fontPreview")}: </span>
          {renderQuranText(preview)}
        </p>
      </div>
      <label className="check">
        <input
          type="checkbox"
          checked={prefs.translation}
          onChange={(e) => prefsStore.set((p) => ({ ...p, translation: e.target.checked }))}
        />
        {t(locale, "settings.translation")}
      </label>
      <div className="field" data-testid="hijri-offset">
        <label htmlFor="hijri-offset">
          {t(locale, "settings.hijriOffset")}:{" "}
          <output htmlFor="hijri-offset" data-testid="hijri-offset-value" dir="ltr">
            {localizeDigits(
              prefs.hijriOffset > 0 ? `+${prefs.hijriOffset}` : String(prefs.hijriOffset),
              locale,
            )}
          </output>
        </label>
        <div className="row">
          <button
            type="button"
            className="btn"
            aria-label={`${t(locale, "settings.hijriOffset")} −`}
            disabled={prefs.hijriOffset <= -HIJRI_OFFSET_MAX}
            onClick={() =>
              prefsStore.set((p) => ({ ...p, hijriOffset: clampHijriOffset(p.hijriOffset - 1) }))
            }
          >
            −
          </button>
          <span id="hijri-offset" data-testid="hijri-offset-preview">
            {now
              ? hijriDate(now, Intl.DateTimeFormat().resolvedOptions().timeZone, locale, prefs.hijriOffset)
              : ""}
          </span>
          <button
            type="button"
            className="btn"
            aria-label={`${t(locale, "settings.hijriOffset")} +`}
            disabled={prefs.hijriOffset >= HIJRI_OFFSET_MAX}
            onClick={() =>
              prefsStore.set((p) => ({ ...p, hijriOffset: clampHijriOffset(p.hijriOffset + 1) }))
            }
          >
            +
          </button>
        </div>
        <p className="muted">{t(locale, "settings.hijriOffsetHint")}</p>
      </div>
    </section>
  );
}
