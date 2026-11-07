import { expect, type Page } from "@playwright/test";

export const EVIDENCE = "../../tests/evidence/web";
export const SHOTS = `${EVIDENCE}/screenshots`;

export const MAIN_PAGES = [
  "",
  "quran/",
  "surah/1/",
  "surah/18/",
  "page/1/",
  "page/604/",
  "search/",
  "bookmarks/",
  "prayer/",
  "settings/",
  "about/",
  // Milestone 2
  "page/3/",
  "more/",
  "adhkar/",
  "hisn/",
  "hisn/29/",
  "tasbih/",
  "qibla/",
  "hajj/",
] as const;

/** Collects uncaught page errors and console errors; call `assertClean()` at the end. */
export function watchErrors(page: Page): { errors: string[]; assertClean: () => void } {
  const errors: string[] = [];
  page.on("pageerror", (e) => errors.push(`pageerror: ${e.message}`));
  page.on("console", (m) => {
    if (m.type() === "error") errors.push(`console: ${m.text()}`);
  });
  return { errors, assertClean: () => expect(errors).toEqual([]) };
}

export async function noHorizontalOverflow(page: Page): Promise<void> {
  const { sw, cw } = await page.evaluate(() => ({
    sw: document.documentElement.scrollWidth,
    cw: document.documentElement.clientWidth,
  }));
  expect(sw, "page must not scroll horizontally").toBeLessThanOrEqual(cw);
}
