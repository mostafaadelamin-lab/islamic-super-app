import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import {
  downloadAllPrinted,
  PRINTED_CACHE,
  PRINTED_PAGES,
  printedJob,
  printedSavedCount,
  printedSavedIn,
  startPrintedDownload,
} from "@/lib/mushaf-printed";
import { surahPages } from "@/components/PrintedDownloadBar";

/** Owner 2026-11-26: the Madina font is saved once for the whole Mushaf; saved pages are never fetched again. */
class FakeCache {
  store = new Map<string, Response>();
  abs = (u: string) => new URL(u, location.href).href;
  async match(u: string) {
    return this.store.get(this.abs(u))?.clone();
  }
  async put(u: string, r: Response) {
    this.store.set(this.abs(u), r);
  }
  async keys() {
    return [...this.store.keys()].map((u) => new Request(u));
  }
}

describe("Madina font offline", () => {
  let cache: FakeCache;
  beforeEach(() => {
    cache = new FakeCache();
    vi.stubGlobal("caches", { open: async (name: string) => (name === PRINTED_CACHE ? cache : new FakeCache()) });
  });
  afterEach(() => vi.unstubAllGlobals());

  it("saves every page once, resumes after a cut, and skips saved pages", async () => {
    const asked: string[] = [];
    let cut = true;
    const fetchImpl = (async (url: string) => {
      if (cut && url.includes("p300.woff2")) return new Response("", { status: 503 });
      asked.push(url);
      return new Response(url.endsWith(".json") ? "{}" : "font");
    }) as unknown as typeof fetch;

    expect(await printedSavedCount()).toBe(0);
    expect(await downloadAllPrinted(() => {}, undefined, fetchImpl)).toBe(false);
    const partial = await printedSavedCount();
    expect(partial).toBeGreaterThan(0);
    expect(partial).toBeLessThan(PRINTED_PAGES);

    cut = false;
    let last = 0;
    expect(await downloadAllPrinted((n) => (last = n), undefined, fetchImpl)).toBe(true);
    expect(last).toBe(PRINTED_PAGES);
    expect(await printedSavedCount()).toBe(PRINTED_PAGES);
    // Every file fetched exactly once over both runs.
    expect(new Set(asked).size).toBe(asked.length);
    expect(asked.length).toBe(PRINTED_PAGES * 2);

    const before = asked.length;
    expect(await downloadAllPrinted(() => {}, undefined, fetchImpl)).toBe(true);
    expect(asked.length).toBe(before);
  });

  it("downloads one surah's pages from the font menu and reports the job", async () => {
    vi.stubGlobal("fetch", async (url: string) => new Response(String(url).endsWith(".json") ? "{}" : "font"));
    const pages = surahPages(3);
    expect(pages[0]).toBe(50);
    expect(pages.at(-1)).toBe(76);
    await startPrintedDownload(pages);
    expect(printedJob()).toMatchObject({ running: false, failed: false, finished: true, done: pages.length });
    expect(await printedSavedIn(pages)).toBe(true);
    expect(await printedSavedCount()).toBe(pages.length);
  });
});
