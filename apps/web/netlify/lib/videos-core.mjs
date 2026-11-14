/**
 * Islamic videos engine for the website (runs as a Netlify Function: browsers cannot read YouTube directly).
 * Same rules as the mobile app (apps/mobile/lib/domain/video_search.dart):
 *  - the feed = newest videos of the trusted channels the owner approved (content/reels/sources.json);
 *  - search = YouTube video search, keeping only trusted channels or titles that are clearly Quran recitation,
 *    religious lessons or advice/admonitions, and never titles with music/songs/entertainment words.
 * No API key and no account: public feeds and the public results page only.
 */

const VIDEO_ID = /^[A-Za-z0-9_-]{11}$/;
const CHANNEL_ID = /^UC[A-Za-z0-9_-]{22}$/;
export const PER_SOURCE = 15;

/** Lower-case, no tashkeel/tatweel, one form of alef/yaa/taa marbuta: so "القرآن" matches "القران". */
export function normalize(s) {
  return String(s)
    .toLowerCase()
    .replace(/[ً-ٰٟـ]/g, "")
    .replace(/[أإآٱ]/g, "ا")
    .replace(/ى/g, "ي")
    .replace(/ة/g, "ه")
    .replace(/\s+/g, " ")
    .trim();
}

/** Words that show a video is Quran recitation, a religious lesson or advice (normalized forms). */
export const ISLAMIC_WORDS = [
  "قران",
  "سوره",
  "تلاوه",
  "تلاوات",
  "ترتيل",
  "تجويد",
  "مصحف",
  "ايات",
  "قارئ",
  "القارئ",
  "مقرئ",
  "الشيخ",
  "شيخ",
  "مشايخ",
  "درس",
  "دروس",
  "محاضره",
  "خطبه",
  "موعظه",
  "مواعظ",
  "نصيحه",
  "نصائح",
  "تذكير",
  "رقائق",
  "تفسير",
  "حديث",
  "احاديث",
  "السنه",
  "النبي",
  "الرسول",
  "صلي الله عليه وسلم",
  "سيره",
  "الصحابه",
  "فقه",
  "فتوي",
  "الله",
  "اسلام",
  "اسلامي",
  "اسلاميه",
  "الايمان",
  "التوبه",
  "الجنه",
  "الاخره",
  "الصلاه",
  "الدعاء",
  "دعاء",
  "اذكار",
  "رمضان",
  "الحج",
  "العمره",
  "الزكاه",
  "التوحيد",
  "العقيده",
  "القيامه",
  "استغفار",
  "الصبر",
  "quran",
  "koran",
  "recitation",
  "surah",
  "surat",
  "tilawat",
  "tajweed",
  "islam",
  "islamic",
  "muslim",
  "sheikh",
  "shaykh",
  "tafsir",
  "hadith",
  "prophet",
  "sunnah",
  "allah",
  "dua",
  "lecture",
  "khutbah",
  "reminder",
  "imam",
];

/** Never shown, even from a search the viewer typed (music, entertainment, mockery). */
export const BLOCKED_WORDS = [
  "اغنيه",
  "اغاني",
  "اغنية",
  "موسيقي",
  "موسيقى",
  "مهرجان",
  "كليب",
  "رقص",
  "فيلم",
  "افلام",
  "مسلسل",
  "حلقه مسلسل",
  "مقلب",
  "مقالب",
  "ضحك",
  "كوميدي",
  "نكت",
  "العاب",
  "لعبه",
  "ريمكس",
  "شيله",
  "غناء",
  "طرب",
  "ديسكو",
  "تيك توك ترند",
  "song",
  "songs",
  "music",
  "remix",
  "dance",
  "dancing",
  "movie",
  "film",
  "trailer",
  "prank",
  "funny",
  "comedy",
  "gaming",
  "gameplay",
  "lyrics",
  "karaoke",
  "beat",
  "rap",
  "concert",
  "dj ",
];

