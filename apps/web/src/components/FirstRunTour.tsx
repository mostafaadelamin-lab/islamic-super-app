"use client";
import { useEffect, useRef, useState } from "react";
import { t, type Locale } from "@/lib/i18n";
import { firstRunStore, replayTour, TOUR_SLIDES } from "@/lib/first-run";
import { prayerStore } from "@/lib/settings";
import { adhanStore } from "@/lib/adhan-alerts";
import { localizeDigits } from "@/lib/digits";
import { useStore } from "@/hooks/useStore";
import { geoErrorKey } from "./PrayerView";
import { Icon } from "./Icon";

/** Position rounding (4 decimals, ~11 m) and the geolocation request limits, as on the prayer page. */
const COORD_SCALE = 10_000;
const GEO_TIMEOUT_MS = 15_000;
const GEO_MAX_AGE_MS = 600_000;

type GeoState = { kind: "idle" } | { kind: "locating" } | { kind: "error"; key: string };

/**
 * Turns the adhan alerts on, asking the browser for notifications first. Must run from the visitor's own
 * click (Safari and Firefox require that). Resolves true when the visitor refused notifications.
 */
async function enableAdhanAlerts(): Promise<boolean> {
  let denied = false;
  if (typeof Notification !== "undefined") {
    let perm = Notification.permission;
    if (perm === "default") {
      try {
        perm = await Notification.requestPermission();
      } catch {
        // older Safari: the in-page alert still works
      }
    }
    denied = perm === "denied";
  }
  adhanStore.set((p) => ({ ...p, enabled: true }));
  return denied;
}

/**
 * What the site can ask for, each with why: location (prayer times and qibla) and notifications (adhan
 * alerts). Shown at the end of the first-visit tour and in the settings (owner 2026-11-24), so a visitor
 * who skipped it can allow them later. [autoAsk] starts both requests once, from the visitor's own click.
 */
export function SetupSteps({ locale, autoAsk = 0 }: { locale: Locale; autoAsk?: number }) {
  const prayer = useStore(prayerStore);
  const adhan = useStore(adhanStore);
  const [geo, setGeo] = useState<GeoState>({ kind: "idle" });
  const [notifDenied, setNotifDenied] = useState(false);

  const locate = (): void => {
    if (typeof navigator === "undefined" || !navigator.geolocation) {
      setGeo({ kind: "error", key: "prayer.geoUnavailable" });
      return;
    }
    setGeo({ kind: "locating" });
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        const tz = Intl.DateTimeFormat().resolvedOptions().timeZone || "UTC";
        prayerStore.set((p) => ({
          ...p,
          custom: {
            lat: Math.round(pos.coords.latitude * COORD_SCALE) / COORD_SCALE,
            lng: Math.round(pos.coords.longitude * COORD_SCALE) / COORD_SCALE,
            tz,
          },
        }));
        setGeo({ kind: "idle" });
      },
      (err) => setGeo({ kind: "error", key: geoErrorKey(err?.code) }),
      { enableHighAccuracy: false, timeout: GEO_TIMEOUT_MS, maximumAge: GEO_MAX_AGE_MS },
    );
  };

  const enableAdhan = async (): Promise<void> => {
    setNotifDenied(false);
    setNotifDenied(await enableAdhanAlerts());
  };

  // The location needs no click of its own: asked as soon as the tour reaches this step.
  useEffect(() => {
    if (autoAsk && !prayerStore.get().custom) locate();
  }, [autoAsk]);

  return (
    <>
      <div className="tour-step">
        <h3>
          <Icon name="location" /> {t(locale, "setup.locationTitle")}
          {prayer.custom && (
            <span className="tour-done" data-testid="tour-location-done">
              <Icon name="checkCircle" /> {t(locale, "setup.done")}
            </span>
          )}
        </h3>
        <p>{t(locale, "setup.webLocationBody")}</p>
        <button
          type="button"
          className="btn"
          data-testid="tour-locate"
          disabled={geo.kind === "locating"}
          onClick={locate}
        >
          <Icon name="myLocation" /> {t(locale, "setup.locationUse")}
        </button>
        {geo.kind === "error" && (
          <p className="muted" role="status">
            {t(locale, geo.key)} {t(locale, "setup.webLocationCity")}
          </p>
        )}
      </div>
      <div className="tour-step">
        <h3>
          <Icon name="bell" /> {t(locale, "setup.notifTitle")}
          {adhan.enabled && !notifDenied && (
            <span className="tour-done" data-testid="tour-adhan-done">
              <Icon name="checkCircle" /> {t(locale, "setup.done")}
            </span>
          )}
        </h3>
        <p>{t(locale, "setup.webNotifBody")}</p>
        {!adhan.enabled && (
          <button type="button" className="btn" data-testid="tour-adhan" onClick={() => void enableAdhan()}>
            <Icon name="bell" /> {t(locale, "setup.notifAction")}
          </button>
        )}
        {notifDenied && (
          <p className="muted" role="status">
            {t(locale, "adhan.webDenied")}
          </p>
        )}
        <p className="muted">{t(locale, "setup.webSilent")}</p>
      </div>
    </>
  );
}

