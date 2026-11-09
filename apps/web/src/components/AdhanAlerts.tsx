"use client";
import { useEffect, useState, useSyncExternalStore } from "react";
import { t, type Locale } from "@/lib/i18n";
import { resolveLocation } from "@/lib/cities";
import { prayerStore } from "@/lib/settings";
import {
  ADHAN_AUDIO_PATH,
  adhanFor,
  adhanStore,
  clampIqama,
  IQAMA_MAX,
  IQAMA_MIN,
  nextAlert,
  PRE_CHOICES,
  type AlertKind,
} from "@/lib/adhan-alerts";
import { localizeDigits } from "@/lib/digits";
import { OBLIGATORY } from "@/lib/next-prayer";
import { withBase } from "@/lib/base-path";
import { useStore } from "@/hooks/useStore";
import type { PrayerKey } from "@/lib/prayer";

// --- One shared <audio> for the alert and the "listen" button -----------------
let audio: HTMLAudioElement | null = null;
let playing = false;
const listeners = new Set<() => void>();
const emit = (): void => listeners.forEach((l) => l());

function audioEl(): HTMLAudioElement {
  if (!audio) {
    audio = new Audio(withBase(ADHAN_AUDIO_PATH));
    audio.preload = "none";
    audio.addEventListener("ended", () => {
      playing = false;
      emit();
    });
  }
  return audio;
}

/** Starts the adhan; resolves false when the browser blocks autoplay. */
export async function playAdhan(): Promise<boolean> {
  const a = audioEl();
  a.currentTime = 0;
  playing = true;
  emit();
  try {
    await a.play();
    return true;
  } catch {
    playing = false;
    emit();
    return false;
  }
}

export function stopAdhan(): void {
  if (audio) {
    audio.pause();
    audio.currentTime = 0;
  }
  playing = false;
  emit();
}

export function useAdhanPlaying(): boolean {
  return useSyncExternalStore(
    (l) => {
      listeners.add(l);
      return () => listeners.delete(l);
    },
    () => playing,
    () => false,
  );
}

const TONE_HZ = [880, 660] as const;
const TONE_STEP_S = 0.35;
const TONE_GAIN = 0.15;

/** A short two-note chime (no recording) for the reminders before the adhan and at the iqama. */
export function playTone(): void {
  try {
    const Ctx =
      window.AudioContext ??
      (window as unknown as { webkitAudioContext?: typeof AudioContext }).webkitAudioContext;
    if (!Ctx) return;
    const ctx = new Ctx();
    TONE_HZ.forEach((hz, i) => {
      const o = ctx.createOscillator();
      const g = ctx.createGain();
      o.frequency.value = hz;
      g.gain.value = TONE_GAIN;
      o.connect(g).connect(ctx.destination);
      o.start(ctx.currentTime + i * TONE_STEP_S);
      o.stop(ctx.currentTime + (i + 1) * TONE_STEP_S);
    });
  } catch {
    // audio unavailable: the notification and banner still show
  }
}

async function showNotification(title: string, body: string, tag = "adhan"): Promise<void> {
  if (typeof Notification === "undefined" || Notification.permission !== "granted") return;
  const opts: NotificationOptions = { body, icon: withBase("/icon-192.png"), tag };
  try {
    const reg = await navigator.serviceWorker?.getRegistration();
    if (reg) {
      await reg.showNotification(title, opts);
      return;
    }
  } catch {
    // fall back to a page notification
  }
  try {
    new Notification(title, opts);
  } catch {
    // Some mobile browsers only allow service-worker notifications.
  }
}

/**
 * Mounted once per page: while the site is open, fires the adhan alert at the
 * next enabled prayer (notification + recording + an in-page banner).
 */
export function AdhanAlerts({ locale }: { locale: Locale }) {
  const prefs = useStore(adhanStore);
  const prayer = useStore(prayerStore);
  const isPlaying = useAdhanPlaying();
  const [ringing, setRinging] = useState<{ key: PrayerKey; kind: AlertKind; blocked: boolean } | null>(null);

  useEffect(() => {
    if (!prefs.enabled) return;
    const loc = resolveLocation(prayer);
    const q = { ...loc, asr: prayer.asr, adjustments: prayer.adjustments };
    let target = nextAlert(new Date(), q, prefs);
    // A coarse ticker instead of one long timeout: timers are throttled or
    // paused while the computer sleeps, and this catches up on wake.
    const tick = (): void => {
      if (!target) return;
      const now = Date.now();
      if (now < target.at.getTime()) return;
      const late = now - target.at.getTime() > 5 * 60_000; // missed while asleep
      const fired = target;
      target = nextAlert(new Date(now + 1000), q, prefs);
      if (late) return;
      const name = t(locale, `prayer.${fired.key}`);
      if (fired.kind !== "adhan") {
        const n = fired.kind === "pre" ? prefs.preMinutes : (prefs.iqama[fired.key] ?? 0);
        const vars = { name, n: localizeDigits(n, locale) };
        void showNotification(
          t(locale, `adhan.${fired.kind}Title`, vars),
          t(locale, `adhan.${fired.kind}Body`, vars),
          fired.kind,
        );
        if (prefs.sound) playTone();
        setRinging({ key: fired.key, kind: fired.kind, blocked: false });
        return;
      }
      void showNotification(t(locale, "adhan.title", { name }), t(locale, "adhan.webBody", { name }));
      if (prefs.sound) {
        void playAdhan().then((ok) => setRinging({ key: fired.key, kind: "adhan", blocked: !ok }));
      } else {
        setRinging({ key: fired.key, kind: "adhan", blocked: false });
      }
    };
    const id = setInterval(tick, 5000);
    return () => clearInterval(id);
  }, [prefs, prayer, locale]);

  if (!ringing) return null;
  const name = t(locale, `prayer.${ringing.key}`);
  const n = ringing.kind === "pre" ? prefs.preMinutes : (prefs.iqama[ringing.key] ?? 0);
  const titleKey = ringing.kind === "adhan" ? "adhan.title" : `adhan.${ringing.kind}Title`;
  return (
    <div className="adhan-ringing" role="alert" data-testid="adhan-ringing" data-kind={ringing.kind}>
      <strong>{t(locale, titleKey, { name, n: localizeDigits(n, locale) })}</strong>
      {ringing.blocked && !isPlaying ? (
        <button type="button" className="btn btn-primary" onClick={() => void playAdhan()}>
          {t(locale, "adhan.playNow")}
        </button>
      ) : null}
      <button
        type="button"
        className="btn"
        onClick={() => {
          stopAdhan();
          setRinging(null);
        }}
      >
        {isPlaying ? t(locale, "adhan.stop") : t(locale, "adhan.dismiss")}
      </button>
    </div>
  );
}

