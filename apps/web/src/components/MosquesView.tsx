"use client";
import { useCallback, useEffect, useState } from "react";
import { t, type Locale } from "@/lib/i18n";
import { localizeDigits } from "@/lib/digits";
import { resolveLocation } from "@/lib/cities";
import { prayerStore } from "@/lib/settings";
import { readJson, writeJson } from "@/lib/storage";
import { useStore } from "@/hooks/useStore";
import {
  DEFAULT_RADIUS_M,
  fetchMosques,
  googleMapsMosque,
  googleMapsNearby,
  RADII_M,
  type Mosque,
} from "@/lib/mosques";

type Status = "idle" | "loading" | "done" | "error";
interface Point {
  lat: number;
  lng: number;
}
interface Cached {
  key: string;
  at: number;
  items: Mosque[];
}
const CACHE_KEY = "rattil.mosques";
const KM = 1000;

const cacheKey = (p: Point, radius: number, locale: Locale): string =>
  `${p.lat.toFixed(3)},${p.lng.toFixed(3)},${radius},${locale}`;

function formatDistance(m: number, locale: Locale): string {
  return m < KM
    ? t(locale, "mosques.meters", { n: localizeDigits(Math.round(m), locale) })
    : t(locale, "mosques.km", { n: localizeDigits((m / KM).toFixed(1), locale) });
}

/** Nearby mosques from OpenStreetMap around the prayer location (or the device location on request). */
export function MosquesView({ locale }: { locale: Locale }) {
  const prefs = useStore(prayerStore);
  const loc = resolveLocation(prefs);
  const [here, setHere] = useState<Point | null>(null);
  const [radius, setRadius] = useState<number>(DEFAULT_RADIUS_M);
  const [status, setStatus] = useState<Status>("idle");
  const [items, setItems] = useState<Mosque[]>([]);
  const [stale, setStale] = useState(false);
  const [geoError, setGeoError] = useState(false);
  const point: Point = here ?? { lat: loc.lat, lng: loc.lng };

  const search = useCallback(
    async (p: Point, r: number): Promise<void> => {
      const key = cacheKey(p, r, locale);
      setStatus("loading");
      setStale(false);
      try {
        const list = await fetchMosques(p.lat, p.lng, r, locale);
        setItems(list);
        setStatus("done");
        writeJson(CACHE_KEY, { key, at: Date.now(), items: list } satisfies Cached);
      } catch {
        const cached = readJson<Cached | null>(CACHE_KEY, null);
        if (cached && cached.key === key && Array.isArray(cached.items)) {
          setItems(cached.items);
          setStale(true);
          setStatus("done");
        } else {
          setStatus("error");
        }
      }
    },
    [locale],
  );

  useEffect(() => {
    void search(point, radius);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [point.lat, point.lng, radius, search]);

  const locateMe = useCallback((): void => {
    setGeoError(false);
    if (typeof navigator === "undefined" || !navigator.geolocation) {
      setGeoError(true);
      return;
    }
    navigator.geolocation.getCurrentPosition(
      (pos) => setHere({ lat: pos.coords.latitude, lng: pos.coords.longitude }),
      () => setGeoError(true),
      // The nearest mosque needs a street-level fix, not the city.
      { enableHighAccuracy: true, timeout: 20000, maximumAge: 60000 },
    );
  }, []);

  // Already allowed before: search around the user straight away, no extra tap.
  useEffect(() => {
    if (typeof navigator === "undefined" || !navigator.permissions?.query) return;
    navigator.permissions
      .query({ name: "geolocation" })
      .then((s) => {
        if (s.state === "granted") locateMe();
      })
      .catch(() => undefined);
  }, [locateMe]);

  const placeName = here
    ? t(locale, "mosques.myLocation")
    : ((locale === "ar" ? loc.city?.nameAr : loc.city?.nameEn) ?? t(locale, "home.myPlace"));

  return (
    <section className="card" aria-labelledby="mosques-h" data-testid="mosques">
      <h2 id="mosques-h" className="card-title">
        {t(locale, "mosques.around", { place: placeName })}
      </h2>
      <div className="row">
        <label htmlFor="mosques-radius">{t(locale, "mosques.radius")}</label>
        <select
          id="mosques-radius"
          data-testid="mosques-radius"
          value={radius}
          onChange={(e) => setRadius(Number(e.target.value))}
        >
          {RADII_M.map((r) => (
            <option key={r} value={r}>
              {formatDistance(r, locale)}
            </option>
          ))}
        </select>
        <button type="button" className="btn" data-testid="mosques-here" onClick={locateMe}>
          {t(locale, "mosques.useMyLocation")}
        </button>
      </div>
      {geoError ? <p className="muted">{t(locale, "mosques.geoDenied")}</p> : null}
      <p role="status" data-testid="mosques-status" className="muted">
        {status === "loading" ? t(locale, "mosques.loading") : null}
        {status === "error" ? t(locale, "mosques.error") : null}
        {status === "done" && items.length === 0 ? t(locale, "mosques.none") : null}
        {status === "done" && items.length > 0
          ? t(locale, "mosques.count", { n: localizeDigits(items.length, locale) })
          : null}
        {stale ? ` ${t(locale, "mosques.offline")}` : null}
      </p>
      {status === "error" ? (
        <button
          type="button"
          className="btn"
          data-testid="mosques-retry"
          onClick={() => void search(point, radius)}
        >
          {t(locale, "mosques.retry")}
        </button>
      ) : null}
      <p>
        <a
          className="btn btn-sm"
          href={googleMapsNearby(point.lat, point.lng, locale === "ar")}
          target="_blank"
          rel="noopener noreferrer"
          data-testid="mosques-google"
        >
          {t(locale, "mosques.onGoogleMaps")}
        </a>
      </p>
      <ul className="mosque-list" data-testid="mosque-list">
        {items.map((m) => (
          <li key={m.id} data-testid="mosque">
            <a href={googleMapsMosque(m)} target="_blank" rel="noopener noreferrer">
              <strong>{m.name ?? t(locale, "mosques.unnamed")}</strong>
            </a>{" "}
            <span className="muted" data-testid="mosque-distance">
              {formatDistance(m.distance, locale)}
            </span>
          </li>
        ))}
      </ul>
      <p className="muted small">
        {t(locale, "mosques.note")}{" "}
        <a href="https://www.openstreetmap.org/copyright" target="_blank" rel="noopener noreferrer">
          © OpenStreetMap contributors
        </a>
      </p>
    </section>
  );
}
