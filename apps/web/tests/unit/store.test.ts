import { createStore } from "@/lib/store";
import { readJson, readStorage, removeStorage, writeJson, writeStorage } from "@/lib/storage";
import {
  clampFontSize,
  DEFAULT_PRAYER,
  DEFAULT_PREFS,
  FONT_MAX,
  FONT_MIN,
  sanitizeLastRead,
  sanitizePrayer,
  sanitizePrefs,
} from "@/lib/settings";
import {
  currentOfflineStatus,
  handleSwMessage,
  registerServiceWorker,
  requestOfflineStatus,
  subscribeOfflineStatus,
} from "@/lib/sw-client";

beforeEach(() => localStorage.clear());

describe("storage helpers never throw", () => {
  it("round-trips values", () => {
    expect(writeStorage("k", "v")).toBe(true);
    expect(readStorage("k")).toBe("v");
    writeJson("j", { a: 1 });
    expect(readJson("j", null)).toEqual({ a: 1 });
    removeStorage("k");
    expect(readStorage("k")).toBeNull();
    localStorage.setItem("bad", "{");
    expect(readJson("bad", "fallback")).toBe("fallback");
    expect(readJson("absent", 7)).toBe(7);
  });
  it("survives a throwing localStorage (private mode / blocked)", () => {
    const get = vi.spyOn(Storage.prototype, "getItem").mockImplementation(() => {
      throw new Error("SecurityError");
    });
    const set = vi.spyOn(Storage.prototype, "setItem").mockImplementation(() => {
      throw new Error("QuotaExceeded");
    });
    const rem = vi.spyOn(Storage.prototype, "removeItem").mockImplementation(() => {
      throw new Error("SecurityError");
    });
    expect(readStorage("k")).toBeNull();
    expect(writeStorage("k", "v")).toBe(false);
    expect(() => removeStorage("k")).not.toThrow();
    const store = createStore("s", 1, (r) => (typeof r === "number" ? r : 1));
    expect(store.get()).toBe(1);
    store.set(2);
    expect(store.get()).toBe(2); // in-memory value still works
    get.mockRestore();
    set.mockRestore();
    rem.mockRestore();
  });
});

describe("createStore", () => {
  it("persists, notifies and reloads on cross-tab storage events", () => {
    const store = createStore("test.store", { n: 0 }, (r) =>
      typeof r === "object" && r && typeof (r as { n: unknown }).n === "number"
        ? (r as { n: number })
        : { n: 0 },
    );
    const listener = vi.fn();
    const unsub = store.subscribe(listener);
    store.set((p) => ({ n: p.n + 1 }));
    expect(store.get()).toEqual({ n: 1 });
    expect(JSON.parse(localStorage.getItem("test.store")!)).toEqual({ n: 1 });
    expect(listener).toHaveBeenCalledTimes(1);
    localStorage.setItem("test.store", JSON.stringify({ n: 9 }));
    window.dispatchEvent(new StorageEvent("storage", { key: "test.store" }));
    expect(store.get()).toEqual({ n: 9 });
    window.dispatchEvent(new StorageEvent("storage", { key: "other" }));
    expect(listener).toHaveBeenCalledTimes(2);
    unsub();
    store.set({ n: 3 });
    expect(listener).toHaveBeenCalledTimes(2);
  });
});

