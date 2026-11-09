import { expect, test } from "@playwright/test";

// The Overpass API is mocked: the real servers are not reachable from the test environment.
const SAMPLE = {
  elements: [
    {
      type: "way",
      id: 2,
      center: { lat: 21.43, lon: 39.83 },
      tags: { name: "مسجد ب", "name:en": "Mosque B" },
    },
    {
      type: "node",
      id: 1,
      lat: 21.4228,
      lon: 39.8262,
      tags: { name: "المسجد الحرام", "name:en": "Al-Masjid al-Haram" },
    },
    { type: "node", id: 3, lat: 21.44, lon: 39.84, tags: {} },
  ],
};

test.describe("nearby mosques (OpenStreetMap)", () => {
  test("lists mosques nearest first, with distances and OSM credit; radius re-queries", async ({ page }) => {
    const bodies: string[] = [];
    await page.route(/overpass/, async (route) => {
      bodies.push(decodeURIComponent(route.request().postData() ?? ""));
      await route.fulfill({ status: 200, contentType: "application/json", body: JSON.stringify(SAMPLE) });
    });
    // Default prayer city: Makkah.
    await page.goto("/en/mosques/");
    const items = page.getByTestId("mosque");
    await expect(items).toHaveCount(3);
    await expect(items.nth(0)).toContainText("Al-Masjid al-Haram");
    await expect(items.nth(2)).toContainText("no name on the map");
    await expect(page.getByTestId("mosques-status")).toHaveText("3 mosques, nearest first");
    await expect(page.getByRole("link", { name: "© OpenStreetMap contributors" })).toBeVisible();
    expect(bodies[0]).toContain('["religion"="muslim"](around:5000,');
    await page.getByTestId("mosques-radius").selectOption("10000");
    await expect.poll(() => bodies.some((b) => b.includes("around:10000,"))).toBe(true);
  });

  test("Arabic: falls back to the last saved list when offline, and shows a retry when nothing is saved", async ({
    page,
  }) => {
    let online = true;
    await page.route(/overpass/, async (route) => {
      if (!online) return route.abort();
      await route.fulfill({ status: 200, contentType: "application/json", body: JSON.stringify(SAMPLE) });
    });
    await page.goto("/ar/mosques/");
    await expect(page.getByTestId("mosque")).toHaveCount(3);
    await expect(page.getByTestId("mosque").nth(0)).toContainText("المسجد الحرام");
    online = false;
    await page.reload();
    await expect(page.getByTestId("mosques-status")).toContainText("آخر نتيجة محفوظة");
    await expect(page.getByTestId("mosque")).toHaveCount(3);
    await page.getByTestId("mosques-radius").selectOption("2000");
    await expect(page.getByTestId("mosques-retry")).toBeVisible();
  });
});
