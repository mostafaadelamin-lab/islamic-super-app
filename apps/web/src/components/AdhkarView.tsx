"use client";
import { useEffect, useState } from "react";
import Link from "next/link";
import { href } from "@/lib/locale-path";
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
import { adhkarViewStore } from "@/lib/dhikr-share";
import { useStore } from "@/hooks/useStore";
import { useAutoExit } from "@/hooks/useAutoExit";
import { Icon } from "./Icon";
import { CardDeck } from "./CardDeck";
import { DhikrTools } from "./DhikrTools";
import type { DhikrExtra } from "@/lib/dhikr-extras";
import { userAdhkarStore, userItems, type UserDhikr } from "@/lib/custom-adhkar";
import { UserDhikrForm, UserDhikrTools } from "./UserAdhkar";

const SESSIONS: readonly Session[] = ["morning", "evening"];

function localToday(): string {
  const d = new Date();
  return isoDate({ year: d.getFullYear(), month: d.getMonth() + 1, day: d.getDate() });
}

/** Morning / evening adhkar with a counter per item; progress is kept per day on this device. */
export function AdhkarView({
  locale,
  items,
  extras = [],
}: {
  locale: Locale;
  items: readonly string[];
  extras?: readonly DhikrExtra[];
}) {
  const [session, setSession] = useState<Session>("morning");
  const [today, setToday] = useState("");
  const stored = useStore(adhkarStore);
  const { mode } = useStore(adhkarViewStore);
  const mine = useStore(userAdhkarStore);
  const [editing, setEditing] = useState<UserDhikr | null>(null);
  useEffect(() => {
    const hash = window.location.hash.slice(1);
    setSession(hash === "morning" || hash === "evening" ? hash : defaultSession(new Date().getHours()));
    setToday(localToday());
  }, []);
  const list = [...sessionItems(items, session), ...userItems(mine, session)];
  const progress = progressFor(stored, today);
  const summary = sessionSummary(stored, today, session, list);
  // Finishing the last dhikr goes back up to the adhkar list at the top of the page (the app closes
  // the screen and shows its adhkar list).
  useAutoExit(
    today !== "" && summary.total > 0 && summary.completed === summary.total,
    `${session}:${today}`,
    () => {
      const reduce = window.matchMedia?.("(prefers-reduced-motion: reduce)").matches ?? false;
      window.scrollTo({ top: 0, behavior: reduce ? "auto" : "smooth" });
    },
  );
  const choose = (s: Session): void => {
    setSession(s);
    window.history.replaceState(window.history.state, "", `#${s}`);
  };

  const bookSource = t(locale, "adhkar.shareSource", { session: t(locale, `adhkar.${session}`) });
  const goToForm = (): void => {
    document.getElementById("user-dhikr-form")?.scrollIntoView?.({ block: "center" });
    document.getElementById("user-dhikr-text")?.focus({ preventScroll: true });
  };
  const item = (i: number): React.JSX.Element => {
    const d = list[i]!;
    const n = progress.done[`${session}:${d.id}`] ?? 0;
    const done = n >= d.count;
    // A dhikr the visitor wrote is not from Hisn al-Muslim.
    const source = d.custom ? t(locale, "adhkar.mine") : bookSource;
    const first = d.custom && (i === 0 || !list[i - 1]!.custom);
    return (
      <li
        key={`${session}-${d.id}`}
        className={`dhikr${done ? " done" : ""}${d.custom ? " mine" : ""}`}
        data-testid={d.custom ? "dhikr-mine" : "dhikr"}
      >
        {first || (d.custom && mode === "cards") ? (
          <p className="mine-head" data-testid={first ? "mine-head" : undefined}>
            <strong>{t(locale, "adhkar.mine")}</strong>{" "}
            <span className="tag">{t(locale, "adhkar.mineTag")}</span>
          </p>
        ) : null}
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
        <DhikrTools
          locale={locale}
          text={d.text}
          source={source}
          where={`${source} · ${localizeDigits(i + 1, locale)}`}
          testId={`dhikr-${i + 1}`}
          extra={d.custom ? undefined : extras[d.id]}
        />
        {d.custom ? (
          <UserDhikrTools
            locale={locale}
            id={d.id}
            onEdit={(x) => {
              setEditing(x);
              requestAnimationFrame(goToForm);
            }}
          />
        ) : null}
      </li>
    );
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
      <p className="muted" data-testid="adhkar-progress" role="status">
        {t(locale, "adhkar.progress", {
          done: localizeDigits(summary.completed, locale),
          total: localizeDigits(summary.total, locale),
        })}
      </p>
      {/* Owner 2026-11-26 (option 2): the tools as coloured squares with their names. */}
      <div className="adhkar-tools">
        <button type="button" className="tool-tile gold" data-testid="user-dhikr-add" onClick={goToForm}>
          <Icon name="plus" size={22} />
          <span>{t(locale, "adhkar.barAdd")}</span>
        </button>
        <button
          type="button"
          className="tool-tile plain"
          data-testid={mode === "cards" ? "view-list" : "view-cards"}
          title={t(locale, mode === "cards" ? "dhikr.view.list" : "dhikr.view.cards")}
          onClick={() => adhkarViewStore.set(() => ({ mode: mode === "cards" ? "list" : "cards" }))}
        >
          <Icon name={mode === "cards" ? "pages" : "palette"} size={22} />
          <span>{t(locale, "adhkar.barView")}</span>
        </button>
        <Link
          className="tool-tile soft"
          href={href(locale, "adhkar/reminders")}
          data-testid="adhkar-tool-reminders"
        >
          <Icon name="alarm" size={22} />
          <span>{t(locale, "adhkar.barAlarm")}</span>
        </Link>
        <button
          type="button"
          className="tool-tile plain"
          data-testid="adhkar-reset"
          title={t(locale, "adhkar.reset")}
          onClick={() => adhkarStore.set((p) => resetSession(p, localToday(), session))}
        >
          <Icon name="reset" size={22} />
          <span>{t(locale, "adhkar.barReset")}</span>
        </button>
      </div>
      {locale !== "ar" ? <p className="alert">{t(locale, "common.arabicOnly")}</p> : null}
      {mode === "cards" ? (
        <CardDeck
          locale={locale}
          count={list.length}
          resetKey={`${session}:${today}`}
          advanceWhen={(i) => (progress.done[`${session}:${list[i]!.id}`] ?? 0) >= list[i]!.count}
          render={(i) => <ol className="dhikr-list">{item(i)}</ol>}
        />
      ) : (
        <ol className="dhikr-list" data-testid="dhikr-list">
          {list.map((_, i) => item(i))}
        </ol>
      )}
      <UserDhikrForm locale={locale} session={session} editing={editing} onDone={() => setEditing(null)} />
    </>
  );
}
