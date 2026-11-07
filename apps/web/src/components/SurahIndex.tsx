"use client";
import Link from "next/link";
import { useState } from "react";
import { t, type Locale } from "@/lib/i18n";
import { href } from "@/lib/locale-path";
import { localizeDigits } from "@/lib/digits";
import { normalizeArabic } from "@/lib/search";
import { pageForAyah, SURAHS, type SurahMeta } from "@/lib/pages";

export function filterSurahs(query: string, list: readonly SurahMeta[] = SURAHS): SurahMeta[] {
  const raw = query.trim();
  if (!raw) return [...list];
  const digits = raw.replace(/[٠-٩]/g, (d) => String(d.charCodeAt(0) - 0x0660));
  if (/^\d+$/.test(digits)) return list.filter((s) => String(s.n).startsWith(digits));
  const q = raw.toLowerCase();
  const qa = normalizeArabic(raw);
  const qLatin = q.replace(/[^a-z]/g, "");
  return list.filter(
    (s) =>
      s.nameEn.toLowerCase().includes(q) ||
      (qLatin.length > 0 &&
        s.translit
          .toLowerCase()
          .replace(/[^a-z]/g, "")
          .includes(qLatin)) ||
      (qa.length > 0 && normalizeArabic(s.nameAr).includes(qa)),
  );
}

export function SurahIndex({ locale }: { locale: Locale }) {
  const [q, setQ] = useState("");
  const list = filterSurahs(q);
  return (
    <>
      <div className="field">
        <label htmlFor="surah-filter">{t(locale, "quran.filter")}</label>
        <input
          id="surah-filter"
          type="search"
          value={q}
          placeholder={t(locale, "quran.filterPlaceholder")}
          onChange={(e) => setQ(e.target.value)}
          autoComplete="off"
        />
      </div>
      {list.length === 0 ? (
        <p className="muted" role="status">
          {t(locale, "quran.noSurahs")}
        </p>
      ) : null}
      <ul className="surah-list grid" aria-label={t(locale, "quran.surahList")} data-testid="surah-list">
        {list.map((s) => (
          <li key={s.n} className="surah-item">
            <Link
              className="tile surah-link"
              href={href(locale, `page/${pageForAyah(s.n, 1)}`)}
              prefetch={false}
              data-testid="surah-open"
            >
              <span className="surah-num">{localizeDigits(s.n, locale)}</span>
              <span>
                <strong lang="ar" className="surah-name-ar">
                  {s.nameAr}
                </strong>
                <br />
                <span className="muted small">
                  {s.translit} · {s.nameEn}
                </span>
              </span>
              <span className="muted small surah-meta">
                {t(locale, "quran.ayahCount", { count: localizeDigits(s.ayahCount, locale) })}
                <br />
                {t(locale, s.revelation === "meccan" ? "quran.meccan" : "quran.medinan")}
              </span>
            </Link>
            <Link
              className="surah-list-view"
              href={href(locale, `surah/${s.n}`)}
              prefetch={false}
              aria-label={t(locale, "quran.listViewOf", { surah: locale === "ar" ? s.nameAr : s.translit })}
              data-testid="surah-list-view"
            >
              {t(locale, "quran.listView")}
            </Link>
          </li>
        ))}
      </ul>
    </>
  );
}
