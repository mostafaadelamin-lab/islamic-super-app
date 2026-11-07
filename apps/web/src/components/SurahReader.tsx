"use client";
import Link from "next/link";
import { useEffect, useRef, useState } from "react";
import { t, type Locale } from "@/lib/i18n";
import { href } from "@/lib/locale-path";
import { localizeDigits } from "@/lib/digits";
import { renderQuranText } from "@/lib/quran-render";
import { pageForAyah, surahMeta, type SurahMeta } from "@/lib/pages";
import { bookmarksStore, isBookmarked, toggleBookmark } from "@/lib/bookmarks";
import { lastReadStore, prefsStore } from "@/lib/settings";
import { useStore } from "@/hooks/useStore";
import { useTranslation } from "@/hooks/useTranslation";
import { AyahMarker } from "./AyahMarker";
import { TafsirPanel } from "./TafsirPanel";

export interface SurahReaderProps {
  locale: Locale;
  meta: SurahMeta;
  ayahs: string[];
  basmala: string | null;
}

export function SurahReader({ locale, meta, ayahs, basmala }: SurahReaderProps) {
  const prefs = useStore(prefsStore);
  const bookmarks = useStore(bookmarksStore);
  const [retry, setRetry] = useState(0);
  const [tafsirFor, setTafsirFor] = useState<number | null>(null);
  const tr = useTranslation(meta.n, prefs.translation, retry);
  const listRef = useRef<HTMLDivElement>(null);
  const prev = surahMeta(meta.n - 1);
  const next = surahMeta(meta.n + 1);
  const name = (m: SurahMeta): string => (locale === "ar" ? m.nameAr : m.translit);

  useEffect(() => {
    const root = listRef.current;
    if (!root || typeof IntersectionObserver === "undefined") return;
    let lastAyah = -1;
    const obs = new IntersectionObserver(
      (entries) => {
        const visible = entries
          .filter((e) => e.isIntersecting)
          .map((e) => Number((e.target as HTMLElement).dataset.ayah))
          .sort((a, b) => a - b);
        const a = visible[0];
        if (a && a !== lastAyah) {
          lastAyah = a;
          lastReadStore.set({ surah: meta.n, ayah: a, page: pageForAyah(meta.n, a), at: Date.now() });
        }
      },
      { rootMargin: "-120px 0px -50% 0px" },
    );
    root.querySelectorAll("[data-ayah]").forEach((el) => obs.observe(el));
    return () => obs.disconnect();
  }, [meta.n]);

  return (
    <>
      <header>
        <h1>
          <span lang="ar" className="surah-name-ar">
            {meta.nameAr}
          </span>{" "}
          <span className="muted">
            · {meta.translit} ({meta.nameEn})
          </span>
        </h1>
        <p className="muted">
          {t(locale, "quran.surahN", { n: localizeDigits(meta.n, locale) })} ·{" "}
          {t(locale, "quran.ayahCount", { count: localizeDigits(meta.ayahCount, locale) })} ·{" "}
          {t(locale, meta.revelation === "meccan" ? "quran.meccan" : "quran.medinan")}
        </p>
        <div className="row">
          <Link className="btn" href={href(locale, `page/${pageForAyah(meta.n, 1)}`)}>
            {t(locale, "quran.readOnPage", { page: localizeDigits(pageForAyah(meta.n, 1), locale) })}
          </Link>
          <label className="check">
            <input
              type="checkbox"
              checked={prefs.translation}
              onChange={(e) => prefsStore.set((p) => ({ ...p, translation: e.target.checked }))}
              data-testid="translation-toggle"
            />
            {t(locale, "quran.showTranslation")}
          </label>
        </div>
        {tr.status === "loading" ? <p className="muted">{t(locale, "quran.translationLoading")}</p> : null}
        {tr.status === "error" ? (
          <p className="alert alert-error" role="alert">
            {t(locale, "quran.loadError")}{" "}
            <button type="button" className="btn" onClick={() => setRetry((r) => r + 1)}>
              {t(locale, "common.retry")}
            </button>
          </p>
        ) : null}
        {tr.status === "ready" ? <p className="muted">{t(locale, "quran.translationNote")}</p> : null}
      </header>

      <div className="reader" ref={listRef}>
        {basmala ? (
          <p className="quran basmala" lang="ar" dir="rtl">
            {renderQuranText(basmala)}
          </p>
        ) : null}
        {ayahs.map((text, i) => {
          const a = i + 1;
          const marked = isBookmarked(bookmarks, meta.n, a);
          const en = tr.status === "ready" ? tr.lines[i] : undefined;
          return (
            <article className="ayah" id={`a-${a}`} data-ayah={a} key={a}>
              <p className="quran" lang="ar" dir="rtl" style={{ margin: 0 }}>
                {renderQuranText(text)}
                <AyahMarker n={a} locale={locale} />
              </p>
              {en ? (
                <p className="translation" lang="en" dir="ltr">
                  {en}
                </p>
              ) : null}
              <div className="ayah-tools">
                <button
                  type="button"
                  className="btn"
                  data-bookmarked={marked ? "true" : "false"}
                  data-testid={`bookmark-${a}`}
                  aria-label={`${marked ? t(locale, "quran.removeBookmark") : t(locale, "quran.bookmark")} — ${t(locale, "quran.ayah", { n: localizeDigits(a, locale) })}`}
                  onClick={() => bookmarksStore.set((s) => toggleBookmark(s, meta.n, a, Date.now()))}
                >
                  {marked ? t(locale, "quran.removeBookmark") : t(locale, "quran.bookmark")}
                </button>
                <button
                  type="button"
                  className="btn"
                  aria-expanded={tafsirFor === a}
                  data-testid={`tafsir-toggle-${a}`}
                  aria-label={t(locale, "tafsir.showOf", { n: localizeDigits(a, locale) })}
                  onClick={() => setTafsirFor((cur) => (cur === a ? null : a))}
                >
                  {t(locale, "tafsir.show")}
                </button>
              </div>
              {tafsirFor === a ? <TafsirPanel locale={locale} surah={meta.n} ayah={a} /> : null}
            </article>
          );
        })}
      </div>

      <nav className="pager" aria-label={t(locale, "quran.surahNav")}>
        {prev ? (
          <Link className="btn" href={href(locale, `surah/${prev.n}`)} rel="prev">
            {t(locale, "quran.prevSurah")}: {name(prev)}
          </Link>
        ) : (
          <span />
        )}
        {next ? (
          <Link className="btn" href={href(locale, `surah/${next.n}`)} rel="next">
            {t(locale, "quran.nextSurah")}: {name(next)}
          </Link>
        ) : null}
      </nav>
    </>
  );
}
