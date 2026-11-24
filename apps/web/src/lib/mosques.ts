/**
 * Nearby mosques from OpenStreetMap (owner's choice, 2026-11-09): free, no API key, works on every platform.
 * Data © OpenStreetMap contributors, ODbL 1.0 — the page must show that credit.
 *
 * The Overpass API is asked for every node/way/relation tagged amenity=place_of_worship + religion=muslim
 * within `radius` metres of the user's prayer location. Results are sorted by straight-line distance.
 * The mobile port (apps/mobile/lib/domain/mosques.dart) builds the same query and parses the same JSON.
 */

/** Public Overpass servers (free and keyless); the first FIRST_WAVE are asked together, the rest when they are slow. */
export const OVERPASS_ENDPOINTS = [
  "https://overpass-api.de/api/interpreter",
  "https://maps.mail.ru/osm/tools/overpass/api/interpreter",
  "https://overpass.private.coffee/api/interpreter",
  "https://overpass.kumi.systems/api/interpreter",
] as const;
export const FIRST_WAVE = 3;
/** Busy Overpass servers answer a 2 km search in about 18 s (2026-11-24). */
export const SERVER_TIMEOUT_MS = 20_000;
export const SPARE_SERVERS_AFTER_MS = 4_000;
const NOMINATIM_TIMEOUT_MS = 10_000;
/** A building-only element this close to a tagged mosque is the same mosque drawn twice. */
const SAME_MOSQUE_M = 60;
/** Closest first (owner 2026-11-24: under 1 km). With nothing that close the page widens by itself. */
export const RADII_M = [500, 1000, 2000, 5000] as const;
export const DEFAULT_RADIUS_M = 1000;
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

/** Muslim places of worship, plus buildings drawn as mosques that nobody tagged as a place of worship. */
export function overpassQuery(lat: number, lng: number, radius: number): string {
  const a = `(around:${Math.round(radius)},${lat.toFixed(3)},${lng.toFixed(3)})`;
  return `[out:json][timeout:20];(nwr["amenity"="place_of_worship"]["religion"="muslim"]${a};nwr["building"="mosque"]${a};);out center tags;`;
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

/** Names of roads, squares and districts, never a mosque (owner 2026-11-20: «طريق طلعت مصطفى» was listed). */
const NOT_MOSQUE =
  /^(طريق|شارع|ش\.|محور|ميدان|كوبري|كورنيش|حي|منطقة|مدينة|قرية|عزبة|road|street|st\.|avenue|square|highway)(\s|$)/i;

/** Words that say a place is a mosque. */
const MOSQUE_WORD = /مسجد|جامع|زاوية|مصلى|mosque|masjid|masjed|jami|musalla/i;
/** Churches and other places of worship (Nominatim's «مسجد» search returns every place of worship). */
const OTHER_FAITH = /كنيسة|كاتدرائية|كنيس|دير\s|معبد|church|cathedral|chapel|monastery|synagogue|temple/i;

/** True for a church, monastery …; a name with a mosque word in it («مسجد الدير») stays. */
export const isOtherFaithName = (name: string | null): boolean =>
  name !== null && OTHER_FAITH.test(name) && !MOSQUE_WORD.test(name);

/** False for names of roads, squares, districts and the like. */
export const isMosqueName = (name: string | null): boolean => name === null || !NOT_MOSQUE.test(name.trim());

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
  const buildingOnly: Mosque[] = [];
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
    const name = pickName(tags, locale);
    if (!isMosqueName(name)) continue;
    const m: Mosque = {
      id: key,
      name,
      lat: mLat,
      lng: mLng,
      distance: distanceM(lat, lng, mLat, mLng),
    };
    (tags.amenity === "place_of_worship" ? out : buildingOnly).push(m);
  }
  const tagged = [...out];
  for (const b of buildingOnly) {
    if (!tagged.some((m) => distanceM(m.lat, m.lng, b.lat, b.lng) < SAME_MOSQUE_M)) out.push(b);
  }
  out.sort((a, b) => a.distance - b.distance);
  return out.slice(0, MAX_RESULTS);
}

/** OpenStreetMap's quick search (Nominatim) for mosques in a box around the point (same as the app). */
export function nominatimUrl(lat: number, lng: number, radius: number, locale: "ar" | "en"): string {
  const la = Number(lat.toFixed(3));
  const ln = Number(lng.toFixed(3));
  const dLat = radius / 111_320;
  const dLng = radius / (111_320 * Math.min(1, Math.max(0.1, Math.abs(Math.cos((la * Math.PI) / 180)))));
  const q = new URLSearchParams({
    q: locale === "ar" ? "مسجد" : "mosque",
    format: "jsonv2",
    limit: "50",
    bounded: "1",
    viewbox: `${ln - dLng},${la + dLat},${ln + dLng},${la - dLat}`,
    "accept-language": locale,
  });
  return `https://nominatim.openstreetmap.org/search?${q.toString()}`;
}

