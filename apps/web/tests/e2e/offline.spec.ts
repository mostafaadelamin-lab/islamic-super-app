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
      has: [
        "/ar/surah/36/",
        "/ar/page/604/",
        "/fonts/AmiriQuran-Regular.ttf",
        "/data/quran-text.json",
        "/data/mushaf-lines.json",
        "/ar/adhkar/",
        "/ar/hisn/29/",
        "/ar/qibla/",
      ].map((p) => paths.includes(p)),
      tafsir: paths.filter((p) => p.startsWith("/data/tafsir/")).length,
    };
  });
  expect(cached.has).toEqual([true, true, true, true, true, true, true, true]);
  expect(cached.count).toBeGreaterThan(1400);
  // Tafsir files are not precached; a surah's file is kept once it has been read.
  expect(cached.tafsir).toBe(0);
  await goto("/ar/page/500/");
  await expect(page.getByTestId("mushaf-stage")).toHaveAttribute("data-ready", "true");
  const tafsirAyah = (await page.locator(".seg").first().getAttribute("data-ayah"))!;
  await page.locator(".seg").first().click();
  await expect(page.getByTestId("tafsir-text")).toBeVisible();
  const tafsirOnline = (await page.getByTestId("tafsir-text").textContent())!;
  expect(tafsirOnline.length).toBeGreaterThan(20);

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
  await page.getByTestId("surah-list").getByRole("link", { name: "عرض كقائمة — يس" }).click();
  await expect(page).toHaveURL(`${base}/ar/surah/36/`);
  await expect(page.locator("article.ayah")).toHaveCount(83);
  // full navigation (document request) to an uncommon page while offline
  await goto("/ar/page/500/");
  await expect(page.locator("h1")).toHaveText("الصفحة ٥٠٠ من ٦٠٤");
  // the Mushaf data comes from the cache, so pages turn on the device while offline
  await expect(page.getByTestId("mushaf-stage")).toHaveAttribute("data-ready", "true");
  // the tafsir read earlier is served from the cache
  await page.locator(`.seg[data-ayah="${tafsirAyah}"]`).first().click();
  await expect(page.getByTestId("tafsir-text")).toHaveText(tafsirOnline);
  await page.getByTestId("next-page").click();
  await expect(page.locator("h1")).toHaveText("الصفحة ٥٠١ من ٦٠٤");
  await expect(page.locator(".m-line")).toHaveCount(15);
  // Quran font is served from cache
  const fontOk = await page.evaluate(async () => {
    await document.fonts.ready;
    return document.fonts.check('26px "Amiri Quran"');
  });
  expect(fontOk).toBe(true);
  // search works offline (index JSON cached)
  await goto("/ar/search/?q=الرحمن");
  await expect(page.getByTestId("search-results").locator("li").first()).toBeVisible();
  // adhkar work offline
  await goto("/ar/adhkar/");
  await expect(page.getByTestId("dhikr").first()).toBeVisible();
  // prayer times are computed on-device
  await goto("/ar/prayer/");
  await expect(page.getByTestId("times").locator("tbody tr")).toHaveCount(6);
  await context.setOffline(false);
});
