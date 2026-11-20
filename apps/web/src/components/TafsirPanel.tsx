"use client";
import { useEffect, useId, useState, useSyncExternalStore } from "react";
import { t, type Locale } from "@/lib/i18n";
import { localizeDigits } from "@/lib/digits";
import { surahName, type Ref } from "@/lib/pages";
import { stepRef } from "@/lib/tafsir";
import {
  DEFAULT_TAFSIR,
  IRAB_PARTS,
  loadBookSection,
  loadIrab,
  quoteRuns,
  TAFSIR_BOOKS,
  tafsirBook,
  type IrabPart,
  type TafsirBookId,
} from "@/lib/tafsir-books";
import { loadMeaningsSurah, meaningsEntry, type WordMeaning } from "@/lib/word-meanings";
import { Icon } from "./Icon";

/** What the panel shows (owner 2026-11-20): the tafsir (a book of the reader's choice), or a study of the ayah. */
export type StudyTab = "tafsir" | "gharib" | IrabPart;
export const STUDY_TABS: readonly StudyTab[] = ["tafsir", "gharib", ...IRAB_PARTS];

type Body =
  | { kind: "text"; text: string; notes?: string; from: number; to: number; quotes: boolean }
  | { kind: "words"; words: readonly WordMeaning[] }
  | { kind: "empty" };

type TafsirState =
  | { status: "loading"; key: string }
  | { status: "ready"; key: string; body: Body }
  | { status: "error"; key: string; offline: boolean };

/**
 * The book and tab chosen in the Mushaf: al-Muyassar and «التفسير» on every visit (owner: al-Muyassar is the
 * default), kept only while the site is open so that moving to the next ayah keeps the reader's choice.
 */
let choice: { book: TafsirBookId; tab: StudyTab } = { book: DEFAULT_TAFSIR, tab: "tafsir" };
const listeners = new Set<() => void>();
const choiceStore = {
  get: () => choice,
  set(next: Partial<typeof choice>): void {
    choice = { ...choice, ...next };
    listeners.forEach((l) => l());
  },
  subscribe(l: () => void): () => void {
    listeners.add(l);
    return () => {
      listeners.delete(l);
    };
  },
};
const DEFAULT_CHOICE = { book: DEFAULT_TAFSIR, tab: "tafsir" as StudyTab };

/** Opens a book or tab (the library's «اقرأ»). */
export function setTafsirChoice(next: Partial<{ book: TafsirBookId; tab: StudyTab }>): void {
  choiceStore.set(next);
}

export function resetTafsirChoiceForTests(): void {
  choice = DEFAULT_CHOICE;
}

async function loadBody(tab: StudyTab, book: TafsirBookId, s: number, a: number): Promise<Body> {
  if (tab === "tafsir") {
    const sec = await loadBookSection(book, s, a);
    return { kind: "text", text: sec.text, notes: sec.notes, from: sec.from, to: sec.to, quotes: book !== "muyassar" };
  }
  if (tab === "gharib") {
    const words = meaningsEntry(await loadMeaningsSurah(s), s, a);
    return words.length ? { kind: "words", words } : { kind: "empty" };
  }
  const v = await loadIrab(s, a, tab);
  return v.part ? { kind: "text", text: v.part, from: v.from, to: v.to, quotes: true } : { kind: "empty" };
}

/** A book's text with its Quran quotes (﴿…﴾) in the Quran colour; new lines kept (white-space: pre-line). */
export function BookText({ text, quotes, testId }: { text: string; quotes: boolean; testId?: string }) {
  return (
    <p className="tafsir-text" lang="ar" dir="rtl" data-testid={testId} tabIndex={0}>
      {quotes
        ? quoteRuns(text).map((r, i) =>
            r.quote ? (
              <span key={i} className="tafsir-quote">
                {r.text}
              </span>
            ) : (
              r.text
            ),
          )
        : text}
    </p>
  );
}

