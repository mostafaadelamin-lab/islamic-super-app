import type { Page } from "@playwright/test";
import { EMPTY_REELS_FEED, expect, test, withHydration } from "./fixtures";
import { SHOTS, watchErrors } from "./helpers";

// The real player lives on youtube-nocookie.com, which tests must not depend on: it is replaced by a local stand-in page that records which video was requested.
const PNG = Buffer.from(
  "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=",
  "base64",
);
const YASSER = "yt-UCYuUcfXvsHapABTcPRWCEoQ";
const autoReel = (ref: string, title: string, published: string) => ({
  id: `yt-${ref}`,
  platform: "youtube",
  ref,
  url: `https://www.youtube.com/watch?v=${ref}`,
  title: { ar: title, en: title },
  speaker: { ar: "الشيخ ياسر الدوسري", en: "Sheikh Yasser Al-Dosari" },
  category: "recitation",
  sourceId: YASSER,
  status: "auto",
  published,
});
const TRUSTED_FEED = {
  schema: "reels-feed.v1",
  sources: [
    {
      id: YASSER,
      channelId: "UCYuUcfXvsHapABTcPRWCEoQ",
      name: { ar: "الشيخ ياسر الدوسري", en: "Sheikh Yasser Al-Dosari" },
      category: "recitation",
    },
  ],
  items: [
    autoReel("AAAAAAAAAA1", "تلاوة خاشعة من سورة الملك", "2026-11-09T10:00:00Z"),
    autoReel("CCCCCCCCCC3", "تلاوة من سورة يس", "2026-11-08T10:00:00Z"),
  ],
};
async function fakePlatforms(page: Page, feed: object = EMPTY_REELS_FEED): Promise<string[]> {
  const requested: string[] = [];
  const player = (label: string) =>
    `<!doctype html><meta charset="utf-8"><body style="margin:0;height:100vh;display:flex;align-items:center;justify-content:center;` +
    `background:linear-gradient(160deg,#0f5c4a,#06281f);color:#fff;font:600 20px sans-serif">${label}</body>`;
  await page.route("https://www.youtube-nocookie.com/**", (r) => {
    requested.push(r.request().url());
    return r.fulfill({ contentType: "text/html", body: player("▶ YouTube (test player)") });
  });
  await page.route("https://i.ytimg.com/**", (r) => r.fulfill({ contentType: "image/png", body: PNG }));
  await page.route("**/v1/reels/feed", (r) => r.fulfill({ json: feed }));
  return requested;
}

test("reels: only reviewed reels by default; reviewer mode shows pending ones with a banner", async ({
  browser,
}) => {
  const ctx = await browser.newContext({ viewport: { width: 390, height: 844 }, deviceScaleFactor: 2 });
  const page = withHydration(await ctx.newPage());
  const { assertClean } = watchErrors(page);
  const requested = await fakePlatforms(page);
  await page.goto("/ar/reels/");
  await expect(page.getByRole("heading", { level: 1 })).toHaveText("ريلز إسلامية");
  // The shipped catalogue has no approved reels yet, so nothing is embedded for normal users.
  await expect(page.getByTestId("reels-empty")).toBeVisible();
  expect(requested).toEqual([]);
  await page.screenshot({ path: `${SHOTS}/reels-web-empty.png` });

  await page.getByTestId("reels-reviewer").check();
  const reels = page.locator("[data-reel]");
  await expect(reels).toHaveCount(2);
  await expect(page.getByTestId("reel-player")).toHaveCount(1);
  await expect(page.getByTestId("reel-pending").first()).toBeVisible();
  await expect.poll(() => requested.length).toBe(1);
  expect(requested[0]).toContain("/embed/hTtlD-u4_HI?");
  await page.waitForTimeout(300);
  await page.screenshot({ path: `${SHOTS}/reels-web-reviewer.png` });

  // Swipe/scroll to the next reel: the first player is torn down, the second one loads.
  await page.getByRole("button", { name: "المقطع التالي" }).click();
  await expect(page.getByTestId("reels-position")).toHaveText("٢ / ٢");
  await expect(reels.nth(1).getByTestId("reel-player")).toBeVisible();
  await expect(reels.nth(0).getByTestId("reel-player")).toHaveCount(0);
  await expect.poll(() => requested.some((u) => u.includes("/embed/26dRG7OeL6Q?"))).toBe(true);

  // Reviewer mode is remembered on this device.
  await page.reload();
  await expect(page.locator("[data-reel]")).toHaveCount(2);
  assertClean();
  await ctx.close();
});

test("reels: keyboard and scroll-snap navigation", async ({ page }) => {
  await fakePlatforms(page);
  await page.goto("/en/reels/");
  await page.getByTestId("reels-reviewer").check();
  const feed = page.getByTestId("reels-feed");
  await feed.focus();
  await page.keyboard.press("ArrowDown");
  await expect(page.getByTestId("reels-position")).toHaveText("2 / 2");
  await page.keyboard.press("ArrowUp");
  await expect(page.getByTestId("reels-position")).toHaveText("1 / 2");
  // Scrolling the feed by one screen snaps to the next reel and the observer makes it active.
  await feed.evaluate((el) => el.scrollTo({ top: el.clientHeight }));
  await expect(page.getByTestId("reels-position")).toHaveText("2 / 2");
});

test("reels tile on home and More", async ({ page }) => {
  await page.goto("/ar/more/");
  await page.locator('a[data-section="reels"]').click();
  await expect(page).toHaveURL(/\/ar\/reels\/$/);
});

test("reels: newest reels of trusted channels play automatically; a channel can be hidden", async ({
  browser,
}) => {
  const ctx = await browser.newContext({ viewport: { width: 390, height: 844 }, deviceScaleFactor: 2 });
  const page = withHydration(await ctx.newPage());
  const { assertClean } = watchErrors(page);
  const requested = await fakePlatforms(page, TRUSTED_FEED);
  await page.goto("/ar/reels/");
  await expect(page.locator("[data-reel]")).toHaveCount(2); // the pending samples stay hidden
  await expect(page.locator('[data-status="auto"]')).toHaveCount(2);
  await expect(page.getByText("قناة موثوقة").first()).toBeVisible();
  await expect.poll(() => requested.some((u) => u.includes("/embed/AAAAAAAAAA1?"))).toBe(true);
  await page.waitForTimeout(300);
  await page.screenshot({ path: `${SHOTS}/reels-web-auto.png` });

  await page.getByTestId("reel-hide-yt-AAAAAAAAAA1").click();
  await expect(page.getByTestId("reels-hidden")).toContainText("تم إخفاء الشيخ ياسر الدوسري");
  await expect(page.locator("[data-reel]")).toHaveCount(0);
  await page.reload();
  await expect(page.getByTestId("reels-show-hidden")).toBeVisible();
  await page.getByTestId("reels-show-hidden").click();
  await expect(page.locator('[data-status="auto"]')).toHaveCount(2);
  assertClean();
  await ctx.close();
});
