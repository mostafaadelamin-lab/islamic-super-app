"use client";
import { useCallback, useEffect, useState } from "react";
import Link from "next/link";
import { t, type Locale } from "@/lib/i18n";
import { href } from "@/lib/locale-path";
import { localizeDigits } from "@/lib/digits";
import {
  bookName,
  displayText,
  hadithBook,
  hadithFavStore,
  loadRange,
  searchBook,
  SEARCH_LIMIT,
  toggleFavourite,
  type HadithBook,
  type HadithItem,
} from "@/lib/hadith";
import { useStore } from "@/hooks/useStore";
import { DhikrTools } from "./DhikrTools";

/** Hadiths shown per screen. */
export const PAGE_SIZE = 20;
/** "#123" in the address opens the screen that holds hadith 123. https://regex101.com/?regex=%5E%23(%5Cd%2B)%24&testString=%23123 */
const HASH_RE = /^#(\d+)$/;

const firstOfPage = (n: number): number => Math.floor((n - 1) / PAGE_SIZE) * PAGE_SIZE + 1;

/** One hadith: number, text unchanged, favourite, share and report. */
export function HadithCard({ locale, book, item }: { locale: Locale; book: HadithBook; item: HadithItem }) {
  const fav = useStore(hadithFavStore);
  const saved = fav.keys.includes(`${book.id}:${item.n}`);
  const num = localizeDigits(item.n, locale);
  const source = t(locale, "hadith.source", { book: bookName(book, locale), n: num });
  return (
    <article className="card hadith" id={`h${item.n}`} data-testid="hadith" data-n={item.n}>
      <header className="hadith-head">
        <span className="badge">{t(locale, "hadith.number", { n: num })}</span>
        <button
          type="button"
          className="btn btn-sm"
          aria-pressed={saved}
          onClick={() => toggleFavourite(book.id, item.n)}
          data-testid="hadith-fav"
        >
          {t(locale, saved ? "hadith.unsave" : "hadith.save")}
        </button>
      </header>
      <p className="hadith-text" lang="ar" dir="rtl">
        {displayText(item.text)}
      </p>
      <DhikrTools
        locale={locale}
        text={displayText(item.text)}
        source={source}
        where={source}
        testId="hadith"
      />
    </article>
  );
}

