// Copies shared schemas, tokens, fonts and split Quran content into the web app.
// Generated output (src/generated, public/fonts, public/data) is not hand-edited.
import { mkdirSync, copyFileSync, readFileSync, writeFileSync, rmSync } from "node:fs";
import { runInNewContext } from "node:vm";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const app = resolve(here, "..");
const repo = resolve(app, "../..");
const gen = join(app, "src/generated");
const pub = join(app, "public");

const readJson = (p) => JSON.parse(readFileSync(join(repo, p), "utf8"));
const writeJson = (p, v) => {
  mkdirSync(dirname(p), { recursive: true });
  writeFileSync(p, JSON.stringify(v));
};

rmSync(gen, { recursive: true, force: true });
rmSync(join(pub, "data"), { recursive: true, force: true });
mkdirSync(gen, { recursive: true });
mkdirSync(join(pub, "fonts"), { recursive: true });

// Muezzin collection (built by tools/adhan_catalog.py; the mobile asset is the one source).
writeJson(join(pub, "data/adhan-catalog.json"), readJson("apps/mobile/assets/content/adhan_catalog.json"));

const copies = {
  "packages/shared-schemas/cities.json": "cities.json",
  "packages/shared-schemas/prayer/methods.json": "methods.json",
  "packages/shared-schemas/geo/wmm2025.json": "wmm2025.json",
  "packages/shared-schemas/i18n/ar.json": "i18n-ar.json",
  "packages/shared-schemas/i18n/en.json": "i18n-en.json",
  "packages/shared-schemas/quran-render.json": "quran-render.json",
  "packages/shared-schemas/search-normalization.json": "search-normalization.json",
  "content/quran/dist/pages.v1.json": "pages.json",
  "packages/design-tokens/dist/tokens.css": "tokens.css",
  "packages/design-tokens/dist/tokens.ts": "tokens.ts",
  "packages/design-tokens/dist/icons.ts": "icons.ts",
  "packages/shared-schemas/audio/reciters.json": "reciters.json",
  "packages/shared-schemas/app-links.json": "app-links.json",
  "content/adhkar/dist/adhkar.v1.json": "adhkar.json",
  "content/adhkar/hisn.json": "hisn.json",
  "content/adhkar/hisn-sections.json": "hisn-sections.json",
  "content/adhkar/dist/adhkar-hadith.v1.json": "adhkar-hadith.json",
  "apps/mobile/assets/content/adhkar-audio.v1.json": "adhkar-audio.json",
  "apps/mobile/assets/content/asma.v1.json": "asma.json",
  "content/asma/dist/asma-audio.v1.json": "asma-audio.json",
  "content/zakat/dar-alifta.v1.json": "zakat.json",
  "content/reels/dist/reels.v1.json": "reels.json",
  "content/stories/dist/stories.v1.json": "stories.json",
  "content/kids/dist/kids.v1.json": "kids.json",
  "content/kids/dist/kids-learn.v1.json": "kids-learn.json",
};
for (const [from, to] of Object.entries(copies)) copyFileSync(join(repo, from), join(gen, to));

for (const f of [
  "KFGQPC-HAFS-Uthmanic-v22.ttf",
  "KFGQPC-HAFS-LICENSE.txt",
  "IBMPlexSansArabic-Regular.ttf",
  "IBMPlexSansArabic-SemiBold.ttf",
  "OFL-IBMPlexSansArabic.txt",
]) {
  copyFileSync(join(repo, "content/fonts", f), join(pub, "fonts", f));
}

