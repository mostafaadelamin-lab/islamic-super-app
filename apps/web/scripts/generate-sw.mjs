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
let bytes = 0;
for (const file of walk(out).sort()) {
  // URL-encode each segment so keys match request URLs (e.g. /_next/.../%5Blocale%5D/...).
  const rel = "/" + relative(out, file).split(sep).map(encodeURIComponent).join("/");
  if (rel === "/sw.js" || rel.endsWith(".map")) continue;
  bytes += statSync(file).size;
  hash.update(rel).update(readFileSync(file));
  // Directory URLs for pages (trailingSlash export): /ar/quran/index.html -> /ar/quran/
  const url = rel.endsWith("/index.html") ? rel.slice(0, -"index.html".length) : rel;
  const heavy = /^\/(ar|en)\/(surah|page)\//.exec(url);
  if (heavy) rest[heavy[1]].push(BASE + url);
  else core.push(BASE + url);
}
const version = hash.digest("hex").slice(0, 16);
const template = readFileSync(join(app, "scripts/sw-template.js"), "utf8");
const sw = template
  .replace("__VERSION__", version)
  .replaceAll("__BASE__", BASE)
  .replace("__CORE__", JSON.stringify(core))
  .replace("__REST__", JSON.stringify(rest));
writeFileSync(join(out, "sw.js"), sw);
console.log(
  `sw.js: version ${version}, ${core.length} core + ${rest.ar.length}/${rest.en.length} ar/en route files, ${(bytes / 1048576).toFixed(1)} MB total`,
);
