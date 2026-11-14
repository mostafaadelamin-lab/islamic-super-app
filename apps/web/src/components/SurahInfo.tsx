import { t, type Locale } from "@/lib/i18n";
import { localizeDigits } from "@/lib/digits";
import type { SurahMeta } from "@/lib/pages";
import type { SurahInfoData } from "@/lib/server/content";
import { Icon } from "./Icon";

/** The app's surah card: place and order of revelation, introduction and reasons for revelation (verbatim). */
export function SurahInfo({ locale, meta, info }: { locale: Locale; meta: SurahMeta; info: SurahInfoData | null }) {
  const paras = (text: string) =>
    text
      .split("\n")
      .filter((p) => p.trim() !== "")
      .map((p, i) => (
        <p key={i} lang="ar" dir="rtl">
          {p}
        </p>
      ));
  return (
    <details className="card surah-info" data-testid="surah-info">
      <summary>
        <Icon name="info" size={18} /> {t(locale, "surahInfo.title")}
      </summary>
      <p className="row surah-info-chips">
        <span className="chip">
          {t(locale, "surahInfo.place")}: {t(locale, meta.revelation === "meccan" ? "quran.meccan" : "quran.medinan")}
        </span>
        {info?.order ? (
          <span className="chip">
            {t(locale, "surahInfo.order")}: {localizeDigits(info.order, locale)}
          </span>
        ) : null}
        <span className="chip">
          {t(locale, "surahInfo.ayahs")}: {localizeDigits(meta.ayahCount, locale)}
        </span>
      </p>
      {!info ? (
        <p className="muted">{t(locale, "surahInfo.missing")}</p>
      ) : (
        <>
          {info.intro ? (
            <>
              <h2>{t(locale, "surahInfo.about")}</h2>
              {paras(info.intro)}
            </>
          ) : null}
          <h2>{t(locale, "surahInfo.asbab")}</h2>
          {info.asbab ? (
            paras(info.asbab)
          ) : info.wahidi && info.wahidi.length > 0 ? (
            <>
              <p className="muted small">{t(locale, "surahInfo.wahidi")}</p>
              {info.wahidi.map((w, i) => (
                <div key={i}>
                  <h3>{t(locale, "surahInfo.ayahN", { n: localizeDigits(w.ayah, locale) })}</h3>
                  {paras(w.text)}
                </div>
              ))}
            </>
          ) : (
            <p className="muted">{t(locale, "surahInfo.noAsbab")}</p>
          )}
        </>
      )}
    </details>
  );
}
