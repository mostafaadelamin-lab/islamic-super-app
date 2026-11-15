import { parseBigDataCloud, parsePlace, placeLabel, placeNameStore, refreshPlaceName } from "@/lib/place-names";
import { prayerStore } from "@/lib/settings";

describe("Area name of the viewer's position (owner 2026-11-16, same rules as the app)", () => {
  beforeEach(() => {
    localStorage.clear();
    placeNameStore.set(() => null);
  });

  it("prefers the district (e.g. a compound or town), then the street answer", () => {
    const district = { address: { town: "مدينتي", state: "القاهرة", country: "مصر" } };
    expect(placeLabel(parsePlace(district))).toBe("مصر - مدينتي");
    const village = { address: { village: "قرية قريبة", country: "مصر" } };
    const street = { address: { suburb: "مدينة نصر", country: "مصر" } };
    expect(parsePlace(village, street)).toEqual({ country: "مصر", area: "مدينة نصر" });
    expect(parsePlace(null, null)).toBeNull();
    expect(parseBigDataCloud({ locality: "Nasr City", countryName: "Egypt" })).toEqual({
      country: "Egypt",
      area: "Nasr City",
    });
  });

  it("looks the name up once for the saved GPS position, in Arabic and English", async () => {
    prayerStore.set((p) => ({ ...p, custom: { lat: 30.1, lng: 31.6, tz: "Africa/Cairo" } }));
    const f = vi.fn(async (url: string) => {
      const ar = url.includes("accept-language=ar");
      return new Response(
        JSON.stringify({ address: { town: ar ? "مدينتي" : "Madinaty", country: ar ? "مصر" : "Egypt" } }),
      );
    });
    await refreshPlaceName(f as unknown as typeof fetch);
    expect(placeNameStore.get()?.ar).toEqual({ country: "مصر", area: "مدينتي" });
    expect(placeNameStore.get()?.en).toEqual({ country: "Egypt", area: "Madinaty" });
    const calls = f.mock.calls.length;
    await refreshPlaceName(f as unknown as typeof fetch);
    expect(f.mock.calls.length).toBe(calls);
  });
});
