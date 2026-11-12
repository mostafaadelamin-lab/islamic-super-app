"use client";
import { useState, useSyncExternalStore } from "react";
import { t, type Locale } from "@/lib/i18n";
import { localizeDigits } from "@/lib/digits";
import { dhikrPlayer, DhikrPlayerBar } from "./DhikrAudio";
import { Icon } from "./Icon";

export interface AsmaName {
  name: string;
  group: string | null;
  text: string;
  seeAlso: string | null;
  /** Sheikh al-Nabulsi's recorded lessons on this name (0–2). */
  lessons: string[];
}

const strip = (s: string): string =>
  s
    .replace(/[ً-ْـ]/g, "")
    .replace(/[أإآ]/g, "ا")
    .replace(/ى/g, "ي")
    .replace(/ة/g, "ه");

function Lessons({ locale, urls, testId }: { locale: Locale; urls: string[]; testId: string }) {
  const p = useSyncExternalStore(dhikrPlayer.subscribe, dhikrPlayer.get, dhikrPlayer.get);
  if (urls.length === 0) return null;
  return (
    <div className="asma-lessons">
      <span className="muted small">{t(locale, "asma.lessonBy")}</span>
      {urls.map((u, k) => {
        const on = p.url === u && p.playing;
        const label =
          urls.length === 1
            ? t(locale, "asma.listenLesson")
            : t(locale, "asma.part", { n: localizeDigits(k + 1, locale) });
        return (
          <button
            key={u}
            type="button"
            className="btn btn-sm"
            aria-pressed={on}
            onClick={() => dhikrPlayer.toggle(u)}
            data-testid={k === 0 ? testId : `${testId}-${k + 1}`}
          >
            <Icon name={on ? "stop" : "headphones"} size={16} /> {on ? t(locale, "asma.stop") : label}
          </button>
        );
      })}
    </div>
  );
}

function Explanation({ locale, text }: { locale: Locale; text: string }) {
  const [open, setOpen] = useState(false);
  const long = text.length > 220;
  return (
    <>
      <p className={long && !open ? "asma-text folded" : "asma-text"} lang="ar" dir="rtl">
        {text}
      </p>
      {long ? (
        <button type="button" className="btn-link small" onClick={() => setOpen((o) => !o)}>
          {open ? t(locale, "asma.less") : t(locale, "asma.more")}
        </button>
      ) : null}
    </>
  );
}

/** The 99 names, each with its explanation and, where recorded, Sheikh al-Nabulsi's lessons on it. */
export function AsmaView({ locale, names }: { locale: Locale; names: readonly AsmaName[] }) {
  const [query, setQuery] = useState("");
  const q = strip(query.trim());
  const list = names
    .map((n, i) => ({ n, i }))
    .filter(({ n }) => !q || strip(`${n.name} ${n.group ?? ""}`).includes(q));
  return (
    <>
      <input
        type="search"
        className="input"
        placeholder={t(locale, "asma.search")}
        aria-label={t(locale, "asma.search")}
        value={query}
        onChange={(e) => setQuery(e.target.value)}
        data-testid="asma-search"
      />
      {list.length === 0 ? <p className="muted">{t(locale, "asma.none")}</p> : null}
      <ol className="asma-list" data-testid="asma-list">
        {list.map(({ n, i }) => (
          <li key={n.name} className="card asma" data-testid={`asma-${i}`}>
            <div className="asma-head">
              <span className="asma-num">{localizeDigits(i + 1, locale)}</span>
              <h2 lang="ar" className="asma-name">
                {n.name}
              </h2>
            </div>
            {n.group ? <p className="muted small">{n.group}</p> : null}
            <Lessons locale={locale} urls={n.lessons} testId={`asma-listen-${i}`} />
            <Explanation locale={locale} text={n.text} />
          </li>
        ))}
      </ol>
      <p className="muted small">{t(locale, "asma.source")}</p>
      <DhikrPlayerBar locale={locale} />
    </>
  );
}
