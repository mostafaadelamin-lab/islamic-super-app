/**
 * Area names for a GPS position (owner 2026-11-16: the website showed only «موقعي»; the app shows
 * "مصر - مدينتي"). Same rules as the app (apps/mobile/lib/data/place_names.dart): OpenStreetMap's
 * reverse geocoder (Nominatim) at district (zoom 14) and street (zoom 16) level, BigDataCloud's free
 * client geocoder if Nominatim cannot be reached. Saved per position and language.
 */
import { createStore } from "./store";
import { prayerStore } from "./settings";
import { distanceM } from "./mosques";

export interface PlaceName {
  country: string | null;
  area: string | null;
}
type Addr = Record<string, unknown>;

/** Names are looked up again when the position moved more than this. */
const SAME_PLACE_M = 1000;
const DISTRICT_ZOOM = 14;
const STREET_ZOOM = 16;
const COORD_DIGITS = 3; // ~100 m: the exact position never leaves the device (kids policy)

const DISTRICT = ["town", "suburb", "quarter", "city_district"];
const SMALL = ["village", "hamlet", "neighbourhood", "residential"];
const STREET = [
  "suburb",
  "town",
  "quarter",
  "city_district",
  "village",
  "hamlet",
  "city",
  "municipality",
  "county",
  "state",
];
const BROAD = ["city", "municipality", "county", "state"];

const str = (a: Addr | null, k: string): string | null => {
  const v = a?.[k];
  return typeof v === "string" && v.trim() ? v.trim() : null;
};
const address = (json: unknown): Addr | null => {
  const a = (json as { address?: unknown } | null)?.address;
  return a && typeof a === "object" ? (a as Addr) : null;
};
const firstOf = (a: Addr | null, keys: readonly string[]): string | null =>
  keys.map((k) => str(a, k)).find((v) => v !== null) ?? null;

/** Nominatim answers at district and street zoom → the area and country (either may be missing). */
export function parsePlace(district: unknown, street?: unknown): PlaceName | null {
  const d = address(district);
  const s = address(street);
  if (!d && !s) return null;
  let area = firstOf(d, DISTRICT);
  if (!area && d) {
    // A small place only when the street-level answer agrees (zoom 14 can name a nearby village).
    const small = firstOf(d, SMALL);
    if (small && (!s || Object.values(s).includes(small))) area = small;
  }
  area ??= firstOf(s, STREET) ?? firstOf(d, BROAD);
  const country = str(d, "country") ?? str(s, "country");
  return { country, area };
}

export function parseBigDataCloud(json: unknown): PlaceName | null {
  if (!json || typeof json !== "object") return null;
  const j = json as Addr;
  const area = str(j, "locality") ?? str(j, "city") ?? str(j, "principalSubdivision");
  const country = str(j, "countryName");
  return area || country ? { country, area } : null;
}

/** "مصر - مدينتي" (or one part when the other is unknown). */
export const placeLabel = (p: PlaceName | null | undefined): string | null =>
  [p?.country, p?.area].filter((x): x is string => !!x).join(" - ") || null;

interface SavedPlace {
  lat: number;
  lng: number;
  ar?: PlaceName;
  en?: PlaceName;
}
const isPlace = (v: unknown): v is PlaceName => !!v && typeof v === "object";
export const placeNameStore = createStore<SavedPlace | null>("rattil.prayer.place", null, (raw) => {
  const r = raw as SavedPlace | null;
  if (!r || typeof r.lat !== "number" || typeof r.lng !== "number") return null;
  return {
    lat: r.lat,
    lng: r.lng,
    ar: isPlace(r.ar) ? r.ar : undefined,
    en: isPlace(r.en) ? r.en : undefined,
  };
});

/** The saved name of the current GPS position in this language, if it is still the same place. */
export function currentPlaceName(
  saved: SavedPlace | null,
  custom: { lat: number; lng: number } | null,
  lang: "ar" | "en",
): PlaceName | null {
  if (!saved || !custom || distanceM(saved.lat, saved.lng, custom.lat, custom.lng) > SAME_PLACE_M)
    return null;
  return saved[lang] ?? null;
}

async function getJson(url: string, f: typeof fetch): Promise<unknown> {
  const res = await f(url, { headers: { Accept: "application/json" } });
  return res.ok ? res.json() : null;
}

export async function lookupPlace(
  lat: number,
  lng: number,
  lang: "ar" | "en",
  f: typeof fetch = fetch,
): Promise<PlaceName | null> {
  const la = lat.toFixed(COORD_DIGITS);
  const lo = lng.toFixed(COORD_DIGITS);
  const nominatim = (zoom: number): string =>
    `https://nominatim.openstreetmap.org/reverse?lat=${la}&lon=${lo}&format=jsonv2&zoom=${zoom}&accept-language=${lang}`;
  const district = await getJson(nominatim(DISTRICT_ZOOM), f).catch(() => null);
  const street = await getJson(nominatim(STREET_ZOOM), f).catch(() => null);
  const p = parsePlace(district, street);
  if (p?.area) return p;
  const b = await getJson(
    `https://api.bigdatacloud.net/data/reverse-geocode-client?latitude=${la}&longitude=${lo}&localityLanguage=${lang}`,
    f,
  )
    .then(parseBigDataCloud)
    .catch(() => null);
  return b ?? p;
}

let running: Promise<void> | null = null;
/** Fills in the area name of the saved GPS position (both languages) when it is missing. */
export function refreshPlaceName(f: typeof fetch = fetch): Promise<void> {
  if (running) return running;
  running = (async () => {
    const custom = prayerStore.get().custom;
    if (!custom) return;
    const saved = placeNameStore.get();
    const same = saved && distanceM(saved.lat, saved.lng, custom.lat, custom.lng) <= SAME_PLACE_M;
    const next: SavedPlace = same ? { ...saved } : { lat: custom.lat, lng: custom.lng };
    for (const lang of ["ar", "en"] as const) {
      if (next[lang]?.area) continue;
      const p = await lookupPlace(custom.lat, custom.lng, lang, f);
      if (p) next[lang] = p;
    }
    placeNameStore.set(() => next);
  })().finally(() => {
    running = null;
  });
  return running;
}
