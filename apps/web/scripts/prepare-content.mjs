// Copies shared schemas, tokens, fonts and split Quran content into the web app.
// Generated output (src/generated, public/fonts, public/data) is not hand-edited.
import { mkdirSync, copyFileSync, readFileSync, writeFileSync, rmSync } from "node:fs";
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
console.log(`content prepared: ${meta.length} surahs`);
