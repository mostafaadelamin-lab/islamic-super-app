"use client";
import { useEffect, useState } from "react";
import { t, type Locale } from "@/lib/i18n";
import { localizeDigits } from "@/lib/digits";
import { surahName, SURAHS } from "@/lib/pages";
import {
  bookSizeMb,
  loadBookSection,
  loadWholeBook,
  MIN_QUERY_LETTERS,
  searchBook,
  TAFSIR_BOOKS,
  tafsirBook,
  type SearchHit,
  type SectionView,
  type TafsirBookId,
} from "@/lib/tafsir-books";
import { BookText, setTafsirChoice, TafsirPanel } from "./TafsirPanel";
import { Icon } from "./Icon";

/**
 * «التفسير» in the library (owner 2026-11-20): every tafsir book to read ayah by ayah (with the gharib, i'rab,
 * sarf, balagha and fawa'id tabs), the books side by side for one ayah, and search inside a book.
 */
type View = "home" | "read" | "compare" | "search";
const VIEWS: readonly View[] = ["home", "read", "compare", "search"];
/** Characters of each book shown in the comparison before «اقرأ الكل». */
const COMPARE_PREVIEW = 600;

interface Place {
  view: View;
  book: TafsirBookId;
  surah: number;
  ayah: number;
}

const START: Place = { view: "home", book: "muyassar", surah: 1, ayah: 1 };

function readUrl(): Place {
  const q = new URLSearchParams(window.location.search);
  const view = VIEWS.find((v) => v === q.get("v")) ?? START.view;
  const book = tafsirBook(q.get("b") ?? "")?.id ?? START.book;
  const surah = Math.min(SURAHS.length, Math.max(1, Number(q.get("s")) || 1));
  const ayah = Math.min(SURAHS[surah - 1]!.ayahCount, Math.max(1, Number(q.get("a")) || 1));
  return { view, book, surah, ayah };
}

function writeUrl(p: Place): void {
  const q = p.view === "home" ? "" : `?v=${p.view}&b=${p.book}&s=${p.surah}&a=${p.ayah}`;
  window.history.replaceState(window.history.state, "", `${window.location.pathname}${q}`);
}

export function TafsirLibrary({ locale }: { locale: Locale }) {
  const [place, setPlace] = useState<Place>(START);
  useEffect(() => setPlace(readUrl()), []);
  const go = (next: Partial<Place>): void => {
    const p = { ...place, ...next };
    setPlace(p);
    writeUrl(p);
    if (next.book) setTafsirChoice({ book: next.book, tab: "tafsir" });
    if (next.view && next.view !== place.view) window.scrollTo({ top: 0 });
  };

  return (
    <div className="tafsir-lib" data-testid="tafsir-lib" data-view={place.view}>
      {place.view === "home" ? null : (
        <button
          type="button"
          className="btn btn-sm tafsir-lib-back"
          data-testid="tafsir-lib-back"
          onClick={() => go({ view: "home" })}
        >
          <Icon name={locale === "ar" ? "next" : "prev"} size={16} /> {t(locale, "tafsirLib.books")}
        </button>
      )}
      {place.view === "home" ? <Home locale={locale} go={go} /> : null}
      {place.view === "read" ? (
        <>
          <AyahPicker
            locale={locale}
            surah={place.surah}
            ayah={place.ayah}
            onChange={(surah, ayah) => go({ surah, ayah })}
          />
          <TafsirPanel
            locale={locale}
            surah={place.surah}
            ayah={place.ayah}
            onStep={([surah, ayah]) => go({ surah, ayah })}
          />
        </>
      ) : null}
      {place.view === "compare" ? (
        <>
          <h2>{t(locale, "tafsirLib.compare")}</h2>
          <AyahPicker
            locale={locale}
            surah={place.surah}
            ayah={place.ayah}
            onChange={(surah, ayah) => go({ surah, ayah })}
          />
          <Compare
            locale={locale}
            surah={place.surah}
            ayah={place.ayah}
            onRead={(book) => go({ view: "read", book })}
          />
        </>
      ) : null}
      {place.view === "search" ? (
        <Search
          locale={locale}
          book={place.book}
          onBook={(book) => go({ book })}
          onOpen={(h) => go({ view: "read", surah: h.surah, ayah: h.from })}
        />
      ) : null}
    </div>
  );
}

