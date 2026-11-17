"use client";
import { useCallback, useEffect, useRef, useState } from "react";
import { t, type Locale } from "@/lib/i18n";
import { localizeDigits } from "@/lib/digits";
import {
  accuracyFromEvent,
  CALIBRATE_ABOVE_DEG,
  headingFromEvent,
  isFacing,
  needsPermission,
  turnAngle,
  type OrientationLike,
} from "@/lib/qibla";
import { magneticDeclination, decimalYear } from "@/lib/declination";
import { Compass } from "./Compass";

type Mode = "idle" | "waiting" | "live" | "unsupported" | "denied";
/** If no north-referenced reading arrives within this time, the static compass is shown. */
const SENSOR_TIMEOUT_MS = 3000;

type PermissionCtor = { requestPermission: () => Promise<"granted" | "denied"> };

/**
 * Qibla compass that follows the device heading (DeviceOrientation), with the static bearing as fallback.
 * Browsers report the heading from magnetic north; the Qibla bearing is from true north, so the local magnetic
 * declination (WMM2025, lib/declination.ts) is added before comparing them.
 */
export function LiveCompass({
  locale,
  bearing,
  lat,
  lng,
}: {
  locale: Locale;
  bearing: number;
  lat: number;
  lng: number;
}) {
  const [mode, setMode] = useState<Mode>("idle");
  const [heading, setHeading] = useState<number | null>(null);
  /** iOS: the compass error in degrees (-1 = uncalibrated); null where the browser does not tell. */
  const [accuracy, setAccuracy] = useState<number | null>(null);
  /** The browser said the compass needs calibrating (Chrome's "compassneedscalibration"). */
  const [needsCal, setNeedsCal] = useState(false);
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
      setAccuracy(accuracyFromEvent(e as unknown as OrientationLike));
      setMode("live");
    };
    const onCalibrate = (): void => setNeedsCal(true);
    window.addEventListener("deviceorientationabsolute", onEvent);
    window.addEventListener("deviceorientation", onEvent);
    window.addEventListener("compassneedscalibration", onCalibrate);
    timer.current = window.setTimeout(
      () => setMode((m) => (m === "waiting" ? "unsupported" : m)),
      SENSOR_TIMEOUT_MS,
    );
    cleanup.current = () => {
      window.removeEventListener("deviceorientationabsolute", onEvent);
      window.removeEventListener("deviceorientation", onEvent);
      window.removeEventListener("compassneedscalibration", onCalibrate);
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

  const declination = magneticDeclination(lat, lng, decimalYear(new Date()));
  const live = mode === "live" && heading !== null ? (((heading + declination) % 360) + 360) % 360 : null;
  const facing = isFacing(bearing, live);
  const deg = localizeDigits(bearing.toFixed(1), locale);
  const calibrate =
    live !== null && (needsCal || (accuracy !== null && (accuracy < 0 || accuracy > CALIBRATE_ABOVE_DEG)));
  /** As the app: "you are facing the Qibla", or which way and how far to turn. */
  const direction = (): string => {
    if (live === null || facing) return t(locale, "qibla.facing");
    const a = turnAngle(bearing, live);
    const n = localizeDigits(Math.round(Math.abs(a)), locale);
    return t(locale, a > 0 ? "qibla.turnRight" : "qibla.turnLeft", { deg: n });
  };
  return (
    <div
      className={facing ? "live-compass facing" : "live-compass"}
      data-testid="live-compass"
      data-mode={mode}
      data-declination={declination.toFixed(6)}
    >
      <Compass
        bearing={bearing}
        heading={live}
        label={t(locale, "prayer.compass", { deg })}
        cardinals={[
          t(locale, "compass.n"),
          t(locale, "compass.e"),
          t(locale, "compass.s"),
          t(locale, "compass.w"),
        ]}
      />
      <p className="compass-status" role="status" data-testid="compass-status">
        {mode === "live" ? direction() : null}
        {mode === "waiting" ? t(locale, "qibla.waiting") : null}
        {mode === "unsupported" ? t(locale, "qibla.fallback") : null}
        {mode === "denied" ? t(locale, "qibla.denied") : null}
      </p>
      {live !== null ? (
        <p className="muted small" data-testid="compass-heading">
          {t(locale, "qibla.heading", { deg: localizeDigits(Math.round(live), locale) })}{" "}
          <span data-testid="compass-declination">
            {t(locale, "qibla.declination", {
              deg: localizeDigits((declination >= 0 ? "+" : "") + declination.toFixed(1), locale),
            })}
          </span>
        </p>
      ) : null}
      {live !== null && accuracy !== null && accuracy >= 0 ? (
        <p className="muted small" data-testid="compass-accuracy">
          {t(locale, "qibla.accuracy", { n: localizeDigits(Math.round(accuracy), locale) })}
        </p>
      ) : null}
      {calibrate ? (
        <div className="alert alert-error qibla-calibrate" role="alert" data-testid="compass-calibrate">
          <strong>{t(locale, "qibla.calibrateTitle")}</strong>
          <p className="small">{t(locale, "qibla.calibrateBody")}</p>
        </div>
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
