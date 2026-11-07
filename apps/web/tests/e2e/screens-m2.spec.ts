import { expect, test, withHydration } from "./fixtures";
import { SHOTS } from "./helpers";
import { fakeMedia, isPlaying } from "./fake-media";

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

// Recitation views (fake media element: nothing is fetched; the player shows the recited ayah).
for (const [name, path, marker, tafsir] of [
  ["recitation-highlight", "/ar/page/1/", "الفاتحة، الآية ٧ — خيارات الآية", false],
  ["recitation-tafsir", "/ar/page/2/", "البقرة، الآية ٣ — خيارات الآية", true],
] as const) {
  test(`screenshot m2-web-${name} (fake media element)`, async ({ browser }) => {
    const ctx = await browser.newContext({ viewport: { width: 390, height: 844 }, deviceScaleFactor: 2 });
    const page = withHydration(await ctx.newPage());
    await fakeMedia(page);
    await page.goto(path);
    await expect(page.getByTestId("mushaf-stage")).toHaveAttribute("data-ready", "true");
    await page.evaluate(() => document.fonts.ready);
    await page.getByRole("button", { name: marker, exact: true }).click();
    await page.getByTestId("act-play").click();
    await page.getByTestId("act-close").click();
    await isPlaying(page);
    if (tafsir) {
      await page.getByTestId("player-tafsir").check();
      await expect(page.getByTestId("recitation-tafsir").getByTestId("tafsir-text")).toBeVisible();
    }
    await page.mouse.move(0, 0);
    await page.waitForTimeout(400);
    await page.screenshot({ path: `${SHOTS}/m2-web-${name}.png` });
    await ctx.close();
  });
}
