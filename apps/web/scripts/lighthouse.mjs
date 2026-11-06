// Runs Lighthouse (mobile + desktop) on the served export and writes reports + a score summary.
// Usage: node scripts/serve.mjs & node scripts/lighthouse.mjs
import { spawnSync } from "node:child_process";
import { mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const app = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const outDir = resolve(app, "../../tests/evidence/web/lighthouse");
mkdirSync(outDir, { recursive: true });
const chrome = process.env.CHROME_PATH ?? "/opt/pw-browsers/chromium";
const base = process.env.LH_BASE ?? "http://127.0.0.1:4173";
const targets = [
  ["home-ar", "/ar/"],
  ["surah-18-ar", "/ar/surah/18/"],
];
const bin = join(app, "node_modules/.bin/lighthouse");
const summary = {};
for (const preset of ["mobile", "desktop"]) {
  for (const [name, path] of targets) {
    const file = join(outDir, `${name}-${preset}`);
    const args = [
      base + path,
      `--chrome-path=${chrome}`,
      "--chrome-flags=--headless=new --no-sandbox --disable-gpu",
      "--output=json",
      "--output=html",
      `--output-path=${file}`,
      "--only-categories=performance,accessibility,best-practices,seo",
      "--quiet",
    ];
    if (preset === "desktop") args.push("--preset=desktop");
    const r = spawnSync(bin, args, { stdio: "inherit", env: { ...process.env, CHROME_PATH: chrome } });
    if (r.status !== 0) throw new Error(`lighthouse failed for ${name} ${preset}`);
    const report = JSON.parse(readFileSync(`${file}.report.json`, "utf8"));
    summary[`${name}-${preset}`] = {
      url: report.finalDisplayedUrl,
      scores: Object.fromEntries(
        Object.entries(report.categories).map(([k, v]) => [k, Math.round(v.score * 100)]),
      ),
      metrics: {
        FCP: report.audits["first-contentful-paint"].displayValue,
        LCP: report.audits["largest-contentful-paint"].displayValue,
        TBT: report.audits["total-blocking-time"].displayValue,
        CLS: report.audits["cumulative-layout-shift"].displayValue,
        transferSize: report.audits["total-byte-weight"].displayValue,
      },
    };
  }
}
writeFileSync(join(outDir, "summary.json"), JSON.stringify(summary, null, 2));
console.log(JSON.stringify(summary, null, 2));