export interface TafsirPanelProps {
  locale: Locale;
  surah: number;
  ayah: number;
  /** Called by the previous/next buttons; without it the panel moves on its own. */
  onStep?: (ref: Ref) => void;
  /** Previous/next ayah buttons (hidden while following the recitation: the player has its own). */
  showNav?: boolean;
  /** The book chips and study tabs (hidden while following the recitation: al-Muyassar only). */
  showChoices?: boolean;
}

/**
 * The tafsir of one ayah (al-Muyassar by default, or another book the reader picks) and the ayah's studies
 * (gharib, i'rab, sarf, balagha, fawa'id), each shown verbatim, with previous/next ayah buttons.
 */
export function TafsirPanel({ locale, surah, ayah, onStep, showNav = true, showChoices = true }: TafsirPanelProps) {
  const [own, setOwn] = useState<Ref>([surah, ayah]);
  const [retry, setRetry] = useState(0);
  const headingId = useId();
  const chosen = useSyncExternalStore(choiceStore.subscribe, choiceStore.get, () => DEFAULT_CHOICE);
  const { book, tab } = showChoices ? chosen : DEFAULT_CHOICE;
  useEffect(() => setOwn([surah, ayah]), [surah, ayah]);
  const [s, a] = onStep ? [surah, ayah] : own;
  const key = `${tab}/${book}/${s}:${a}`;
  const [state, setState] = useState<TafsirState>({ status: "loading", key });

  useEffect(() => {
    let alive = true;
    setState({ status: "loading", key });
    void (async () => {
      try {
        const body = await loadBody(tab, book, s, a);
        if (alive) setState({ status: "ready", key, body });
      } catch {
        if (alive) setState({ status: "error", key, offline: navigator.onLine === false });
      }
    })();
    return () => {
      alive = false;
    };
  }, [s, a, key, retry, tab, book]);

  const move = (delta: 1 | -1): void => {
    const next = stepRef(s, a, delta);
    if (!next) return;
    if (onStep) onStep(next);
    else setOwn(next);
  };
  const ref = t(locale, "quran.ayahRef", { surah: surahName(s, locale), ayah: localizeDigits(a, locale) });
  const shown = state.key === key ? state : { status: "loading" as const, key };
  const bookInfo = tafsirBook(book)!;
  const otherBook = tab === "tafsir" && book !== "muyassar";
  const studyKey = tab === "tafsir" ? "tafsir.title" : `study.${tab}`;
  const titleAr = otherBook ? bookInfo.nameAr : t("ar", studyKey);
  const titleLocal = otherBook ? bookInfo.nameEn : t(locale, studyKey);
  const title = locale === "ar" ? titleAr : titleLocal;
  const sourceByTab: Record<string, string> = {
    tafsir: book === "muyassar" ? t(locale, "tafsir.source") : bookInfo.authorAr,
    gharib: t(locale, "study.gharibBook"),
  };
  const source = sourceByTab[tab] ?? t(locale, "study.irabBook");

  return (
    <section className="tafsir" aria-labelledby={headingId} data-testid="tafsir" data-ayah={`${s}:${a}`} data-book={book} data-tab={tab}>
      {showChoices ? (
        <div className="study-tabs" role="tablist" aria-label={t(locale, "study.tabs")}>
          {STUDY_TABS.map((id) => (
            <button
              key={id}
              type="button"
              role="tab"
              aria-selected={tab === id}
              className={`study-tab${tab === id ? " on" : ""}`}
              data-testid={`study-tab-${id}`}
              onClick={() => choiceStore.set({ tab: id })}
            >
              {t(locale, `study.${id}`)}
            </button>
          ))}
        </div>
      ) : null}
      {showChoices && tab === "tafsir" ? (
        <div className="tafsir-books" role="group" aria-label={t(locale, "study.chooseBook")}>
          {TAFSIR_BOOKS.map((b) => (
            <button
              key={b.id}
              type="button"
              aria-pressed={book === b.id}
              className={`chip${book === b.id ? " on" : ""}`}
              data-testid={`tafsir-book-${b.id}`}
              onClick={() => choiceStore.set({ book: b.id })}
            >
              {locale === "ar" ? b.shortAr : b.nameEn}
            </button>
          ))}
        </div>
      ) : null}
      <div className="tafsir-head">
        <h2 id={headingId} className="tafsir-title">
          {title}
          {locale === "ar" ? null : (
            <span lang="ar" dir="rtl">
              {" "}({titleAr})
            </span>
          )}
        </h2>
        <p className="tafsir-ref" data-testid="tafsir-ref">
          {t(locale, "tafsir.of", { ref })}
        </p>
      </div>
      {locale === "ar" ? null : (
        <p className="muted small tafsir-note" data-testid="tafsir-arabic-only">
          {t(locale, "tafsir.arabicOnly")}
        </p>
      )}
      <div className="tafsir-body" aria-live="polite" aria-busy={shown.status === "loading"}>
        {shown.status === "loading" ? (
          <p className="muted" data-testid="tafsir-loading">
            {t(locale, "tafsir.loading")}
          </p>
        ) : null}
        {shown.status === "error" ? (
          <div className="alert alert-error" role="alert" data-testid="tafsir-error">
            <p>{t(locale, shown.offline ? "tafsir.offline" : "tafsir.error")}</p>
            <button type="button" className="btn btn-sm" data-testid="tafsir-retry" onClick={() => setRetry((r) => r + 1)}>
              {t(locale, "tafsir.retry")}
            </button>
          </div>
        ) : null}
        {shown.status === "ready" ? <StudyBody locale={locale} body={shown.body} surah={s} ayah={a} tab={tab} /> : null}
      </div>
      <p className="tafsir-source muted small" data-testid="tafsir-source">
        {source}
      </p>
      {showNav ? (
        <div className="tafsir-nav">
          <button type="button" className="btn btn-sm" data-testid="tafsir-prev" disabled={!stepRef(s, a, -1)} onClick={() => move(-1)}>
            <Icon name={locale === "ar" ? "next" : "prev"} size={16} /> {t(locale, "tafsir.prev")}
          </button>
          <button type="button" className="btn btn-sm" data-testid="tafsir-next" disabled={!stepRef(s, a, 1)} onClick={() => move(1)}>
            {t(locale, "tafsir.next")} <Icon name={locale === "ar" ? "prev" : "next"} size={16} />
          </button>
        </div>
      ) : null}
    </section>
  );
}

