"use client";
import Link from "next/link";
import { useEffect, useState, type ReactNode } from "react";
import { t, type Locale } from "@/lib/i18n";
import { href } from "@/lib/locale-path";
import { localizeDigits } from "@/lib/digits";
import { withBase } from "@/lib/base-path";
import {
  bookPageUrl,
  levelCount,
  readCardCounts,
  readMemorized,
  writeCardCounts,
  writeMemorized,
  type CardDhikr,
  type KidsStep,
  type HadithLevel,
  type KidsBook,
} from "@/lib/kids-learn-store";
import { Icon } from "./Icon";

/** The evening session starts in the afternoon (as in the app). */
const EVENING_FROM_HOUR = 15;
/** Pause before moving on to the next dhikr. */
const AUTO_NEXT_MS = 350;

/** Previous / page label / next, with an optional action row under it. */
function Pager({
  locale,
  label,
  onPrev,
  onNext,
  children,
}: {
  locale: Locale;
  label: string;
  onPrev: (() => void) | null;
  onNext: (() => void) | null;
  children?: ReactNode;
}) {
  // RTL: «السابق» sits on the right, so its arrow points right (forward in reading order is left).
  return (
    <div className="kl-pager">
      {children ? <div className="kl-pager-extra">{children}</div> : null}
      <div className="row" style={{ justifyContent: "space-between", gap: "0.5rem" }}>
        <button
          type="button"
          className="btn"
          data-testid="pager-prev"
          disabled={!onPrev}
          onClick={() => onPrev?.()}
        >
          <Icon name="prev" /> {t(locale, "kidsLearn.prev")}
        </button>
        <span className="muted" aria-live="polite">
          {label}
        </span>
        <button
          type="button"
          className="btn"
          data-testid="pager-next"
          disabled={!onNext}
          onClick={() => onNext?.()}
        >
          {t(locale, "kidsLearn.next")} <Icon name="next" />
        </button>
      </div>
    </div>
  );
}

/** One book, page by page (pictures of the published pages). */
export function KidsBookReader({ locale, book, base }: { locale: Locale; book: KidsBook; base: string }) {
  const n = (v: number): string => localizeDigits(v, locale);
  const [page, setPage] = useState(1);
  useEffect(() => {
    // Warm the next page so turning feels instant.
    if (page < book.pages) {
      const img = new Image();
      img.src = bookPageUrl(base, book, page + 1);
    }
  }, [page, book, base]);
  return (
    <div data-testid="kids-book">
      <p className="muted small">{t(locale, "kidsLearn.webOffline")}</p>
      <div className="kl-frame">
        {/* eslint-disable-next-line @next/next/no-img-element -- static export: no image optimiser */}
        <img
          src={bookPageUrl(base, book, page)}
          alt={`${book.title} · ${t(locale, "kidsLearn.page", { n: n(page), total: n(book.pages) })}`}
          className="kl-page"
          data-testid="kids-book-page"
        />
      </div>
      <Pager
        locale={locale}
        label={t(locale, "kidsLearn.page", { n: n(page), total: n(book.pages) })}
        onPrev={page > 1 ? () => setPage(page - 1) : null}
        onNext={page < book.pages ? () => setPage(page + 1) : null}
      />
    </div>
  );
}

