import { expect, test } from "./fixtures";
import { noHorizontalOverflow, SHOTS } from "./helpers";

const VIEWPORTS = [
  { name: "mobile", width: 360, height: 780 },
  { name: "tablet", width: 768, height: 1024 },
  { name: "desktop", width: 1280, height: 900 },
] as const;
const PAGES = [
  "",
  "quran/",
  "surah/2/",
  "page/3/",
  "search/?q=رحمة",
  "bookmarks/",
  "prayer/",
  "settings/",
  "about/",
];

for (const vp of VIEWPORTS) {
  for (const locale of ["ar", "en"] as const) {
    test(`${locale} @ ${vp.width}px: no horizontal overflow, nav reachable`, async ({ page }) => {
      await page.setViewportSize({ width: vp.width, height: vp.height });
      for (const p of PAGES) {
        await page.goto(`/${locale}/${p}`);
        await page.waitForLoadState("networkidle");
        await noHorizontalOverflow(page);
        // all six main nav links are visible without scrolling sideways
        const links = page.getByRole("navigation").first().getByRole("link");
        await expect(links).toHaveCount(6);
        for (const l of await links.all()) await expect(l).toBeInViewport();
        if (
          vp.name !== "tablet" &&
          ["", "surah/2/", "page/3/", "prayer/", "settings/", "quran/"].includes(p)
        ) {
          const name = `${locale}-${vp.name}-${p.replace(/[/?=]/g, "_") || "home"}`.replace(/_+$/, "");
          await page.screenshot({ path: `${SHOTS}/${name}.png`, fullPage: false });
        }
      }
    });
  }
}
