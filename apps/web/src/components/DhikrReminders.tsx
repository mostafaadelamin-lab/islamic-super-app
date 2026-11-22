"use client";
import { useEffect, useState } from "react";
import adhkar from "@/generated/adhkar.json";
import { t, type Locale } from "@/lib/i18n";
import { localizeDigits } from "@/lib/digits";
import { useStore } from "@/hooks/useStore";
import { registerAudio } from "@/lib/audio-focus";
import { withBase } from "@/lib/base-path";
import {
  DHIKR_INTERVALS,
  DHIKR_REMINDER_ITEMS,
  dhikrClipSrc,
  dhikrReminderStore,
  dhikrSlots,
  nextDhikrReminder,
} from "@/lib/dhikr-reminders";
import { Icon } from "./Icon";
import { adhanStore, inQuiet, quietWindows } from "@/lib/adhan-alerts";
import { prayerStore } from "@/lib/settings";
import { resolveLocation } from "@/lib/cities";

/** True when `at` falls in the quiet time around an enabled adhan (until its iqama). */
function inPrayerQuiet(at: Date): boolean {
  try {
    const prayer = prayerStore.get();
    const q = { ...resolveLocation(prayer), asr: prayer.asr, adjustments: prayer.adjustments };
    return inQuiet(at, quietWindows(at, q, adhanStore.get()));
  } catch {
    return false;
  }
}

const TEXTS = (adhkar as { items: string[] }).items;
const textOf = (id: string): string => TEXTS[DHIKR_REMINDER_ITEMS.find((d) => d.id === id)?.index ?? 0] ?? "";
const BANNER_MS = 12_000;
const TICK_MS = 5_000;
const LATE_MS = 2 * 60_000;

let clip: HTMLAudioElement | null = null;
function playClip(id: string, onEnd?: () => void): void {
  if (!clip) {
    clip = new Audio();
    clip.preload = "none";
    registerAudio(clip, () => clip?.pause());
  }
  clip.onended = onEnd ?? null;
  clip.src = dhikrClipSrc(id);
  void clip.play().catch(() => onEnd?.());
}
function stopClip(): void {
  clip?.pause();
}

async function notify(title: string, body: string): Promise<void> {
  if (typeof Notification === "undefined" || Notification.permission !== "granted") return;
  const opts: NotificationOptions = { body, icon: withBase("/icon-192.png"), tag: "dhikr", silent: true };
  try {
    const reg = await navigator.serviceWorker?.getRegistration();
    if (reg) return void (await reg.showNotification(title, opts));
  } catch {
    // fall back to a page notification
  }
  try {
    new Notification(title, opts);
  } catch {
    // some mobile browsers only allow service-worker notifications
  }
}

/** Mounted once per page: while the site is open, says / shows the chosen dhikr at each reminder time. */
export function DhikrReminderAlerts({ locale }: { locale: Locale }) {
  const prefs = useStore(dhikrReminderStore);
  const [shown, setShown] = useState<string | null>(null);

  useEffect(() => {
    let target = nextDhikrReminder(new Date(), prefs);
    if (!target) return;
    const tick = (): void => {
      if (!target) return;
      const now = Date.now();
      if (now < target.at.getTime()) return;
      const fired = target;
      target = nextDhikrReminder(new Date(now + 1000), prefs);
      if (now - fired.at.getTime() > LATE_MS) return; // missed while the computer slept
      if (inPrayerQuiet(fired.at)) return; // owner 2026-11-22: nothing else around the adhan
      void notify(t(locale, "dhikrRem.notifTitle"), textOf(fired.id));
      if (prefs.sound) playClip(fired.id);
      setShown(fired.id);
    };
    const id = setInterval(tick, TICK_MS);
    return () => clearInterval(id);
  }, [prefs, locale]);

  useEffect(() => {
    if (!shown) return;
    const id = setTimeout(() => setShown(null), BANNER_MS);
    return () => clearTimeout(id);
  }, [shown]);

  if (!shown) return null;
  return (
    <div className="adhan-ringing dhikr-ringing" role="status" data-testid="dhikr-ringing" data-id={shown}>
      <span className="dua">{textOf(shown)}</span>
      <button
        type="button"
        className="btn btn-sm"
        onClick={() => {
          stopClip();
          setShown(null);
        }}
      >
        {t(locale, "dhikrRem.dismiss")}
      </button>
    </div>
  );
}

const hhmm = (m: number): string =>
  `${String(Math.floor(m / 60)).padStart(2, "0")}:${String(m % 60).padStart(2, "0")}`;
const fromHhmm = (v: string): number | null => {
  const m = /^(\d{1,2}):(\d{2})$/.exec(v);
  return m ? Number(m[1]) * 60 + Number(m[2]) : null;
};

