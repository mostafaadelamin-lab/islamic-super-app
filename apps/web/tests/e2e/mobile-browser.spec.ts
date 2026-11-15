import { devices, expect, test } from "@playwright/test";

/**
 * The Mushaf in a phone's browser (owner 2026-11-15): on the live site an iPhone showed raw page data
 * instead of the Mushaf. Cause: the service worker answered with a saved page from an older upload, the
 * newer data did not match, and Next.js then opened the data file itself. These checks run on phone
 * screens with the service worker on, as a visitor's browser does.
 */
const PHONES = [
  ["Android Chrome", devices["Pixel 7"]],
  ["iPhone Safari size", devices["iPhone 13"]],
] as const;

for (const [name, device] of PHONES) {
  test.describe(name, () => {
    test.use({
      viewport: device.viewport,
      userAgent: device.userAgent,
      deviceScaleFactor: device.deviceScaleFactor,
      isMobile: device.isMobile,
      hasTouch: device.hasTouch,
      serviceWorkers: "allow",
    });

    test("the Mushaf page opens and shows its lines, with no script errors", async ({ page }) => {
      const errors: string[] = [];
      page.on("pageerror", (e) => errors.push(e.message));
      await page.goto("/ar/page/128/");
      const mushaf = page.getByTestId("mushaf-page").first();
      await expect(mushaf).toBeVisible();
      expect((await mushaf.innerText()).length).toBeGreaterThan(100);
      const box = await mushaf.boundingBox();
      expect(box!.width).toBeLessThanOrEqual(device.viewport.width);
      expect(errors).toEqual([]);
    });

    test("a saved page from an older upload is never shown; opening a data file shows the page", async ({
      page,
    }) => {
      await page.goto("/ar/");
      await page.evaluate(async () => {
        await navigator.serviceWorker.ready;
      });
      await page.reload();
      await expect.poll(() => page.evaluate(() => navigator.serviceWorker.controller !== null)).toBe(true);
      // An old copy of the page sits in the worker's cache.
      await page.evaluate(async () => {
        const key = (await caches.keys()).find((k) => k.startsWith("rattil-"))!;
        const cache = await caches.open(key);
        await cache.put(
          "/ar/page/128/",
          new Response("<!doctype html><title>old</title><p id=old>OLD UPLOAD</p>", {
            headers: { "Content-Type": "text/html" },
          }),
        );
      });
      await page.goto("/ar/page/128/");
      await expect(page.locator("#old")).toHaveCount(0);
      await expect(page.getByTestId("mushaf-page").first()).toBeVisible();
      // Next.js sends the browser to ".../index.txt" after a version change: the page shows, not raw data.
      await page.goto("/ar/page/128/index.txt");
      await expect(page).toHaveURL(/\/ar\/page\/128\/$/);
      await expect(page.getByTestId("mushaf-page").first()).toBeVisible();
    });
  });
}