/**
 * First visit (owner 2026-11-14, same as the apps): a short tour of the main features, then the
 * setup of what the site can ask for: location (prayer times) and notifications (adhan alerts).
 * Browsers cannot ring with every page closed or override the phone's silent mode, so the last
 * step says so honestly and points to the phone app. Shown once; Settings can show it again.
 */
export function FirstRunTour({ locale }: { locale: Locale }) {
  const state = useStore(firstRunStore);
  // Rendered only after hydration: the server does not know whether this visitor has seen it.
  const [mounted, setMounted] = useState(false);
  const [index, setIndex] = useState(0);
  // Bumped by Next / Skip into the setup step: SetupSteps then asks for both permissions (see goToSetup).
  const [ask, setAsk] = useState(0);
  const dialog = useRef<HTMLDivElement>(null);

  useEffect(() => setMounted(true), []);
  const open = mounted && !state.done;

  useEffect(() => {
    if (!open) return;
    setIndex(0);
    const onKey = (e: KeyboardEvent): void => {
      if (e.key === "Escape") firstRunStore.set({ done: true });
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [open]);

  useEffect(() => {
    if (open) dialog.current?.querySelector<HTMLElement>("[data-autofocus]")?.focus();
  }, [open, index]);

  if (!open) return null;

  const count = TOUR_SLIDES.length + 1;
  const last = index === count - 1;
  const finish = (): void => firstRunStore.set({ done: true });
  const n = (v: number): string => localizeDigits(String(v), locale);

  /**
   * Owner (2026-11-14): on first open the site asks for the location and to turn on the adhan alerts
   * right away. Called from the Next / Skip click, so the browser sees the notification request as
   * the visitor's own action (Safari and Firefox require that); the location is asked by SetupSteps.
   */
  const goToSetup = (): void => {
    setIndex(count - 1);
    setAsk((a) => a + 1);
    if (!adhanStore.get().enabled) void enableAdhanAlerts();
  };

  const slide = TOUR_SLIDES[index];
  return (
    <div className="tour-backdrop" data-testid="first-run">
      <div
        ref={dialog}
        className="tour card"
        role="dialog"
        aria-modal="true"
        aria-labelledby="tour-h"
        aria-describedby="tour-step"
      >
        <div className="tour-top">
          <span id="tour-step" className="muted">
            {t(locale, "tour.page", { n: n(index + 1), total: n(count) })}
          </span>
          {!last && (
            <button type="button" className="btn-link" data-testid="tour-skip" onClick={goToSetup}>
              {t(locale, "tour.skip")}
            </button>
          )}
        </div>
        {slide ? (
          <div className="tour-slide" data-testid={`tour-slide-${slide.key}`}>
            <span className="tour-icon" aria-hidden="true">
              <Icon name={slide.icon} size={56} />
            </span>
            <h2 id="tour-h">{t(locale, `tour.${slide.key}Title`)}</h2>
            <p>{t(locale, `tour.${slide.key}Body`)}</p>
          </div>
        ) : (
          <div className="tour-setup" data-testid="tour-setup">
            <h2 id="tour-h">{t(locale, "setup.title")}</h2>
            <p className="muted">{t(locale, "setup.webIntro")}</p>
            <SetupSteps locale={locale} autoAsk={ask} />
          </div>
        )}
        <div className="tour-nav">
          <span>
            {index > 0 && (
              <button
                type="button"
                className="btn"
                data-testid="tour-back"
                onClick={() => setIndex(index - 1)}
              >
                {t(locale, "tour.back")}
              </button>
            )}
          </span>
          <span className="tour-dots" aria-hidden="true">
            {Array.from({ length: count }, (_, i) => (
              <span key={i} className={i === index ? "on" : undefined} />
            ))}
          </span>
          {last ? (
            <button
              type="button"
              className="btn btn-primary"
              data-testid="tour-start"
              data-autofocus
              onClick={finish}
            >
              {t(locale, "setup.start")}
            </button>
          ) : (
            <button
              type="button"
              className="btn btn-primary"
              data-testid="tour-next"
              data-autofocus
              onClick={() => (index + 1 === count - 1 ? goToSetup() : setIndex(index + 1))}
            >
              {t(locale, "tour.next")}
            </button>
          )}
        </div>
      </div>
    </div>
  );
}

/** Settings: shows the tour again. */
export function TourReplayButton({ locale }: { locale: Locale }) {
  return (
    <section className="card" aria-labelledby="tour-replay-h">
      <h2 id="tour-replay-h" style={{ marginTop: 0 }}>
        {t(locale, "settings.tour")}
      </h2>
      <p className="muted">{t(locale, "settings.tourHint")}</p>
      <button
        type="button"
        className="btn"
        data-testid="tour-replay"
        onClick={() => {
          replayTour();
          window.scrollTo({ top: 0 });
        }}
      >
        <Icon name="info" /> {t(locale, "settings.tour")}
      </button>
    </section>
  );
}
