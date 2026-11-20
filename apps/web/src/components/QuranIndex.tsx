"use client";
import Link from "next/link";
import { useEffect, useMemo, useState } from "react";
import quartersJson from "@/generated/quarters.json";
import { t, type Locale } from "@/lib/i18n";
import { href } from "@/lib/locale-path";
import { localizeDigits } from "@/lib/digits";
import { normalizeArabic } from "@/lib/search";
import { renderQuranText } from "@/lib/quran-render";
import { JUZ, juzForPage, pageForAyah, SURAHS, type Ref, type SurahMeta } from "@/lib/pages";
import { lastReadStore } from "@/lib/settings";
import { useStore } from "@/hooks/useStore";
import { filterSurahs } from "./SurahIndex";
import { Icon } from "./Icon";

/** One hizb quarter (rub' al-hizb). `opening` is copied verbatim from the canonical text at build time. */
export interface Quarter {
  n: number;
  hizb: number;
  quarter: number; // 0 = start of the hizb, 1..3 = 1/4, 2/4, 3/4
  juz: number;
  start: Ref;
  page: number;
  opening: string;
  more: boolean;
}

export const QUARTERS: readonly Quarter[] = quartersJson as Quarter[];

const cmp = (a: Ref, b: Ref): number => a[0] - b[0] || a[1] - b[1];
const QUARTERS_PER_HIZB = 4;
const ARABIC_ZERO = 0x0660;
const MUSHAF_PAGES = 604;

/** The juz in which ayah [r] lies (by the juz start ayahs). */
export function juzOfAyah(r: Ref): number {
  return JUZ.filter((z) => cmp(z.start, r) <= 0).reduce((j, z) => z.juz, 1);
}

export function juzTitle(locale: Locale, juz: number): string {
  const ordinal = t(locale, "quran.juzOrdinals").split("|")[juz - 1] ?? String(juz);
  return t(locale, "quran.juzTitle", { ordinal });
}

/** Badge text for a quarter: the hizb number at its start, then 1/4, 2/4, 3/4 (as in the printed Mushaf index). */
export function quarterBadge(q: Quarter, locale: Locale): string {
  return q.quarter === 0
    ? localizeDigits(q.hizb, locale)
    : `${localizeDigits(q.quarter, locale)}/${localizeDigits(QUARTERS_PER_HIZB, locale)}`;
}

export function filterQuarters(query: string, list: readonly Quarter[] = QUARTERS): Quarter[] {
  const raw = query.trim();
  if (!raw) return [...list];
  // Arabic-Indic digits to ASCII: "٢٦" -> "26"; other characters are kept ("al" stays "al").
  const digits = raw.replace(/[٠-٩]/g, (d) => String(d.charCodeAt(0) - ARABIC_ZERO));
  // Only ASCII digits: "26" matches, "2a" does not.
  if (/^\d+$/.test(digits)) {
    const n = Number(digits);
    return list.filter((q) => q.hizb === n || q.page === n);
  }
  const surahs = new Set(filterSurahs(raw).map((s) => s.n));
  const qa = normalizeArabic(raw);
  return list.filter(
    (q) => surahs.has(q.start[0]) || (qa.length > 1 && normalizeArabic(q.opening).includes(qa)),
  );
}

function groupByJuz<T>(items: readonly T[], juzOf: (x: T) => number): { juz: number; items: T[] }[] {
  return items.reduce<{ juz: number; items: T[] }[]>((out, x) => {
    const j = juzOf(x);
    const last = out[out.length - 1];
    if (last && last.juz === j) last.items.push(x);
    else out.push({ juz: j, items: [x] });
    return out;
  }, []);
}

function StarBadge({ label, small }: { label: string; small?: boolean }) {
  return (
    <span className={`qidx-badge${small ? " qidx-badge-frac" : ""}`} aria-hidden="true">
      <svg viewBox="0 0 48 48" focusable="false">
        <rect x="9" y="9" width="30" height="30" rx="2" />
        <rect x="9" y="9" width="30" height="30" rx="2" transform="rotate(45 24 24)" />
        <circle cx="24" cy="24" r="13.5" />
      </svg>
      <span>{label}</span>
    </span>
  );
}

