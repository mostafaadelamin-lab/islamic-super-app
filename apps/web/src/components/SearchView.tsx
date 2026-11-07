"use client";
import Link from "next/link";
import { useEffect, useMemo, useRef, useState } from "react";
import { t, type Locale } from "@/lib/i18n";
import { href } from "@/lib/locale-path";
import { localizeDigits } from "@/lib/digits";
import { renderQuranText } from "@/lib/quran-render";
import { queryLength, SearchIndex } from "@/lib/search";
import { surahMeta } from "@/lib/pages";
import { withBase } from "@/lib/base-path";

const LIMIT = 50;
let indexPromise: Promise<SearchIndex> | null = null;

export function loadIndex(fetchImpl: typeof fetch = fetch): Promise<SearchIndex> {
  if (!indexPromise) {
    indexPromise = fetchImpl(withBase("/data/quran-text.json"))
      .then((r) => {
        if (!r.ok) throw new Error(String(r.status));
        return r.json() as Promise<string[][]>;
      })
      .then((surahs) => new SearchIndex(surahs))
      .catch((e: unknown) => {
        indexPromise = null;
        throw e;
      });
  }
  return indexPromise;
}

export function resetSearchIndexForTests(): void {
  indexPromise = null;
}

type IndexState = { status: "idle" | "loading" | "error" } | { status: "ready"; index: SearchIndex };

export function SearchView({ locale }: { locale: Locale }) {
  const [q, setQ] = useState("");
  const [debounced, setDebounced] = useState("");
  const [idx, setIdx] = useState<IndexState>({ status: "idle" });
  const inputRef = useRef<HTMLInputElement>(null);

  const ensureIndex = (): void => {
    if (idx.status === "ready" || idx.status === "loading") return;
    setIdx({ status: "loading" });
    loadIndex()
      .then((index) => setIdx({ status: "ready", index }))
      .catch(() => setIdx({ status: "error" }));
  };

  useEffect(() => {
    const initial = new URLSearchParams(window.location.search).get("q");
    if (initial) {
      setQ(initial);
      setDebounced(initial);
    }
    // Load the index as soon as the search page is opened.
    setIdx({ status: "loading" });
    loadIndex()
      .then((index) => setIdx({ status: "ready", index }))
      .catch(() => setIdx({ status: "error" }));
  }, []);

  useEffect(() => {
    const id = setTimeout(() => setDebounced(q), 200);
    return () => clearTimeout(id);
  }, [q]);

  useEffect(() => {
    const url = new URL(window.location.href);
    if (debounced) url.searchParams.set("q", debounced);
    else url.searchParams.delete("q");
    window.history.replaceState(window.history.state, "", url.toString());
  }, [debounced]);

  const tooShort = debounced.trim() !== "" && queryLength(debounced) < 2;
  const result = useMemo(
    () =>
      idx.status === "ready" && !tooShort && debounced.trim() ? idx.index.search(debounced, LIMIT) : null,
    [idx, debounced, tooShort],
  );

  return (
    <>
      <form role="search" onSubmit={(e) => e.preventDefault()} className="field">
        <label htmlFor="q">{t(locale, "quran.search")}</label>
        <input
          ref={inputRef}
          id="q"
          type="search"
          dir="rtl"
          lang="ar"
          value={q}
          placeholder={t(locale, "quran.searchHint")}
          onFocus={ensureIndex}
          onChange={(e) => setQ(e.target.value)}
          autoComplete="off"
        />
      </form>
      <div aria-live="polite" data-testid="search-status">
        {idx.status === "loading" ? <p className="muted">{t(locale, "quran.searchLoading")}</p> : null}
        {idx.status === "error" ? (
          <p className="alert alert-error" role="alert">
            {t(locale, "quran.loadError")}{" "}
            <button type="button" className="btn" onClick={ensureIndex}>
              {t(locale, "common.retry")}
            </button>
          </p>
        ) : null}
        {tooShort ? <p className="muted">{t(locale, "quran.searchMin")}</p> : null}
        {result ? (
          <p>
            {result.total === 0
              ? t(locale, "quran.noResults")
              : t(locale, "quran.results", { count: localizeDigits(result.total, locale) })}
            {result.total > LIMIT
              ? ` ${t(locale, "quran.resultsShown", { shown: localizeDigits(LIMIT, locale) })}`
              : ""}
          </p>
        ) : null}
      </div>
      {result && result.results.length > 0 ? (
        <ol className="results" data-testid="search-results">
          {result.results.map((r) => {
            const m = surahMeta(r.s);
            return (
              <li key={`${r.s}:${r.a}`}>
                <p className="quran" lang="ar" dir="rtl" style={{ margin: 0 }}>
                  {renderQuranText(r.text)}
                </p>
                <Link href={`${href(locale, `surah/${r.s}`)}#a-${r.a}`}>
                  {t(locale, "quran.ayahRef", {
                    surah: m ? (locale === "ar" ? m.nameAr : m.translit) : String(r.s),
                    ayah: localizeDigits(r.a, locale),
                  })}{" "}
                  ({localizeDigits(`${r.s}:${r.a}`, locale)})
                </Link>
              </li>
            );
          })}
        </ol>
      ) : null}
    </>
  );
}
