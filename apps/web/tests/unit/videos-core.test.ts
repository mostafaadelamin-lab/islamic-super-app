import {
  allowedChannel,
  allowedFeedTitle,
  allowedVideo,
  buildFeed,
  isBlocked,
  looksIslamic,
  parseChannelVideos,
  parseFeed,
  parseVideoSearch,
  searchVideos,
} from "../../netlify/lib/videos-core.mjs";
import { addToHistory, HISTORY_MAX, sanitizeHits } from "@/lib/videos";

const CH = "UCYuUcfXvsHapABTcPRWCEoQ";
const OTHER = "UCaaaaaaaaaaaaaaaaaaaaaa";

const feedXml = (ids: string[], shorts = true): string =>
  `<feed>${ids
    .map(
      (id, i) =>
        `<entry><yt:videoId>${id}</yt:videoId><title>تلاوة &amp; خشوع ${i}</title><link rel="alternate" href="https://www.youtube.com/${shorts ? "shorts" : "watch?v="}/${id}"/><published>2026-11-1${i}T00:00:00+00:00</published></entry>`,
    )
    .join("")}</feed>`;

const resultsPage = (rows: { id: string; title: string; channel: string; cid: string }[]): string =>
  `var ytInitialData = {"contents":[${rows
    .map(
      (r) =>
        `{"videoRenderer":{"videoId":"${r.id}","thumbnail":{},"title":{"runs":[{"text":"${r.title}"}]},"ownerText":{"runs":[{"text":"${r.channel}","navigationEndpoint":{"browseEndpoint":{"browseId":"${r.cid}"}}}]},"lengthText":{"simpleText":"12:34"}}}`,
    )
    .join(",")}]};`;

describe("videos engine (website function)", () => {
  it("knows Islamic titles and blocks music and entertainment", () => {
    expect(looksIslamic("سورة البقرة كاملة بصوت ياسر الدوسري")).toBe(true);
    expect(looksIslamic("بالقرآن نحيا")).toBe(true);
    expect(looksIslamic("Beautiful Quran recitation")).toBe(true);
    expect(looksIslamic("مدرسة المشاغبين")).toBe(false); // "درس" inside another word does not count
    expect(isBlocked("اغنية جديدة 2026")).toBe(true);
    expect(isBlocked("Islamic song remix")).toBe(true);
    expect(isBlocked("موعظة مؤثرة")).toBe(false);
  });

  it("recitation only: trusted reciters pass, others need a recitation title, never lessons", () => {
    const trusted = new Set([CH]);
    expect(allowedVideo({ title: "vlog", channel: "x", channelId: CH }, trusted)).toBe(true);
    expect(allowedVideo({ title: "تلاوة سورة الكهف", channel: "x", channelId: OTHER }, trusted)).toBe(true);
    expect(allowedVideo({ title: "تفسير سورة الكهف", channel: "x", channelId: OTHER }, trusted)).toBe(false);
    expect(allowedVideo({ title: "درس عن الصبر", channel: "x", channelId: CH }, trusted)).toBe(false);
    expect(allowedVideo({ title: "my day vlog", channel: "x", channelId: OTHER }, trusted)).toBe(false);
    expect(allowedVideo({ title: "اغنية عن الله", channel: "x", channelId: CH }, trusted)).toBe(false);
    expect(
      allowedVideo({ title: "تلاوة سورة يس", channel: "الشيخ محمد حسان", channelId: OTHER }, trusted),
    ).toBe(false);
  });

  it("feed titles and channel names (same rules as the app)", () => {
    expect(allowedFeedTitle("سورة القصص كاملة")).toBe(true);
    expect(allowedFeedTitle("سورة الشرح")).toBe(true);
    expect(allowedFeedTitle("صلاة العشاء من المسجد الحرام")).toBe(true);
    expect(allowedFeedTitle("خطبة الجمعة من المسجد النبوي")).toBe(false);
    expect(allowedFeedTitle("نشيد جميل")).toBe(false);
    expect(allowedChannel("تلاوات خاشعة")).toBe(true);
    expect(allowedChannel("دروس ومواعظ")).toBe(false);
  });

  it("parses YouTube feeds and results pages", () => {
    expect(parseFeed(feedXml(["abcdefghijk"]))).toEqual([
      { ref: "abcdefghijk", title: "تلاوة & خشوع 0", published: "2026-11-10T00:00:00+00:00" },
    ]);
    expect(parseFeed(feedXml(["abcdefghijk"], false), true)).toEqual([]);
    const hits = parseVideoSearch(
      resultsPage([{ id: "abcdefghijk", title: "درس \\u0645", channel: "قناة", cid: CH }]),
    );
    expect(hits).toEqual([
      { ref: "abcdefghijk", title: "درس م", channel: "قناة", channelId: CH, duration: "12:34" },
    ]);
  });

  it("builds the trusted channels' feed in the API's shape", async () => {
    const get = vi.fn(async (u: string) =>
      u.includes("UUSH") ? feedXml(["abcdefghijk", "bcdefghijkl"]) : null,
    );
    const body = await buildFeed(
      [{ id: `yt-${CH}`, channelId: CH, name: { ar: "الشيخ", en: "Sheikh" }, category: "recitation" }],
      get,
    );
    expect(body.schema).toBe("reels-feed.v1");
    expect(body.items.map((r: { ref: string }) => r.ref)).toEqual(["bcdefghijkl", "abcdefghijk"]);
    expect(body.items[0]).toMatchObject({ status: "auto", sourceId: `yt-${CH}`, category: "recitation" });
  });

  it("search drops non-Islamic results, puts trusted channels first, and refuses blocked queries", async () => {
    const page = resultsPage([
      { id: "aaaaaaaaaaa", title: "تلاوة خاشعة", channel: "قناة عامة", cid: OTHER },
      { id: "bbbbbbbbbbb", title: "مقلب مضحك", channel: "ترفيه", cid: OTHER },
      { id: "ccccccccccc", title: "Short clip", channel: "الدوسري", cid: CH },
    ]);
    const get = vi.fn(async () => page);
    const res = await searchVideos("تلاوة", get, new Set([CH]));
    expect(res.items.map((h: { ref: string }) => h.ref)).toEqual(["ccccccccccc", "aaaaaaaaaaa"]);
    expect(res.items[0]?.trusted).toBe(true);
    expect((await searchVideos("اغاني", get, new Set())).items).toEqual([]);
    expect(get).toHaveBeenCalledTimes(1);
    await expect(searchVideos("درس", async () => null, new Set())).rejects.toThrow();
  });
});

