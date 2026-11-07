"use client";
import { useEffect, useState } from "react";
import { t, type Locale } from "@/lib/i18n";
import { localizeDigits } from "@/lib/digits";
import {
  adhkarStore,
  countOne,
  defaultSession,
  progressFor,
  resetSession,
  sessionItems,
  sessionSummary,
  type Session,
} from "@/lib/adhkar";
import { isoDate } from "@/lib/time";
import { useStore } from "@/hooks/useStore";
import { Icon } from "./Icon";

const SESSIONS: readonly Session[] = ["morning", "evening"];

function localToday(): string {
  const d = new Date();
  return isoDate({ year: d.getFullYear(), month: d.getMonth() + 1, day: d.getDate() });
}

/** Morning / evening adhkar with a counter per item; progress is kept per day on this device. */
export function AdhkarView({ locale, items }: { locale: Locale; items: readonly string[] }) {
  const [session, setSession] = useState<Session>("morning");
  const [today, setToday] = useState("");
  const stored = useStore(adhkarStore);
  useEffect(() => {
    const hash = window.location.hash.slice(1);
    setSession(hash === "morning" || hash === "evening" ? hash : defaultSession(new Date().getHours()));
    setToday(localToday());
  }, []);
  const list = sessionItems(items, session);
  const progress = progressFor(stored, today);
  const summary = sessionSummary(stored, today, session, list);
  const choose = (s: Session): void => {
    setSession(s);
    window.history.replaceState(window.history.state, "", `#${s}`);
  };

  return (
    <>
      <div className="segmented" role="group" aria-label={t(locale, "adhkar.session")}>
        {SESSIONS.map((s) => (
          <button
            key={s}
            type="button"
            aria-pressed={session === s}
            data-testid={`session-${s}`}
            onClick={() => choose(s)}
          >
            <Icon name={s === "morning" ? "sun" : "moon"} size={18} /> {t(locale, `adhkar.${s}`)}
          </button>
        ))}
      </div>
      <div className="adhkar-summary row">
        <p className="muted" data-testid="adhkar-progress" role="status">
          {t(locale, "adhkar.progress", {
            done: localizeDigits(summary.completed, locale),
            total: localizeDigits(summary.total, locale),
          })}
        </p>
        <button
          type="button"
          className="btn btn-sm"
          data-testid="adhkar-reset"
          onClick={() => adhkarStore.set((p) => resetSession(p, localToday(), session))}
        >
          <Icon name="reset" size={16} /> {t(locale, "adhkar.reset")}
        </button>
      </div>
      {locale !== "ar" ? <p className="alert">{t(locale, "common.arabicOnly")}</p> : null}
      <ol className="dhikr-list" data-testid="dhikr-list">
        {list.map((d, i) => {
          const n = progress.done[`${session}:${d.id}`] ?? 0;
          const done = n >= d.count;
          return (
            <li key={`${session}-${d.id}`} className={done ? "dhikr done" : "dhikr"} data-testid="dhikr">
              <p className="dhikr-text" lang="ar" dir="rtl">
                {d.text}
              </p>
              <div className="dhikr-foot">
                <span className="muted small">
                  {t(locale, "adhkar.repeat", { n: localizeDigits(d.count, locale) })}
                </span>
                <button
                  type="button"
                  className={done ? "counter done" : "counter"}
                  data-testid="dhikr-count"
                  disabled={done}
                  onClick={() => adhkarStore.set((p) => countOne(p, localToday(), session, d))}
                >
                  {done ? <Icon name="check" size={18} /> : null}
                  <span className="sr-only">
                    {t(locale, "adhkar.countLabel", {
                      i: localizeDigits(i + 1, locale),
                      n: localizeDigits(n, locale),
                      total: localizeDigits(d.count, locale),
                    })}
                  </span>
                  <span aria-hidden="true">
                    {localizeDigits(n, locale)} / {localizeDigits(d.count, locale)}
                  </span>
                </button>
              </div>
            </li>
          );
        })}
      </ol>
      <p className="muted small">{t(locale, "adhkar.source")}</p>
    </>
  );
}