type Tab = "surahs" | "juz" | "quarters";

/**
 * The Quran index ("فهرس السور"): a Surahs / Quarters toggle, a search box and a
 * list grouped under juz headers. Tapping a row opens the Mushaf at that page.
 * The row holding the reader's current page (from ?page=N, else the last read
 * position) is highlighted.
 */
export function QuranIndex({ locale }: { locale: Locale }) {
  const [tab, setTab] = useState<Tab>("surahs");
  const [q, setQ] = useState("");
  const [fromPage, setFromPage] = useState<number | null>(null);
  const last = useStore(lastReadStore);

  useEffect(() => {
    const p = Number(new URLSearchParams(window.location.search).get("page"));
    if (Number.isInteger(p) && p >= 1 && p <= MUSHAF_PAGES) setFromPage(p);
    const tabParam = new URLSearchParams(window.location.search).get("tab");
    if (tabParam === "quarters" || tabParam === "juz") setTab(tabParam);
  }, []);

  // Coming from the reader (?page=N) wins over the saved last-read ayah.
  const current: Ref | null = !fromPage && last ? [last.surah, last.ayah] : null;
  const currentPage = fromPage ?? last?.page ?? null;

  // Coming from the reader: bring the highlighted row into view.
  useEffect(() => {
    if (fromPage) document.querySelector(".qidx-item.current")?.scrollIntoView({ block: "center" });
  }, [fromPage, tab]);

  const surahGroups = useMemo(() => groupByJuz(filterSurahs(q), (s) => juzOfAyah([s.n, 1])), [q]);
  const quarterGroups = useMemo(() => groupByJuz(filterQuarters(q), (x) => x.juz), [q]);

  // Highlight: the surah / quarter that contains the current position.
  const surahOnPage = currentPage
    ? (SURAHS.findLast((s) => pageForAyah(s.n, 1) <= currentPage)?.n ?? null)
    : null;
  const currentSurah = current ? current[0] : surahOnPage;
  const reached = (x: Quarter): boolean => {
    if (current) return cmp(x.start, current) <= 0;
    return currentPage !== null && x.page <= currentPage;
  };
  const currentQuarter = QUARTERS.findLast(reached)?.n ?? null;

  const juzRows = useMemo(() => filterJuz(q), [q]);
  const currentJuz = current ? juzOfAyah(current) : currentPage ? juzForPage(currentPage) : null;
  const empty =
    tab === "surahs"
      ? surahGroups.length === 0
      : tab === "juz"
        ? juzRows.length === 0
        : quarterGroups.length === 0;

  return (
    <section className="qidx" aria-labelledby="qidx-title">
      <h1 id="qidx-title" className="qidx-title">
        {t(locale, "quran.index")}
      </h1>
      <div className="qidx-tabs" role="tablist" aria-label={t(locale, "quran.index")}>
        {(["surahs", "juz", "quarters"] as const).map((k) => (
          <button
            key={k}
            type="button"
            role="tab"
            id={`qidx-tab-${k}`}
            aria-selected={tab === k}
            aria-controls="qidx-panel"
            className={tab === k ? "on" : ""}
            data-testid={`qidx-tab-${k}`}
            onClick={() => setTab(k)}
          >
            {t(
              locale,
              k === "surahs" ? "quran.tabSurahs" : k === "juz" ? "quran.tabJuz" : "quran.tabQuarters",
            )}
          </button>
        ))}
      </div>
      <div className="qidx-search">
        <label className="qidx-field">
          <Icon name="search" />
          <span className="sr-only">
            {t(locale, tab === "surahs" ? "quran.filter" : "quran.indexSearch")}
          </span>
          <input
            id="surah-filter"
            type="search"
            value={q}
            placeholder={t(locale, "quran.indexSearch")}
            aria-label={t(locale, tab === "surahs" ? "quran.filter" : "quran.indexSearch")}
            onChange={(e) => setQ(e.target.value)}
            autoComplete="off"
            data-testid="qidx-search"
          />
        </label>
        <button
          type="button"
          className="qidx-clear"
          aria-label={t(locale, "quran.clearSearch")}
          onClick={() => setQ("")}
          disabled={!q}
        >
          <Icon name="close" />
        </button>
      </div>

      <div id="qidx-panel" role="tabpanel" aria-labelledby={`qidx-tab-${tab}`}>
        {empty ? (
          <p className="muted qidx-empty" role="status">
            {t(locale, tab === "surahs" ? "quran.noSurahs" : "quran.noResults")}
          </p>
        ) : null}
        {tab === "surahs" ? (
          <div data-testid="surah-list" aria-label={t(locale, "quran.surahList")}>
            {surahGroups.map((g) => (
              <section key={g.juz} className="qidx-group" aria-label={juzTitle(locale, g.juz)}>
                <h2 className="qidx-juz">{juzTitle(locale, g.juz)}</h2>
                <ul className="qidx-list">
                  {g.items.map((s) => (
                    <SurahRow key={s.n} s={s} locale={locale} current={s.n === currentSurah} />
                  ))}
                </ul>
              </section>
            ))}
          </div>
        ) : tab === "juz" ? (
          <ul className="qidx-list qidx-juz-list" data-testid="juz-list">
            {juzRows.map((z) => (
              <JuzRow key={z.juz} juz={z.juz} locale={locale} current={z.juz === currentJuz} />
            ))}
          </ul>
        ) : (
          <div data-testid="quarter-list">
            {quarterGroups.map((g) => (
              <section key={g.juz} className="qidx-group" aria-label={juzTitle(locale, g.juz)}>
                <h2 className="qidx-juz">{juzTitle(locale, g.juz)}</h2>
                <ul className="qidx-list">
                  {g.items.map((x) => (
                    <QuarterRow key={x.n} x={x} locale={locale} current={x.n === currentQuarter} />
                  ))}
                </ul>
              </section>
            ))}
          </div>
        )}
      </div>
    </section>
  );
}

