import { readRepoJson } from "../repo";
import {
  BUNDLED_SOURCES,
  embedUrl,
  inTab,
  LIVE_CHANNELS,
  liveEmbedUrl,
  savedReelsStore,
  toggleSaved,
  fetchReelsFeed,
  mixReels,
  posterUrl,
  REELS,
  sanitizeReels,
  sanitizeSources,
  visibleReels,
  type Reel,
} from "@/lib/reels";

const yt: Reel = {
  id: "yt-hTtlD-u4_HI",
  platform: "youtube",
  ref: "hTtlD-u4_HI",
  url: "https://www.youtube.com/watch?v=hTtlD-u4_HI",
  title: { ar: "عنوان", en: "Title" },
  speaker: null,
  category: "recitation",
  source: null,
  status: "approved",
  reviewer: "Reviewer",
  reviewedAt: "2026-11-09",
};
const pend: Reel = { ...yt, id: "yt-26dRG7OeL6Q", ref: "26dRG7OeL6Q", status: "pending" };
const ig: Reel = {
  ...yt,
  id: "ig-C1a2B3c4D5e",
  platform: "instagram",
  ref: "C1a2B3c4D5e",
  url: "https://www.instagram.com/reel/C1a2B3c4D5e/",
};

describe("reels", () => {
  it("bundles exactly the built catalogue (rejected ones never reach the app)", () => {
    const built = readRepoJson<{ items: Reel[] }>("content/reels/dist/reels.v1.json");
    expect(REELS).toEqual(built.items);
    expect(REELS.every((r) => r.status === "approved" || r.status === "pending")).toBe(true);
  });
  it("shows only approved reels unless reviewer mode is on", () => {
    expect(visibleReels([yt, pend], false)).toEqual([yt]);
    expect(visibleReels([yt, pend], true)).toEqual([yt, pend]);
  });
  it("drops malformed or unknown items instead of embedding them", () => {
    const bad = [
      { ...yt, ref: "x" },
      { ...yt, platform: "tiktok" },
      { ...yt, status: "rejected" },
      { ...pend, ref: "../../evil" },
      { ...ig, ref: "a/b" },
      { ...yt, category: "music" },
      { ...yt, category: "lesson" }, // owner 2026-11-27: recitation only
      { ...yt, category: "admonition" },
      null,
    ];
    expect(sanitizeReels({ items: [yt, ...bad, pend, ig] })).toEqual([yt, pend, ig]);
    expect(sanitizeReels({})).toEqual([]);
  });
  it("builds official embed URLs", () => {
    const u = new URL(embedUrl(yt, "https://app.example"));
    expect(u.origin).toBe("https://www.youtube-nocookie.com");
    expect(u.pathname).toBe("/embed/hTtlD-u4_HI");
    expect(u.searchParams.get("autoplay")).toBe("1");
    expect(u.searchParams.get("mute")).toBe("1");
    expect(u.searchParams.get("playsinline")).toBe("1");
    expect(u.searchParams.get("origin")).toBe("https://app.example");
    expect(posterUrl(yt)).toBe("https://i.ytimg.com/vi/hTtlD-u4_HI/hqdefault.jpg");
    expect(embedUrl(ig)).toBe("https://www.instagram.com/reel/C1a2B3c4D5e/embed/");
    expect(posterUrl(ig)).toBeNull();
  });
});

describe("automatic reels", () => {
  const auto = (ref: string, published: string, sourceId: string): Reel => ({
    ...yt,
    id: `yt-${ref}`,
    ref,
    status: "auto",
    reviewer: null,
    reviewedAt: null,
    sourceId,
    published,
  });
  it("accepts auto reels only with a source channel", () => {
    expect(sanitizeReels({ items: [auto("AAAAAAAAAA1", "2026-11-01", "yt-x")] })).toHaveLength(1);
    expect(
      sanitizeReels({ items: [{ ...auto("AAAAAAAAAA1", "2026-11-01", "yt-x"), sourceId: null }] }),
    ).toHaveLength(0);
  });
  it("mixes channels newest first, one per channel in turn, without duplicates", () => {
    const a = [auto("AAAAAAAAAA1", "2026-11-01", "a"), auto("AAAAAAAAAA2", "2026-11-03", "a")];
    const b = [auto("BBBBBBBBBB1", "2026-11-02", "b")];
    expect(mixReels([a, b, a]).map((r) => r.ref)).toEqual(["AAAAAAAAAA2", "BBBBBBBBBB1", "AAAAAAAAAA1"]);
  });
  it("fetches and validates the API feed", async () => {
    const body = {
      schema: "reels-feed.v1",
      sources: [
        { id: "yt-a", channelId: "UCa", name: { ar: "أ", en: "A" }, category: "recitation" },
        { id: 1 },
      ],
      items: [auto("AAAAAAAAAA1", "2026-11-01", "yt-a"), yt],
    };
    const f = (async () => new Response(JSON.stringify(body))) as unknown as typeof fetch;
    const out = await fetchReelsFeed("https://api.example/", f, 5);
    expect(out.items.map((r) => r.ref)).toEqual(["AAAAAAAAAA1"]);
    expect(out.sources).toHaveLength(1);
    expect(out.at).toBe(5);
    const bad = (async () => new Response("{}", { status: 503 })) as unknown as typeof fetch;
    await expect(fetchReelsFeed("https://api.example", bad, 0)).rejects.toThrow();
    expect(sanitizeSources("x")).toEqual([]);
  });
});

describe("recitation only: groups, live, saved (owner 2026-11-27)", () => {
  it("ships the reciters by group and the two Haramain live streams", () => {
    expect(BUNDLED_SOURCES.length).toBeGreaterThan(40);
    expect(BUNDLED_SOURCES.every((s) => s.category === "recitation" && !!s.group)).toBe(true);
    expect(LIVE_CHANNELS.map((l) => l.place)).toEqual(["makkah", "madinah"]);
    const u = new URL(liveEmbedUrl(LIVE_CHANNELS[0]!));
    expect(u.pathname).toBe("/embed/live_stream");
    expect(u.searchParams.get("channel")).toBe(LIVE_CHANNELS[0]!.channelId);
  });
  it("tabs: Haramain = Makkah + Madinah imams; viewer channels only under «الكل»", () => {
    expect(inTab("makkah", "haramain")).toBe(true);
    expect(inTab("madinah", "haramain")).toBe(true);
    expect(inTab("golden", "haramain")).toBe(false);
    expect(inTab("golden", "golden")).toBe(true);
    expect(inTab(null, "all")).toBe(true);
    expect(inTab(null, "golden")).toBe(false);
  });
  it("saves and unsaves a recitation", () => {
    savedReelsStore.set([]);
    expect(toggleSaved(yt)).toBe(true);
    expect(savedReelsStore.get().map((r) => r.ref)).toEqual([yt.ref]);
    expect(toggleSaved(yt)).toBe(false);
    expect(savedReelsStore.get()).toEqual([]);
  });
});
