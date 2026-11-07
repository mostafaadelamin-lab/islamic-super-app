import { expect, test, withHydration } from "./fixtures";
import { watchErrors } from "./helpers";

test.describe("navigation & language", () => {
  test("main nav reaches every section in both languages", async ({ page }) => {
    const w = watchErrors(page);
    await page.goto("/en/");
    const nav = page.getByRole("navigation", { name: "Main navigation" });
    for (const [name, url, h1] of [
      ["Quran", "/en/quran/", "Surahs"],
      ["Prayer", "/en/prayer/", "Prayer times"],
      ["Adhkar", "/en/adhkar/", "Morning & evening adhkar"],
      ["More", "/en/more/", "All sections"],
      ["Home", "/en/", "Peace be upon you"],
    ] as const) {
      await nav.getByRole("link", { name, exact: true }).click();
      await expect(page).toHaveURL(url);
      await expect(page.locator("h1")).toHaveText(h1);
      await expect(nav.getByRole("link", { name, exact: true })).toHaveAttribute("aria-current", "page");
    }
    // Search, bookmarks and settings live under "More"
    for (const [name, url, h1] of [
      ["Search the Quran", "/en/search/", "Search the Quran"],
      ["Bookmarks", "/en/bookmarks/", "Bookmarks"],
      ["Settings", "/en/settings/", "Settings"],
    ] as const) {
      await nav.getByRole("link", { name: "More", exact: true }).click();
      await page
        .getByTestId("section-tiles")
        .getByRole("link", { name: new RegExp(`^${name}`) })
        .click();
      await expect(page).toHaveURL(url);
      await expect(page.locator("h1")).toHaveText(h1);
      await expect(nav.getByRole("link", { name: "More", exact: true })).toHaveAttribute(
        "aria-current",
        "page",
      );
    }
    await page.getByRole("contentinfo").getByRole("link", { name: "About" }).click();
    await expect(page.locator("h1")).toHaveText("About");
    await page.getByRole("contentinfo").getByRole("link", { name: "Mushaf pages" }).click();
    await expect(page).toHaveURL("/en/page/1/");
    w.assertClean();
  });

  test("language switch keeps the page, flips direction and persists", async ({ page }) => {
    await page.goto("/ar/surah/36/");
    await expect(page.locator("html")).toHaveAttribute("dir", "rtl");
    await page.getByTestId("lang-switch").click();
    await expect(page).toHaveURL("/en/surah/36/");
    await expect(page.locator("html")).toHaveAttribute("dir", "ltr");
    await expect(page.locator("html")).toHaveAttribute("lang", "en");
    await page.goto("/");
    await expect(page).toHaveURL("/en/");
    await page.goto("/en/settings/");
    await expect(page.locator("html")).toHaveAttribute("data-hydrated", "true");
    await page.getByLabel("Language").selectOption("ar");
    await expect(page).toHaveURL("/ar/settings/");
    await expect(page.locator("html")).toHaveAttribute("dir", "rtl");
  });

  test("home quick links and tiles", async ({ page }) => {
    await page.goto("/ar/");
    const tiles = page.getByTestId("section-tiles").getByRole("link");
    await expect(tiles).toHaveCount(8);
    const hrefs = await tiles.evaluateAll((as) => as.map((a) => a.getAttribute("href")));
    expect(hrefs).toEqual([
      "/ar/page/1/",
      "/ar/quran/",
      "/ar/adhkar/",
      "/ar/hisn/",
      "/ar/tasbih/",
      "/ar/qibla/",
      "/ar/hajj/",
      "/ar/search/",
    ]);
    await tiles.nth(0).click();
    await expect(page).toHaveURL("/ar/page/1/");
  });
});

