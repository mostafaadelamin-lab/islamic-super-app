"use client";
import { useEffect, useState, useSyncExternalStore } from "react";
import { t, type Locale } from "@/lib/i18n";
import { resolveLocation } from "@/lib/cities";
import { prayerStore } from "@/lib/settings";
import { ADHAN_AUDIO_PATH, adhanFor, adhanStore, nextAdhanAlert } from "@/lib/adhan-alerts";
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

async function showNotification(title: string, body: string): Promise<void> {
  if (typeof Notification === "undefined" || Notification.permission !== "granted") return;
  const opts: NotificationOptions = { body, icon: withBase("/icon-192.png"), tag: "adhan" };
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
  const [ringing, setRinging] = useState<{ key: PrayerKey; blocked: boolean } | null>(null);

  useEffect(() => {
    if (!prefs.enabled) return;
    const loc = resolveLocation(prayer);
    const q = { ...loc, asr: prayer.asr, adjustments: prayer.adjustments };
    let target = nextAdhanAlert(new Date(), q, prefs);
    // A coarse ticker instead of one long timeout: timers are throttled or
    // paused while the computer sleeps, and this catches up on wake.
    const tick = (): void => {
      if (!target) return;
      const now = Date.now();
      if (now < target.at.getTime()) return;
      const late = now - target.at.getTime() > 5 * 60_000; // missed while asleep
      const fired = target;
      target = nextAdhanAlert(new Date(now + 1000), q, prefs);
      if (late) return;
      const name = t(locale, `prayer.${fired.key}`);
      void showNotification(t(locale, "adhan.title", { name }), t(locale, "adhan.webBody", { name }));
      if (prefs.sound) {
        void playAdhan().then((ok) => setRinging({ key: fired.key, blocked: !ok }));
      } else {
        setRinging({ key: fired.key, blocked: false });
      }
    };
    const id = setInterval(tick, 5000);
    return () => clearInterval(id);
  }, [prefs, prayer, locale]);

  if (!ringing) return null;
  const name = t(locale, `prayer.${ringing.key}`);
  return (
    <div className="adhan-ringing" role="alert" data-testid="adhan-ringing">
      <strong>{t(locale, "adhan.title", { name })}</strong>
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
