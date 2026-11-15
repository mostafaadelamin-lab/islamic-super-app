// Writes out/sw.js with the precache manifest of the static export.
import { readdirSync, readFileSync, statSync, writeFileSync } from "node:fs";
import { createHash } from "node:crypto";
import { dirname, join, relative, resolve, sep } from "node:path";
import { fileURLToPath } from "node:url";

const app = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const out = join(app, "out");
const BASE = process.env.NEXT_PUBLIC_BASE_PATH ?? "";

// CSS url("/fonts/...") is not rewritten by Next's basePath; prefix it here.
if (BASE) {
  const cssDir = join(out, "_next/static/css");
  for (const name of readdirSync(cssDir)) {
    const p = join(cssDir, name);
    writeFileSync(p, readFileSync(p, "utf8").replace(/url\((["']?)\/fonts\//g, `url($1${BASE}/fonts/`));
  }
}

function walk(dir) {
  const files = [];
  for (const name of readdirSync(dir)) {
    const p = join(dir, name);
    if (statSync(p).isDirectory()) files.push(...walk(p));
    else files.push(p);
  }
  return files;
}

const hash = createHash("sha256");
const core = [];
const rest = { ar: [], en: [] };
const extra = [];
const restBytes = { ar: 0, en: 0 };
let extraBytes = 0;
// The shell: code, styles, fonts, icons, the two home pages and the error page.
const SHELL = /^\/(_next\/static\/|fonts\/|icons?\/|[^/]+\.(webmanifest|png|svg|ico)$|404\.html$|(ar|en)\/$)/;
let bytes = 0;
for (const file of walk(out).sort()) {
  // URL-encode each segment so keys match request URLs (e.g. /_next/.../%5Blocale%5D/...).
  const rel = "/" + relative(out, file).split(sep).map(encodeURIComponent).join("/");
  if (rel === "/sw.js" || rel.endsWith(".map")) continue;
  bytes += statSync(file).size;
  hash.update(rel).update(readFileSync(file));
  // Directory URLs for pages (trailingSlash export): /ar/quran/index.html -> /ar/quran/
  const url = rel.endsWith("/index.html") ? rel.slice(0, -"index.html".length) : rel;
  // Tafsir files (~2.7 MB) are not precached: the worker keeps each surah's file once it is first read.
  if (url.startsWith("/data/tafsir/")) continue;
  // Hadith books (~70 MB) are not precached either: each part is kept once it has been read.
  if (url.startsWith("/data/hadith/")) continue;
  // Alafasy's morning/evening adhkar recordings (~9 MB) stream on demand, like the other long audio.
  if (url.startsWith("/audio/adhkar_")) continue;
  // Owner 2026-11-15 (site slow after an upload): the worker installs only the app shell. Everything else
  // (pages, recordings, data) is kept once opened, or all at once only when the visitor asks to save the
  // whole site for offline use in Settings.
  const page = /^\/(ar|en)\//.exec(url);
  if (SHELL.test(url)) core.push(BASE + url);
  else if (page) rest[page[1]].push(BASE + url);
  else extra.push(BASE + url);
  if (!SHELL.test(url)) {
    const size = statSync(file).size;
    if (page) restBytes[page[1]] += size;
    else extraBytes += size;
  }
}
const mb = (n) => Math.round(n / 1048576);
const version = hash.digest("hex").slice(0, 16);
const template = readFileSync(join(app, "scripts/sw-template.js"), "utf8");
const sw = template
  .replace("__VERSION__", version)
  .replaceAll("__BASE__", BASE)
  .replace("__CORE__", JSON.stringify(core))
  .replace("__REST__", JSON.stringify(rest))
  .replace("__EXTRA__", JSON.stringify(extra))
  .replace("__FULL_MB__", JSON.stringify({ ar: mb(extraBytes + restBytes.ar), en: mb(extraBytes + restBytes.en) }));
writeFileSync(join(out, "sw.js"), sw);
console.log(
  `sw.js: version ${version}, shell ${core.length} files, +${extra.length} shared + ${rest.ar.length}/${rest.en.length} ar/en page files on request, ${(bytes / 1048576).toFixed(1)} MB total`,
);