describe("settings sanitisers", () => {
  it("prefs", () => {
    expect(sanitizePrefs(null)).toEqual(DEFAULT_PREFS);
    expect(sanitizePrefs({ locale: "en", theme: "dark", fontSize: 99, translation: true })).toEqual({
      locale: "en",
      theme: "dark",
      fontSize: FONT_MAX,
      translation: true,
    });
    expect(sanitizePrefs({ locale: "fr", theme: "neon", fontSize: 2 })).toMatchObject({
      locale: null,
      theme: "system",
      fontSize: FONT_MIN,
    });
  });
  it("font size clamps to 18..40", () => {
    expect(FONT_MIN).toBe(18);
    expect(FONT_MAX).toBe(40);
    expect(clampFontSize("30")).toBe(30);
    expect(clampFontSize("x")).toBe(26);
    expect(clampFontSize(17)).toBe(18);
    expect(clampFontSize(41)).toBe(40);
  });
  it("prayer prefs", () => {
    expect(sanitizePrayer(undefined)).toEqual(DEFAULT_PRAYER);
    expect(
      sanitizePrayer({
        cityId: "c1",
        method: "isna",
        asr: "hanafi",
        adjustments: { fajr: 45, isha: -3, dhuhr: 0, bogus: 4, asr: "x" },
        custom: { lat: 1, lng: 2, tz: "UTC" },
      }),
    ).toEqual({
      cityId: "c1",
      method: "isna",
      asr: "hanafi",
      adjustments: { fajr: 30, isha: -3 },
      custom: { lat: 1, lng: 2, tz: "UTC" },
    });
    expect(sanitizePrayer({ method: "bogus", custom: { lat: "1" } })).toMatchObject({
      method: null,
      custom: null,
    });
  });
  it("last read", () => {
    expect(sanitizeLastRead(null)).toBeNull();
    expect(sanitizeLastRead({ surah: 0, ayah: 1 })).toBeNull();
    expect(sanitizeLastRead({ surah: 2, ayah: 3, page: 999 })).toEqual({
      surah: 2,
      ayah: 3,
      page: null,
      at: 0,
    });
    expect(sanitizeLastRead({ surah: 2, ayah: 3, page: 3, at: 5 })).toEqual({
      surah: 2,
      ayah: 3,
      page: 3,
      at: 5,
    });
  });
});

describe("service worker client", () => {
  it("tracks progress messages", () => {
    const l = vi.fn();
    const unsub = subscribeOfflineStatus(l);
    handleSwMessage(null);
    handleSwMessage({ type: "other" });
    expect(l).not.toHaveBeenCalled();
    handleSwMessage({ type: "precache-progress", done: 3, total: 10, complete: false });
    expect(currentOfflineStatus()).toEqual({ supported: true, done: 3, total: 10, complete: false });
    handleSwMessage({ type: "precache-progress", done: "x", complete: true });
    expect(currentOfflineStatus()).toEqual({ supported: true, done: 0, total: 0, complete: true });
    expect(l).toHaveBeenCalledTimes(2);
    unsub();
  });
  it("registers the worker and requests a full precache for the page locale", async () => {
    const post = vi.fn();
    const reg = { active: { postMessage: post } };
    const listeners: Record<string, (e: MessageEvent) => void> = {};
    const nav = {
      serviceWorker: {
        register: vi.fn().mockResolvedValue(reg),
        ready: Promise.resolve(reg),
        addEventListener: (t: string, fn: (e: MessageEvent) => void) => (listeners[t] = fn),
      },
    } as unknown as Navigator;
    document.documentElement.lang = "en";
    registerServiceWorker(nav);
    registerServiceWorker(nav); // idempotent
    await new Promise((r) => setTimeout(r, 0));
    expect(nav.serviceWorker.register).toHaveBeenCalledTimes(1);
    expect(post).toHaveBeenCalledWith({ type: "precache-all", locale: "en" });
    listeners.message?.({
      data: { type: "precache-progress", done: 1, total: 2, complete: false },
    } as MessageEvent);
    expect(currentOfflineStatus().total).toBe(2);
    document.documentElement.lang = "ar";
    requestOfflineStatus(nav);
    await new Promise((r) => setTimeout(r, 0));
    expect(post).toHaveBeenLastCalledWith({ type: "precache-all", locale: "ar" });
    requestOfflineStatus({} as Navigator);
  });
});

describe("resolveLocale", () => {
  it("accepts ar/en and 404s otherwise", async () => {
    const { resolveLocale } = await import("@/lib/page-locale");
    await expect(resolveLocale(Promise.resolve({ locale: "en" }))).resolves.toBe("en");
    await expect(resolveLocale(Promise.resolve({ locale: "fr" }))).rejects.toThrow("NEXT_NOT_FOUND");
  });
});
