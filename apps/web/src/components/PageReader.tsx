"use client";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { Fragment, useEffect } from "react";
import { dirOf, t, type Locale } from "@/lib/i18n";
import { href } from "@/lib/locale-path";
import { localizeDigits } from "@/lib/digits";
import { renderQuranText } from "@/lib/quran-render";
import { PAGE_COUNT, surahMeta } from "@/lib/pages";
import { lastReadStore } from "@/lib/settings";
import { AyahMarker } from "./AyahMarker";
import { GoToPage } from "./GoToPage";

export interface PageAyah {
  s: number;
  a: number;
  text: string;
}

export interface PageReaderProps {
  locale: Locale;
  page: number;
  juz: number;
  ayahs: PageAyah[];
  basmala: string;
}

/** Which page a horizontal arrow key leads to. In RTL the left arrow turns forward, like a printed Mushaf. */
export function arrowTarget(key: string, page: number, dir: "rtl" | "ltr"): number | null {
  let delta = 0;
  if (key === "ArrowLeft") delta = dir === "rtl" ? 1 : -1;
  else if (key === "ArrowRight") delta = dir === "rtl" ? -1 : 1;
  else return null;
  const target = page + delta;
  return target >= 1 && target <= PAGE_COUNT ? target : null;
}

export function PageReader({ locale, page, juz, ayahs, basmala }: PageReaderProps) {
  const router = useRouter();
  const first = ayahs[0];
  useEffect(() => {
    if (first) lastReadStore.set({ surah: first.s, ayah: first.a, page, at: Date.now() });
  }, [first, page]);

  useEffect(() => {
    const onKey = (e: KeyboardEvent): void => {
      if (e.altKey || e.ctrlKey || e.metaKey || e.shiftKey) return;
      const el = e.target as HTMLElement | null;
      if (el && (el.isContentEditable || ["INPUT", "SELECT", "TEXTAREA"].includes(el.tagName))) return;
      const target = arrowTarget(e.key, page, dirOf(locale));
      if (target !== null) {
        e.preventDefault();
        router.push(href(locale, `page/${target}`));
      }
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [page, locale, router]);

  const surahsHere = [...new Set(ayahs.map((x) => x.s))];
  const names = surahsHere
    .map((s) => surahMeta(s))
    .map((m) => (m ? (locale === "ar" ? m.nameAr : m.translit) : ""))
    .join(locale === "ar" ? "، " : ", ");

  return (
    <>
      <h1>
        {t(locale, "quran.pageOf", {
          page: localizeDigits(page, locale),
          total: localizeDigits(PAGE_COUNT, locale),
        })}
      </h1>
      <div className="page-head">
        <span data-testid="juz">{t(locale, "quran.juz", { juz: localizeDigits(juz, locale) })}</span>
        <span>
          <span className="sr-only">{t(locale, "quran.surahsOnPage")}: </span>
          {names}
        </span>
      </div>
      <div className="reader">
        <div className="quran mushaf" lang="ar" dir="rtl" data-testid="mushaf-page">
          {ayahs.map((x) => {
            const m = surahMeta(x.s);
            return (
              <Fragment key={`${x.s}:${x.a}`}>
                {x.a === 1 && m ? (
                  <>
                    <span className="surah-banner" style={{ display: "block" }}>
                      سورة {m.nameAr}
                    </span>
                    {x.s !== 1 && x.s !== 9 ? (
                      <span className="basmala" style={{ display: "block" }}>
                        {renderQuranText(basmala)}
                      </span>
                    ) : null}
                  </>
                ) : null}
                <span className="ayah-inline" id={`a-${x.s}-${x.a}`}>
                  {renderQuranText(x.text)}
                  <AyahMarker n={x.a} locale={locale} />{" "}
                </span>
              </Fragment>
            );
          })}
        </div>
      </div>
      <nav className="pager" aria-label={t(locale, "quran.pageNav")}>
        {page > 1 ? (
          <Link className="btn" href={href(locale, `page/${page - 1}`)} rel="prev" data-testid="prev-page">
            {t(locale, "quran.prevPage")}
          </Link>
        ) : (
          <span />
        )}
        {page < PAGE_COUNT ? (
          <Link
            className="btn btn-primary"
            href={href(locale, `page/${page + 1}`)}
            rel="next"
            data-testid="next-page"
          >
            {t(locale, "quran.nextPage")}
          </Link>
        ) : null}
      </nav>
      <GoToPage locale={locale} />
      <p className="muted">{t(locale, "quran.keysHint")}</p>
      {first ? (
        <p>
          <Link href={`${href(locale, `surah/${first.s}`)}#a-${first.a}`}>
            {(() => {
              const m = surahMeta(first.s);
              return m
                ? t(locale, "quran.ayahRef", {
                    surah: locale === "ar" ? m.nameAr : m.translit,
                    ayah: localizeDigits(first.a, locale),
                  })
                : null;
            })()}
          </Link>
        </p>
      ) : null}
    </>
  );
}