/** Arabic words may carry a joined prefix (و، ف، ب، ل، ال، وال، بال، فال، لل). */
const AR_PREFIX = /^(?:و|ف|ب|ل|ك)?(?:ال|ل)?/;
const hasWord = (text, words) => {
  const t = normalize(text);
  const tokens = new Set(
    t
      .split(/[^\p{L}\p{N}]+/u)
      .filter(Boolean)
      .flatMap((w) => [w, w.replace(AR_PREFIX, "")]),
  );
  return words.some((w) => {
    const n = normalize(w);
    if (n.includes(" ")) return ` ${t} `.includes(` ${n} `) || t.includes(n);
    return tokens.has(n) || tokens.has(n.replace(AR_PREFIX, ""));
  });
};

export const isBlocked = (text) => hasWord(text, BLOCKED_WORDS);
export const looksIslamic = (text) => hasWord(text, ISLAMIC_WORDS);

/** A search result may be shown: never a blocked title; trusted channels always; others only clearly Islamic. */
export function allowedVideo(hit, trustedChannelIds) {
  if (isBlocked(hit.title) || isBlocked(hit.channel ?? "")) return false;
  if (hit.channelId && trustedChannelIds.has(hit.channelId)) return true;
  return looksIslamic(hit.title) || looksIslamic(hit.channel ?? "");
}

export const shortsFeed = (cid) => `https://www.youtube.com/feeds/videos.xml?playlist_id=UUSH${cid.slice(2)}`;
export const channelFeed = (cid) => `https://www.youtube.com/feeds/videos.xml?channel_id=${cid}`;
export const channelVideosPage = (cid) => `https://www.youtube.com/channel/${cid}/videos?hl=ar`;
export const handlePage = (h) => `https://www.youtube.com/@${encodeURIComponent(h)}`;
export const searchPage = (q) =>
  `https://www.youtube.com/results?${new URLSearchParams({ search_query: q, sp: "EgIQAQ==", hl: "ar" })}`;

