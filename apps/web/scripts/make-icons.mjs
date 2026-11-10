// Renders the Rattil app icon (packages/design-tokens/app-icon/*.svg) to every size the
// Android app, the iOS app and the website need. Run from apps/web (uses its Playwright):
//   cd apps/web && node scripts/make-icons.mjs && python3 ../../tools/flatten_ios_icons.py
// The PNGs are committed; re-run only when the SVGs change.
import { chromium } from "@playwright/test";
import { mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const repo = resolve(dirname(fileURLToPath(import.meta.url)), "../../..");
const src = (n) => readFileSync(join(repo, "packages/design-tokens/app-icon", n), "utf8");
const android = join(repo, "apps/mobile/android/app/src/main/res");
const ios = join(repo, "apps/mobile/ios/Runner/Assets.xcassets/AppIcon.appiconset");
const web = join(repo, "apps/web/public");

const browser = await chromium.launch({ executablePath: process.env.CHROMIUM_PATH || undefined });
/** radius: corner radius as a fraction of the size (0 = square), pad: inset fraction. */
async function render(svg, size, out, { radius = 0, pad = 0 } = {}) {
  const inner = Math.round(size * (1 - 2 * pad));
  const page = await browser.newPage({ viewport: { width: size, height: size } });
  await page.setContent(
    `<html><body style="margin:0;background:transparent"><div style="width:${size}px;height:${size}px;display:flex;align-items:center;justify-content:center">` +
      `<div style="width:${inner}px;height:${inner}px;border-radius:${inner * radius}px;overflow:hidden;line-height:0">` +
      svg.replace("<svg ", `<svg width="${inner}" height="${inner}" `) +
      `</div></div></body></html>`,
  );
  mkdirSync(dirname(out), { recursive: true });
  await page.screenshot({ path: out, omitBackground: true });
  await page.close();
}

const icon = src("icon.svg");
const densities = { mdpi: 1, hdpi: 1.5, xhdpi: 2, xxhdpi: 3, xxxhdpi: 4 };
for (const [d, k] of Object.entries(densities)) {
  const dir = join(android, `mipmap-${d}`);
  await render(icon, 48 * k, join(dir, "ic_launcher.png"), { radius: 0.22, pad: 1 / 24 });
  await render(icon, 48 * k, join(dir, "ic_launcher_round.png"), { radius: 0.5, pad: 1 / 24 });
  await render(src("foreground.svg"), 108 * k, join(dir, "ic_launcher_foreground.png"));
  await render(src("background.svg"), 108 * k, join(dir, "ic_launcher_background.png"));
  await render(src("monochrome.svg"), 108 * k, join(dir, "ic_launcher_monochrome.png"));
  await render(src("foreground.svg"), 96 * k, join(android, `drawable-${d}`, "launch_mark.png"));
}

const launch = join(repo, "apps/mobile/ios/Runner/Assets.xcassets/LaunchImage.imageset");
for (const [suffix, k] of [
  ["", 1],
  ["@2x", 2],
  ["@3x", 3],
]) {
  await render(src("foreground.svg"), 96 * k, join(launch, `LaunchImage${suffix}.png`));
}

const contents = JSON.parse(readFileSync(join(ios, "Contents.json"), "utf8"));
for (const img of contents.images) {
  const px = Math.round(parseFloat(img.size) * parseInt(img.scale, 10));
  await render(icon, px, join(ios, img.filename)); // square and opaque: iOS applies the mask
}

writeFileSync(
  join(web, "icon.svg"),
  icon.replace('<rect width="1024" height="1024"', '<rect width="1024" height="1024" rx="230"'),
);
await render(icon, 192, join(web, "icon-192.png"), { radius: 0.22 });
await render(icon, 512, join(web, "icon-512.png"), { radius: 0.22 });
await render(icon, 512, join(web, "icon-maskable-512.png")); // full bleed for the maskable purpose
await render(icon, 180, join(web, "apple-touch-icon.png"));
await render(icon, 32, join(web, "favicon-32.png"), { radius: 0.22 });
await browser.close();
console.log("app icons written");
