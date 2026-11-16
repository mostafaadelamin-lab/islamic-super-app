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

test.describe("Mushaf on a phone", () => {
  test.use({ ...{ viewport: devices["iPhone 13"].viewport, isMobile: true, hasTouch: true } });

  test("pinch zooms the page, one finger then pans instead of turning, and the button resets", async ({
    page,
    browserName,
  }) => {
    test.skip(browserName !== "chromium", "touch input via CDP");
    await page.addInitScript(() => {
      localStorage.setItem("rattil.readerGuide", "1");
      localStorage.setItem("rattil.readerHint", "9");
    });
    await page.goto("/ar/page/3/");
    await expect(page.getByTestId("mushaf-page").first()).toBeVisible();
    await page.getByTestId("reader-full").click();
    // the "show tools" button sits above the page, not over its first line
    const exitBox = await page.getByTestId("reader-exit-full").boundingBox();
    const frameBox = await page.getByTestId("mushaf-frame").boundingBox();
    expect(exitBox!.y + exitBox!.height).toBeLessThanOrEqual(frameBox!.y + 1);

    const cdp = await page.context().newCDPSession(page);
    const two = (d: number) => [
      { x: 195 - d, y: 330, id: 1 },
      { x: 195 + d, y: 330, id: 2 },
    ];
    await cdp.send("Input.dispatchTouchEvent", { type: "touchStart", touchPoints: two(40) });
    for (let d = 45; d <= 100; d += 5) {
      await cdp.send("Input.dispatchTouchEvent", { type: "touchMove", touchPoints: two(d) });
    }
    await cdp.send("Input.dispatchTouchEvent", { type: "touchEnd", touchPoints: [] });
    const reset = page.getByTestId("reader-zoom-reset");
    await expect(reset).toBeVisible();
    await expect(page.getByTestId("mushaf-frame")).toHaveAttribute("style", /scale\(/);

    await cdp.send("Input.dispatchTouchEvent", { type: "touchStart", touchPoints: [{ x: 100, y: 400 }] });
    for (let x = 120; x <= 300; x += 20) {
      await cdp.send("Input.dispatchTouchEvent", { type: "touchMove", touchPoints: [{ x, y: 400 }] });
    }
    await cdp.send("Input.dispatchTouchEvent", { type: "touchEnd", touchPoints: [] });
    await page.waitForTimeout(500);
    await expect(page).toHaveURL(/\/ar\/page\/3\/?$/);

    await reset.click();
    await expect(reset).toBeHidden();
    await expect(page.getByTestId("mushaf-frame")).not.toHaveAttribute("style", /scale\(/);
  });
});

test("links move between pages without a script error (theme-colour tags stay in place)", async ({
  page,
}) => {
  const errors: string[] = [];
  page.on("pageerror", (e) => errors.push(e.message));
  await page.goto("/ar/about/");
  for (const to of ["/ar/help/", "/ar/settings/", "/ar/"]) {
    await page
      .locator(`a[href="${to}"]`)
      .first()
      .evaluate((a: HTMLAnchorElement) => a.click());
    await expect(page).toHaveURL(new RegExp(`${to}$`));
    await expect(page.locator("main h1").first()).toBeAttached();
  }
  expect(errors).toEqual([]);
});
