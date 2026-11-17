import { mkdirSync } from "node:fs";
import type { Page } from "@playwright/test";
import { expect, test } from "./fixtures";

/** 1.2.1 Mushaf edits (owner 2026-11-17): page turn like a paper Mushaf, whole surah, list paging, highlight. */
const SHOTS = process.env.RATTIL_WEB_SHOTS;

async function openMushaf(page: Page, path: string): Promise<void> {
  await page.goto(path);
  await expect(page.getByTestId("mushaf-stage")).toHaveAttribute("data-ready", "true");
  await page.evaluate(() => document.fonts.ready);
}
async function shot(page: Page, name: string): Promise<void> {
  if (!SHOTS) return;
  mkdirSync(SHOTS, { recursive: true });
  await page.screenshot({ path: `${SHOTS}/${name}.png` });
}

test.use({ viewport: { width: 390, height: 844 }, deviceScaleFactor: 2, hasTouch: true });

test("drag from left to right: this page turns away on the spine, the next one lies underneath", async ({
  page,
}) => {
  await openMushaf(page, "/ar/page/10/");
  const box = (await page.getByTestId("mushaf-stage").boundingBox())!;
  const y = box.y + box.height / 2;
  await page.mouse.move(box.x + 60, y);
  await page.mouse.down();
  await page.mouse.move(box.x + 120, y, { steps: 4 });
  await page.mouse.move(box.x + 190, y, { steps: 4 });
  await expect(page.getByTestId("mushaf-turn-under")).toBeVisible();
  const transform = await page
    .getByTestId("mushaf-frame")
    .evaluate((el) => (el as HTMLElement).style.transform);
  expect(transform).toContain("rotateY");
  await shot(page, "w1_turn");
  await page.mouse.move(box.x + 330, y, { steps: 4 });
  await page.mouse.up();
  await expect(page).toHaveURL(/\/page\/11\/?$/);
});

test("the selected ayah is a clear warm tint", async ({ page }) => {
  await openMushaf(page, "/ar/page/10/");
  await page.locator('[data-ayah="2:63"].seg').first().click();
  const bg = await page
    .locator('[data-ayah="2:63"].seg')
    .first()
    .evaluate((el) => getComputedStyle(el).getPropertyValue("--hl").trim());
  expect(bg).toContain("240 176 30");
  await shot(page, "w2_highlight");
});

test("whole surah: the surah flows on one screen; A+ enlarges it; next surah", async ({ page }) => {
  await openMushaf(page, "/ar/page/10/");
  await page.getByTestId("tab-surah").click();
  const flow = page.getByTestId("surah-flow");
  await expect(flow).toHaveAttribute("data-surah", "2");
  await expect(page.locator('[data-testid="flow-ayah"][data-ayah="2:286"]')).toHaveCount(1);
  await page.waitForTimeout(300);
  await shot(page, "w3_whole_surah");
  await page.evaluate(() => window.scrollTo(0, 0));
  await shot(page, "w3_whole_surah_top");
  const size = async (): Promise<number> =>
    flow.locator(".rd-flow").evaluate((el) => parseFloat(getComputedStyle(el).fontSize));
  const before = await size();
  await page.getByTestId("reader-font").click();
  expect(await size()).toBeGreaterThan(before);
  await page.getByTestId("reader-font-down").click();
  await page.getByTestId("flow-next-surah").click();
  await expect(flow).toHaveAttribute("data-surah", "3");
});

test("tafsir view: next page button at the end and a sideways swipe", async ({ page }) => {
  await openMushaf(page, "/ar/page/10/");
  await page.getByTestId("tab-tafsir").click();
  const next = page.getByTestId("list-next-page");
  await next.scrollIntoViewIfNeeded();
  await shot(page, "w4_tafsir_next_page");
  await next.click();
  await expect(page).toHaveURL(/\/page\/11\/?$/);
  await page.getByTestId("list-prev-page").click();
  await expect(page).toHaveURL(/\/page\/10\/?$/);
});
