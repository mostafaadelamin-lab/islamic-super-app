/**
 * Nearby mosques from OpenStreetMap (owner's choice, 2026-11-09): free, no API key, works on every platform.
 * Data © OpenStreetMap contributors, ODbL 1.0 — the page must show that credit.
 *
 * The Overpass API is asked for every node/way/relation tagged amenity=place_of_worship + religion=muslim
 * within `radius` metres of the user's prayer location. Results are sorted by straight-line distance.
 * The mobile port (apps/mobile/lib/domain/mosques.dart) builds the same query and parses the same JSON.
 */

/** Public Overpass servers, tried in order (both free and keyless). */
export const OVERPASS_ENDPOINTS = [
  "https://overpass-api.de/api/interpreter",
  "https://overpass.kumi.systems/api/interpreter",
] as const;
export const RADII_M = [2000, 5000, 10000] as const;
export const DEFAULT_RADIUS_M = 5000;
export const MAX_RESULTS = 60;
const EARTH_RADIUS_M = 6_371_000;

export interface Mosque {
  /** "node/123", "way/456" … (stable OSM id). */
  id: string;
  name: string | null;
  lat: number;
  lng: number;
  /** Straight-line distance from the search point, metres. */
  distance: number;
}

export function overpassQuery(lat: number, lng: number, radius: number): string {
  const r = Math.round(radius);
  const p = `${lat.toFixed(5)},${lng.toFixed(5)}`;
  return `[out:json][timeout:25];nwr["amenity"="place_of_worship"]["religion"="muslim"](around:${r},${p});out center tags;`;
}

/** Great-circle distance in metres. */
export function distanceM(lat1: number, lng1: number, lat2: number, lng2: number): number {
  const rad = Math.PI / 180;
  const dLat = (lat2 - lat1) * rad;
  const dLng = (lng2 - lng1) * rad;
  const a = Math.sin(dLat / 2) ** 2 + Math.cos(lat1 * rad) * Math.cos(lat2 * rad) * Math.sin(dLng / 2) ** 2;
  return 2 * EARTH_RADIUS_M * Math.asin(Math.min(1, Math.sqrt(a)));
}

interface OsmElement {
  type?: unknown;
  id?: unknown;
  lat?: unknown;
  lon?: unknown;
  center?: { lat?: unknown; lon?: unknown };
  tags?: Record<string, unknown>;
}

const num = (v: unknown): number | null => (typeof v === "number" && Number.isFinite(v) ? v : null);
const str = (v: unknown): string | null => (typeof v === "string" && v.trim() !== "" ? v.trim() : null);

/** Name in the user's language when OSM has one, else the local name. */
function pickName(tags: Record<string, unknown>, locale: "ar" | "en"): string | null {
  return locale === "ar"
    ? (str(tags["name:ar"]) ?? str(tags.name) ?? str(tags["name:en"]))
    : (str(tags["name:en"]) ?? str(tags.name) ?? str(tags["name:ar"]));
}

/** Parses an Overpass JSON answer; ignores malformed elements. Sorted by distance, capped at MAX_RESULTS. */
export function parseOverpass(json: unknown, lat: number, lng: number, locale: "ar" | "en"): Mosque[] {
  const elements = (json as { elements?: unknown })?.elements;
  if (!Array.isArray(elements)) return [];
  const seen = new Set<string>();
  const out: Mosque[] = [];
  for (const raw of elements as OsmElement[]) {
    const type = str(raw?.type);
    const id = num(raw?.id);
    const mLat = num(raw?.lat) ?? num(raw?.center?.lat);
    const mLng = num(raw?.lon) ?? num(raw?.center?.lon);
    if (type === null || id === null || mLat === null || mLng === null) continue;
    const key = `${type}/${id}`;
    if (seen.has(key)) continue;
    seen.add(key);
    const tags = raw.tags && typeof raw.tags === "object" ? raw.tags : {};
    out.push({
      id: key,
      name: pickName(tags, locale),
      lat: mLat,
      lng: mLng,
      distance: distanceM(lat, lng, mLat, mLng),
    });
  }
  out.sort((a, b) => a.distance - b.distance);
  return out.slice(0, MAX_RESULTS);
}

/** Fetches mosques around a point, trying each Overpass server in turn. Throws when all fail. */
export async function fetchMosques(
  lat: number,
  lng: number,
  radius: number,
  locale: "ar" | "en",
  fetchFn: typeof fetch = fetch,
): Promise<Mosque[]> {
  const body = `data=${encodeURIComponent(overpassQuery(lat, lng, radius))}`;
  let last: unknown = null;
  for (const url of OVERPASS_ENDPOINTS) {
    try {
      const res = await fetchFn(url, {
        method: "POST",
        headers: { "Content-Type": "application/x-www-form-urlencoded" },
        body,
      });
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      return parseOverpass(await res.json(), lat, lng, locale);
    } catch (e) {
      last = e;
    }
  }
  throw last instanceof Error ? last : new Error("Overpass unavailable");
}

/** Link that opens the mosque on openstreetmap.org (from there the user can ask for directions). */
export function osmLink(m: Pick<Mosque, "lat" | "lng">): string {
  return `https://www.openstreetmap.org/?mlat=${m.lat.toFixed(6)}&mlon=${m.lng.toFixed(6)}#map=18/${m.lat.toFixed(6)}/${m.lng.toFixed(6)}`;
}

/** Walking/driving directions in the phone's maps app (geo: URI works on Android; iOS opens Apple Maps). */
export function directionsLink(m: Pick<Mosque, "lat" | "lng">, ios: boolean): string {
  return ios
    ? `https://maps.apple.com/?daddr=${m.lat.toFixed(6)},${m.lng.toFixed(6)}`
    : `geo:${m.lat.toFixed(6)},${m.lng.toFixed(6)}?q=${m.lat.toFixed(6)},${m.lng.toFixed(6)}`;
}
