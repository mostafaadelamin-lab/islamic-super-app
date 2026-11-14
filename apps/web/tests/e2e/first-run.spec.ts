import AxeBuilder from "@axe-core/playwright";
import { expect, test } from "./fixtures";

// A first visit: no saved state (the config marks the tour as seen for every other spec).
test.use({ storageState: { cookies: [], origins: [] } });

for (const locale of ["ar", "en"] as const) {
  test(`first visit shows the tour, setup, then never again (${locale})`, async ({ page }) => {
    await page.goto(`/${locale}/`);
    const dialog = page.getByRole("dialog");
    await expect(dialog).toBeVisible();
    await expect(page.getByTestId("tour-slide-welcome")).toBeVisible();
    // @axe-core/playwright is typed against a newer playwright-core; the runtime API it uses is the same.
    type AxePage = ConstructorParameters<typeof AxeBuilder>[0]["page"];
    const axe = await new AxeBuilder({ page: page as unknown as AxePage })
      .include(".tour")
      .withTags(["wcag2a", "wcag2aa", "wcag21a", "wcag21aa"])
      .analyze();
    expect(axe.violations.map((v) => v.id)).toEqual([]);
    for (let i = 0; i < 5; i++) await page.getByTestId("tour-next").click();
    await expect(page.getByTestId("tour-setup")).toBeVisible();
    await page.screenshot({ path: `test-results/first-run-setup-${locale}.png` });
    await page.getByTestId("tour-start").click();
    await expect(dialog).toBeHidden();
    await page.reload();
    await expect(page.locator("html")).toHaveAttribute("data-hydrated", "true");
    await expect(page.getByTestId("first-run")).toHaveCount(0);
  });
}

test("phone width: the tour fits without horizontal scroll", async ({ page }) => {
  await page.setViewportSize({ width: 360, height: 640 });
  await page.goto("/ar/");
  await expect(page.getByRole("dialog")).toBeVisible();
  const overflow = await page.evaluate(() => document.documentElement.scrollWidth - window.innerWidth);
  expect(overflow).toBeLessThanOrEqual(0);
  await page.getByTestId("tour-skip").click();
  await expect(page.getByTestId("first-run")).toHaveCount(0);
});