const quran = readJson("content/quran/dist/quran.v1.json");
const meta = quran.surahs.map(({ n, nameAr, nameEn, translit, revelation, ayahCount }) => ({
  n,
  nameAr,
  nameEn,
  translit,
  revelation,
  ayahCount,
}));
writeJson(join(gen, "surah-meta.json"), meta);
writeJson(join(gen, "quran-info.json"), {
  version: quran.version,
  riwayah: quran.riwayah,
  numbering: quran.numbering,
  source: quran.source,
});
for (const s of quran.surahs) writeJson(join(pub, "data/en", `${s.n}.json`), s.en);
// Hizb quarters for the Quran index: the opening words of each quarter, copied
// verbatim from the canonical text (only the leading rub' al-hizb sign ۞ is dropped,
// the index shows the quarter number in its own badge).
const QUARTER_WORDS = 10;
const pagesData = readJson("content/quran/dist/pages.v1.json");
writeJson(
  join(gen, "quarters.json"),
  pagesData.quarters.map((q) => {
    const text = quran.surahs[q.start[0] - 1].ayahs[q.start[1] - 1].replace(/^\u06de\s*/, "");
    const words = text.split(" ");
    return { ...q, opening: words.slice(0, QUARTER_WORDS).join(" "), more: words.length > QUARTER_WORDS };
  }),
);
// Opening words of the first ayah of each Mushaf page (khatma wirds start on a page), copied verbatim from the
// canonical text, like the quarters above.
const PAGE_WORDS = 6;
writeJson(
  join(gen, "page-openings.json"),
  pagesData.pages.map((p) => {
    const words = quran.surahs[p.start[0] - 1].ayahs[p.start[1] - 1].replace(/^\u06de\s*/, "").split(" ");
    return words.slice(0, PAGE_WORDS).join(" ") + (words.length > PAGE_WORDS ? " …" : "");
  }),
);
// Arabic text for client-side search (loaded only by the search page).
writeJson(
  join(pub, "data/quran-text.json"),
  quran.surahs.map((s) => s.ayahs),
);
// 15-line Madinah Mushaf layout (word ranges into quran.v1.json); fetched once by the Mushaf reader and
// resolved against /data/quran-text.json on the device. The canonical text itself is never rewritten.
copyFileSync(join(repo, "content/quran/dist/mushaf-lines.v1.json"), join(pub, "data/mushaf-lines.json"));
// Tafsir al-Muyassar: one file per surah (an array, one entry per ayah), fetched on demand by the ayah panel
// and kept by the service worker once used (not precached). Entries are copied verbatim.
// Hadith books (Open-Hadith-Data, ODbL): book list in src/generated, text chunks served from /data/hadith/<book>/<k>.json.
// Al-Sha'rawi audio tafsir: lesson list (audio streamed per lesson), fetched by the /sharawi page.
copyFileSync(join(repo, "content/sharawi/dist/sharawi.v1.json"), join(pub, "data/sharawi.json"));
// Lesson series («سلاسل الدروس»): series and lesson list (audio streamed per lesson), fetched by the /lessons page
// and the Sha'rawi section. The name carries a number (see LESSONS_URL): browsers and older service workers keep
// a file by its name, so a new list under the old name was not seen (owner 2026-11-23). Raise both together.
copyFileSync(join(repo, "content/lessons/dist/lessons.v1.json"), join(pub, "data/lessons-6.json"));
// Sheikh Mohamed Ahmed Shabib: track list (audio streamed per track), fetched by the /shabib page.
copyFileSync(join(repo, "content/shabib/dist/shabib.v1.json"), join(pub, "data/shabib.json"));
// Ayah timings of the reciters recorded one file per surah, fetched by the player when such a reciter plays.
copyFileSync(
  join(repo, "packages/shared-schemas/audio/ayah-timings.json"),
  join(pub, "data/ayah-timings.json"),
);
// Nasheeds (same list as the mobile app, voice-only): munshid list with streamed/saved audio, fetched by /nasheeds.
copyFileSync(join(repo, "apps/mobile/assets/content/nasheeds.v2.json"), join(pub, "data/nasheeds.json"));
// Videos function (netlify/functions/videos.mjs): the trusted channels (feed) and the suggested ones (search ranking).
writeJson(
  join(gen, "reel-suggestions.json"),
  readJson("apps/mobile/assets/content/reel-suggestions.v1.json"),
);
writeJson(join(app, "netlify/lib/reel-sources.json"), {
  feed: readJson("content/reels/dist/reel-sources.v1.json").sources,
  suggested: readJson("apps/mobile/assets/content/reel-suggestions.v1.json").sources,
});
const hadith = readJson("content/hadith/dist/books.v1.json");
writeJson(join(gen, "hadith-books.json"), hadith);
for (const b of hadith.books) {
  for (let k = 0; k < b.chunks; k++) {
    const dest = join(pub, "data/hadith", b.id, `${k}.json`);
    mkdirSync(dirname(dest), { recursive: true });
    copyFileSync(join(repo, "content/hadith/dist", b.id, `${k}.json`), dest);
  }
  // Bukhari/Muslim (sunnah.com copy): sunnah.com numbers per entry + old al-Alamiyya number -> entry (bookmarks).
  if (b.refs) {
    for (const f of ["refs.json", "from-alamiyya.json"]) {
      copyFileSync(join(repo, "content/hadith/dist", b.id, f), join(pub, "data/hadith", b.id, f));
    }
  }
}
// Simplified explanations (quoted from a published hadith encyclopedia, same file as the app's
// assets/hadith/explained.v1.json), split per book: /data/hadith/explained/<book>.json = { map: {n: id}, entries }.
{
  const ex = readJson("content/hadith/dist/explained.v1.json");
  const perBook = {};
  for (const [key, id] of Object.entries(ex.map)) {
    const [book, n] = key.split(":");
    const b = (perBook[book] ??= { map: {}, entries: {} });
    b.map[n] = id;
    b.entries[id] = ex.entries[id];
  }
  mkdirSync(join(pub, "data/hadith/explained"), { recursive: true });
  for (const [book, b] of Object.entries(perBook)) {
    writeFileSync(join(pub, "data/hadith/explained", `${book}.json`), JSON.stringify(b));
  }
}

