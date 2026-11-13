// Builds the Bluehost (Apache + PHP) upload folder from the static export: `node scripts/package-bluehost.mjs`
// after `npm run build`. Output: out-bluehost/ (zip its CONTENTS and extract them in the domain's folder).
// Replaces Netlify-only parts: netlify.toml + netlify/functions/videos.mjs -> .htaccess + api/videos.php.
import { cpSync, rmSync, mkdirSync, existsSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const app = join(dirname(fileURLToPath(import.meta.url)), "..");
const out = join(app, "out-bluehost");
rmSync(out, { recursive: true, force: true });
cpSync(join(app, "out"), out, { recursive: true });
for (const f of ["netlify", "netlify.toml", ".netlify"]) rmSync(join(out, f), { recursive: true, force: true });
const bh = join(app, "bluehost");
cpSync(join(bh, "htaccess.txt"), join(out, ".htaccess"));
mkdirSync(join(out, "api", "cache"), { recursive: true });
cpSync(join(bh, "api", "videos.php"), join(out, "api", "videos.php"));
cpSync(join(bh, "api", "htaccess.txt"), join(out, "api", ".htaccess"));
cpSync(join(bh, "api", "cache-htaccess.txt"), join(out, "api", "cache", ".htaccess"));
const sources = join(app, "netlify", "lib", "reel-sources.json");
if (!existsSync(sources)) throw new Error("run `npm run content` first (writes netlify/lib/reel-sources.json)");
cpSync(sources, join(out, "api", "reel-sources.json"));
console.log(`Bluehost folder ready: ${out}`);
