"use client";
import Link from "next/link";
import { useState } from "react";
import { t, type Locale } from "@/lib/i18n";
import { href } from "@/lib/locale-path";
import { localizeDigits } from "@/lib/digits";
import { juzForPage, pageDef, surahName } from "@/lib/pages";
import pageOpenings from "@/generated/page-openings.json";
import {
  completeWird,
  khatmaStore,
  MAX_DAYS,
  MAX_PAGES_PER_DAY,
  MIN_DAYS,
  MIN_PAGES_PER_DAY,
  MUSHAF_PAGES,
  planByDays,
  planByPages,
  progress,
  reschedule,
  wirdPages,
  type IsoDay,
  type Khatma,
} from "@/lib/khatma";
import { isoDate, localDateInTz } from "@/lib/time";
import { useStore } from "@/hooks/useStore";
import { useNow } from "@/hooks/useNow";

const OPENINGS = pageOpenings as string[];
const RING_R = 52;
const FULL_TURN = 2 * Math.PI;
const RING_C = FULL_TURN * RING_R;
const PERCENT = 100;
const MONTH_DAYS = 30;
const TWO_MONTHS_DAYS = 60;
const WEEK_DAYS = 7;
/** Quick choices: a month (e.g. Ramadan), two months, a week. */
const DAY_PRESETS = [MONTH_DAYS, TWO_MONTHS_DAYS, WEEK_DAYS] as const;
const DEFAULT_DAYS = MONTH_DAYS;
const DEFAULT_PAGES = 20;
const MINUTE_MS = 60_000;

/** List class of wird `i` when `done` wirds are read. */
function wirdClass(i: number, done: number): string | undefined {
  if (i < done) return "done";
  return i === done ? "current" : undefined;
}

function localToday(now: Date): IsoDay {
  const tz = Intl.DateTimeFormat().resolvedOptions().timeZone || "UTC";
  return isoDate(localDateInTz(now, tz));
}

function formatDay(d: IsoDay, locale: Locale): string {
  const [y, m, day] = d.split("-").map(Number) as [number, number, number];
  return new Intl.DateTimeFormat(locale === "ar" ? "ar-EG-u-nu-arab" : "en-GB", {
    timeZone: "UTC",
    day: "numeric",
    month: "long",
    year: "numeric",
  }).format(new Date(Date.UTC(y, m - 1, day)));
}

/** "From surah X ayah n, page p — to surah Y ayah m, page q" for a wird. */
function WirdRange({ k, i, locale }: { k: Khatma; i: number; locale: Locale }) {
  const { from, to } = wirdPages(k, i);
  const a = pageDef(from).start;
  const b = pageDef(to).end;
  const n = (x: number): string => localizeDigits(x, locale);
  return (
    <span>
      {t(locale, "khatma.range", {
        fromSurah: surahName(a[0], locale),
        fromAyah: n(a[1]),
        fromPage: n(from),
        toSurah: surahName(b[0], locale),
        toAyah: n(b[1]),
        toPage: n(to),
      })}
    </span>
  );
}

