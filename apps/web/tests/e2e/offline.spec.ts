import { spawn, type ChildProcess } from "node:child_process";
import { expect, test } from "@playwright/test";

test.use({ serviceWorkers: "allow" });

// Each run gets its own static server so the test can take it down: "offline" then
// means the origin is really unreachable, not only emulated. On top of that,
// Chromium and Firefox also use context.setOffline(). Playwright's WebKit build
// fails page.goto with "internal error" when setOffline() is combined with a
// service worker, so WebKit relies on the stopped server alone.
let server: ChildProcess | undefined;
let base = "";

test.beforeEach(async ({ browserName }, info) => {
  const port = 4300 + ["chromium", "firefox", "webkit"].indexOf(browserName) * 10 + info.parallelIndex;
  base = `http://127.0.0.1:${port}`;
  server = spawn(process.execPath, ["scripts/serve.mjs"], {
    env: { ...process.env, PORT: String(port) },
    stdio: "ignore",
  });
  for (let i = 0; i < 100; i++) {
    try {
      if ((await fetch(`${base}/ar/`)).ok) return;
    } catch {
      /* not up yet */
    }
    await new Promise((r) => setTimeout(r, 100));
  }
  throw new Error("static server did not start");
});

test.afterEach(() => {
  server?.kill();
});

test("service worker precaches the app; it works offline after first load", async ({
  page,
  context,
  browserName,
}) => {
  test.setTimeout(240_000);
  const goto = (path: string) => page.goto(base + path);
  await goto("/ar/");
  await page.evaluate(async () => {
    await navigator.serviceWorker.ready;
  });
  // The settings page shows precache progress reported by the worker.
  await goto("/ar/settings/");
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

  server?.kill();
  await expect
    .poll(async () =>
      fetch(`${base}/ar/`).then(
        () => "up",
        () => "down",
      ),
    )
    .toBe("down");
  if (browserName !== "webkit") await context.setOffline(true);
  await goto("/ar/");
  await expect(page.locator("h1")).toHaveText("السلام عليكم");
  await page.reload();
  await expect(page.locator("h1")).toHaveText("السلام عليكم");
  // client-side navigation to a surah while offline
  await page.getByRole("navigation").getByRole("link", { name: "القرآن", exact: true }).click();
  await expect(page).toHaveURL(`${base}/ar/quran/`);
  await page.getByTestId("surah-list").getByRole("link", { name: /يس/ }).click();
  await expect(page).toHaveURL(`${base}/ar/surah/36/`);
  await expect(page.locator("article.ayah")).toHaveCount(83);
  // full navigation (document request) to an uncommon page while offline
  await goto("/ar/page/500/");
  await expect(page.locator("h1")).toHaveText("الصفحة ٥٠٠ من ٦٠٤");
  // Quran font is served from cache
  const fontOk = await page.evaluate(async () => {
    await document.fonts.ready;
    return document.fonts.check('26px "Amiri Quran"');
  });
  expect(fontOk).toBe(true);
  // search works offline (index JSON cached)
  await goto("/ar/search/?q=الرحمن");
  await expect(page.getByTestId("search-results").locator("li").first()).toBeVisible();
  // prayer times are computed on-device
  await goto("/ar/prayer/");
  await expect(page.getByTestId("times").locator("tbody tr")).toHaveCount(6);
  await context.setOffline(false);
});