function Home({ locale, go }: { locale: Locale; go: (p: Partial<Place>) => void }) {
  return (
    <>
      <div className="tafsir-lib-tools">
        <button
          type="button"
          className="tafsir-lib-tool"
          data-testid="tafsir-lib-compare"
          onClick={() => go({ view: "compare" })}
        >
          <Icon name="book" size={22} />
          <span>
            <b>{t(locale, "tafsirLib.compare")}</b>
            <small>{t(locale, "tafsirLib.compareSub")}</small>
          </span>
        </button>
        <button
          type="button"
          className="tafsir-lib-tool"
          data-testid="tafsir-lib-search"
          onClick={() => go({ view: "search" })}
        >
          <Icon name="search" size={22} />
          <span>
            <b>{t(locale, "tafsirLib.search")}</b>
            <small>{t(locale, "tafsirLib.searchSub")}</small>
          </span>
        </button>
      </div>
      <h2>{t(locale, "tafsirLib.books")}</h2>
      <ul className="tafsir-lib-books">
        {TAFSIR_BOOKS.map((b) => (
          <li key={b.id}>
            <button
              type="button"
              className="tafsir-lib-book"
              data-testid={`tafsir-lib-book-${b.id}`}
              onClick={() => go({ view: "read", book: b.id })}
            >
              <b lang="ar">{b.nameAr}</b>
              <small lang="ar">{b.authorAr}</small>
              <span className="tafsir-lib-tag">{t(locale, `tafsirLib.len.${b.length}`)}</span>
            </button>
          </li>
        ))}
        <li>
          <button
            type="button"
            className="tafsir-lib-book"
            data-testid="tafsir-lib-book-irab"
            onClick={() => {
              go({ view: "read" });
              setTafsirChoice({ tab: "irab" });
            }}
          >
            <b lang="ar">{t("ar", "tafsirLib.irabName")}</b>
            <small>{t(locale, "tafsirLib.irabSub")}</small>
            <span className="tafsir-lib-tag">{t(locale, "study.irab")}</span>
          </button>
        </li>
      </ul>
    </>
  );
}

export function AyahPicker({
  locale,
  surah,
  ayah,
  onChange,
}: {
  locale: Locale;
  surah: number;
  ayah: number;
  onChange: (surah: number, ayah: number) => void;
}) {
  const count = SURAHS[surah - 1]!.ayahCount;
  return (
    <div className="ayah-picker">
      <label>
        <span>{t(locale, "tafsirLib.surah")}</span>
        <select data-testid="pick-surah" value={surah} onChange={(e) => onChange(Number(e.target.value), 1)}>
          {SURAHS.map((m) => (
            <option key={m.n} value={m.n}>
              {localizeDigits(m.n, locale)}. {surahName(m.n, locale)}
            </option>
          ))}
        </select>
      </label>
      <label>
        <span>{t(locale, "tafsirLib.ayah")}</span>
        <select
          data-testid="pick-ayah"
          value={ayah}
          onChange={(e) => onChange(surah, Number(e.target.value))}
        >
          {Array.from({ length: count }, (_, i) => (
            <option key={i + 1} value={i + 1}>
              {localizeDigits(i + 1, locale)}
            </option>
          ))}
        </select>
      </label>
    </div>
  );
}

type Loaded = { status: "loading" } | { status: "ready"; sec: SectionView } | { status: "error" };

function Compare({
  locale,
  surah,
  ayah,
  onRead,
}: {
  locale: Locale;
  surah: number;
  ayah: number;
  onRead: (b: TafsirBookId) => void;
}) {
  return (
    <div className="tafsir-compare" data-testid="tafsir-compare">
      {TAFSIR_BOOKS.map((b) => (
        <CompareCard
          key={`${b.id}/${surah}:${ayah}`}
          locale={locale}
          book={b.id}
          surah={surah}
          ayah={ayah}
          onRead={() => onRead(b.id)}
        />
      ))}
    </div>
  );
}

