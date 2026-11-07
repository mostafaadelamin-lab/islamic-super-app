import AxeBuilder from "@axe-core/playwright";
import { mkdirSync, readFileSync, writeFileSync } from "node:fs";
import type { Page } from "@playwright/test";
import { expect, test } from "./fixtures";
import { EVIDENCE, noHorizontalOverflow } from "./helpers";

/**
 * Tafsir al-Muyassar in the ayah sheet (Mushaf) and in the surah list view. The expected text is read from
 * the stored content (content/tafsir/dist/muyassar.v1.json) and compared exactly with what is shown.
 */
const TAFSIR = JSON.parse(
  readFileSync(new URL("../../../../content/tafsir/dist/muyassar.v1.json", import.meta.url), "utf8"),
) as { surahs: string[][] };
const stored = (s: number, a: number): string => TAFSIR.surahs[s - 1]![a - 1]!;
const PHONE = { width: 390, height: 844 };
const DESKTOP = { width: 1280, height: 900 };

async function openMushaf(page: Page, path: string): Promise<void> {
  await page.goto(path);
  await expect(page.getByTestId("mushaf-stage")).toHaveAttribute("data-ready", "true");
}
/** Taps an ayah's end marker (its accessible name is "<ref> — ayah options"). */
const tapAyah = (page: Page, name: string) => page.getByRole("button", { name, exact: true }).click();

async function expectTafsir(page: Page, s: number, a: number): Promise<void> {
  await expect(page.getByTestId("tafsir")).toHaveAttribute("data-ayah", `${s}:${a}`);
  const text = page.getByTestId("tafsir-text");
  await expect(text).toBeVisible();
  expect(await text.textContent()).toBe(stored(s, a)); // exactly as stored
}

async function axeSheet(page: Page, slug: string): Promise<void> {
  type AxePage = ConstructorParameters<typeof AxeBuilder>[0]["page"];
  const r = await new AxeBuilder({ page: page as unknown as AxePage })
    .withTags(["wcag2a", "wcag2aa", "wcag21a", "wcag21aa", "best-practice"])
    .analyze();
  mkdirSync(`${EVIDENCE}/axe`, { recursive: true });
  writeFileSync(
    `${EVIDENCE}/axe/tafsir-${slug}.json`,
    JSON.stringify(
      {
        violations: r.violations.map((v) => ({ id: v.id, impact: v.impact ?? null, nodes: v.nodes.length })),
      },
      null,
      1,
    ),
  );
  const serious = r.violations.filter((v) => v.impact === "serious" || v.impact === "critical");
  expect(serious.map((v) => `${v.id}: ${v.nodes.map((n) => n.target.join(" ")).join(", ")}`)).toEqual([]);
}

