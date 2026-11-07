"use client";
import { useCallback, useEffect, useRef, useState } from "react";
import { t, type Locale } from "@/lib/i18n";
import { localizeDigits } from "@/lib/digits";
import { headingFromEvent, isFacing, needsPermission, type OrientationLike } from "@/lib/qibla";
import { Compass } from "./Compass";

type Mode = "idle" | "waiting" | "live" | "unsupported" | "denied";
/** If no north-referenced reading arrives within this time, the static compass is shown. */
const SENSOR_TIMEOUT_MS = 3000;

type PermissionCtor = { requestPermission: () => Promise<"granted" | "denied"> };

/** Qibla compass that follows the device heading (DeviceOrientation), with the static bearing as fallback. */
export function LiveCompass({ locale, bearing }: { locale: Locale; bearing: number }) {
  const [mode, setMode] = useState<Mode>("idle");
  const [heading, setHeading] = useState<number | null>(null);
  const timer = useRef<number | null>(null);
  const cleanup = useRef<(() => void) | null>(null);

  const listen = useCallback(() => {
    cleanup.current?.();
    setMode("waiting");
    const onEvent = (e: Event): void => {
      const angle = typeof screen !== "undefined" ? (screen.orientation?.angle ?? 0) : 0;
      const h = headingFromEvent(e as unknown as OrientationLike, angle);
      if (h === null) return;
      if (timer.current !== null) window.clearTimeout(timer.current);
      timer.current = null;
      setHeading(h);
      setMode("live");
    };
    window.addEventListener("deviceorientationabsolute", onEvent);
    window.addEventListener("deviceorientation", onEvent);
    timer.current = window.setTimeout(
      () => setMode((m) => (m === "waiting" ? "unsupported" : m)),
      SENSOR_TIMEOUT_MS,
    );
    cleanup.current = () => {
      window.removeEventListener("deviceorientationabsolute", onEvent);
      window.removeEventListener("deviceorientation", onEvent);
      if (timer.current !== null) window.clearTimeout(timer.current);
    };
  }, []);

  const [permissionNeeded, setPermissionNeeded] = useState(false);

  useEffect(() => {
    if (typeof window === "undefined" || !("DeviceOrientationEvent" in window)) {
      setMode("unsupported");
      return;
    }
    setPermissionNeeded(needsPermission(window.DeviceOrientationEvent));
    // Listen right away: Android/desktop deliver events without a prompt. On iOS nothing arrives until the
    // permission is granted through the "Enable compass" button (a user gesture is required there).
    listen();
    return () => cleanup.current?.();
  }, [listen]);

  const enable = async (): Promise<void> => {
    try {
      const res = await (window.DeviceOrientationEvent as unknown as PermissionCtor).requestPermission();
      if (res === "granted") listen();
      else setMode("denied");
    } catch {
      setMode("denied");
    }
  };

  const live = mode === "live" ? heading : null;
  const facing = isFacing(bearing, live);
  const deg = localizeDigits(bearing.toFixed(1), locale);
  return (
    <div
      className={facing ? "live-compass facing" : "live-compass"}
      data-testid="live-compass"
      data-mode={mode}
    >
      <Compass bearing={bearing} heading={live} label={t(locale, "prayer.compass", { deg })} />
      <p className="compass-status" role="status" data-testid="compass-status">
        {mode === "live" ? t(locale, facing ? "qibla.facing" : "qibla.turn") : null}
        {mode === "waiting" ? t(locale, "qibla.waiting") : null}
        {mode === "unsupported" ? t(locale, "qibla.fallback") : null}
        {mode === "denied" ? t(locale, "qibla.denied") : null}
      </p>
      {live !== null ? (
        <p className="muted small" data-testid="compass-heading">
          {t(locale, "qibla.heading", { deg: localizeDigits(Math.round(live), locale) })}
        </p>
      ) : null}
      {permissionNeeded && mode !== "live" ? (
        <button
          type="button"
          className="btn btn-primary"
          data-testid="compass-enable"
          onClick={() => void enable()}
        >
          {t(locale, "qibla.enable")}
        </button>
      ) : null}
    </div>
  );
}