test.describe("theme & font size", () => {
  test("dark theme applies token colours and persists across reloads", async ({ page }) => {
    await page.goto("/en/settings/");
    const bg = () => page.evaluate(() => getComputedStyle(document.body).backgroundColor);
    await page.getByRole("radio", { name: "Light" }).check();
    expect(await bg()).toBe("rgb(245, 242, 234)"); // --color-bg light #F5F2EA (emerald + gold palette)
    await page.getByRole("radio", { name: "Dark" }).check();
    await expect(page.locator("html")).toHaveAttribute("data-theme", "dark");
    expect(await bg()).toBe("rgb(12, 23, 20)"); // --color-bg dark #0C1714
    await page.reload();
    await expect(page.locator("html")).toHaveAttribute("data-theme", "dark");
    await page.getByRole("radio", { name: "System" }).check();
    await expect(page.locator("html")).not.toHaveAttribute("data-theme", /.+/);
  });

  test("system theme follows prefers-color-scheme", async ({ browser }) => {
    const ctx = await browser.newContext({ colorScheme: "dark" });
    const page = withHydration(await ctx.newPage());
    await page.goto("/ar/");
    expect(await page.evaluate(() => getComputedStyle(document.body).backgroundColor)).toBe(
      "rgb(12, 23, 20)",
    );
    await ctx.close();
  });

  test("Quran font size (18–40) applies to the reader and persists", async ({ page }) => {
    await page.goto("/en/settings/");
    const slider = page.getByRole("slider");
    await slider.fill("40");
    await expect(page.getByRole("button", { name: "Quran font size +" })).toBeDisabled();
    await page.goto("/en/surah/1/");
    const size = await page
      .locator("article.ayah p.quran")
      .first()
      .evaluate((e) => getComputedStyle(e).fontSize);
    expect(size).toBe("40px");
    await page.goto("/en/settings/");
    await page.getByRole("button", { name: "Quran font size −" }).click();
    await page.reload();
    await expect(page.getByRole("slider")).toHaveValue("39");
    await slider.fill("18");
    await expect(page.getByRole("button", { name: "Quran font size −" })).toBeDisabled();
  });
});