function StudyBody({ locale, body, surah, ayah, tab }: { locale: Locale; body: Body; surah: number; ayah: number; tab: StudyTab }) {
  if (body.kind === "empty") {
    return (
      <p className="muted" data-testid="study-empty">
        {t(locale, tab === "gharib" ? "study.noGharib" : "study.noPart", { part: t(locale, `study.${tab}`) })}
      </p>
    );
  }
  if (body.kind === "words") {
    return (
      <dl className="study-words" lang="ar" dir="rtl" data-testid="study-words">
        {body.words.map(([w, m], i) => (
          <div key={i} className="study-word">
            <dt className="tafsir-quote">{w}</dt>
            <dd>{m}</dd>
          </div>
        ))}
      </dl>
    );
  }
  const range = body.from !== body.to;
  return (
    <>
      {range ? (
        <p className="study-range muted small" data-testid="tafsir-range">
          {t(locale, "study.range", {
            surah: surahName(surah, locale),
            from: localizeDigits(body.from, locale),
            to: localizeDigits(body.to, locale),
            ayah: localizeDigits(ayah, locale),
          })}
        </p>
      ) : null}
      <BookText text={body.text} quotes={body.quotes} testId="tafsir-text" />
      {body.notes ? (
        <details className="tafsir-notes" data-testid="tafsir-notes">
          <summary>{t(locale, "study.notes")}</summary>
          <BookText text={body.notes} quotes={false} />
        </details>
      ) : null}
    </>
  );
}