/** Adhan alert settings on the prayer page. */
export function AdhanSettings({ locale }: { locale: Locale }) {
  const prefs = useStore(adhanStore);
  const isPlaying = useAdhanPlaying();
  const [denied, setDenied] = useState(false);
  const name = (k: PrayerKey): string => t(locale, `prayer.${k}`);

  const enable = async (on: boolean): Promise<void> => {
    setDenied(false);
    if (on && typeof Notification !== "undefined" && Notification.permission === "default") {
      try {
        const res = await Notification.requestPermission();
        if (res === "denied") setDenied(true);
      } catch {
        // older Safari: callback form only; the in-page alert still works
      }
    } else if (on && typeof Notification !== "undefined" && Notification.permission === "denied") {
      setDenied(true);
    }
    adhanStore.set((p) => ({ ...p, enabled: on }));
  };

  return (
    <section className="card" aria-labelledby="adhan-h" data-testid="adhan-settings">
      <h2 id="adhan-h" style={{ marginTop: 0 }}>
        {t(locale, "adhan.settings")}
      </h2>
      <label className="check">
        <input
          type="checkbox"
          checked={prefs.enabled}
          onChange={(e) => void enable(e.target.checked)}
          data-testid="adhan-enable"
        />{" "}
        {t(locale, "adhan.enable")}
      </label>
      {denied ? (
        <p className="alert" role="status" data-testid="adhan-denied">
          {t(locale, "adhan.webDenied")}
        </p>
      ) : null}
      {prefs.enabled ? (
        <>
          <fieldset className="adhan-prayers">
            <legend className="muted">{t(locale, "adhan.prayers")}</legend>
            {OBLIGATORY.map((k) => (
              <label className="check" key={k}>
                <input
                  type="checkbox"
                  checked={adhanFor(prefs, k)}
                  onChange={(e) =>
                    adhanStore.set((p) => ({ ...p, prayers: { ...p.prayers, [k]: e.target.checked } }))
                  }
                  data-testid={`adhan-${k}`}
                />{" "}
                {name(k)}
              </label>
            ))}
          </fieldset>
          <label className="check">
            <input
              type="checkbox"
              checked={prefs.sound}
              onChange={(e) => adhanStore.set((p) => ({ ...p, sound: e.target.checked }))}
              data-testid="adhan-sound"
            />{" "}
            {t(locale, "adhan.webSound")}
          </label>
          <div className="field">
            <label htmlFor="adhan-pre">{t(locale, "adhan.pre")}</label>
            <select
              id="adhan-pre"
              value={prefs.preMinutes}
              onChange={(e) => adhanStore.set((p) => ({ ...p, preMinutes: Number(e.target.value) }))}
              data-testid="adhan-pre"
            >
              {PRE_CHOICES.map((m) => (
                <option key={m} value={m}>
                  {m === 0
                    ? t(locale, "adhan.off")
                    : t(locale, "adhan.minutes", { n: localizeDigits(m, locale) })}
                </option>
              ))}
            </select>
          </div>
          <label className="check">
            <input
              type="checkbox"
              checked={prefs.iqamaEnabled}
              onChange={(e) => adhanStore.set((p) => ({ ...p, iqamaEnabled: e.target.checked }))}
              data-testid="adhan-iqama"
            />{" "}
            {t(locale, "adhan.iqama")}
          </label>
          {prefs.iqamaEnabled ? (
            <div className="adjust-grid" data-testid="iqama-grid">
              {OBLIGATORY.map((k) => (
                <div className="adjust" key={k}>
                  <label htmlFor={`iqama-${k}`}>{name(k)}</label>
                  <input
                    id={`iqama-${k}`}
                    type="number"
                    inputMode="numeric"
                    min={IQAMA_MIN}
                    max={IQAMA_MAX}
                    value={prefs.iqama[k] ?? IQAMA_MIN}
                    onChange={(e) =>
                      adhanStore.set((p) => ({
                        ...p,
                        iqama: { ...p.iqama, [k]: clampIqama(e.target.value) },
                      }))
                    }
                  />
                  <span className="muted">{t(locale, "adhan.minAfter")}</span>
                </div>
              ))}
            </div>
          ) : null}
        </>
      ) : null}
      <p>
        <button
          type="button"
          className="btn"
          data-testid="adhan-listen"
          onClick={() => (isPlaying ? stopAdhan() : void playAdhan())}
        >
          {isPlaying ? t(locale, "adhan.stop") : t(locale, "adhan.listen")}
        </button>
      </p>
      <p className="muted">{t(locale, "adhan.webNote")}</p>
      <p className="muted" style={{ fontSize: "0.85em" }}>
        {t(locale, "adhan.credit")}
      </p>
    </section>
  );
}
