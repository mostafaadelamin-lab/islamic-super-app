import { readFileSync } from "node:fs";
import { expect, test, withHydration } from "./fixtures";
import { SHOTS, watchErrors } from "./helpers";

// Episodes stream from archive.org and verses from everyayah.com; tests must not depend on either, so both
// are answered with a short silent MP3 and the requested URLs are recorded.
const SILENCE = readFileSync(new URL("./fixtures/silence.mp3", import.meta.url));
test("stories: the narrator's episodes need review; reviewer mode plays one; verse stories recite in order", async ({
  browser,
}) => {
  const ctx = await browser.newContext({ viewport: { width: 390, height: 844 }, deviceScaleFactor: 2 });
  const page = withHydration(await ctx.newPage());
  const { assertClean } = watchErrors(page);
  const requested: string[] = [];
  await page.route(/archive\.org|everyayah\.com/, (r) => {
    requested.push(r.request().url());
    return r.fulfill({ status: 200, contentType: "audio/mpeg", body: SILENCE });
  });

  await page.goto("/ar/stories/");
  await expect(page.getByRole("heading", { level: 1 })).toHaveText("قصص قرآنية مسموعة");
  await expect(page.getByTestId("series-hidden")).toHaveCount(0);
  await expect(page.getByTestId("stories-reviewer")).toHaveCount(0);
  await expect(page.locator("[data-episode]")).toHaveCount(19);
  await page.getByTestId("episode-yusuf").click();
  await expect(page.getByTestId("series-audio")).toHaveAttribute(
    "src",
    /^https:\/\/archive\.org\/download\/prophets_stories_Nabel-ElAwadde\/.+\.mp3$/,
  );
  await expect(page.getByTestId("series-error")).toHaveCount(0);
  await page.getByTestId("sleep-timer").selectOption("30");
  await expect(page.getByTestId("sleep-left")).toContainText("٣٠");
  await page.screenshot({ path: `${SHOTS}/stories-web-series.png` });

  await page.getByText("اقرأ آيات القصة").click();
  await expect(page).toHaveURL(/\/ar\/stories\/yusuf\/$/);
  await expect(page.locator("article.ayah")).toHaveCount(98);
  await expect(page.getByTestId("story-source")).toContainText("التفسير الميسّر");
  await expect(page.getByTestId("sleep-timer")).toHaveValue("30"); // one timer for the whole app
  await page.getByTestId("story-play").click();
  await expect(page.getByTestId("player-now")).toContainText("يوسف");
  await expect.poll(() => requested.some((u) => u.endsWith("/012004.mp3"))).toBe(true);
  await page.screenshot({ path: `${SHOTS}/stories-web-yusuf.png` });
  assertClean();
  await ctx.close();
});