test.describe("tafsir al-Muyassar in the Mushaf", () => {
  for (const theme of ["light", "dark"] as const) {
    test(`Arabic phone (${theme}): tap 2:255 → its stored tafsir; next/previous move the selection; axe`, async ({
      page,
    }) => {
      await page.emulateMedia({ colorScheme: theme });
      await page.setViewportSize(PHONE);
      await openMushaf(page, "/ar/page/42/");
      await tapAyah(page, "البقرة، الآية ٢٥٥ — خيارات الآية");
      const sheet = page.getByTestId("ayah-sheet");
      await expect(sheet).toBeVisible();
      await expect(sheet.getByRole("heading", { name: "التفسير الميسر" })).toBeVisible();
      await expect(page.getByTestId("tafsir-source")).toHaveText("مجمع الملك فهد لطباعة المصحف الشريف");
      await expect(page.getByTestId("tafsir-arabic-only")).toHaveCount(0);
      await expectTafsir(page, 2, 255);
      // the tafsir uses the UI font, never the Quran font
      const font = await page.getByTestId("tafsir-text").evaluate((e) => getComputedStyle(e).fontFamily);
      expect(font).toContain("IBM Plex Sans Arabic");
      expect(font).not.toContain("Amiri");
      await noHorizontalOverflow(page);
      await axeSheet(page, `${theme}-ar-phone-2-255`);
      await page.getByTestId("tafsir-next").click();
      await expectTafsir(page, 2, 256);
      await expect(page.locator('.seg.selected[data-ayah="2:256"]').first()).toBeVisible();
      await page.getByTestId("tafsir-prev").click();
      await page.getByTestId("tafsir-prev").click();
      await expectTafsir(page, 2, 254);
      await expect(page.locator('.seg.selected[data-ayah="2:254"]').first()).toBeAttached();
      await page.getByTestId("act-close").click();
      await expect(page.getByTestId("tafsir")).toHaveCount(0);
    });
  }

  test("English desktop: a page with three surahs (604): 112:1 and 113:1, Arabic-only note; axe", async ({
    page,
  }) => {
    await page.setViewportSize(DESKTOP);
    await openMushaf(page, "/en/page/604/");
    await tapAyah(page, "Al-Ikhlas, ayah 1 — ayah options");
    await expectTafsir(page, 112, 1);
    await expect(page.getByTestId("tafsir-text")).toHaveAttribute("lang", "ar");
    await expect(page.getByTestId("tafsir-arabic-only")).toHaveText(
      "This simplified tafsir is available in Arabic only.",
    );
    await expect(page.getByTestId("tafsir-ref")).toHaveText("Tafsir of Al-Ikhlas, ayah 1");
    await axeSheet(page, "light-en-desktop-112-1");
    await tapAyah(page, "Al-Falaq, ayah 1 — ayah options");
    await expectTafsir(page, 113, 1);
    await page.getByTestId("tafsir-prev").click(); // across the surah boundary
    await expectTafsir(page, 112, 4);
    await noHorizontalOverflow(page);
  });

  test("next from the last ayah of a page turns the page (2:5 → 2:6 on page 3)", async ({ page }) => {
    await openMushaf(page, "/ar/page/2/");
    await tapAyah(page, "البقرة، الآية ٥ — خيارات الآية");
    await expectTafsir(page, 2, 5);
    await page.getByTestId("tafsir-next").click();
    await expect(page).toHaveURL("/ar/page/3/");
    await expectTafsir(page, 2, 6);
    await expect(page.locator('.seg.selected[data-ayah="2:6"]').first()).toBeVisible();
  });

  test("offline: a clear message, then retry once back online", async ({ page, context }) => {
    await openMushaf(page, "/en/page/50/");
    await context.setOffline(true);
    await page.locator(".seg").first().click();
    const error = page.getByTestId("tafsir-error");
    await expect(error).toBeVisible();
    await expect(error).toHaveAttribute("role", "alert");
    await expect(error).toContainText("You are offline");
    await expect(page.getByTestId("tafsir-text")).toHaveCount(0);
    await context.setOffline(false);
    await page.getByTestId("tafsir-retry").click();
    const key = (await page.getByTestId("tafsir").getAttribute("data-ayah"))!;
    const [s, a] = key.split(":").map(Number) as [number, number];
    await expectTafsir(page, s, a);
  });
});

test("list view: the Tafsir button opens the stored tafsir under the ayah (English phone)", async ({
  page,
}) => {
  await page.setViewportSize(PHONE);
  await page.goto("/en/surah/112/");
  const toggle = page.getByTestId("tafsir-toggle-1");
  await expect(toggle).toHaveAttribute("aria-expanded", "false");
  await toggle.click();
  await expect(toggle).toHaveAttribute("aria-expanded", "true");
  await expect(page.locator("#a-1").getByTestId("tafsir")).toBeVisible();
  await expectTafsir(page, 112, 1);
  await page.getByTestId("tafsir-next").click();
  await expectTafsir(page, 112, 2);
  await noHorizontalOverflow(page);
  await axeSheet(page, "light-en-phone-list-112");
});
