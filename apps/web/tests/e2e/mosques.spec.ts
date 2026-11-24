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
    await page.route(/nominatim/, (route) =>
      route.fulfill({ status: 200, contentType: "application/json", body: "[]" }),
    );
    // Default prayer city: Makkah.
    await page.goto("/en/mosques/");
    const items = page.getByTestId("mosque");
    await expect(items).toHaveCount(3);
    await expect(items.nth(0)).toContainText("Al-Masjid al-Haram");
    await expect(items.nth(2)).toContainText("no name on the map");
    await expect(page.getByTestId("mosques-status")).toHaveText("3 mosques, nearest first");
    await expect(page.getByRole("link", { name: "© OpenStreetMap contributors" })).toBeVisible();
    // Starts from the closest distance: 1 km (500 m, 1 km, 2 km, 5 km offered).
    expect(bodies[0]).toContain('["religion"="muslim"](around:1000,');
    await expect(page.getByTestId("mosques-radius").getByRole("button")).toHaveText([
      "500 m",
      "1 km",
      "2 km",
      "5 km",
    ]);
    await expect(page.getByTestId("mosques-radius-1000")).toHaveAttribute("aria-pressed", "true");
    await page.getByTestId("mosques-radius-500").click();
    await expect.poll(() => bodies.some((b) => b.includes("around:500,"))).toBe(true);
  });

  test("nothing within 1 km: widens to 2 km by itself and says so", async ({ page }) => {
    await page.route(/nominatim/, (route) =>
      route.fulfill({ status: 200, contentType: "application/json", body: "[]" }),
    );
    await page.route(/overpass/, async (route) => {
      const body = decodeURIComponent(route.request().postData() ?? "");
      const json = body.includes("around:1000,") ? { elements: [] } : SAMPLE;
      await route.fulfill({ status: 200, contentType: "application/json", body: JSON.stringify(json) });
    });
    await page.goto("/en/mosques/");
    await expect(page.getByTestId("mosque")).toHaveCount(3);
    await expect(page.getByTestId("mosques-radius-2000")).toHaveAttribute("aria-pressed", "true");
    await expect(page.getByTestId("mosques-widened")).toHaveText(
      "No mosque is mapped within 1 km, so these are the nearest within 2 km.",
    );
  });

  test("Arabic: falls back to the last saved list when offline, and shows a retry when nothing is saved", async ({
    page,
  }) => {
    let online = true;
    await page.route(/overpass/, async (route) => {
      if (!online) return route.abort();
      await route.fulfill({ status: 200, contentType: "application/json", body: JSON.stringify(SAMPLE) });
    });
    await page.route(/nominatim/, (route) =>
      online ? route.fulfill({ status: 200, contentType: "application/json", body: "[]" }) : route.abort(),
    );
    await page.goto("/ar/mosques/");
    await expect(page.getByTestId("mosque")).toHaveCount(3);
    await expect(page.getByTestId("mosque").nth(0)).toContainText("المسجد الحرام");
    online = false;
    await page.reload();
    await expect(page.getByTestId("mosques-status")).toContainText("آخر نتيجة محفوظة");
    await expect(page.getByTestId("mosque")).toHaveCount(3);
    await page.getByTestId("mosques-radius-2000").click();
    await expect(page.getByTestId("mosques-retry")).toBeVisible();
  });
});