test.describe("Quran", () => {
  test("surah index has 114 surahs and filters", async ({ page }) => {
    await page.goto("/ar/quran/");
    await expect(page.getByTestId("surah-list").locator("li")).toHaveCount(114);
    await page.getByLabel("تصفية السور").fill("الكهف");
    await expect(page.getByTestId("surah-list").locator("li")).toHaveCount(1);
    // a surah opens in the Mushaf at its first page
    await page.getByTestId("surah-list").getByTestId("surah-open").click();
    await expect(page).toHaveURL("/ar/page/293/");
    await expect(page.getByTestId("page-surahs")).toContainText("سورة الكهف");
    await expect(page.getByTestId("sura-band")).toHaveText("سورة الكهف");
    await expect(page.getByTestId("ayah-marker").first()).toHaveText(/۝/);
    // the list view is still one tap away
    await page.goto("/ar/quran/");
    await page.getByLabel("تصفية السور").fill("الكهف");
    await page.getByTestId("surah-list").getByTestId("surah-list-view").click();
    await expect(page).toHaveURL("/ar/surah/18/");
    await expect(page.locator("article.ayah")).toHaveCount(110);
    await expect(page.getByTestId("ayah-marker").first()).toHaveText("۝١");
  });

  test("surah reader: translation toggle, neighbours and Mushaf link", async ({ page }) => {
    await page.goto("/en/surah/112/");
    await expect(page.locator("article.ayah")).toHaveCount(4);
    await expect(page.getByTestId("ayah-marker").first()).toHaveText("(1)");
    await page.getByTestId("translation-toggle").check();
    await expect(page.locator(".translation").first()).toContainText('Say, "He is Allah, [who is] One');
    await page.reload();
    await expect(page.getByTestId("translation-toggle")).toBeChecked();
    await expect(page.locator(".translation")).toHaveCount(4);
    await page.getByRole("link", { name: /Next surah/ }).click();
    await expect(page).toHaveURL("/en/surah/113/");
    await page.getByRole("link", { name: /Previous surah/ }).click();
    await expect(page).toHaveURL("/en/surah/112/");
    await page.getByRole("link", { name: /Read in the Mushaf/ }).click();
    await expect(page).toHaveURL("/en/page/604/");
  });

  test("display map is applied only to rendered text", async ({ page, request }) => {
    await page.goto("/ar/surah/18/");
    const shown = await page.locator("#a-2 p.quran").innerText();
    expect(shown).toContain("ࣰ");
    expect(shown).not.toContain("ٗ");
    const canonical = (await (await request.get("/data/quran-text.json")).json()) as string[][];
    expect(canonical[17]![1]).toContain("ٗ");
    expect(canonical[17]![1]).not.toContain("ࣰ");
  });

  test("Mushaf page reader: header, prev/next, arrow keys and go-to-page validation", async ({ page }) => {
    const w = watchErrors(page);
    await page.goto("/ar/page/1/");
    await expect(page.locator("h1")).toHaveText("الصفحة ١ من ٦٠٤");
    await expect(page.getByTestId("juz")).toHaveText("الجزء ١");
    await page.getByTestId("next-page").click();
    await expect(page).toHaveURL("/ar/page/2/");
    await page.locator("body").press("ArrowLeft"); // RTL: left = next
    await expect(page).toHaveURL("/ar/page/3/");
    const text = (await (await page.request.get("/data/quran-text.json")).json()) as string[][];
    await expect(page.getByTestId("mushaf-page")).toContainText(text[1]![5]!); // 2:6 opens page 3
    await page.locator("body").press("ArrowRight");
    await expect(page).toHaveURL("/ar/page/2/");
    await page.getByTestId("prev-page").click();
    await expect(page).toHaveURL("/ar/page/1/");
    const input = page.getByLabel("اذهب إلى صفحة");
    for (const bad of ["0", "605", "abc", "1.5"]) {
      await input.fill(bad);
      await page.getByRole("button", { name: "اذهب", exact: true }).click();
      await expect(page.locator("main form").getByRole("alert")).toContainText("٦٠٤");
      await expect(page).toHaveURL("/ar/page/1/");
    }
    await input.fill("٣٠٠");
    await input.press("Enter");
    await expect(page).toHaveURL("/ar/page/300/");
    await expect(page.getByTestId("juz")).toHaveText("الجزء ١٥");
    w.assertClean();
  });

  test("English Mushaf: right arrow = next", async ({ page }) => {
    await page.goto("/en/page/10/");
    await page.locator("body").press("ArrowRight");
    await expect(page).toHaveURL("/en/page/11/");
    await expect(page.locator("h1")).toHaveText("Page 11 of 604");
  });

  test("search is diacritic-insensitive and links to the ayah", async ({ page }) => {
    await page.goto("/en/search/");
    await page.getByLabel("Search the Quran").fill("اياك نعبد");
    const results = page.getByTestId("search-results");
    await expect(results.locator("li")).toHaveCount(1);
    const text = (await (await page.request.get("/data/quran-text.json")).json()) as string[][];
    await expect(results.locator("p.quran")).toHaveText(text[0]![4]!); // original 1:5, unmodified
    await expect(page).toHaveURL(/\?q=/);
    await results.getByRole("link").click();
    // results open the Mushaf page with the ayah selected
    await expect(page).toHaveURL("/en/page/1/#a-1-5");
    await expect(page.getByTestId("ayah-actions")).toContainText("Al-Fatihah, ayah 5");
    await expect(page.locator('.seg[data-ayah="1:5"]').first()).toHaveClass(/selected/);
    await page.goto("/en/search/?q=ق");
    await expect(page.getByText("Type at least 2 Arabic letters.")).toBeVisible();
    await page.getByLabel("Search the Quran").fill("الرحمة");
    await expect(page.getByTestId("search-status")).toContainText("results");
  });

  test("bookmarks: add in reader, survive reload, list, remove; continue reading", async ({ page }) => {
    const w = watchErrors(page);
    await page.goto("/en/surah/2/");
    await page.getByTestId("bookmark-255").click();
    await expect(page.getByTestId("bookmark-255")).toHaveAttribute("data-bookmarked", "true");
    await page.getByTestId("bookmark-1").click();
    await page.reload();
    await expect(page.getByTestId("bookmark-255")).toHaveAttribute("data-bookmarked", "true");
    await expect(page.getByTestId("bookmark-255")).toHaveText("Remove bookmark");
    await page.goto("/en/bookmarks/");
    await expect(page.getByTestId("bookmark-list").locator("li")).toHaveCount(2);
    await page.getByRole("button", { name: "Remove — Al-Baqarah, ayah 1" }).click();
    await expect(page.getByTestId("bookmark-list").locator("li")).toHaveCount(1);
    await page.reload();
    await expect(page.getByTestId("bookmark-list").locator("li")).toHaveCount(1);
    await page.getByRole("link", { name: "Al-Baqarah, ayah 255" }).click();
    await expect(page).toHaveURL("/en/surah/2/#a-255");
    await expect(page.locator("#a-255")).toBeInViewport();
    // reading position was recorded; continue reading from home
    await page.waitForTimeout(300);
    await page.goto("/en/");
    const cont = page.getByTestId("continue-surah");
    await expect(cont).toContainText("Al-Baqarah");
    await cont.click();
    await expect(page).toHaveURL(/\/en\/surah\/2\/#a-\d+/);
    await page.goto("/en/");
    await page.getByTestId("continue-page").click();
    await expect(page).toHaveURL(/\/en\/page\/\d+\//);
    w.assertClean();
  });
});

test.describe("prayer", () => {
  test("city, method, asr, adjustments, countdown and qibla", async ({ page }) => {
    const w = watchErrors(page);
    await page.goto("/en/prayer/");
    const rows = page.getByTestId("times").locator("tbody tr");
    await expect(rows).toHaveCount(6);
    await page.getByLabel("City").selectOption({ label: "Cairo" });
    await expect(page.getByText("Time zone: Africa/Cairo")).toBeVisible();
    const fajr = rows.nth(0).locator("td");
    const before = await fajr.innerText();
    await page.getByRole("button", { name: "Increase Fajr by one minute" }).click();
    await expect(fajr).not.toHaveText(before);
    await page.getByLabel("Fajr", { exact: true }).fill("-30");
    await expect(page.getByRole("button", { name: "Decrease Fajr by one minute" })).toBeDisabled();
    await page.getByRole("button", { name: "Reset adjustments" }).click();
    await expect(fajr).toHaveText(before);
    await page.getByLabel("Calculation method").selectOption("mwl");
    await expect(fajr).not.toHaveText(before); // MWL 18° vs Egypt 19.5°
    const asr = rows.nth(3).locator("td");
    const asrStd = await asr.innerText();
    await page.getByLabel("Asr method").selectOption("hanafi");
    await expect(asr).not.toHaveText(asrStd);
    const c1 = await page.getByTestId("countdown").innerText();
    await expect(page.getByTestId("countdown")).not.toHaveText(c1, { timeout: 3000 });
    await expect(page.getByTestId("qibla-bearing")).toContainText("°");
    await expect(page.getByTestId("compass")).toBeVisible();
    await page.reload();
    await expect(page.getByLabel("City")).toHaveValue("c1");
    await expect(page.getByLabel("Asr method")).toHaveValue("hanafi");
    w.assertClean();
  });

  test("use my location (granted)", async ({ browser }) => {
    const ctx = await browser.newContext({
      geolocation: { latitude: 51.5074, longitude: -0.1278 },
      permissions: ["geolocation"],
      timezoneId: "Europe/London",
    });
    const page = withHydration(await ctx.newPage());
    await page.goto("/en/prayer/");
    await page.getByRole("button", { name: "Use my location" }).click();
    await expect(page.getByLabel("City")).toHaveValue("__custom");
    await expect(page.getByText("Time zone: Europe/London")).toBeVisible();
    await expect(page.getByTestId("qibla-bearing")).toContainText("119.0");
    await ctx.close();
  });

  test("use my location (denied) shows an error", async ({ browser }) => {
    const ctx = await browser.newContext({ permissions: [] });
    const page = withHydration(await ctx.newPage());
    await page.goto("/ar/prayer/");
    await page.getByRole("button", { name: "استخدم موقعي" }).click();
    await expect(page.getByTestId("geo-error")).toContainText("رُفض إذن الموقع");
    await ctx.close();
  });

  test("high-latitude note (London, midsummer)", async ({ page }) => {
    await page.clock.setFixedTime(new Date("2026-06-21T10:00:00Z"));
    await page.goto("/en/prayer/");
    // Wait for hydration: selecting before React attaches handlers is lost (seen once on WebKit in CI).
    await expect(page.getByTestId("times").locator("tbody tr")).toHaveCount(6);
    await page.getByLabel("City").selectOption({ label: "London" });
    await expect(page.getByTestId("highlat-note")).toContainText("Fajr, Isha");
  });

  test("home shows the next prayer countdown", async ({ page }) => {
    await page.goto("/ar/");
    await expect(page.getByTestId("home-countdown")).toHaveText(/^[٠-٩]+:[٠-٩]{2}:[٠-٩]{2}$/);
  });
});

test.describe("account (no server)", () => {
  test("unreachable API shows a visible network/CORS error", async ({ page }) => {
    await page.goto("/en/settings/");
    await page.getByLabel("API base URL").fill("http://127.0.0.1:9");
    await page.getByRole("button", { name: "Save URL" }).click();
    await expect(page.getByRole("status").filter({ hasText: "Saved." })).toBeVisible();
    await page.getByLabel("Email").fill("someone@example.org");
    await page.getByLabel(/^Password/).fill("0123456789");
    await page.getByRole("button", { name: "Sign in" }).click();
    await expect(page.getByTestId("account-status").getByRole("alert")).toContainText(
      "Could not reach the server",
    );
  });
  test("offline sign-in attempt says so", async ({ page, context }) => {
    await page.goto("/en/settings/");
    await page.getByLabel("Email").fill("someone@example.org");
    await page.getByLabel(/^Password/).fill("0123456789");
    await context.setOffline(true);
    await page.getByRole("button", { name: "Create account" }).click();
    await expect(page.getByTestId("account-status").getByRole("alert")).toContainText("You are offline");
    await context.setOffline(false);
  });
});

test("about page: free-forever statement and sources", async ({ page }) => {
  await page.goto("/en/about/");
  await expect(page.getByTestId("free-statement")).toContainText(
    "no ads, no subscriptions, no in-app purchases",
  );
  await expect(page.getByText(/quranenc\.com/)).toBeVisible();
  await expect(page.getByText(/Saheeh International/)).toBeVisible();
  await expect(page.getByText("Madinah Mushaf KFGQPC 1405H")).toBeVisible();
  const [lic] = await Promise.all([
    page.waitForResponse(/OFL\.txt/),
    page.getByRole("link", { name: "Amiri Quran — OFL" }).click(),
  ]);
  expect(lic.status()).toBe(200);
});
