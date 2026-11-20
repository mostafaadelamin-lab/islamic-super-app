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
  readCardsToday,
  readMemorized,
  writeCardsToday,
  writeMemorized,
  type HadithLevel,
  type KidsBook,
} from "@/lib/kids-learn-store";
import { Icon } from "./Icon";

const MAX_STARS = 8;

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

/** «بطاقات الأذكار»: the published cards (boys' or girls' edition), with a star for each card said today. */
export function KidsCards({ locale, cards }: { locale: Locale; cards: number[] }) {
  const n = (v: number): string => localizeDigits(v, locale);
  const [girls, setGirls] = useState(false);
  const [i, setI] = useState(0);
  const [done, setDone] = useState<Set<number>>(new Set());
  useEffect(() => setDone(readCardsToday()), []);
  const page = cards[i] ?? cards[0] ?? 0;
  const isDone = done.has(page);
  const stars = cards.filter((c) => done.has(c)).length;
  const toggle = () => {
    const s = new Set(done);
    if (s.has(page)) s.delete(page);
    else s.add(page);
    setDone(s);
    writeCardsToday(s);
  };
  return (
    <div data-testid="kids-cards">
      <div className="row" role="group" style={{ justifyContent: "center", gap: "0.5rem" }}>
        {[false, true].map((g) => (
          <button
            key={String(g)}
            type="button"
            className={`btn btn-sm${girls === g ? " btn-primary" : ""}`}
            aria-pressed={girls === g}
            data-testid={`kids-cards-${g ? "girls" : "boys"}`}
            onClick={() => setGirls(g)}
          >
            {t(locale, g ? "kidsLearn.girls" : "kidsLearn.boys")}
          </button>
        ))}
      </div>
      {stars > 0 ? (
        <p className="kl-stars" data-testid="kids-cards-stars">
          {"⭐".repeat(Math.min(stars, MAX_STARS))} {t(locale, "kidsLearn.cardsToday", { n: n(stars) })}
        </p>
      ) : null}
      <div className="kl-frame">
        {/* eslint-disable-next-line @next/next/no-img-element -- static export: no image optimiser */}
        <img
          src={withBase(`/kids/cards/${girls ? "g" : "b"}${page}.webp`)}
          alt={t(locale, "kidsLearn.page", { n: n(i + 1), total: n(cards.length) })}
          className="kl-page"
          data-testid="kids-card-img"
        />
      </div>
      <Pager
        locale={locale}
        label={t(locale, "kidsLearn.page", { n: n(i + 1), total: n(cards.length) })}
        onPrev={i > 0 ? () => setI(i - 1) : null}
        onNext={i < cards.length - 1 ? () => setI(i + 1) : null}
      >
        <button
          type="button"
          className="btn btn-primary"
          aria-pressed={isDone}
          data-testid="kids-card-done"
          onClick={toggle}
        >
          <Icon name="star" /> {t(locale, isDone ? "kidsLearn.cardDone" : "kidsLearn.cardMark")}
        </button>
      </Pager>
    </div>
  );
}

/** «تعلّم الوضوء» / «تعلّم الصلاة»: the book's pictured steps, one by one. */
export function KidsSteps({
  locale,
  salah,
  pages,
  credit,
}: {
  locale: Locale;
  salah: boolean;
  pages: number[];
  credit: string;
}) {
  const n = (v: number): string => localizeDigits(v, locale);
  const [i, setI] = useState(0);
  const last = i === pages.length - 1;
  const label = t(locale, "kidsLearn.step", { n: n(i + 1), total: n(pages.length) });
  return (
    <div data-testid={salah ? "kids-salah" : "kids-wudu"}>
      <div className="kl-frame">
        {/* eslint-disable-next-line @next/next/no-img-element -- static export: no image optimiser */}
        <img src={withBase(`/kids/wudu/${pages[i]}.webp`)} alt={label} className="kl-page" />
      </div>
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
export function KidsLearnTiles({ locale }: { locale: Locale }) {
  const items = [
    ["books", "openBook"],
    ["hadith", "star"],
    ["cards", "adhkar"],
    ["wudu", "prayer"],
    ["salah", "prayer"],
  ] as const;
  return (
    <>
      {items.map(([id, icon]) => (
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