describe("feed fallback when YouTube's feeds fail", () => {
  const lockup =
    '{"lockupViewModel":{"contentImage":{"thumbnailViewModel":{"image":{"sources":[{"url":"https://i.ytimg.com/vi/abcdefghijk/hq720.jpg"}]}}},"metadata":{"lockupMetadataViewModel":{"title":{"content":"سورة الكهف كاملة"}}}}}';
  it("reads the channel's Videos tab", async () => {
    expect(parseChannelVideos(`x ${lockup} y`)).toEqual([
      { ref: "abcdefghijk", title: "سورة الكهف كاملة", published: null },
    ]);
    const get = vi.fn(async (u: string) => (u.endsWith("/videos?hl=ar") ? `x ${lockup}` : null));
    const body = await buildFeed(
      [{ id: `yt-${CH}`, channelId: CH, name: { ar: "الشيخ", en: "Sheikh" }, category: "recitation" }],
      get,
    );
    expect(body.items.map((r: { ref: string }) => r.ref)).toEqual(["abcdefghijk"]);
  });
});

describe("video search client", () => {
  it("keeps the newest search first, without duplicates, at most HISTORY_MAX", () => {
    let h: string[] = [];
    for (let i = 0; i < HISTORY_MAX + 5; i++) h = addToHistory(h, `q${i}`);
    expect(h).toHaveLength(HISTORY_MAX);
    expect(addToHistory(["a", "B"], " b ")).toEqual(["b", "a"]);
    expect(addToHistory(["a"], "  ")).toEqual(["a"]);
  });
  it("drops malformed hits", () => {
    expect(
      sanitizeHits({
        items: [
          { ref: "bad", title: "x" },
          { ref: "abcdefghijk", title: "ok", trusted: true },
        ],
      }),
    ).toEqual([
      { ref: "abcdefghijk", title: "ok", channel: null, channelId: null, duration: null, trusted: true },
    ]);
  });
});