/** The settings page of the dhikr reminders. */
export function DhikrRemindersView({ locale }: { locale: Locale }) {
  const prefs = useStore(dhikrReminderStore);
  const [denied, setDenied] = useState(false);
  const [listening, setListening] = useState<string | null>(null);
  const n = (v: number): string => localizeDigits(v, locale);
  const everyLabel = (m: number): string =>
    m === 60
      ? t(locale, "dhikrRem.hour")
      : m === 120
        ? t(locale, "dhikrRem.twoHours")
        : m % 60 === 0
          ? t(locale, "dhikrRem.hours", { n: n(m / 60) })
          : t(locale, "dhikrRem.minutes", { n: n(m) });
  const custom = !(DHIKR_INTERVALS as readonly number[]).includes(prefs.every);

  useEffect(() => () => stopClip(), []);

  const enable = async (on: boolean): Promise<void> => {
    setDenied(false);
    if (on && typeof Notification !== "undefined") {
      if (Notification.permission === "default") {
        try {
          if ((await Notification.requestPermission()) === "denied") setDenied(true);
        } catch {
          // older Safari: the in-page banner still works
        }
      } else if (Notification.permission === "denied") setDenied(true);
    }
    dhikrReminderStore.set((p) => ({ ...p, enabled: on }));
  };

  return (
    <div data-testid="dhikr-reminders">
      <section className="card">
        <label className="check">
          <input
            type="checkbox"
            checked={prefs.enabled}
            onChange={(e) => void enable(e.target.checked)}
            data-testid="dhikr-rem-on"
          />{" "}
          <strong>{t(locale, "dhikrRem.enable")}</strong>
        </label>
        <p className="muted small">{t(locale, "dhikrRem.webHint")}</p>
        {denied ? (
          <p className="alert" role="status">
            {t(locale, "dhikrRem.denied")}
          </p>
        ) : null}
        <label className="check">
          <input
            type="checkbox"
            checked={prefs.sound}
            onChange={(e) => dhikrReminderStore.set((p) => ({ ...p, sound: e.target.checked }))}
            data-testid="dhikr-rem-sound"
          />{" "}
          {t(locale, "dhikrRem.sound")}
        </label>
        {prefs.enabled && prefs.ids.length ? (
          <p className="muted small" data-testid="dhikr-rem-summary">
            {t(locale, "dhikrRem.summary", { count: n(dhikrSlots(prefs).length) })}
          </p>
        ) : null}
      </section>
      <section className="card">
        <h2 className="section-title">{t(locale, "dhikrRem.every")}</h2>
        <div className="row" role="group" style={{ flexWrap: "wrap", gap: "0.5rem" }}>
          {DHIKR_INTERVALS.map((m) => (
            <button
              key={m}
              type="button"
              className={`btn btn-sm${prefs.every === m ? " btn-primary" : ""}`}
              aria-pressed={prefs.every === m}
              data-testid={`dhikr-rem-every-${m}`}
              onClick={() => dhikrReminderStore.set((p) => ({ ...p, every: m }))}
            >
              {everyLabel(m)}
            </button>
          ))}
          <label className={`btn btn-sm${custom ? " btn-primary" : ""}`}>
            {t(locale, "dhikrRem.customShort")}{" "}
            <input
              type="number"
              min={5}
              max={720}
              value={prefs.every}
              aria-label={t(locale, "dhikrRem.customTitle")}
              style={{ width: "4.5rem" }}
              data-testid="dhikr-rem-every-custom"
              onChange={(e) => {
                const v = Number(e.target.value);
                if (Number.isFinite(v) && v > 0) dhikrReminderStore.set((p) => ({ ...p, every: v }));
              }}
            />
          </label>
        </div>
      </section>
      <section className="card">
        <div className="row" style={{ flexWrap: "wrap", gap: "0.75rem", alignItems: "center" }}>
          <label>
            <strong>{t(locale, "dhikrRem.from")}</strong>{" "}
            <input
              type="time"
              value={hhmm(prefs.from)}
              data-testid="dhikr-rem-from"
              onChange={(e) => {
                const v = fromHhmm(e.target.value);
                if (v !== null) dhikrReminderStore.set((p) => ({ ...p, from: v }));
              }}
            />
          </label>
          <label>
            <strong>{t(locale, "dhikrRem.to")}</strong>{" "}
            <input
              type="time"
              value={hhmm(prefs.to)}
              data-testid="dhikr-rem-to"
              onChange={(e) => {
                const v = fromHhmm(e.target.value);
                if (v !== null) dhikrReminderStore.set((p) => ({ ...p, to: v }));
              }}
            />
          </label>
        </div>
        <p className="muted small">{t(locale, "dhikrRem.windowHint")}</p>
      </section>
      <section className="card">
        <h2 className="section-title">
          {t(locale, "dhikrRem.pick")} <span className="muted small">{t(locale, "dhikrRem.pickHint")}</span>
        </h2>
        {prefs.ids.length === 0 ? <p className="error">{t(locale, "dhikrRem.pickOne")}</p> : null}
        <ul style={{ listStyle: "none", padding: 0, margin: 0 }}>
          {DHIKR_REMINDER_ITEMS.map((d) => {
            const on = prefs.ids.includes(d.id);
            return (
              <li key={d.id} className="row dhikr-rem-row" style={{ gap: "0.5rem", alignItems: "center" }}>
                <label className="check" style={{ flex: 1 }}>
                  <input
                    type="checkbox"
                    checked={on}
                    data-testid={`dhikr-rem-${d.id}`}
                    onChange={() =>
                      dhikrReminderStore.set((p) => ({
                        ...p,
                        ids: on ? p.ids.filter((x) => x !== d.id) : [...p.ids, d.id],
                      }))
                    }
                  />{" "}
                  <span className="dua">{TEXTS[d.index]}</span>
                </label>
                <button
                  type="button"
                  className="btn btn-sm"
                  aria-label={t(locale, "dhikrRem.listen")}
                  aria-pressed={listening === d.id}
                  data-testid={`dhikr-rem-listen-${d.id}`}
                  onClick={() => {
                    if (listening === d.id) {
                      stopClip();
                      setListening(null);
                    } else {
                      setListening(d.id);
                      playClip(d.id, () => setListening(null));
                    }
                  }}
                >
                  <Icon name={listening === d.id ? "stop" : "play"} />
                </button>
              </li>
            );
          })}
        </ul>
      </section>
    </div>
  );
}
