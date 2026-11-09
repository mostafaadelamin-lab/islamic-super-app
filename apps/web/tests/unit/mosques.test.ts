import {
  directionsLink,
  distanceM,
  fetchMosques,
  MAX_RESULTS,
  osmLink,
  overpassQuery,
  parseOverpass,
} from "@/lib/mosques";

const CAIRO = { lat: 30.0444, lng: 31.2357 };
const SAMPLE = {
  elements: [
    {
      type: "way",
      id: 2,
      center: { lat: 30.05, lon: 31.2357 },
      tags: { name: "مسجد ب", "name:en": "Mosque B" },
    },
    { type: "node", id: 1, lat: 30.045, lon: 31.2357, tags: { name: "مسجد أ" } },
    { type: "node", id: 3, lat: 30.06, lon: 31.24, tags: {} },
    { type: "node", id: 1, lat: 30.045, lon: 31.2357, tags: { name: "duplicate" } },
    { type: "node", id: 4, tags: { name: "no coordinates" } },
    { bogus: true },
  ],
};

describe("nearby mosques (OpenStreetMap / Overpass)", () => {
  it("asks for Muslim places of worship around the point", () => {
    const q = overpassQuery(CAIRO.lat, CAIRO.lng, 5000);
    expect(q).toContain('["amenity"="place_of_worship"]["religion"="muslim"]');
    expect(q).toContain("(around:5000,30.04440,31.23570)");
    expect(q).toContain("out center tags;");
  });

  it("distance (haversine)", () => {
    expect(distanceM(30, 31, 30, 31)).toBe(0);
    expect(distanceM(0, 0, 0, 1)).toBeCloseTo(111_195, -1); // one degree of longitude at the equator
    expect(distanceM(21.4225, 39.8262, 24.4672, 39.6111)).toBeGreaterThan(330_000); // Makkah-Madinah ≈ 337 km
    expect(distanceM(21.4225, 39.8262, 24.4672, 39.6111)).toBeLessThan(345_000);
  });

  it("parses, de-duplicates, drops malformed elements and sorts by distance", () => {
    const list = parseOverpass(SAMPLE, CAIRO.lat, CAIRO.lng, "ar");
    expect(list.map((m) => m.id)).toEqual(["node/1", "way/2", "node/3"]);
    expect(list[0]!.name).toBe("مسجد أ");
    expect(list[0]!.distance).toBeCloseTo(66.7, 0);
    expect(list[2]!.name).toBeNull();
    expect(parseOverpass(SAMPLE, CAIRO.lat, CAIRO.lng, "en")[1]!.name).toBe("Mosque B");
    expect(parseOverpass(null, 0, 0, "ar")).toEqual([]);
    expect(parseOverpass({ elements: "x" }, 0, 0, "ar")).toEqual([]);
  });

  it("caps the list", () => {
    const many = {
      elements: Array.from({ length: 100 }, (_, i) => ({ type: "node", id: i, lat: 30 + i / 1000, lon: 31 })),
    };
    expect(parseOverpass(many, 30, 31, "ar")).toHaveLength(MAX_RESULTS);
  });

  it("falls back to the second Overpass server, then throws when both fail", async () => {
    const calls: string[] = [];
    const ok = vi.fn(async (url: string) => {
      calls.push(url);
      if (calls.length === 1) return new Response("busy", { status: 429 });
      return new Response(JSON.stringify(SAMPLE), { status: 200 });
    });
    const list = await fetchMosques(CAIRO.lat, CAIRO.lng, 2000, "ar", ok as unknown as typeof fetch);
    expect(list).toHaveLength(3);
    expect(calls[0]).toContain("overpass-api.de");
    expect(calls[1]).toContain("kumi.systems");
    const bad = vi.fn(async () => {
      throw new TypeError("offline");
    });
    await expect(fetchMosques(0, 0, 2000, "ar", bad as unknown as typeof fetch)).rejects.toThrow("offline");
  });

  it("links", () => {
    expect(osmLink({ lat: 30.045, lng: 31.2357 })).toBe(
      "https://www.openstreetmap.org/?mlat=30.045000&mlon=31.235700#map=18/30.045000/31.235700",
    );
    expect(directionsLink({ lat: 1, lng: 2 }, true)).toBe("https://maps.apple.com/?daddr=1.000000,2.000000");
    expect(directionsLink({ lat: 1, lng: 2 }, false)).toBe("geo:1.000000,2.000000?q=1.000000,2.000000");
  });
});
