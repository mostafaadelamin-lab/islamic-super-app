import { expect, test } from "@playwright/test";

test.use({ serviceWorkers: "allow" });

test("service worker precaches the app; it works offline after first load", async ({ page, context }) => {
  test.setTimeout(240_000);
  await page.goto("/ar/");
  await page.evaluate(async () => {
    await navigator.serviceWorker.ready;
  });
  // The settings page shows precache progress reported by the worker.
  await page.goto("/ar/settings/");
  await expect(page.getByTestId("offline-status")).toContainText("حُفظ التطبيق كاملًا", { timeout: 200_000 });
  const cached = await page.evaluate(async () => {
    const keys = await caches.keys();
    const cache = await caches.open(keys.find((k) => k.startsWith("rattil-"))!);
    const paths = (await cache.keys()).map((r) => new URL(r.url).pathname);
    return {
      count: paths.length,
      has: ["/ar/surah/36/", "/ar/page/604/", "/fonts/AmiriQuran-Regular.ttf", "/data/quran-text.json"].map(
        (p) => paths.includes(p),
      ),
    };
  });
  expect(cached.has).toEqual([true, true, true, true]);
  expect(cached.count).toBeGreaterThan(1400);

  await context.setOffline(true);
  await page.goto("/ar/");
  await expect(page.locator("h1")).toHaveText("السلام عليكم");
  await page.reload();
  await expect(page.locator("h1")).toHaveText("السلام عليكم");
  // client-side navigation to a surah while offline
  await page.getByRole("navigation").getByRole("link", { name: "القرآن", exact: true }).click();
  await expect(page).toHaveURL("/ar/quran/");
  await page.getByTestId("surah-list").getByRole("link", { name: /يس/ }).click();
  await expect(page).toHaveURL("/ar/surah/36/");
  await expect(page.locator("article.ayah")).toHaveCount(83);
  // full navigation (document request) to an uncommon page while offline
  await page.goto("/ar/page/500/");
  await expect(page.locator("h1")).toHaveText("الصفحة ٥٠٠ من ٦٠٤");
  // Quran font is served from cache
  const fontOk = await page.evaluate(async () => {
    await document.fonts.ready;
    return document.fonts.check('26px "Amiri Quran"');
  });
  expect(fontOk).toBe(true);
  // search works offline (index JSON cached)
  await page.goto("/ar/search/?q=الرحمن");
  await expect(page.getByTestId("search-results").locator("li").first()).toBeVisible();
  // prayer times are computed on-device
  await page.goto("/ar/prayer/");
  await expect(page.getByTestId("times").locator("tbody tr")).toHaveCount(6);
  await context.setOffline(false);
});