function CompareCard({
  locale,
  book,
  surah,
  ayah,
  onRead,
}: {
  locale: Locale;
  book: TafsirBookId;
  surah: number;
  ayah: number;
  onRead: () => void;
}) {
  const [state, setState] = useState<Loaded>({ status: "loading" });
  const [open, setOpen] = useState(false);
  useEffect(() => {
    let alive = true;
    void (async () => {
      try {
        const sec = await loadBookSection(book, surah, ayah);
        if (alive) setState({ status: "ready", sec });
      } catch {
        if (alive) setState({ status: "error" });
      }
    })();
    return () => {
      alive = false;
    };
  }, [book, surah, ayah]);
  const info = tafsirBook(book)!;
  const long = state.status === "ready" && state.sec.text.length > COMPARE_PREVIEW;
  return (
    <article className="tafsir-compare-card" data-testid={`compare-${book}`}>
      <header>
        <h3 lang="ar">{info.nameAr}</h3>
        <span className="tafsir-lib-tag">{t(locale, `tafsirLib.len.${info.length}`)}</span>
      </header>
      {state.status === "loading" ? <p className="muted">{t(locale, "tafsir.loading")}</p> : null}
      {state.status === "error" ? <p className="muted">{t(locale, "tafsir.error")}</p> : null}
      {state.status === "ready" ? (
        <>
          <BookText
            text={open || !long ? state.sec.text : `${state.sec.text.slice(0, COMPARE_PREVIEW)} …`}
            quotes={book !== "muyassar"}
          />
          <div className="tafsir-compare-actions">
            {long ? (
              <button
                type="button"
                className="btn btn-sm"
                data-testid={`compare-more-${book}`}
                onClick={() => setOpen((o) => !o)}
              >
                {t(locale, open ? "tafsirLib.less" : "tafsirLib.more")}
              </button>
            ) : null}
            <button type="button" className="btn btn-sm" onClick={onRead}>
              {t(locale, "tafsirLib.readBook")}
            </button>
          </div>
        </>
      ) : null}
    </article>
  );
}

type SearchState =
  | { status: "idle" }
  | { status: "loading" }
  | { status: "ready"; hits: SearchHit[]; query: string }
  | { status: "error" };

function Search({
  locale,
  book,
  onBook,
  onOpen,
}: {
  locale: Locale;
  book: TafsirBookId;
  onBook: (b: TafsirBookId) => void;
  onOpen: (h: SearchHit) => void;
}) {
  const [query, setQuery] = useState("");
  const [state, setState] = useState<SearchState>({ status: "idle" });
  const run = async (b: TafsirBookId, q: string): Promise<void> => {
    if (q.trim().length < MIN_QUERY_LETTERS) return;
    setState({ status: "loading" });
    try {
      const surahs = await loadWholeBook(b);
      setState({ status: "ready", hits: searchBook(surahs, q), query: q });
    } catch {
      setState({ status: "error" });
    }
  };
  return (
    <div className="tafsir-search" data-testid="tafsir-search">
      <h2>{t(locale, "tafsirLib.search")}</h2>
      <form
        className="tafsir-search-form"
        role="search"
        onSubmit={(e) => {
          e.preventDefault();
          void run(book, query);
        }}
      >
        <input
          type="search"
          dir="rtl"
          lang="ar"
          data-testid="tafsir-search-input"
          value={query}
          placeholder={t(locale, "tafsirLib.searchHint")}
          aria-label={t(locale, "tafsirLib.search")}
          onChange={(e) => setQuery(e.target.value)}
        />
        <button type="submit" className="btn" data-testid="tafsir-search-go">
          <Icon name="search" size={18} /> {t(locale, "tafsirLib.searchGo")}
        </button>
      </form>
      <div className="tafsir-books" role="group" aria-label={t(locale, "study.chooseBook")}>
        {TAFSIR_BOOKS.map((b) => (
          <button
            key={b.id}
            type="button"
            aria-pressed={book === b.id}
            className={`chip${book === b.id ? " on" : ""}`}
            data-testid={`search-book-${b.id}`}
            onClick={() => {
              onBook(b.id);
              if (state.status === "ready") void run(b.id, state.query);
            }}
          >
            {locale === "ar" ? b.shortAr : b.nameEn}
          </button>
        ))}
      </div>
      {state.status === "loading" ? (
        <p className="muted" data-testid="tafsir-search-loading">
          {t(locale, "tafsirLib.searchLoading", { mb: localizeDigits(bookSizeMb(book), locale) })}
        </p>
      ) : null}
      {state.status === "error" ? <p className="muted">{t(locale, "tafsir.error")}</p> : null}
      {state.status === "ready" ? (
        <>
          <p className="muted small" data-testid="tafsir-search-count">
            {t(locale, "tafsirLib.results", { n: localizeDigits(state.hits.length, locale) })}
          </p>
          <ul className="tafsir-search-hits">
            {state.hits.map((h) => (
              <li key={`${h.surah}:${h.from}`}>
                <button
                  type="button"
                  className="tafsir-search-hit"
                  data-testid="tafsir-search-hit"
                  onClick={() => onOpen(h)}
                >
                  <span className="tafsir-search-ref">
                    {t(locale, "quran.ayahRef", {
                      surah: surahName(h.surah, locale),
                      ayah: localizeDigits(h.from, locale),
                    })}
                  </span>
                  <span className="tafsir-search-snippet" lang="ar" dir="rtl">
                    {h.before}
                    <mark>{h.match}</mark>
                    {h.after}
                  </span>
                </button>
              </li>
            ))}
          </ul>
        </>
      ) : null}
    </div>
  );
}
