"use client";
import { useMemo, useState } from "react";
import { t, type Locale } from "@/lib/i18n";
import { localizeDigits } from "@/lib/digits";
import { CITIES, resolveLocation } from "@/lib/cities";
import { nextPrayer } from "@/lib/next-prayer";
import {
  ADJUST_MAX,
  ADJUST_MIN,
  clampAdjustment,
  methodsConfig,
  METHOD_IDS,
  PRAYER_KEYS,
  prayerTimes,
  qiblaBearing,
  type PrayerDay,
  type PrayerKey,
} from "@/lib/prayer";
import { formatCountdown, formatHHMM, isoDate, localDateInTz } from "@/lib/time";
import { prayerStore } from "@/lib/settings";
import { useStore } from "@/hooks/useStore";
import { useNow } from "@/hooks/useNow";
import { Compass } from "./Compass";

type GeoState = { kind: "idle" } | { kind: "locating" } | { kind: "error"; key: string };

export function geoErrorKey(code: number | undefined): string {
  if (code === 1) return "prayer.geoDenied";
  if (code === 3) return "prayer.geoTimeout";
  return "prayer.geoUnavailable";
}

export function PrayerView({ locale }: { locale: Locale }) {
  const prefs = useStore(prayerStore);
  const now = useNow();
  const [geo, setGeo] = useState<GeoState>({ kind: "idle" });
  const loc = resolveLocation(prefs);
  const dateKey = now ? isoDate(localDateInTz(now, loc.tz)) : null;
  const name = (k: PrayerKey): string => t(locale, `prayer.${k}`);
  const methodName = (id: string): string => {
    const m = methodsConfig.methods[id];
    return m ? (locale === "ar" ? m.nameAr : m.nameEn) : id;
  };

  const computed = useMemo((): { day: PrayerDay } | { error: string } | null => {
    if (!dateKey) return null;
    const [y, m, d] = dateKey.split("-").map(Number) as [number, number, number];
    try {
      return {
        day: prayerTimes(
          { year: y, month: m, day: d },
          loc.lat,
          loc.lng,
          loc.method,
          prefs.asr,
          prefs.adjustments,
        ),
      };
    } catch (e) {
      return { error: e instanceof Error ? e.message : String(e) };
    }
  }, [dateKey, loc.lat, loc.lng, loc.method, prefs.asr, prefs.adjustments]);

  let next: { key: PrayerKey; at: Date } | null = null;
  if (now && computed && "day" in computed) {
    try {
      next = nextPrayer(now, { ...loc, asr: prefs.asr, adjustments: prefs.adjustments });
    } catch {
      next = null;
    }
  }
  const bearing = qiblaBearing(loc.lat, loc.lng);
  const bearingText = localizeDigits(bearing.toFixed(1), locale);

  const locateMe = (): void => {
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
            lat: Math.round(pos.coords.latitude * 10000) / 10000,
            lng: Math.round(pos.coords.longitude * 10000) / 10000,
            tz,
          },
        }));
        setGeo({ kind: "idle" });
      },
      (err) => setGeo({ kind: "error", key: geoErrorKey(err?.code) }),
      { enableHighAccuracy: false, timeout: 15000, maximumAge: 600000 },
    );
  };

  const setAdjust = (k: PrayerKey, v: number): void => {
    prayerStore.set((p) => ({ ...p, adjustments: { ...p.adjustments, [k]: clampAdjustment(v) } }));
  };

  const cityValue = prefs.custom ? "__custom" : (loc.city?.id ?? "");

  return (
    <>
      <div className="two-col">
        <section className="card" aria-labelledby="loc-h">
          <h2 id="loc-h" style={{ marginTop: 0 }}>
            {t(locale, "prayer.location")}
          </h2>
          <div className="field">
            <label htmlFor="city">{t(locale, "prayer.city")}</label>
            <select
              id="city"
              value={cityValue}
              onChange={(e) => {
                const id = e.target.value;
                if (id === "__custom") return;
                prayerStore.set((p) => ({ ...p, cityId: id, custom: null, method: null }));
              }}
            >
              {prefs.custom ? (
                <option value="__custom">
                  {t(locale, "prayer.myLocation", {
                    lat: localizeDigits(prefs.custom.lat.toFixed(2), locale),
                    lng: localizeDigits(prefs.custom.lng.toFixed(2), locale),
                  })}
                </option>
              ) : null}
              {CITIES.map((c) => (
                <option key={c.id} value={c.id}>
                  {locale === "ar" ? `${c.nameAr} — ${c.countryAr}` : c.nameEn}
                </option>
              ))}
            </select>
          </div>
          <button type="button" className="btn" onClick={locateMe} disabled={geo.kind === "locating"}>
            {geo.kind === "locating" ? t(locale, "prayer.locating") : t(locale, "prayer.useLocation")}
          </button>
          {geo.kind === "error" ? (
            <p className="alert alert-error" role="alert" data-testid="geo-error">
              {t(locale, geo.key)}
            </p>
          ) : null}
          <p className="muted">{t(locale, "prayer.tz", { tz: loc.tz })}</p>
        </section>

        <section className="card" aria-labelledby="calc-h">
          <h2 id="calc-h" style={{ marginTop: 0 }}>
            {t(locale, "prayer.settings")}
          </h2>
          <div className="field">
            <label htmlFor="method">{t(locale, "prayer.method")}</label>
            <select
              id="method"
              value={prefs.method ?? ""}
              onChange={(e) => prayerStore.set((p) => ({ ...p, method: e.target.value || null }))}
            >
              <option value="">
                {t(locale, "prayer.methodDefault", { name: methodName(loc.defaultMethod) })}
              </option>
              {METHOD_IDS.map((id) => (
                <option key={id} value={id}>
                  {methodName(id)}
                </option>
              ))}
            </select>
          </div>
          <div className="field">
            <label htmlFor="asr">{t(locale, "prayer.asrMethod")}</label>
            <select
              id="asr"
              value={prefs.asr}
              onChange={(e) =>
                prayerStore.set((p) => ({ ...p, asr: e.target.value === "hanafi" ? "hanafi" : "standard" }))
              }
            >
              <option value="standard">{t(locale, "prayer.asrStandard")}</option>
              <option value="hanafi">{t(locale, "prayer.asrHanafi")}</option>
            </select>
          </div>
        </section>
      </div>

      <section className="card" aria-labelledby="times-h">
        <h2 id="times-h" style={{ marginTop: 0 }}>
          {t(locale, "prayer.timesTable")}
          {dateKey ? <span className="muted"> — {localizeDigits(dateKey, locale)}</span> : null}
        </h2>
        {!computed ? <p className="muted">{t(locale, "prayer.loading")}</p> : null}
        {computed && "error" in computed ? (
          <p className="alert alert-error" role="alert">
            {t(locale, "prayer.error", { msg: computed.error })}
          </p>
        ) : null}
        {computed && "day" in computed ? (
          <>
            {next && now ? (
              <div data-testid="next-prayer">
                <p style={{ margin: 0 }}>{t(locale, "prayer.next", { name: name(next.key) })}</p>
                <p className="countdown" data-testid="countdown">
                  {localizeDigits(formatCountdown(next.at.getTime() - now.getTime()), locale)}
                </p>
              </div>
            ) : null}
            <table className="times" data-testid="times">
              <thead>
                <tr>
                  <th scope="col">{t(locale, "prayer.name")}</th>
                  <th scope="col">{t(locale, "prayer.time")}</th>
                </tr>
              </thead>
              <tbody>
                {PRAYER_KEYS.map((k) => {
                  const at = computed.day.times[k];
                  const isNext = next?.key === k && next.at.getTime() === at.getTime();
                  return (
                    <tr key={k} className={isNext ? "next" : undefined} data-prayer={k}>
                      <th scope="row">{name(k)}</th>
                      <td className="time">{localizeDigits(formatHHMM(at, loc.tz), locale)}</td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
            {computed.day.highLatitudeAdjusted.length > 0 ? (
              <p className="alert" data-testid="highlat-note">
                {t(locale, "prayer.highLatNote")}{" "}
                {t(locale, "prayer.highLat", {
                  list: computed.day.highLatitudeAdjusted.map(name).join(locale === "ar" ? "، " : ", "),
                })}
              </p>
            ) : null}
          </>
        ) : null}
      </section>

      <div className="two-col">
        <section className="card" aria-labelledby="adj-h">
          <h2 id="adj-h" style={{ marginTop: 0 }}>
            {t(locale, "prayer.adjust")}
          </h2>
          <div className="adjust-grid">
            {PRAYER_KEYS.map((k) => {
              const v = prefs.adjustments[k] ?? 0;
              return (
                <div className="adjust" key={k}>
                  <label htmlFor={`adj-${k}`}>{name(k)}</label>
                  <button
                    type="button"
                    className="btn"
                    aria-label={t(locale, "prayer.decrease", { name: name(k) })}
                    onClick={() => setAdjust(k, v - 1)}
                    disabled={v <= ADJUST_MIN}
                  >
                    −
                  </button>
                  <input
                    id={`adj-${k}`}
                    type="number"
                    inputMode="numeric"
                    min={ADJUST_MIN}
                    max={ADJUST_MAX}
                    step={1}
                    value={v}
                    onChange={(e) => setAdjust(k, Number(e.target.value))}
                  />
                  <button
                    type="button"
                    className="btn"
                    aria-label={t(locale, "prayer.increase", { name: name(k) })}
                    onClick={() => setAdjust(k, v + 1)}
                    disabled={v >= ADJUST_MAX}
                  >
                    +
                  </button>
                </div>
              );
            })}
          </div>
          <button
            type="button"
            className="btn"
            onClick={() => prayerStore.set((p) => ({ ...p, adjustments: {} }))}
            style={{ marginTop: "var(--space-md)" }}
          >
            {t(locale, "prayer.reset")}
          </button>
        </section>

        <section className="card" aria-labelledby="qibla-h">
          <h2 id="qibla-h" style={{ marginTop: 0 }}>
            {t(locale, "prayer.qibla")}
          </h2>
          <p className="countdown" data-testid="qibla-bearing">
            {t(locale, "prayer.qiblaDeg", { deg: bearingText })}
          </p>
          <Compass bearing={bearing} label={t(locale, "prayer.compass", { deg: bearingText })} />
          <p className="muted">{t(locale, "prayer.qiblaNote")}</p>
        </section>
      </div>
    </>
  );
}