/** «احفظ حديث»: levels → list → one big card to read, repeat and mark «حفظته». */
export function KidsHadith({
  locale,
  levels,
  hadith,
}: {
  locale: Locale;
  levels: HadithLevel[];
  hadith: string[];
}) {
  const hadithText = (h: number): string => hadith[h - 1] ?? "";
  const n = (v: number): string => localizeDigits(v, locale);
  const [done, setDone] = useState<Set<number>>(new Set());
  const [level, setLevel] = useState<HadithLevel | null>(null);
  const [open, setOpen] = useState<number | null>(null);
  const [reads, setReads] = useState(0);
  useEffect(() => setDone(readMemorized()), []);
  const toggle = (h: number) => {
    const s = new Set(done);
    if (s.has(h)) s.delete(h);
    else s.add(h);
    setDone(s);
    writeMemorized(s);
  };

  if (level && open !== null) {
    const isDone = done.has(open);
    const go = (h: number) => {
      setOpen(h);
      setReads(0);
    };
    return (
      <div data-testid="kids-hadith-card">
        <nav className="crumbs">
          <button type="button" className="kl-crumb" onClick={() => setOpen(null)}>
            {t(locale, "kidsLearn.level", { n: n(level.level) })}
          </button>
        </nav>
        <h2>{t(locale, "kidsLearn.hadithNo", { n: n(open) })}</h2>
        <div
          className="kl-hadith-text"
          style={{ borderColor: level.color, background: `${level.color}1a` }}
          data-testid={`kids-hadith-text-${open}`}
        >
          {hadithText(open)}
        </div>
        <Pager
          locale={locale}
          label={t(locale, "kidsLearn.hadithNo", { n: n(open) })}
          onPrev={open > level.from ? () => go(open - 1) : null}
          onNext={open < level.to ? () => go(open + 1) : null}
        >
          <button
            type="button"
            className="btn"
            data-testid="kids-hadith-repeat"
            onClick={() => setReads(reads + 1)}
          >
            <Icon name="repeat" /> {t(locale, "kidsLearn.reads", { n: n(reads) })}
          </button>
          <button
            type="button"
            className="btn btn-primary"
            aria-pressed={isDone}
            data-testid="kids-hadith-memorized"
            style={isDone ? { background: level.color, borderColor: level.color } : undefined}
            onClick={() => toggle(open)}
          >
            <Icon name={isDone ? "checkCircle" : "check"} />{" "}
            {t(locale, isDone ? "kidsLearn.memorized" : "kidsLearn.markMemorized")}
          </button>
        </Pager>
      </div>
    );
  }

  if (level) {
    const nums = Array.from({ length: levelCount(level) }, (_, i) => level.from + i);
    return (
      <div data-testid="kl-hadith-list">
        <nav className="crumbs">
          <button type="button" className="kl-crumb" onClick={() => setLevel(null)}>
            {t(locale, "kidsLearn.levelsBack")}
          </button>
        </nav>
        <h2>{t(locale, "kidsLearn.level", { n: n(level.level) })}</h2>
        <ul className="kl-hadith-list">
          {nums.map((h) => (
            <li key={h}>
              <button
                type="button"
                className="card kl-hadith-row"
                data-testid={`kids-hadith-${h}`}
                onClick={() => {
                  setOpen(h);
                  setReads(0);
                }}
              >
                <span
                  className="kl-hadith-num"
                  style={
                    done.has(h)
                      ? { background: level.color, color: "#fff" }
                      : { background: `${level.color}2e` }
                  }
                >
                  {done.has(h) ? <Icon name="check" /> : n(h)}
                </span>
                <span className="kl-hadith-preview">{hadithText(h)}</span>
              </button>
            </li>
          ))}
        </ul>
      </div>
    );
  }

  return (
    <div data-testid="kids-hadith">
      <p className="muted">{t(locale, "kidsLearn.hadithNote")}</p>
      <ul className="kl-levels">
        {levels.map((lv) => {
          const got = [...done].filter((h) => h >= lv.from && h <= lv.to).length;
          return (
            <li key={lv.level}>
              <button
                type="button"
                className="card kl-level"
                data-testid={`kids-hadith-level${lv.level}`}
                onClick={() => setLevel(lv)}
              >
                <span className="kl-level-badge" style={{ background: lv.color }}>
                  {n(lv.level)}
                </span>
                <span style={{ flex: 1 }}>
                  <strong>{t(locale, "kidsLearn.level", { n: n(lv.level) })}</strong>
                  <span className="muted small" style={{ display: "block" }}>
                    {t(locale, "kidsLearn.levelSub", { from: n(lv.from), to: n(lv.to) })}
                  </span>
                  <progress
                    value={got}
                    max={levelCount(lv)}
                    style={{ accentColor: lv.color, width: "100%" }}
                  />
                  <span className="small" style={{ display: "block" }}>
                    {t(locale, "kidsLearn.progress", { n: n(got), total: n(levelCount(lv)) })}
                  </span>
                </span>
                <Icon name="chevronForward" />
              </button>
            </li>
          );
        })}
      </ul>
    </div>
  );
}