const tafsir = readJson("content/tafsir/dist/muyassar.v1.json");
if (
  tafsir.schema !== "tafsir.v1" ||
  tafsir.id !== "muyassar" ||
  tafsir.surahs.length !== quran.surahs.length
) {
  throw new Error("muyassar.v1.json: unexpected schema");
}
tafsir.surahs.forEach((entries, i) => {
  const s = quran.surahs[i];
  if (entries.length !== s.ayahs.length || !entries.every((e) => typeof e === "string" && e.length > 0)) {
    throw new Error(`muyassar.v1.json: surah ${s.n} does not match the Quran's ayah count`);
  }
  writeJson(join(pub, "data/tafsir/muyassar", `${s.n}.json`), entries);
});
// More tafsir books (owner 2026-11-20): al-Sa'di, Ibn Kathir, al-Tabari, al-Baghawi, al-Qurtubi, built verbatim by
// tools/tafsir_books.py. One file per surah (/data/tafsir/<book>/<n>.json: [[from, to, text, notes?], ...], each
// section covering the ayahs the book explains together) plus the whole book gzipped (/data/tafsir/<book>/book.v1.dat)
// for search and for the app's offline download. Al-Muyassar gets the same whole-book file (one section per ayah).
{
  const { gunzipSync, gzipSync } = await import("node:zlib");
  const books = {};
  for (const id of ["saadi", "ibn-kathir", "tabari", "baghawi", "qurtubi"]) {
    const raw = readFileSync(join(repo, "content/tafsir/dist", `${id}.v1.json.gz`));
    const book = JSON.parse(gunzipSync(raw).toString("utf8"));
    if (book.schema !== "tafsir-book.v1" || book.id !== id || book.surahs.length !== quran.surahs.length) {
      throw new Error(`${id}.v1.json.gz: unexpected schema`);
    }
    book.surahs.forEach((secs, i) => {
      const n = quran.surahs[i].ayahs.length;
      let next = 1;
      for (const [from, to, text] of secs) {
        if (from !== next || to < from || typeof text !== "string" || !text) throw new Error(`${id}: surah ${i + 1} sections`);
        next = to + 1;
      }
      if (next !== n + 1) throw new Error(`${id}: surah ${i + 1} does not cover every ayah`);
      writeJson(join(pub, "data/tafsir", id, `${i + 1}.json`), secs);
    });
    writeFileSync(join(pub, "data/tafsir", id, "book.v1.dat"), raw);
    books[id] = { bytes: raw.length };
  }
  const muy = {
    schema: "tafsir-book.v1",
    id: "muyassar",
    nameAr: tafsir.nameAr,
    surahs: tafsir.surahs.map((entries) => entries.map((text, a) => [a + 1, a + 1, text])),
  };
  const muyRaw = gzipSync(Buffer.from(JSON.stringify(muy)), { level: 9 });
  writeFileSync(join(pub, "data/tafsir/muyassar/book.v1.dat"), muyRaw);
  books.muyassar = { bytes: muyRaw.length };
  writeJson(join(gen, "tafsir-books.json"), books);
  // I'rab, sarf, balagha and fawa'id («الجدول في إعراب القرآن وصرفه وبيانه»), tools/irab_build.py, verbatim:
  // /data/irab/jadwal/<n>.json = [[from, to, irab, sarf, balagha, fawaid], ...].
  const irab = JSON.parse(gunzipSync(readFileSync(join(repo, "content/irab/dist/jadwal.v1.json.gz"))).toString("utf8"));
  if (irab.schema !== "irab.v1" || irab.surahs.length !== quran.surahs.length) throw new Error("jadwal.v1: unexpected schema");
  irab.surahs.forEach((secs, i) => {
    const end = secs.reduce((next, s) => {
      if (s[0] !== next || s[1] < s[0] || s.length !== 6) throw new Error(`jadwal: surah ${i + 1} sections`);
      return s[1] + 1;
    }, 1);
    if (end !== quran.surahs[i].ayahs.length + 1) throw new Error(`jadwal: surah ${i + 1} does not cover every ayah`);
    writeJson(join(pub, "data/irab/jadwal", `${i + 1}.json`), secs);
  });
}
// Word meanings («السراج في بيان غريب القرآن»), one file per surah: [[word, meaning], ...] per ayah, verbatim.
const meanings = readJson("content/word-meanings/dist/siraj.v1.json");
if (
  meanings.schema !== "word-meanings.v1" ||
  meanings.id !== "siraj" ||
  meanings.surahs.length !== quran.surahs.length
) {
  throw new Error("siraj.v1.json: unexpected schema");
}
meanings.surahs.forEach((entries, i) => {
  const s = quran.surahs[i];
  if (entries.length !== s.ayahs.length) {
    throw new Error(`siraj.v1.json: surah ${s.n} does not match the Quran's ayah count`);
  }
  writeJson(join(pub, "data/meanings/siraj", `${s.n}.json`), entries);
});
// «عن السورة وأسباب النزول» (the app's surah card), one file per surah, verbatim from the app's asset.
const surahInfoAll = readJson("apps/mobile/assets/content/surah-info.v1.json");
if (!Array.isArray(surahInfoAll.surahs) || surahInfoAll.surahs.length !== quran.surahs.length) {
  throw new Error("surah-info.v1.json: unexpected shape");
}
for (const info of surahInfoAll.surahs) writeJson(join(pub, "data/surah-info", `${info.n}.json`), info);
writeJson(
  join(gen, "hajj.json"),
  extractHajj(readFileSync(join(repo, "content/pilgrimage/source-hajj.js"), "utf8")),
);
// Official Hajj guide text (owner 2026-11-14): copied verbatim, checked for shape only.
const dalil = JSON.parse(readFileSync(join(repo, "content/pilgrimage/dalil-hajj.v1.json"), "utf8"));
if (
  dalil.schema !== 1 ||
  dalil.types?.length !== 3 ||
  dalil.umrah?.length !== 4 ||
  dalil.hajj?.length !== 9
) {
  throw new Error("dalil-hajj.v1.json: unexpected schema");
}
writeJson(join(gen, "dalil-hajj.json"), dalil);
// What is said at each place of Umrah and Hajj (owner 2026-11-15): references into Hisn al-Muslim and the
// Quran, resolved here; a 'part' must be an exact substring of its chapter, or the build fails.
{
  const map = JSON.parse(readFileSync(join(repo, "content/pilgrimage/step-duas.v1.json"), "utf8"));
  const hisnBook = JSON.parse(readFileSync(join(repo, "content/adhkar/hisn.json"), "utf8"));
  const chapter = (id) => {
    const c = hisnBook[id - 1];
    if (!c) throw new Error(`step-duas: no Hisn chapter ${id}`);
    return { title: c[0], text: c[1].join("\n") };
  };
  const places = {};
  for (const [key, groups] of Object.entries(map.places)) {
    places[key] = groups.map((g) => ({
      title: chapter(g.hisn).title,
      say: g.say.map((x) => {
        if (x.quran) {
          const [s, a] = x.quran;
          const text = quran.surahs[s - 1]?.ayahs[a - 1];
          if (!text) throw new Error(`step-duas: no ayah ${s}:${a}`);
          return { kind: x.kind, quran: [s, a], text };
        }
        const full = chapter(x.hisn).text;
        if (x.part && !full.includes(x.part))
          throw new Error(`step-duas: part not in Hisn ${x.hisn}: ${x.part}`);
        return { kind: x.kind, text: x.part ?? full };
      }),
    }));
  }
  writeJson(join(gen, "hajj-duas.json"), { places, rules: map.rules });
}
// The sourced Hajj & Umrah guide (owner 2026-11-16): every text is cut from its published source by
// content/pilgrimage/build-guide.mjs, and the 3D pictures are drawn by build-scenes.mjs. Copied as is.
{
  const guide = readJson("content/pilgrimage/dist/hajj-guide.v2.json");
  if (guide.schema !== "hajj-guide.v2") throw new Error("hajj-guide.v2.json: unexpected schema");
  const scenes = readJson("content/pilgrimage/dist/hajj-scenes.v1.json");
  if (scenes.schema !== "hajj-scenes.v1") throw new Error("hajj-scenes.v1.json: unexpected schema");
  writeJson(join(gen, "hajj-guide.json"), guide);
  writeJson(join(gen, "hajj-scenes.json"), scenes);
  writeJson(join(gen, "scene-roles.json"), readJson("content/pilgrimage/scene-roles.v1.json"));
}
console.log(`content prepared: ${meta.length} surahs`);

