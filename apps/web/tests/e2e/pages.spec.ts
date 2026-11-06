import { expect, test } from "./fixtures";
import { writeFileSync } from "node:fs";
import { EVIDENCE, MAIN_PAGES, watchErrors } from "./helpers";

for (const locale of ["ar", "en"] as const) {
  test.describe(`${locale} pages`, () => {
    for (const path of MAIN_PAGES) {
      test(`/${locale}/${path} renders with correct lang/dir and working links`, async ({
        page,
        request,
      }) => {
        const w = watchErrors(page);
        const res = await page.goto(`/${locale}/${path}`);
        expect(res?.status()).toBe(200);
        await expect(page.locator("html")).toHaveAttribute("lang", locale);
        await expect(page.locator("html")).toHaveAttribute("dir", locale === "ar" ? "rtl" : "ltr");
        await expect(page.locator("h1").first()).toBeVisible();
        await expect(page).toHaveTitle(/.+/);
        // Every internal link on the page resolves (200) in the static export.
        const hrefs = await page.$$eval("a[href]", (as) => [
          ...new Set(as.map((a) => a.getAttribute("href")!)),
        ]);
        for (const href of hrefs) {
          if (/^https?:/.test(href)) continue;
          const url = href.split("#")[0]!;
          if (!url) continue;
          const r = await request.get(url);
          expect(r.status(), `link ${href} on /${locale}/${path}`).toBe(200);
        }
        w.assertClean();
      });
    }
  });
}

test("root redirects to /ar/ by default and to the saved language", async ({ page }) => {
  await page.goto("/");
  await expect(page).toHaveURL(/\/ar\/$/);
  await page.getByTestId("lang-switch").click();
  await expect(page).toHaveURL(/\/en\/$/);
  await page.goto("/");
  await expect(page).toHaveURL(/\/en\/$/);
});

test("unknown routes return the 404 page", async ({ page }) => {
  const res = await page.goto("/ar/surah/115/");
  expect(res?.status()).toBe(404);
  await expect(page.locator("h1")).toContainText("Page not found");
});

/**
 * Functionality inventory: every visible interactive control on every main page, in both languages.
 * Each control is then exercised either generically below or by a dedicated test in features.spec.ts.
 */
test("functionality inventory: every control is enabled, labelled and handled", async ({ page }) => {
  test.setTimeout(180_000);
  const inventory: { page: string; tag: string; type: string | null; name: string; href: string | null }[] =
    [];
  for (const locale of ["ar", "en"]) {
    for (const path of MAIN_PAGES) {
      await page.goto(`/${locale}/${path}`);
      await page.waitForLoadState("networkidle");
      const controls = await page.$$eval("a[href], button, input, select, textarea", (els) =>
        els
          .filter((e) => (e as HTMLElement).offsetParent !== null || e.tagName === "INPUT")
          .map((e) => {
            const el = e as HTMLElement & { labels?: NodeListOf<HTMLLabelElement> };
            const name =
              el.getAttribute("aria-label") ??
              (el.labels && el.labels[0]?.textContent) ??
              el.textContent ??
              el.getAttribute("placeholder") ??
              "";
            return {
              tag: el.tagName.toLowerCase(),
              type: el.getAttribute("type"),
              name: name.trim().replace(/\s+/g, " ").slice(0, 80),
              href: el.getAttribute("href"),
            };
          }),
      );
      for (const c of controls) inventory.push({ page: `/${locale}/${path}`, ...c });
    }
  }
  writeFileSync(`${EVIDENCE}/functionality-inventory.json`, JSON.stringify(inventory, null, 1));
  // Every control has an accessible name (no anonymous placeholder buttons).
  const unnamed = inventory.filter((c) => !c.name && c.type !== "hidden");
  expect(unnamed).toEqual([]);
  expect(inventory.length).toBeGreaterThan(300);
});
