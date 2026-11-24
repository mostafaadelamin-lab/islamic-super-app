import {
  directionsLink,
  distanceM,
  fetchMosques,
  googleMapsMosque,
  isMosqueName,
  googleMapsNearby,
  MAX_RESULTS,
  osmLink,
  overpassQuery,
  parseOverpass,
  parseNominatim,
  isOtherFaithName,
  RADII_M,
  DEFAULT_RADIUS_M,
} from "@/lib/mosques";

const CAIRO = { lat: 30.0444, lng: 31.2357 };
const SAMPLE = {
  elements: [
    {
      type: "way",
      id: 2,
      center: { lat: 30.05, lon: 31.2357 },
      tags: { amenity: "place_of_worship", name: "مسجد ب", "name:en": "Mosque B" },
    },
    { type: "node", id: 1, lat: 30.045, lon: 31.2357, tags: { amenity: "place_of_worship", name: "مسجد أ" } },
    { type: "node", id: 3, lat: 30.06, lon: 31.24, tags: { amenity: "place_of_worship" } },
    // The outline of mosque 1, drawn as a building only: the same mosque.
    { type: "way", id: 5, center: { lat: 30.0451, lon: 31.2357 }, tags: { building: "mosque" } },
    // A mosque mapped only as a building.
    {
      type: "way",
      id: 6,
      center: { lat: 30.07, lon: 31.2357 },
      tags: { building: "mosque", name: "مسجد ج" },
    },
    { type: "node", id: 1, lat: 30.045, lon: 31.2357, tags: { name: "duplicate" } },
    { type: "node", id: 4, tags: { name: "no coordinates" } },
    { bogus: true },
  ],
};