function CreateForm({ locale, today }: { locale: Locale; today: IsoDay }) {
  const [name, setName] = useState("");
  const [mode, setMode] = useState<"days" | "pages">("days");
  const [days, setDays] = useState(DEFAULT_DAYS);
  const [pages, setPages] = useState(DEFAULT_PAGES);
  const plan =
    mode === "days"
      ? planByDays(name.trim() || t(locale, "khatma.defaultName"), today, days)
      : planByPages(name.trim() || t(locale, "khatma.defaultName"), today, pages);
  const p = progress(plan, today);
  const perDay = Math.ceil(MUSHAF_PAGES / plan.wirds);
  return (
    <section className="card" aria-labelledby="khatma-new-h" data-testid="khatma-create">
      <h2 id="khatma-new-h" style={{ marginTop: 0 }}>
        {t(locale, "khatma.new")}
      </h2>
      <div className="field">
        <label htmlFor="khatma-name">{t(locale, "khatma.name")}</label>
        <input
          id="khatma-name"
          value={name}
          maxLength={40}
          placeholder={t(locale, "khatma.defaultName")}
          onChange={(e) => setName(e.target.value)}
        />
      </div>
      <fieldset className="field" style={{ border: 0, padding: 0 }}>
        <legend className="label">{t(locale, "khatma.mode")}</legend>
        <div className="row">
          <label className="check">
            <input type="radio" name="mode" checked={mode === "days"} onChange={() => setMode("days")} />
            {t(locale, "khatma.byDays")}
          </label>
          <label className="check">
            <input
              type="radio"
              name="mode"
              checked={mode === "pages"}
              onChange={() => setMode("pages")}
              data-testid="khatma-mode-pages"
            />
            {t(locale, "khatma.byPages")}
          </label>
        </div>
      </fieldset>
      {mode === "days" ? (
        <div className="field">
          <label htmlFor="khatma-days">{t(locale, "khatma.days")}</label>
          <input
            id="khatma-days"
            type="number"
            inputMode="numeric"
            min={MIN_DAYS}
            max={MAX_DAYS}
            value={days}
            onChange={(e) => setDays(Number(e.target.value) || MIN_DAYS)}
          />
          <div className="row" style={{ marginTop: "var(--space-xs)" }}>
            {DAY_PRESETS.map((d) => (
              <button key={d} type="button" className="btn" onClick={() => setDays(d)}>
                {t(locale, "khatma.daysN", { n: localizeDigits(d, locale) })}
              </button>
            ))}
          </div>
        </div>
      ) : (
        <div className="field">
          <label htmlFor="khatma-pages">{t(locale, "khatma.pagesPerDay")}</label>
          <input
            id="khatma-pages"
            type="number"
            inputMode="numeric"
            min={MIN_PAGES_PER_DAY}
            max={MAX_PAGES_PER_DAY}
            value={pages}
            onChange={(e) => setPages(Number(e.target.value) || MIN_PAGES_PER_DAY)}
          />
        </div>
      )}
      <p className="muted" data-testid="khatma-preview">
        {t(locale, "khatma.preview", {
          wirds: localizeDigits(plan.wirds, locale),
          pages: localizeDigits(perDay, locale),
          end: formatDay(p.endDate, locale),
        })}
      </p>
      <button
        type="button"
        className="btn btn-primary"
        data-testid="khatma-start"
        onClick={() => khatmaStore.set((s) => ({ ...s, current: plan }))}
      >
        {t(locale, "khatma.start")}
      </button>
    </section>
  );
}

function History({ locale }: { locale: Locale }) {
  const { history } = useStore(khatmaStore);
  return (
    <section className="card" aria-labelledby="khatma-hist-h" data-testid="khatma-history">
      <h2 id="khatma-hist-h" style={{ marginTop: 0 }}>
        {t(locale, "khatma.history")}
      </h2>
      {history.length === 0 ? (
        <p className="muted">{t(locale, "khatma.historyEmpty")}</p>
      ) : (
        <ul className="plain-list">
          {history.map((h, i) => (
            <li key={`${h.finishedDate}-${i}`}>
              <strong>{h.name}</strong>{" "}
              <span className="muted">
                {t(locale, "khatma.finishedOn", {
                  date: formatDay(h.finishedDate, locale),
                  days: localizeDigits(h.days, locale),
                })}
              </span>
            </li>
          ))}
        </ul>
      )}
    </section>
  );
}