/** «بطاقات الأذكار» as text (owner 2026-11-21): the cards' adhkar one by one with a big counter, like the
 * morning / evening adhkar; finishing a dhikr moves on to the next. */
export function KidsCards({ locale, items }: { locale: Locale; items: CardDhikr[] }) {
  const n = (v: number): string => localizeDigits(v, locale);
  const [evening, setEvening] = useState(false);
  const [counts, setCounts] = useState<Record<string, number>>({});
  const [i, setI] = useState(0);
  useEffect(() => {
    setEvening(new Date().getHours() >= EVENING_FROM_HOUR);
    setCounts(readCardCounts());
  }, []);
  const list = items.filter((c) => (evening ? c.e : c.m) > 0);
  const key = (c: CardDhikr): string => `${evening ? "e" : "m"}${c.n}`;
  const need = (c: CardDhikr): number => (evening ? c.e : c.m);
  const got = (c: CardDhikr): number => counts[key(c)] ?? 0;
  const isDone = (c: CardDhikr): boolean => got(c) >= need(c);
  const finished = list.filter(isDone).length;
  const at = Math.min(i, Math.max(0, list.length - 1));
  const c = list[at];
  const pick = (ev: boolean): void => {
    setEvening(ev);
    setI(0);
  };
  const tap = (): void => {
    if (!c || isDone(c)) return;
    const next = { ...counts, [key(c)]: got(c) + 1 };
    setCounts(next);
    writeCardCounts(next);
    if (next[key(c)]! >= need(c) && at < list.length - 1) window.setTimeout(() => setI(at + 1), AUTO_NEXT_MS);
  };
  const reset = (): void => {
    const next = Object.fromEntries(
      Object.entries(counts).filter(([k]) => !k.startsWith(evening ? "e" : "m")),
    );
    setCounts(next);
    writeCardCounts(next);
    setI(0);
  };
  return (
    <div data-testid="kids-cards">
      <div className="row" style={{ gap: "0.5rem", justifyContent: "center" }}>
        <div className="segmented" role="group" aria-label={t(locale, "adhkar.session")}>
          {[false, true].map((ev) => (
            <button
              key={String(ev)}
              type="button"
              aria-pressed={evening === ev}
              data-testid={`kids-cards-${ev ? "evening" : "morning"}`}
              onClick={() => pick(ev)}
            >
              <Icon name={ev ? "moon" : "sun"} size={18} />{" "}
              {t(locale, ev ? "adhkar.evening" : "adhkar.morning")}
            </button>
          ))}
        </div>
        <button type="button" className="btn btn-sm" data-testid="kids-cards-reset" onClick={reset}>
          <Icon name="reset" /> {t(locale, "adhkar.reset")}
        </button>
      </div>
      <progress
        className="kl-bar"
        value={finished}
        max={Math.max(1, list.length)}
        data-testid="kids-cards-bar"
      />
      <p
        className="muted small"
        role="status"
        data-testid="kids-cards-progress"
        style={{ textAlign: "center" }}
      >
        {t(locale, "adhkar.progress", { done: n(finished), total: n(list.length) })}
      </p>
      {c ? (
        <div className={isDone(c) ? "card kl-dhikr done" : "card kl-dhikr"} data-testid={`kids-card-${c.n}`}>
          <p className="muted small">{t(locale, "kidsLearn.repeatTimes", { n: n(need(c)) })}</p>
          <p className="kl-dhikr-text" lang="ar" dir="rtl" data-testid="kids-card-text">
            {c.text}
          </p>
          {(c.surahs ?? []).map((s) => (
            <p key={s} className="kl-dhikr-text" lang="ar" dir="rtl">
              {s}
            </p>
          ))}
          <p className="kl-dhikr-note">{c.note}</p>
          <button
            type="button"
            className={isDone(c) ? "kl-count done" : "kl-count"}
            data-testid="kids-card-count"
            disabled={isDone(c)}
            onClick={tap}
          >
            {isDone(c) ? (
              <Icon name="check" size={56} />
            ) : (
              <>
                <strong>{n(got(c))}</strong>
                <span>/ {n(need(c))}</span>
              </>
            )}
          </button>
          <p className="muted small" style={{ textAlign: "center" }}>
            {t(locale, isDone(c) ? "kidsLearn.cardDoneOne" : "kidsLearn.tapCounter")}
          </p>
        </div>
      ) : null}
      <Pager
        locale={locale}
        label={`${n(at + 1)} / ${n(list.length)}`}
        onPrev={at > 0 ? () => setI(at - 1) : null}
        onNext={at < list.length - 1 ? () => setI(at + 1) : null}
      />
    </div>
  );
}