function SurahRow({ s, locale, current }: { s: SurahMeta; locale: Locale; current: boolean }) {
  const page = pageForAyah(s.n, 1);
  const name = locale === "ar" ? s.nameAr : s.translit;
  return (
    <li className={`qidx-item${current ? " current" : ""}`} aria-current={current ? "location" : undefined}>
      <Link
        className="qidx-row"
        href={href(locale, `page/${page}`)}
        prefetch={false}
        data-testid="surah-open"
      >
        <StarBadge label={localizeDigits(s.n, locale)} />
        <span className="qidx-text">
          <strong className="qidx-name" lang={locale === "ar" ? "ar" : undefined}>
            {t(locale, "quran.surahTitle", { name })}
            {locale === "ar" ? null : <span className="muted small"> · {s.nameEn}</span>}
          </strong>
          <span className="qidx-sub">
            {t(locale, "quran.surahLine", {
              page: localizeDigits(page, locale),
              count: localizeDigits(s.ayahCount, locale),
              kind: t(locale, s.revelation === "meccan" ? "quran.meccan" : "quran.medinan"),
            })}
          </span>
        </span>
      </Link>
      <Link
        className="qidx-listview"
        href={href(locale, `surah/${s.n}`)}
        prefetch={false}
        aria-label={t(locale, "quran.listViewOf", { surah: locale === "ar" ? s.nameAr : s.translit })}
        title={t(locale, "quran.listView")}
        data-testid="surah-list-view"
      >
        <Icon name="book" />
      </Link>
    </li>
  );
}