/** Khatma page: create a plan, follow today's wird, reschedule when late, and the list of finished khatmas. */
export function KhatmaView({ locale }: { locale: Locale }) {
  const state = useStore(khatmaStore);
  const now = useNow(MINUTE_MS);
  const [showAll, setShowAll] = useState(false);
  const [editing, setEditing] = useState(false);
  if (!now) return null;
  const today = localToday(now);
  const k = state.current;
  if (!k) {
    return (
      <>
        <CreateForm locale={locale} today={today} />
        <History locale={locale} />
      </>
    );
  }
  const p = progress(k, today);
  const n = (x: number): string => localizeDigits(x, locale);
  const pct = Math.round(p.fraction * PERCENT);
  const cur = wirdPages(k, k.done);
  return (
    <>
      <section className="card khatma-card" aria-labelledby="khatma-h" data-testid="khatma-current">
        <div className="khatma-top">
          <svg className="khatma-ring" viewBox="0 0 120 120" role="img" aria-label={`${n(pct)}%`}>
            <circle cx="60" cy="60" r={RING_R} className="ring-bg" />
            <circle
              cx="60"
              cy="60"
              r={RING_R}
              className="ring-fg"
              strokeDasharray={RING_C}
              strokeDashoffset={RING_C * (1 - p.fraction)}
              transform="rotate(-90 60 60)"
            />
            <text x="60" y="66" textAnchor="middle" className="ring-text" data-testid="khatma-percent">
              {`${n(pct)}${locale === "ar" ? "٪" : "%"}`}
            </text>
          </svg>
          <div>
            {editing ? (
              <input
                aria-label={t(locale, "khatma.name")}
                defaultValue={k.name}
                maxLength={40}
                autoFocus
                onBlur={(e) => {
                  const v = e.target.value.trim();
                  khatmaStore.set((s) =>
                    s.current ? { ...s, current: { ...s.current, name: v || s.current.name } } : s,
                  );
                  setEditing(false);
                }}
              />
            ) : (
              <h2 id="khatma-h" style={{ margin: 0 }}>
                {k.name}{" "}
                <button type="button" className="btn btn-link" onClick={() => setEditing(true)}>
                  {t(locale, "khatma.rename")}
                </button>
              </h2>
            )}
            <p className="muted" style={{ margin: 0 }}>
              {t(locale, "khatma.endsOn", { date: formatDay(p.endDate, locale) })}
            </p>
          </div>
        </div>
        <div className="khatma-stats">
          <div>
            <span className="muted">{t(locale, "khatma.remainingWirds")}</span>
            <strong data-testid="khatma-remaining">{n(p.remainingWirds)}</strong>
            <progress max={k.wirds} value={k.done} aria-label={t(locale, "khatma.remainingWirds")} />
          </div>
          <div>
            <span className="muted">{t(locale, "khatma.remainingDays")}</span>
            <strong>{n(p.remainingDays)}</strong>
          </div>
        </div>
        {p.behind > 0 && (
          <div className="alert" role="status" data-testid="khatma-behind">
            {t(locale, "khatma.behind", { n: n(p.behind) })}{" "}
            <button
              type="button"
              className="btn"
              data-testid="khatma-reschedule"
              onClick={() =>
                khatmaStore.set((s) => (s.current ? { ...s, current: reschedule(s.current, today) } : s))
              }
            >
              {t(locale, "khatma.reschedule")}
            </button>
          </div>
        )}
        {p.ahead > 0 && (
          <p className="alert alert-ok" data-testid="khatma-ahead">
            {t(locale, "khatma.ahead", { n: n(p.ahead) })}
          </p>
        )}
      </section>

      <section className="card" aria-labelledby="wird-h" data-testid="khatma-wird">
        <div className="row" style={{ justifyContent: "space-between" }}>
          <h2 id="wird-h" style={{ margin: 0 }}>
            {t(locale, "khatma.currentWird", { n: n(k.done + 1), total: n(k.wirds) })}
          </h2>
          <button type="button" className="btn btn-link" onClick={() => setShowAll((v) => !v)}>
            {showAll ? t(locale, "khatma.hideAll") : t(locale, "khatma.showAll")}
          </button>
        </div>
        <p className="khatma-opening" lang="ar">
          {t("ar", "khatma.opening")} {OPENINGS[cur.from - 1]}
        </p>
        <p className="muted">
          {t(locale, "khatma.juz", { n: n(juzForPage(cur.from)) })} ·{" "}
          <WirdRange k={k} i={k.done} locale={locale} />
        </p>
        <div className="row">
          <Link className="btn btn-primary" href={href(locale, `page/${cur.from}`)} data-testid="khatma-read">
            {t(locale, "khatma.read")}
          </Link>
          <button
            type="button"
            className="btn"
            data-testid="khatma-done"
            onClick={() => khatmaStore.set((s) => completeWird(s, today))}
          >
            {t(locale, "khatma.markDone")}
          </button>
        </div>
        {showAll ? (
          <ol className="khatma-all" data-testid="khatma-all">
            {Array.from({ length: k.wirds }, (_, i) => (
              <li key={i} className={wirdClass(i, k.done)}>
                <WirdRange k={k} i={i} locale={locale} />
              </li>
            ))}
          </ol>
        ) : null}
      </section>

      <p className="muted">{t(locale, "khatma.webReminderNote")}</p>
      <button
        type="button"
        className="btn btn-danger"
        data-testid="khatma-delete"
        onClick={() => {
          if (window.confirm(t(locale, "khatma.deleteConfirm")))
            khatmaStore.set((s) => ({ ...s, current: null }));
        }}
      >
        {t(locale, "khatma.delete")}
      </button>
      <History locale={locale} />
    </>
  );
}