/** «تعلّم الوضوء» / «تعلّم الصلاة»: the book's pictured steps, one by one. */
export function KidsSteps({
  locale,
  salah,
  steps,
  credit,
}: {
  locale: Locale;
  salah: boolean;
  steps: KidsStep[];
  credit: string;
}) {
  const n = (v: number): string => localizeDigits(v, locale);
  const [i, setI] = useState(0);
  const last = i === steps.length - 1;
  const label = t(locale, "kidsLearn.step", { n: n(i + 1), total: n(steps.length) });
  const step = steps[i];
  if (!step) return null;
  return (
    <div data-testid={salah ? "kids-salah" : "kids-wudu"}>
      <article className="kl-step" data-testid={`kids-step-${i}`}>
        {step.pic ? (
          /* eslint-disable-next-line @next/next/no-img-element -- static export: no image optimiser */
          <img src={withBase(`/kids/steps/${step.pic}.webp`)} alt={step.title} className="kl-step-pic" />
        ) : null}
        <h2 className="kl-step-title">{step.title}</h2>
        <p className={step.pic ? "kl-step-text" : "kl-step-text kl-step-long"}>{step.text}</p>
        {step.ayah ? (
          <p className="kl-dhikr-text" lang="ar">
            {step.ayah}
          </p>
        ) : null}
      </article>
      <Pager
        locale={locale}
        label={label}
        onPrev={i > 0 ? () => setI(i - 1) : null}
        onNext={!last ? () => setI(i + 1) : null}
      >
        {last ? <strong data-testid="kids-steps-done">{t(locale, "kidsLearn.stepsDone")}</strong> : null}
      </Pager>
      <p className="muted small" style={{ textAlign: "center" }}>
        {t(locale, "kidsLearn.credit", { name: credit })}
      </p>
    </div>
  );
}

/** The four corners as tiles on the kids page. */
const LEARN_TILES = {
  books: "openBook",
  hadith: "star",
  cards: "adhkar",
  wudu: "prayer",
  salah: "prayer",
} as const;
export type LearnTile = keyof typeof LEARN_TILES;

export function KidsLearnTiles({ locale, ids }: { locale: Locale; ids: readonly LearnTile[] }) {
  return (
    <>
      {ids
        .map((id) => [id, LEARN_TILES[id]] as const)
        .map(([id, icon]) => (
          <li key={id}>
            <Link className="tile tile-sm" href={href(locale, `kids/${id}`)} data-testid={`kids-tab-${id}`}>
              <span className="tile-icon">
                <Icon name={icon} />
              </span>
              <span className="tile-text">
                <strong>{t(locale, `kidsLearn.${id}`)}</strong>
                <span className="muted small">{t(locale, `kidsLearn.${id}Sub`)}</span>
              </span>
            </Link>
          </li>
        ))}
    </>
  );
}