describe("nearby mosques (OpenStreetMap / Overpass)", () => {
  it("asks for Muslim places of worship around the point", () => {
    const q = overpassQuery(CAIRO.lat, CAIRO.lng, 5000);
    expect(q).toContain('["amenity"="place_of_worship"]["religion"="muslim"]');
    expect(q).toContain("(around:5000,30.044,31.236)");
    expect(q).toContain('nwr["building"="mosque"](around:5000,30.044,31.236)');
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
    expect(list.map((m) => m.id)).toEqual(["node/1", "way/2", "node/3", "way/6"]);
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

  it("asks the quick search and three Overpass servers together; a busy one is ignored; throws when all fail", async () => {
    const calls: string[] = [];
    const ok = vi.fn(async (url: string) => {
      calls.push(url);
      if (url.includes("nominatim")) return new Response("[]", { status: 200 });
      if (url.includes("overpass-api.de")) return new Response("busy", { status: 429 });
      return new Response(JSON.stringify(SAMPLE), { status: 200 });
    });
    const list = await fetchMosques(CAIRO.lat, CAIRO.lng, 2000, "ar", ok as unknown as typeof fetch);
    expect(list).toHaveLength(4);
    expect(calls[0]).toContain("nominatim.openstreetmap.org");
    expect(calls.slice(1, 4)).toEqual([
      expect.stringContaining("overpass-api.de"),
      expect.stringContaining("mail.ru"),
      expect.stringContaining("private.coffee"),
    ]);
    const bad = vi.fn(async () => {
      throw new TypeError("offline");
    });
    await expect(fetchMosques(0, 0, 2000, "ar", bad as unknown as typeof fetch)).rejects.toThrow("offline");
  });

  it("slow Overpass: the quick list arrives first, then both are merged; churches are left out", async () => {
    const nominatim = [
      {
        osm_type: "node",
        osm_id: 1,
        lat: "30.045",
        lon: "31.2357",
        category: "amenity",
        type: "place_of_worship",
        name: "مسجد أ",
      },
      {
        osm_type: "node",
        osm_id: 99,
        lat: "30.044",
        lon: "31.234",
        category: "amenity",
        type: "place_of_worship",
        name: "مسجد قريب",
      },
      {
        osm_type: "node",
        osm_id: 77,
        lat: "30.046",
        lon: "31.2357",
        category: "amenity",
        type: "place_of_worship",
        name: "كنيسة العذراء",
      },
    ];
    const slow = vi.fn(async (url: string) => {
      if (url.includes("nominatim")) return new Response(JSON.stringify(nominatim), { status: 200 });
      await new Promise((r) => setTimeout(r, 50));
      return new Response(JSON.stringify(SAMPLE), { status: 200 });
    });
    const early: string[][] = [];
    const list = await fetchMosques(CAIRO.lat, CAIRO.lng, 1000, "ar", slow as unknown as typeof fetch, (l) =>
      early.push(l.map((m) => m.name ?? "")),
    );
    expect(early).toEqual([["مسجد أ", "مسجد قريب"]]);
    expect(list.map((m) => m.id)).toContain("node/99");
    expect(list.some((m) => m.name === "كنيسة العذراء")).toBe(false);
    expect(list.map((m) => m.distance)).toEqual([...list.map((m) => m.distance)].sort((a, b) => a - b));
  });

  it("quick search: distance limit, churches and mosque words", () => {
    expect(isOtherFaithName("كنيسة مار جرجس")).toBe(true);
    expect(isOtherFaithName("مسجد الدير ")).toBe(false);
    const json = [
      {
        osm_type: "node",
        osm_id: 1,
        lat: "30.06",
        lon: "31.2357",
        category: "amenity",
        type: "place_of_worship",
        name: "مسجد بعيد",
      },
      {
        osm_type: "way",
        osm_id: 2,
        lat: "30.045",
        lon: "31.2357",
        category: "building",
        type: "yes",
        name: "جامع النور",
      },
      {
        osm_type: "way",
        osm_id: 3,
        lat: "30.045",
        lon: "31.2357",
        category: "highway",
        type: "primary",
        name: "شارع الجامع",
      },
    ];
    expect(parseNominatim(json, CAIRO.lat, CAIRO.lng, 1000).map((m) => m.name)).toEqual(["جامع النور"]);
    expect(RADII_M[0]).toBe(500);
    expect(DEFAULT_RADIUS_M).toBe(1000);
  });

  it("links", () => {
    expect(osmLink({ lat: 30.045, lng: 31.2357 })).toBe(
      "https://www.openstreetmap.org/?mlat=30.045000&mlon=31.235700#map=18/30.045000/31.235700",
    );
    expect(googleMapsNearby(30.0444, 31.2357, true)).toBe(
      "https://www.google.com/maps/search/%D9%85%D8%B3%D8%AC%D8%AF/@30.044400,31.235700,15z",
    );
    expect(googleMapsMosque({ lat: 1, lng: 2, name: "مسجد النور" })).toBe(
      "https://www.google.com/maps/search/?api=1&query=%D9%85%D8%B3%D8%AC%D8%AF+%D8%A7%D9%84%D9%86%D9%88%D8%B1+1.000000%2C2.000000",
    );
    expect(directionsLink({ lat: 1, lng: 2 }, true)).toBe("https://maps.apple.com/?daddr=1.000000,2.000000");
    expect(directionsLink({ lat: 1, lng: 2 }, false)).toBe("geo:1.000000,2.000000?q=1.000000,2.000000");
  });
});

describe("not mosques (owner 2026-11-20)", () => {
  it("drops roads, squares and districts", () => {
    expect(isMosqueName("طريق طلعت مصطفى")).toBe(false);
    expect(isMosqueName("Road 90")).toBe(false);
    expect(isMosqueName("مسجد الرحمة")).toBe(true);
    const json = {
      elements: [
        {
          type: "way",
          id: 9,
          center: { lat: 30.05, lon: 31.24 },
          tags: { amenity: "place_of_worship", religion: "muslim", name: "طريق طلعت مصطفى" },
        },
        {
          type: "node",
          id: 8,
          lat: 30.05,
          lon: 31.25,
          tags: { amenity: "place_of_worship", religion: "muslim", name: "مسجد الرحمة" },
        },
      ],
    };
    expect(parseOverpass(json, 30.0444, 31.2357, "ar").map((m) => m.name)).toEqual(["مسجد الرحمة"]);
  });
});
