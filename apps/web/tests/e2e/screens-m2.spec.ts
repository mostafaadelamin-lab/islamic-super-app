import { expect, test, withHydration } from "./fixtures";
import { SHOTS } from "./helpers";

// Phone screenshots (390 px, device scale 2) of the Milestone 2 screens for the owner's review.
for (const [name, path] of [
  ["home", "/ar/"],
  ["mushaf-p3", "/ar/page/3/"],
  ["mushaf-p1", "/ar/page/1/"],
  ["adhkar", "/ar/adhkar/#morning"],
  ["tafsir", "/ar/page/42/#a-2-255"], // Ayat al-Kursi selected: the sheet with its tafsir
] as const) {
  test(`screenshot m2-web-${name}`, async ({ browser }) => {
    const ctx = await browser.newContext({ viewport: { width: 390, height: 844 }, deviceScaleFactor: 2 });
    const page = withHydration(await ctx.newPage());
    await page.goto(path);
    await page.waitForLoadState("networkidle");
    await page.evaluate(() => document.fonts.ready);
    if (name.startsWith("mushaf") || name === "tafsir")
      await expect(page.getByTestId("mushaf-stage")).toHaveAttribute("data-ready", "true");
    if (name === "tafsir") await expect(page.getByTestId("tafsir-text")).toBeVisible();
    await page.waitForTimeout(400);
    await page.screenshot({ path: `${SHOTS}/m2-web-${name}.png` });
    await ctx.close();
  });
}