/** «الأجزاء»: the 30 juz; a search by number or by the surah a juz starts in. */
export function filterJuz(query: string): (typeof JUZ)[number][] {
  const raw = query.trim();
  if (!raw) return [...JUZ];
  const digits = raw.replace(/[٠-٩]/g, (d) => String(d.charCodeAt(0) - ARABIC_ZERO));
  if (/^\d+$/.test(digits)) return JUZ.filter((z) => z.juz === Number(digits));
  const surahs = new Set(filterSurahs(raw).map((s) => s.n));
  return JUZ.filter((z, i) => {
    const last = (JUZ[i + 1]?.start[0] ?? 115) - 1;
    for (let n = z.start[0]; n <= Math.max(z.start[0], last); n++) if (surahs.has(n)) return true;
    return false;
  });
}

/**
 * One juz in «الأجزاء» (owner 2026-11-20: the Mushaf by ajzaa): opens the whole juz as one flowing text
 * (?view=juz); the book button opens its first Mushaf page instead. The opening words are the first quarter's,
 * copied from the canonical text at build time.
 */
function JuzRow({ juz, locale, current }: { juz: number; locale: Locale; current: boolean }) {
  const z = JUZ[juz - 1]!;
  const s = SURAHS[z.start[0] - 1]!;
  const opening = QUARTERS.find((x) => x.juz === juz && x.quarter === 0);
  const title = juzTitle(locale, juz);
  return (
    <li className={`qidx-item${current ? " current" : ""}`} aria-current={current ? "location" : undefined}>
      <Link
        className="qidx-row"
        href={`${href(locale, `page/${z.page}`)}?view=juz`}
        prefetch={false}
        data-testid="juz-open"
      >
        <StarBadge label={localizeDigits(juz, locale)} />
        <span className="qidx-text">
          <strong className="qidx-name">{title}</strong>
          {opening ? (
            <span className="qidx-opening" lang="ar" dir="rtl">
              {renderQuranText(opening.opening)}
              {opening.more ? " …" : ""}
            </span>
          ) : null}
          <span className="qidx-sub">
            {t(locale, "quran.juzLine", {
              surah: t(locale, "quran.surahTitle", { name: locale === "ar" ? s.nameAr : s.translit }),
              ayah: localizeDigits(z.start[1], locale),
              page: localizeDigits(z.page, locale),
            })}
          </span>
        </span>
      </Link>
      <Link
        className="qidx-listview"
        href={href(locale, `page/${z.page}`)}
        prefetch={false}
        aria-label={t(locale, "quran.juzInMushaf", { juz: title })}
        title={t(locale, "quran.juzInMushaf", { juz: title })}
        data-testid="juz-mushaf"
      >
        <Icon name="book" />
      </Link>
    </li>
  );
}

function QuarterRow({ x, locale, current }: { x: Quarter; locale: Locale; current: boolean }) {
  const s = SURAHS[x.start[0] - 1]!;
  const label =
    x.quarter === 0
      ? t(locale, "quran.hizbN", { n: localizeDigits(x.hizb, locale) })
      : t(locale, "quran.quarterOfHizb", {
          q: localizeDigits(x.quarter, locale),
          n: localizeDigits(x.hizb, locale),
        });
  return (
    <li className={`qidx-item${current ? " current" : ""}`} aria-current={current ? "location" : undefined}>
      <Link
        className="qidx-row"
        href={href(locale, `page/${x.page}`)}
        prefetch={false}
        aria-label={`${label}، ${t(locale, "quran.quarterLine", {
          surah: locale === "ar" ? s.nameAr : s.translit,
          ayah: localizeDigits(x.start[1], locale),
          page: localizeDigits(x.page, locale),
        })}`}
        data-testid="quarter-open"
      >
        <StarBadge label={quarterBadge(x, locale)} small={x.quarter !== 0} />
        <span className="qidx-text">
          <span className="qidx-opening" lang="ar" dir="rtl">
            {renderQuranText(x.opening)}
            {x.more ? " …" : ""}
          </span>
          <span className="qidx-sub">
            {t(locale, "quran.quarterLine", {
              surah: t(locale, "quran.surahTitle", { name: locale === "ar" ? s.nameAr : s.translit }),
              ayah: localizeDigits(x.start[1], locale),
              page: localizeDigits(x.page, locale),
            })}
          </span>
        </span>
      </Link>
    </li>
  );
}
