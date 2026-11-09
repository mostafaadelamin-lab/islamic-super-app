import { test as base, expect, type Page } from "@playwright/test";

/**
 * The site is a static export: HTML is interactive only after React hydrates.
 * Interacting earlier (Playwright is faster than a person) loses input — seen in
 * CI on WebKit for a <select> and for a text field. After every navigation to an
 * app page we wait for <html data-hydrated="true">, set by ClientEffects.
 */
async function waitForHydration(page: Page, status: number | undefined): Promise<void> {
  if (status !== undefined && status >= 400) return; // static 404 page has no app shell
  const path = new URL(page.url()).pathname;
  if (!/^\/(ar|en)\//.test(path)) return; // root redirect page has no app shell
  await expect(page.locator("html")).toHaveAttribute("data-hydrated", "true", { timeout: 15_000 });
}

/** Makes page.goto/page.reload wait for hydration. Use for pages from browser.newContext(). */
export function withHydration(page: Page): Page {
  const goto = page.goto.bind(page);
  const reload = page.reload.bind(page);
  page.goto = async (...args: Parameters<Page["goto"]>) => {
    const res = await goto(...args);
    await waitForHydration(page, res?.status());
    return res;
  };
  page.reload = async (...args: Parameters<Page["reload"]>) => {
    const res = await reload(...args);
    await waitForHydration(page, res?.status());
    return res;
  };
  return page;
}

/** The reels page asks the API for automatic reels; tests answer with an empty feed unless they route their own. */
export const EMPTY_REELS_FEED = { schema: "reels-feed.v1", sources: [], items: [] };

export const test = base.extend({
  context: async ({ context }, provide) => {
    await context.route("**/v1/reels/feed", (r) => r.fulfill({ json: EMPTY_REELS_FEED }));
    await provide(context);
  },
  page: async ({ page }, provide) => {
    await provide(withHydration(page));
  },
});

export { expect };
