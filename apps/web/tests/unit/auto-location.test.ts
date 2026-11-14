import { beforeEach, describe, expect, it, vi } from "vitest";
import { autoLocationStore, refreshAutoLocation } from "@/lib/auto-location";
import { prayerStore } from "@/lib/settings";

const nav = (state: string, lat: number, lng: number) =>
  ({
    permissions: { query: vi.fn().mockResolvedValue({ state }) },
    geolocation: {
      getCurrentPosition: vi.fn((ok: PositionCallback) =>
        ok({ coords: { latitude: lat, longitude: lng } } as GeolocationPosition),
      ),
    },
  }) as unknown as Navigator;

beforeEach(() => {
  localStorage.clear();
  prayerStore.reload();
  autoLocationStore.reload();
});

describe("auto location (the app's prayerAutoLocation)", () => {
  it("refreshes the saved position when location is already allowed and the viewer moved", async () => {
    prayerStore.set((p) => ({ ...p, custom: { lat: 30.0444, lng: 31.2357, tz: "Africa/Cairo" } }));
    expect(await refreshAutoLocation(nav("granted", 31.2001, 29.9187))).toBe(true);
    expect(prayerStore.get().custom).toMatchObject({ lat: 31.2001, lng: 29.9187 });
  });
  it("never asks for permission, keeps a city from the list, and can be switched off", async () => {
    prayerStore.set((p) => ({ ...p, custom: { lat: 30.0444, lng: 31.2357, tz: "Africa/Cairo" } }));
    const prompt = nav("prompt", 31.2, 29.9);
    expect(await refreshAutoLocation(prompt)).toBe(false);
    expect(prompt.geolocation.getCurrentPosition).not.toHaveBeenCalled();
    autoLocationStore.set(false);
    expect(await refreshAutoLocation(nav("granted", 31.2, 29.9))).toBe(false);
    autoLocationStore.set(true);
    prayerStore.set((p) => ({ ...p, custom: null }));
    expect(await refreshAutoLocation(nav("granted", 31.2, 29.9))).toBe(false);
  });
  it("ignores small moves", async () => {
    prayerStore.set((p) => ({ ...p, custom: { lat: 30.0444, lng: 31.2357, tz: "Africa/Cairo" } }));
    expect(await refreshAutoLocation(nav("granted", 30.0446, 31.2359))).toBe(false);
  });
});
