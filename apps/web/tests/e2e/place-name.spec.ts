import { expect, test } from "./fixtures";

// Owner 2026-11-16: with "use my location" the home showed only «موقعي»; it shows the area like the app.
test("home shows the area name of the viewer's own position", async ({ page }) => {
  await page.route("https://nominatim.openstreetmap.org/**", (route) =>
    route.fulfill({
      contentType: "application/json",
      headers: { "Access-Control-Allow-Origin": "*" },
      body: JSON.stringify({ address: { town: "مدينتي", country: "مصر" } }),
    }),
  );
  await page.addInitScript(() =>
    localStorage.setItem(
      "rattil.prayer",
      JSON.stringify({ cityId: "cairo", custom: { lat: 30.1, lng: 31.6, tz: "Africa/Cairo" } }),
    ),
  );
  await page.goto("/ar/");
  await expect(page.getByText("مصر - مدينتي").first()).toBeVisible();
});