/** Browse a book twenty hadiths at a time, jump to a number, or search it. */
export function HadithReader({ locale, bookId }: { locale: Locale; bookId: string }) {
  const book = hadithBook(bookId)!;
  const [from, setFrom] = useState(1);
  const [items, setItems] = useState<HadithItem[] | null>(null);
  const [error, setError] = useState(false);
  const [go, setGo] = useState("");
  const [query, setQuery] = useState("");
  const [results, setResults] = useState<HadithItem[] | null>(null);
  const [progress, setProgress] = useState<[number, number] | null>(null);
  const n = (v: number): string => localizeDigits(v, locale);

  const open = useCallback(
    (start: number) => {
      const s = Math.min(Math.max(1, start), book.count);
      setFrom(firstOfPage(s));
      setResults(null);
      if (typeof window !== "undefined") history.replaceState(null, "", `#${s}`);
    },
    [book.count],
  );

  useEffect(() => {
    const m = HASH_RE.exec(window.location.hash);
    if (m) setFrom(firstOfPage(Math.min(Math.max(1, Number(m[1])), book.count)));
  }, [book.count]);

  useEffect(() => {
    let live = true;
    setItems(null);
    setError(false);
    loadRange(book, from, from + PAGE_SIZE - 1)
      .then((list) => live && setItems(list))
      .catch(() => live && setError(true));
    return () => {
      live = false;
    };
  }, [book, from]);

  const runSearch = async (): Promise<void> => {
    setProgress([0, book.chunks]);
    try {
      setResults(await searchBook(book, query, (d, total) => setProgress([d, total])));
    } catch {
      setError(true);
    }
    setProgress(null);
  };

  const last = Math.min(from + PAGE_SIZE - 1, book.count);
  return (
    <>
      {locale !== "ar" ? <p className="alert">{t(locale, "common.arabicOnly")}</p> : null}
      <section className="card hadith-tools">
        <form
          className="row"
          onSubmit={(e) => {
            e.preventDefault();
            const v = Number(go);
            if (Number.isInteger(v) && v >= 1) open(v);
          }}
        >
          <label className="field">
            <span>{t(locale, "hadith.goTo", { max: n(book.count) })}</span>
            <input
              type="number"
              min={1}
              max={book.count}
              inputMode="numeric"
              value={go}
              onChange={(e) => setGo(e.target.value)}
              data-testid="hadith-go"
            />
          </label>
          <button type="submit" className="btn" data-testid="hadith-go-btn">
            {t(locale, "hadith.go")}
          </button>
        </form>
        <form
          className="row"
          role="search"
          onSubmit={(e) => {
            e.preventDefault();
            void runSearch();
          }}
        >
          <label className="field">
            <span>{t(locale, "hadith.search", { book: bookName(book, locale) })}</span>
            <input
              type="search"
              lang="ar"
              dir="rtl"
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              data-testid="hadith-query"
            />
          </label>
          <button type="submit" className="btn" disabled={progress !== null} data-testid="hadith-search-btn">
            {t(locale, "hadith.searchGo")}
          </button>
        </form>
        {progress ? (
          <p className="muted small" role="status" data-testid="hadith-progress">
            {t(locale, "hadith.searching", { done: n(progress[0]), total: n(progress[1]) })}
          </p>
        ) : null}
      </section>
      {error ? (
        <p className="alert alert-error" role="alert" data-testid="hadith-error">
          {t(locale, "hadith.loadError")}
        </p>
      ) : null}
      {results ? (
        <section aria-labelledby="hadith-results-h" data-testid="hadith-results">
          <h2 id="hadith-results-h">
            {t(locale, results.length >= SEARCH_LIMIT ? "hadith.resultsMany" : "hadith.results", {
              count: n(results.length),
            })}
          </h2>
          <p>
            <button
              type="button"
              className="btn btn-sm"
              onClick={() => setResults(null)}
              data-testid="hadith-clear"
            >
              {t(locale, "hadith.backToBook")}
            </button>
          </p>
          {results.map((h) => (
            <HadithCard key={h.n} locale={locale} book={book} item={h} />
          ))}
        </section>
      ) : (
        <section aria-live="polite">
          <p className="muted" data-testid="hadith-range">
            {t(locale, "hadith.range", { from: n(from), to: n(last), count: n(book.count) })}
          </p>
          {items === null && !error ? <p className="muted">{t(locale, "common.loading")}</p> : null}
          {items?.map((h) => (
            <HadithCard key={h.n} locale={locale} book={book} item={h} />
          ))}
          <nav className="row pager" aria-label={t(locale, "hadith.pager")}>
            <button
              type="button"
              className="btn"
              disabled={from <= 1}
              onClick={() => open(from - PAGE_SIZE)}
              data-testid="hadith-prev"
            >
              {t(locale, "hadith.prev")}
            </button>
            <button
              type="button"
              className="btn"
              disabled={last >= book.count}
              onClick={() => open(from + PAGE_SIZE)}
              data-testid="hadith-next"
            >
              {t(locale, "hadith.next")}
            </button>
          </nav>
        </section>
      )}
      <p className="small muted">
        <Link href={href(locale, "hadith/")}>{t(locale, "hadith.allBooks")}</Link>
      </p>
    </>
  );
}

/** Saved hadiths, loaded from their books. */
export function HadithFavourites({ locale }: { locale: Locale }) {
  const fav = useStore(hadithFavStore);
  const [items, setItems] = useState<{ book: HadithBook; item: HadithItem }[] | null>(null);
  useEffect(() => {
    let live = true;
    Promise.all(
      fav.keys.map(async (key) => {
        const [id, num] = key.split(":");
        const book = hadithBook(id!)!;
        const [item] = await loadRange(book, Number(num), Number(num));
        return { book, item: item! };
      }),
    )
      .then((list) => live && setItems(list))
      .catch(() => live && setItems([]));
    return () => {
      live = false;
    };
  }, [fav.keys]);
  if (fav.keys.length === 0) {
    return (
      <p className="muted" data-testid="hadith-fav-empty">
        {t(locale, "hadith.noFavourites")}
      </p>
    );
  }
  return (
    <div data-testid="hadith-favourites">
      {items === null ? <p className="muted">{t(locale, "common.loading")}</p> : null}
      {items?.map(({ book, item }) => (
        <div key={`${book.id}:${item.n}`}>
          <p className="small">
            <Link href={`${href(locale, `hadith/${book.id}/`)}#${item.n}`}>{bookName(book, locale)}</Link>
          </p>
          <HadithCard locale={locale} book={book} item={item} />
        </div>
      ))}
    </div>
  );
}