/** Parses a Nominatim answer: places of worship (not churches) and names with a mosque word, within maxDistance. */
export function parseNominatim(json: unknown, lat: number, lng: number, maxDistance?: number): Mosque[] {
  if (!Array.isArray(json)) return [];
  const out: Mosque[] = [];
  const seen = new Set<string>();
  for (const raw of json as Record<string, unknown>[]) {
    const mLat = Number(raw?.lat);
    const mLng = Number(raw?.lon);
    const id = `${String(raw?.osm_type)}/${String(raw?.osm_id)}`;
    if (!Number.isFinite(mLat) || !Number.isFinite(mLng) || seen.has(id)) continue;
    seen.add(id);
    const name = str(raw.name);
    const worship = raw.category === "amenity" && raw.type === "place_of_worship";
    if (!worship && !(name !== null && MOSQUE_WORD.test(name))) continue;
    if (!isMosqueName(name) || isOtherFaithName(name)) continue;
    const d = distanceM(lat, lng, mLat, mLng);
    if (maxDistance !== undefined && d > maxDistance) continue;
    out.push({ id, name, lat: mLat, lng: mLng, distance: d });
  }
  out.sort((a, b) => a.distance - b.distance);
  return out.slice(0, MAX_RESULTS);
}

/** Adds the extra mosques not already in base (same id or within 60 m), nearest first. */
export function mergeMosques(base: Mosque[], extra: Mosque[]): Mosque[] {
  const out = [...base];
  for (const e of extra) {
    if (!base.some((m) => m.id === e.id || distanceM(m.lat, m.lng, e.lat, e.lng) < SAME_MOSQUE_M))
      out.push(e);
  }
  out.sort((a, b) => a.distance - b.distance);
  return out.slice(0, MAX_RESULTS);
}

/**
 * Fetches mosques around a point. The quick search (Nominatim, about 1 s) and the Overpass servers (complete but
 * often busy) are asked together; the quick list goes to onEarly at once, the result is the first Overpass answer
 * with mosques merged with it. Throws when every server fails.
 */
export function fetchMosques(
  lat: number,
  lng: number,
  radius: number,
  locale: "ar" | "en",
  fetchFn: typeof fetch = fetch,
  onEarly?: (list: Mosque[]) => void,
): Promise<Mosque[]> {
  const body = `data=${encodeURIComponent(overpassQuery(lat, lng, radius))}`;
  return new Promise<Mosque[]>((resolve, reject) => {
    let settled = false;
    let quick: Mosque[] | null = null;
    let quickDone = false;
    let left: number = OVERPASS_ENDPOINTS.length;
    let firstLeft: number = FIRST_WAVE;
    let answered = false;
    let spares = false;
    let last: unknown = null;
    const finish = (list: Mosque[] | null): void => {
      if (settled) return;
      settled = true;
      clearTimeout(spareTimer);
      clearTimeout(deadline);
      if (list) resolve(list);
      else reject(last instanceof Error ? last : new Error("Overpass unavailable"));
    };
    const settle = (): void => {
      if (left === 0 && quickDone) finish(quick ?? (answered ? [] : null));
    };
    const ask = (url: string, first: boolean): void => {
      fetchFn(url, {
        method: "POST",
        headers: { "Content-Type": "application/x-www-form-urlencoded" },
        body,
        signal: AbortSignal.timeout(SERVER_TIMEOUT_MS),
      })
        .then(async (res) => {
          if (!res.ok) throw new Error(`HTTP ${res.status}`);
          const list = parseOverpass(await res.json(), lat, lng, locale);
          answered = true;
          if (list.length > 0) finish(mergeMosques(list, quick ?? []));
        })
        .catch((e: unknown) => {
          last = e;
        })
        .finally(() => {
          left -= 1;
          if (first && --firstLeft === 0 && !settled) askSpares();
          settle();
        });
    };
    const askSpares = (): void => {
      if (spares) return;
      spares = true;
      for (const u of OVERPASS_ENDPOINTS.slice(FIRST_WAVE)) ask(u, false);
    };
    fetchFn(nominatimUrl(lat, lng, radius, locale), { signal: AbortSignal.timeout(NOMINATIM_TIMEOUT_MS) })
      .then(async (res) => {
        if (!res.ok) throw new Error(`HTTP ${res.status}`);
        const list = parseNominatim(await res.json(), lat, lng, radius);
        if (list.length > 0) {
          quick = list;
          if (!settled) onEarly?.(list);
        }
      })
      .catch((e: unknown) => {
        last ??= e;
      })
      .finally(() => {
        quickDone = true;
        settle();
      });
    for (const u of OVERPASS_ENDPOINTS.slice(0, FIRST_WAVE)) ask(u, true);
    const spareTimer = setTimeout(askSpares, SPARE_SERVERS_AFTER_MS);
    const deadline = setTimeout(() => finish(quick), SERVER_TIMEOUT_MS + SPARE_SERVERS_AFTER_MS);
  });
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

/** Nearby mosques on Google Maps (same link as the app's googleMapsNearbyUri). */
export function googleMapsNearby(lat: number, lng: number, arabic: boolean): string {
  return `https://www.google.com/maps/search/${encodeURIComponent(arabic ? "مسجد" : "mosque")}/@${lat.toFixed(6)},${lng.toFixed(6)},15z`;
}

/** One mosque on Google Maps, by its name next to its position (the app opens Google Maps on tap). */
export function googleMapsMosque(m: Pick<Mosque, "lat" | "lng" | "name">): string {
  const p = `${m.lat.toFixed(6)},${m.lng.toFixed(6)}`;
  return `https://www.google.com/maps/search/?${new URLSearchParams({ api: "1", query: m.name ? `${m.name} ${p}` : p }).toString()}`;
}
