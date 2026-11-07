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

const copies = {
  "packages/shared-schemas/cities.json": "cities.json",
  "packages/shared-schemas/prayer/methods.json": "methods.json",
  "packages/shared-schemas/i18n/ar.json": "i18n-ar.json",
  "packages/shared-schemas/i18n/en.json": "i18n-en.json",
  "packages/shared-schemas/quran-render.json": "quran-render.json",
  "packages/shared-schemas/search-normalization.json": "search-normalization.json",
  "content/quran/dist/pages.v1.json": "pages.json",
  "packages/design-tokens/dist/tokens.css": "tokens.css",
  "packages/design-tokens/dist/tokens.ts": "tokens.ts",
  "packages/shared-schemas/audio/reciters.json": "reciters.json",
  "content/adhkar/dist/adhkar.v1.json": "adhkar.json",
  "content/adhkar/hisn.json": "hisn.json",
};
for (const [from, to] of Object.entries(copies)) copyFileSync(join(repo, from), join(gen, to));

for (const f of [
  "AmiriQuran-Regular.ttf",
  "IBMPlexSansArabic-Regular.ttf",
  "IBMPlexSansArabic-SemiBold.ttf",
  "OFL.txt",
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
// Arabic text for client-side search (loaded only by the search page).
writeJson(
  join(pub, "data/quran-text.json"),
  quran.surahs.map((s) => s.ayahs),
);
// 15-line Madinah Mushaf layout (word ranges into quran.v1.json); fetched once by the Mushaf reader and
// resolved against /data/quran-text.json on the device. The canonical text itself is never rewritten.
copyFileSync(join(repo, "content/quran/dist/mushaf-lines.v1.json"), join(pub, "data/mushaf-lines.json"));
writeJson(
  join(gen, "hajj.json"),
  extractHajj(readFileSync(join(repo, "content/pilgrimage/source-hajj.js"), "utf8")),
);
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
