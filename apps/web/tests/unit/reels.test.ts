import { readRepoJson } from "../repo";
import { embedUrl, posterUrl, REELS, sanitizeReels, visibleReels, type Reel } from "@/lib/reels";

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
const pend: Reel = { ...yt, id: "yt-26dRG7OeL6Q", ref: "26dRG7OeL6Q", category: "lesson", status: "pending" };
const ig: Reel = {
  ...yt,
  id: "ig-C1a2B3c4D5e",
  platform: "instagram",
  ref: "C1a2B3c4D5e",
  url: "https://www.instagram.com/reel/C1a2B3c4D5e/",
  category: "admonition",
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
