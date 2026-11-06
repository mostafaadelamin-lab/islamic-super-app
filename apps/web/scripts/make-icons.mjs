// Renders public/icon.svg to the PNG sizes the web manifest needs (run once; PNGs are committed).
import { chromium } from "@playwright/test";
import { readFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const pub = join(resolve(dirname(fileURLToPath(import.meta.url)), ".."), "public");
const svg = readFileSync(join(pub, "icon.svg"), "utf8");
const browser = await chromium.launch({ executablePath: process.env.CHROMIUM_PATH || undefined });
for (const size of [192, 512]) {
  const page = await browser.newPage({ viewport: { width: size, height: size } });
  await page.setContent(
    `<html><body style="margin:0">${svg.replace("<svg ", `<svg width="${size}" height="${size}" `)}</body></html>`,
  );
  await page.screenshot({ path: join(pub, `icon-${size}.png`), omitBackground: true });
  await page.close();
}
await browser.close();
console.log("icons written");
