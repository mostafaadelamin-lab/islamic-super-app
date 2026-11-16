import { devices } from "@playwright/test";
import { expect, test } from "./fixtures";
import { noHorizontalOverflow } from "./helpers";

/**
 * Phones get the website look too (owner 2026-11-16): header with a ☰ drawer holding the menus, hero,
 * section cards and the site-map footer; no app-style bottom tab bar on the web.
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
      deviceScaleFactor: 1,
      isMobile: device.isMobile,
      hasTouch: device.hasTouch,
    });

    test("home looks like the website and the ☰ menu opens the sections", async ({ page }) => {
      await page.goto("/ar/");
      await expect(page.locator(".main-nav")).toBeHidden();
      await expect(page.getByTestId("hero-read")).toBeVisible();
      await expect(page.getByTestId("home-explore")).toBeVisible();
      await expect(page.locator(".site-footer-col").first()).toBeVisible();
      await noHorizontalOverflow(page);

      const nav = page.locator("#site-nav");
      await expect(nav).toBeHidden();
      await page.getByTestId("site-burger").click();
      await expect(nav).toBeVisible();
      await nav.locator(".site-nav-group > button").first().click();
      const first = nav.locator(".site-menu-list a").first();
      await expect(first).toBeVisible();
      await first.click();
      await expect(page).toHaveURL(/\/ar\/page\/1\/?$/);
      await expect(nav).toBeHidden();
    });

    test("the radio station name is shown in full", async ({ page }) => {
      await page.goto("/ar/");
      const select = page.locator(".radio-reciter select").first();
      await expect(select).toBeVisible();
      const { sw, cw } = await select.evaluate((el) => {
        const s = el as HTMLSelectElement;
        const c = document.createElement("span");
        c.style.cssText = `position:absolute;visibility:hidden;white-space:nowrap;font:${getComputedStyle(s).font}`;
        c.textContent = s.selectedOptions[0]?.text ?? "";
        document.body.append(c);
        const w = c.getBoundingClientRect().width;
        c.remove();
        return { sw: w, cw: s.clientWidth };
      });
      expect(sw).toBeLessThan(cw);
    });
  });
}