const decodeXml = (s) =>
  s
    .replace(/<!\[CDATA\[([\s\S]*?)\]\]>/g, "$1")
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/&quot;/g, '"')
    .replace(/&#39;|&apos;/g, "'")
    .replace(/&#(\d+);/g, (_, n) => String.fromCodePoint(Number(n)))
    .replace(/&amp;/g, "&");

/** Entries of a YouTube Atom feed. */
export function parseFeed(xml, shortsOnly = false) {
  const out = [];
  for (const m of String(xml).matchAll(/<entry>([\s\S]*?)<\/entry>/g)) {
    const e = m[1];
    const vid = (e.match(/<yt:videoId>([^<]+)<\/yt:videoId>/) ?? [])[1]?.trim() ?? "";
    const title = decodeXml((e.match(/<title>([\s\S]*?)<\/title>/) ?? [])[1] ?? "").trim();
    const href = (e.match(/<link[^>]*href="([^"]+)"/) ?? [])[1] ?? "";
    const published = (e.match(/<published>([^<]+)<\/published>/) ?? [])[1]?.trim() ?? null;
    if (!VIDEO_ID.test(vid) || !title || (shortsOnly && !href.includes("/shorts/"))) continue;
    out.push({ ref: vid, title, published });
  }
  return out;
}

const ID_ON_PAGE = [
  /<link rel="canonical" href="https:\/\/www\.youtube\.com\/channel\/(UC[A-Za-z0-9_-]{22})"/,
  /<meta itemprop="identifier" content="(UC[A-Za-z0-9_-]{22})"/,
  /"externalId":"(UC[A-Za-z0-9_-]{22})"/,
  /"browseId":"(UC[A-Za-z0-9_-]{22})"/,
];
export function channelIdFromPage(html) {
  for (const rx of ID_ON_PAGE) {
    const m = String(html).match(rx);
    if (m) return m[1];
  }
  return null;
}

const jsonString = (raw) => {
  try {
    return JSON.parse(`"${raw}"`);
  } catch {
    return raw;
  }
};

/** Videos on YouTube's results page (the page embeds its data as JSON; no API key needed). */
export function parseVideoSearch(html, max = 30) {
  const page = String(html);
  const out = [];
  const seen = new Set();
  const re = /"videoRenderer":\{"videoId":"([A-Za-z0-9_-]{11})"/g;
  let m;
  while ((m = re.exec(page)) && out.length < max) {
    const id = m[1];
    if (seen.has(id)) continue;
    const chunk = page.slice(m.index, m.index + 8000);
    const title =
      chunk.match(/"title":\{"runs":\[\{"text":"((?:[^"\\]|\\.)*)"/) ??
      chunk.match(/"title":\{"simpleText":"((?:[^"\\]|\\.)*)"/);
    if (!title) continue;
    const owner = chunk.match(
      /"(?:ownerText|longBylineText)":\{"runs":\[\{"text":"((?:[^"\\]|\\.)*)"[\s\S]{0,600}?"browseId":"(UC[A-Za-z0-9_-]{22})"/,
    );
    const length = chunk.match(/"lengthText":\{[\s\S]{0,400}?"simpleText":"([0-9:]+)"/);
    seen.add(id);
    out.push({
      ref: id,
      title: jsonString(title[1]),
      channel: owner ? jsonString(owner[1]) : null,
      channelId: owner ? owner[2] : null,
      duration: length ? length[1] : null,
    });
  }
  return out;
}

/**
 * Videos tab of a channel page (newest first). YouTube's public feeds sometimes fail (404/500, seen
 * 2026-11-13), so the feed falls back to this page; it uses the "lockupViewModel" layout.
 */
export function parseChannelVideos(html, max = 30) {
  const page = String(html);
  const out = [];
  const seen = new Set();
  const re =
    /"lockupViewModel":\{"contentImage":\{"thumbnailViewModel":\{"image":\{"sources":\[\{"url":"https:\/\/i\.ytimg\.com\/vi\/([A-Za-z0-9_-]{11})\//g;
  let m;
  while ((m = re.exec(page)) && out.length < max) {
    const id = m[1];
    if (seen.has(id)) continue;
    const title = page.slice(m.index, m.index + 12000).match(/"title":\{"content":"((?:[^"\\]|\\.)*)"/);
    if (!title) continue;
    seen.add(id);
    out.push({ ref: id, title: jsonString(title[1]), published: null });
  }
  return out;
}

/** Each channel newest first, then one per channel in turn; duplicates dropped. */
export function mix(perSource) {
  const queues = perSource
    .filter((q) => q.length > 0)
    .map((q) => [...q].sort((a, b) => (b.published ?? "").localeCompare(a.published ?? "")));
  const seen = new Set();
  const out = [];
  const longest = Math.max(0, ...queues.map((q) => q.length));
  for (let i = 0; i < longest; i++) {
    for (const q of queues) {
      const r = q[i];
      if (r && !seen.has(r.id)) {
        seen.add(r.id);
        out.push(r);
      }
    }
  }
  return out;
}

/** Shorts first; else the channel feed (Shorts entries, else every upload). Null when unreachable. */
export async function fetchSource(cid, get) {
  const shorts = await get(shortsFeed(cid));
  const fromShorts = shorts ? parseFeed(shorts) : [];
  if (fromShorts.length) return fromShorts;
  const all = await get(channelFeed(cid));
  const fromFeed = all == null ? [] : parseFeed(all, true).length ? parseFeed(all, true) : parseFeed(all);
  if (fromFeed.length) return fromFeed;
  const page = await get(channelVideosPage(cid));
  if (page == null) return shorts == null && all == null ? null : [];
  return parseChannelVideos(page);
}

const toReel = (src, r) => ({
  id: `yt-${r.ref}`,
  platform: "youtube",
  ref: r.ref,
  url: `https://www.youtube.com/watch?v=${r.ref}`,
  title: { ar: r.title, en: r.title },
  speaker: src.name,
  category: src.category,
  source: null,
  status: "auto",
  reviewer: null,
  reviewedAt: null,
  sourceId: src.id,
  published: r.published ?? null,
});

/** GET /api/v1/reels/feed: same shape as the API server's endpoint (schema reels-feed.v1). */
export async function buildFeed(sources, get) {
  const lists = await Promise.all(
    sources.map(async (s) => {
      let cid = s.channelId;
      if (!cid && s.handle) {
        const page = await get(handlePage(s.handle));
        cid = page ? channelIdFromPage(page) : null;
      }
      if (!cid || !CHANNEL_ID.test(cid)) return [];
      const items = (await fetchSource(cid, get)) ?? [];
      return items.slice(0, PER_SOURCE).map((r) => toReel(s, r));
    }),
  );
  return {
    schema: "reels-feed.v1",
    sources: sources.map(({ id, channelId, handle, name, category }) => ({
      id,
      channelId,
      handle,
      name,
      category,
    })),
    items: mix(lists),
  };
}

/** GET /api/videos/search?q=…: Islamic videos only (see allowedVideo); trusted channels first. */
export async function searchVideos(query, get, trustedChannelIds) {
  const q = String(query ?? "")
    .trim()
    .slice(0, 120);
  if (!q || isBlocked(q)) return { schema: "video-search.v1", query: q, items: [] };
  const page = await get(searchPage(q));
  if (page == null) throw new Error("youtube unreachable");
  const hits = parseVideoSearch(page).filter((h) => allowedVideo(h, trustedChannelIds));
  const trusted = (h) => (h.channelId && trustedChannelIds.has(h.channelId) ? 0 : 1);
  hits.sort((a, b) => trusted(a) - trusted(b));
  return {
    schema: "video-search.v1",
    query: q,
    items: hits.map((h) => ({ ...h, trusted: trusted(h) === 0 })),
  };
}

/** Channels on YouTube's channel-search page (same parsing as the app's ReelsFeed.parseChannelSearch). */
export function parseChannelSearch(html, max = 15) {
  const out = [];
  const seen = new Set();
  const re =
    /"channelRenderer":\{"channelId":"(UC[A-Za-z0-9_-]{22})","title":\{"simpleText":"((?:[^"\\]|\\.)*)"/g;
  let m;
  while ((m = re.exec(html)) && out.length < max) {
    if (seen.has(m[1])) continue;
    seen.add(m[1]);
    const after = html.slice(re.lastIndex, re.lastIndex + 4000);
    const subs = /"subscriberCountText":\{[^}]*?"simpleText":"([^"]+)"/.exec(after);
    out.push({ id: m[1], title: jsonString(m[2]), subs: subs ? jsonString(subs[1]) : null });
  }
  return out;
}

export const channelSearchPage = (q) =>
  `https://www.youtube.com/results?${new URLSearchParams({ search_query: q, sp: "EgIQAg==", hl: "ar" }).toString()}`;

/** GET /api/channels/search?q=…: channels the viewer can add to their videos (as in the app). */
export async function searchChannels(query, get) {
  const q = String(query ?? "")
    .trim()
    .slice(0, 120);
  if (!q || isBlocked(q)) return { schema: "channel-search.v1", query: q, items: [] };
  const page = await get(channelSearchPage(q));
  if (page == null) throw new Error("youtube unreachable");
  return { schema: "channel-search.v1", query: q, items: parseChannelSearch(page) };
}

/** GET /api/v1/reels/channel?id=UC…: one channel the viewer added (same reel shape as the feed). */
export async function channelReels(cid, get) {
  if (!CHANNEL_ID.test(String(cid ?? ""))) return null;
  const src = { id: `yt-${cid}`, channelId: cid, name: { ar: "", en: "" }, category: "lesson" };
  const feed = await buildFeed([src], get);
  return { schema: "reels-channel.v1", channelId: cid, items: feed.items };
}