/**
 * The Hajj/Umrah guide exists only as the prototype's source file. Its data constants are evaluated in an
 * empty VM context (no globals), and the few sentences that live inside the view functions are taken by
 * position; the build fails if the source no longer has the expected shape.
 */
function extractHajj(src) {
  const head = src.slice(0, src.indexOf("function hijriMonthDay"));
  const names = ["TALBIYA", "UMRAH", "HAJJ_DAYS", "HAJJ_TYPES", "MIQAT", "IHRAM_NO", "MADINAH"];
  const data = runInNewContext(`${head}\n({${names.join(",")}})`, Object.create(null), { timeout: 1000 });
  const strings = (fn) => {
    const i = src.indexOf(`function ${fn}(`);
    if (i < 0) throw new Error(`source-hajj.js: ${fn} missing`);
    const j = src.indexOf("\nfunction", i + 5);
    return [...src.slice(i, j < 0 ? undefined : j).matchAll(/"([^"]*[\u0621-\u064A][^"]*)"/g)].map(
      (m) => m[1],
    );
  };
  const u = strings("umrahView");
  const h = strings("hajjView");
  const r = strings("ihramView");
  const m = strings("madinahCard");
  if (u.length !== 2 || h.length !== 4 || r.length !== 6 || m.length !== 1)
    throw new Error(`source-hajj.js changed shape: ${[u.length, h.length, r.length, m.length]}`);
  const step = (x) => ({ title: x.t ?? x.d, points: x.p, dhikr: x.z ?? null, tool: x.tool ?? null });
  return {
    reviewStatus: "pending",
    talbiya: { title: r[4], text: data.TALBIYA },
    umrah: { intro: u[0], steps: data.UMRAH.map(step) },
    hajj: {
      typesTitle: h[0],
      types: data.HAJJ_TYPES.map(([name, body]) => ({ name, body })),
      days: data.HAJJ_DAYS.map(step),
      pillars: { title: h[2], body: h[3] },
    },
    ihram: {
      miqatTitle: r[0],
      miqat: data.MIQAT.map(([name, body]) => ({ name, body })),
      miqatNote: r[1],
      prohibitionsTitle: r[2],
      prohibitions: data.IHRAM_NO,
      prohibitionsNote: r[3],
    },
    madinah: { title: m[0], points: data.MADINAH },
  };
}

// «شكل المصحف المطبوع»: one small layout file per page (glyph codes of the King Fahd Complex page fonts + the
// ayah of every word; tools/mushaf_printed_build.py). The basmala line uses the canonical text of 1:1.
{
  const printed = readJson("content/quran/dist/mushaf-printed.v1.json");
  const basmala = readJson("content/quran/dist/quran.v1.json").surahs[0].ayahs[0];
  printed.pages.forEach((lines, i) => writeJson(join(pub, `data/printed/${i + 1}.json`), { lines, basmala }));
}
