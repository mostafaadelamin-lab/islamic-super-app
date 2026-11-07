import { readFileSync } from "node:fs";
import type { Page, Route } from "@playwright/test";
import { expect, test, withHydration } from "./fixtures";
import { noHorizontalOverflow, watchErrors } from "./helpers";

/**
 * Milestone 2: Mushaf reader (15 lines, swipe, slider, ayah actions), recitation player, home dashboard,
 * adhkar, Hisn al-Muslim, tasbih, live Qibla compass, Hajj & Umrah guide, bottom tabs.
 *
 * Audio: everyayah.com is NOT contacted in these tests. Every request to it is answered by a local silent
 * MP3 (tests/e2e/fixtures/silence.mp3) — tests that rely on this say "mocked network" in their names.
 */
const SILENCE = readFileSync(new URL("./fixtures/silence.mp3", import.meta.url));
const AUDIO_HOST = "https://everyayah.com/**";

async function mockAudio(page: Page, mode: "ok" | "fail" = "ok"): Promise<string[]> {
  const urls: string[] = [];
  await page.route(AUDIO_HOST, async (route: Route) => {
    urls.push(route.request().url());
    if (mode === "fail") await route.fulfill({ status: 404, body: "not found" });
    else
      await route.fulfill({
        status: 200,
        body: SILENCE,
        headers: { "Content-Type": "audio/mpeg", "Access-Control-Allow-Origin": "*" },
      });
  });
  return urls;
}

const file = (u: string): string => u.split("/").slice(-2).join("/");
const quranText = async (page: Page): Promise<string[][]> =>
  (await (await page.request.get("/data/quran-text.json")).json()) as string[][];

async function readyMushaf(page: Page, path: string): Promise<void> {
  await page.goto(path);
  await expect(page.getByTestId("mushaf-stage")).toHaveAttribute("data-ready", "true");
}

/** Drags the page horizontally with the mouse (pointer events), like a finger swipe. */
async function swipe(page: Page, dx: number): Promise<void> {
  const box = (await page.getByTestId("mushaf-stage").boundingBox())!;
  const y = box.y + box.height / 2;
  const x0 = box.x + box.width / 2 - dx / 2;
  await page.mouse.move(x0, y);
  await page.mouse.down();
  for (let i = 1; i <= 8; i++) await page.mouse.move(x0 + (dx * i) / 8, y);
  await page.mouse.up();
}

test.describe("Mushaf reader (15-line Madinah layout)", () => {
  for (const vp of [
    { name: "phone", width: 390, height: 844 },
    { name: "desktop", width: 1280, height: 900 },
  ]) {
    test(`page 3 @ ${vp.name}: 15 justified lines fill the frame without overflow`, async ({ page }) => {
      await page.setViewportSize(vp);
      await readyMushaf(page, "/ar/page/3/");
      await page.evaluate(() => document.fonts.ready);
      await page.waitForTimeout(150);
      const lines = await page.locator(".m-line.m-text").evaluateAll((els) =>
        els.map((e) => ({
          client: e.clientWidth,
          scroll: e.scrollWidth,
          inner: (e.querySelector(".m-in") as HTMLElement).getBoundingClientRect().width,
        })),
      );
      expect(lines).toHaveLength(15);
      for (const l of lines) {
        expect(l.scroll, "line must not overflow").toBeLessThanOrEqual(l.client + 1);
        expect(l.inner, "line is justified edge to edge").toBeGreaterThanOrEqual(l.client - 2);
      }
      // the whole frame is inside the viewport width and the page does not scroll sideways
      const frame = (await page.getByTestId("mushaf-frame").boundingBox())!;
      expect(frame.x).toBeGreaterThanOrEqual(0);
      expect(frame.x + frame.width).toBeLessThanOrEqual(vp.width);
      await noHorizontalOverflow(page);
      // Amiri Quran is the font of the page
      expect(await page.getByTestId("mushaf-page").evaluate((e) => getComputedStyle(e).fontFamily)).toContain(
        "Amiri Quran",
      );
    });
  }

  test("page 1: 8 centred lines, surah band, Arabic-Indic ayah markers; header shows surah, juz, page", async ({
    page,
  }) => {
    await page.goto("/ar/page/1/");
    await expect(page.locator(".m-line")).toHaveCount(8);
    await expect(page.getByTestId("mushaf-page")).toHaveClass(/centred/);
    await expect(page.getByTestId("sura-band")).toHaveText("سورة الفاتحة");
    await expect(page.getByTestId("ayah-marker").locator("[aria-hidden]")).toHaveText([
      "۝١",
      "۝٢",
      "۝٣",
      "۝٤",
      "۝٥",
      "۝٦",
      "۝٧",
    ]);
    await expect(page.getByTestId("page-surahs")).toContainText("سورة الفاتحة");
    await expect(page.getByTestId("juz")).toHaveText("الجزء ١");
    await expect(page.locator("h1")).toHaveText("الصفحة ١ من ٦٠٤");
  });

  test("rendered text is the canonical text with only the display glyph map applied", async ({ page }) => {
    const text = await quranText(page);
    await page.goto("/ar/page/293/");
    const shown = (await page.locator('.seg[data-ayah="18:2"]').allInnerTexts()).join(" ");
    const canonical = text[17]![1]!;
    expect(canonical).toContain("ٗ");
    expect(shown).not.toContain("ٗ");
    expect(shown.replaceAll("ࣰ", "ٗ").replaceAll("ࣱ", "ٞ").replaceAll("ࣲ", "ٖ")).toBe(canonical);
    await expect(page.getByTestId("basmala")).toHaveText(text[0]![0]!);
  });

  test("swipe turns pages like a book (Arabic: drag right = next), short drags snap back", async ({
    page,
  }) => {
    const w = watchErrors(page);
    await readyMushaf(page, "/ar/page/3/");
    await swipe(page, 220);
    await expect(page).toHaveURL("/ar/page/4/");
    await expect(page.locator("h1")).toHaveText("الصفحة ٤ من ٦٠٤");
    await expect(page.getByTestId("mushaf-page")).toHaveAttribute("data-page", "4");
    await swipe(page, -220);
    await expect(page).toHaveURL("/ar/page/3/");
    await swipe(page, 20); // too short: stays
    await page.waitForTimeout(400);
    await expect(page).toHaveURL("/ar/page/3/");
    // the reading position follows
    await page.goto("/ar/");
    await expect(page.getByTestId("continue-page")).toHaveText("صفحة ٣");
    w.assertClean();
  });

  test("swipe in English: drag left = next; keyboard arrows and buttons", async ({ page }) => {
    await readyMushaf(page, "/en/page/10/");
    await swipe(page, -220);
    await expect(page).toHaveURL("/en/page/11/");
    await page.locator("body").press("ArrowRight");
    await expect(page).toHaveURL("/en/page/12/");
    await page.getByTestId("prev-page").click();
    await expect(page).toHaveURL("/en/page/11/");
    await page.getByTestId("next-page").click();
    await expect(page).toHaveURL("/en/page/12/");
    await expect(page.locator("h1")).toHaveText("Page 12 of 604");
  });

  test("page slider jumps to a page and remembers it", async ({ page }) => {
    await readyMushaf(page, "/ar/page/1/");
    await page.getByTestId("page-slider").fill("250");
    await expect(page).toHaveURL("/ar/page/250/");
    await expect(page.getByTestId("slider-value")).toHaveText("٢٥٠");
    await expect(page.getByTestId("juz")).toHaveText("الجزء ١٣");
    await page.reload();
    await expect(page.getByTestId("page-slider")).toHaveValue("250");
    await page.goto("/ar/quran/");
    await expect(page.getByTestId("continue-page")).toHaveAttribute("href", "/ar/page/250/");
  });

  test("tap an ayah: highlight, bookmark, copy, close", async ({ page, context, browserName }) => {
    if (browserName === "chromium") await context.grantPermissions(["clipboard-read", "clipboard-write"]);
    const text = await quranText(page);
    await readyMushaf(page, "/ar/page/3/");
    await page.getByRole("button", { name: "البقرة، الآية ٧ — خيارات الآية" }).click();
    const bar = page.getByTestId("ayah-actions");
    await expect(bar).toContainText("البقرة، الآية ٧");
    for (const seg of await page.locator('.seg[data-ayah="2:7"]').all())
      await expect(seg).toHaveClass(/selected/);
    await bar.getByTestId("act-bookmark").click();
    await expect(bar.getByTestId("act-bookmark")).toHaveAttribute("data-bookmarked", "true");
    await bar.getByTestId("act-copy").click();
    await expect(bar.getByTestId("mushaf-notice")).toHaveText("نُسخت الآية.");
    if (browserName === "chromium") {
      expect(await page.evaluate(() => navigator.clipboard.readText())).toBe(
        `${text[1]![6]} — البقرة، الآية ٧`,
      );
    }
    await bar.getByTestId("act-close").click();
    await expect(bar).toBeHidden();
    // tapping words selects their ayah too
    await page.locator('.seg[data-ayah="2:10"]').first().click();
    await expect(page.getByTestId("ayah-actions")).toContainText("البقرة، الآية ١٠");
    await page.keyboard.press("Escape");
    await expect(page.getByTestId("ayah-actions")).toBeHidden();
    await page.goto("/ar/bookmarks/");
    await expect(page.getByTestId("bookmark-list").locator("li")).toHaveCount(1);
    await expect(page.getByTestId("bookmark-list")).toContainText("البقرة، الآية ٧");
  });
});

test.describe("recitation (mocked network: everyayah.com answered by a local silent MP3)", () => {
  test("play page: basmala first, then each ayah; highlight; stop (mocked network)", async ({ page }) => {
    const urls = await mockAudio(page);
    await readyMushaf(page, "/ar/page/2/");
    await expect(page.getByTestId("player")).toBeHidden();
    await page.getByTestId("play-page").click();
    await expect(page.getByTestId("player")).toBeVisible();
    await expect(page.getByTestId("player-status")).toContainText("اتصال");
    await expect.poll(() => urls.map(file)).toContain("Alafasy_128kbps/002001.mp3");
    expect(file(urls[0]!)).toBe("Alafasy_128kbps/001001.mp3"); // basmala before al-Baqarah 1
    await expect(page.locator(".seg.playing").first()).toHaveAttribute("data-ayah", /^2:/);
    await expect.poll(() => urls.map(file), { timeout: 15_000 }).toContain("Alafasy_128kbps/002003.mp3");
    await page.getByTestId("player-stop").click();
    await expect(page.getByTestId("player")).toBeHidden();
    await expect(page.locator(".seg.playing")).toHaveCount(0);
  });

  test("play from a selected ayah continues across pages and turns the page (mocked network)", async ({
    page,
  }) => {
    const urls = await mockAudio(page);
    await readyMushaf(page, "/ar/page/2/");
    await page.getByRole("button", { name: "البقرة، الآية ٥ — خيارات الآية" }).click();
    await page.getByTestId("act-play").click();
    await expect(page.getByTestId("player-now")).toHaveText("البقرة، الآية ٥");
    expect(file(urls[0]!)).toBe("Alafasy_128kbps/002005.mp3"); // no basmala in the middle of a surah
    // 2:6 is on page 3: the reader follows
    await expect(page).toHaveURL("/ar/page/3/", { timeout: 15_000 });
    await expect(page.locator('.seg.playing[data-ayah="2:6"]').first()).toBeVisible();
    await expect(page.getByTestId("player-now")).toHaveText("البقرة، الآية ٦");
    await page.getByTestId("player-stop").click();
  });

  test("controls: pause/resume, next/previous ayah, repeat, reciter choice is saved (mocked network)", async ({
    page,
  }) => {
    const urls = await mockAudio(page);
    await readyMushaf(page, "/en/page/604/");
    await page.getByTestId("play-surah").click(); // the first surah on the page: al-Ikhlas
    await expect(page.getByTestId("player-now")).toHaveText(/Al-Ikhlas/);
    await page.getByTestId("player-toggle").click();
    await expect(page.getByTestId("player-toggle")).toHaveAttribute("data-state", "paused");
    await page.getByTestId("player-next").click();
    await expect(page.getByTestId("player-now")).toHaveText(/Al-Ikhlas, ayah [12]/);
    await page.getByTestId("player-reciter").selectOption("Husary_128kbps");
    await page.getByTestId("player-next").click();
    await expect.poll(() => urls.at(-1)).toMatch(/Husary_128kbps\/11200[23]\.mp3$/);
    await page.getByTestId("player-prev").click();
    await page.getByTestId("player-repeat").selectOption("3");
    await page.getByTestId("player-stop").click();
    // the choice is persisted and shown in Settings
    await page.goto("/en/settings/");
    await expect(page.getByLabel("Reciter")).toHaveValue("Husary_128kbps");
    await expect(page.getByLabel("Repeat each ayah")).toHaveValue("3");
    await page.getByLabel("Reciter").selectOption("Maher_AlMuaiqly_64kbps");
    await readyMushaf(page, "/en/page/604/");
    await page.getByTestId("play-page").click();
    await expect.poll(() => urls.at(-1)).toBe("https://everyayah.com/data/Maher_AlMuaiqly_64kbps/001001.mp3");
    await page.getByTestId("player-stop").click();
  });

  test("a failed audio request shows a clear error (mocked network returning 404)", async ({ page }) => {
    await mockAudio(page, "fail");
    await readyMushaf(page, "/ar/page/50/");
    await page.getByTestId("play-page").click();
    await expect(page.getByTestId("player-error")).toContainText("تعذّر تحميل التلاوة");
    await page.getByTestId("player-stop").click();
    await expect(page.getByTestId("player")).toBeHidden();
  });

  test("offline: playing says that recitation needs the internet", async ({ page, context, browserName }) => {
    test.skip(browserName === "webkit", "WebKit's setOffline does not affect media requests reliably");
    await mockAudio(page);
    await readyMushaf(page, "/en/page/5/");
    await context.setOffline(true);
    await page.getByTestId("play-page").click();
    await expect(page.getByTestId("player-error")).toContainText("You are offline");
    await context.setOffline(false);
  });
});

test.describe("home", () => {
  test("next prayer with a live countdown, today's times, Hijri + Gregorian dates, city", async ({
    page,
  }) => {
    await page.goto("/en/");
    const cd = page.getByTestId("home-countdown");
    await expect(cd).toHaveText(/^\d+:\d{2}:\d{2}$/);
    const first = await cd.innerText();
    await expect(cd).not.toHaveText(first, { timeout: 3000 });
    await expect(page.getByTestId("home-times").locator("li")).toHaveCount(6);
    await expect(page.getByTestId("home-times").locator("li.next")).toHaveCount(1);
    await expect(page.getByTestId("home-place")).toHaveText("Makkah");
    await expect(page.getByTestId("home-hijri")).toHaveText(/\d{4} AH/);
    await expect(page.getByTestId("home-gregorian")).toHaveText(/\d{4}/);
    await page.getByRole("link", { name: "All prayer times" }).click();
    await expect(page).toHaveURL("/en/prayer/");
    await page.getByLabel("City").selectOption({ label: "Cairo" });
    await page.goto("/en/");
    await expect(page.getByTestId("home-place")).toHaveText("Cairo");
  });

  test("Arabic home: Arabic-Indic countdown and section tiles", async ({ page }) => {
    await page.goto("/ar/");
    await expect(page.getByTestId("home-countdown")).toHaveText(/^[٠-٩]+:[٠-٩]{2}:[٠-٩]{2}$/);
    await expect(page.getByTestId("home-hijri")).toHaveText(/هـ/);
    await page
      .getByTestId("section-tiles")
      .getByRole("link", { name: /أذكار الصباح والمساء/ })
      .click();
    await expect(page).toHaveURL("/ar/adhkar/");
  });
});

test.describe("navigation", () => {
  test("phone: bottom tab bar with five tabs; desktop: tabs in the top bar", async ({ page }) => {
    await page.setViewportSize({ width: 390, height: 844 });
    await page.goto("/ar/");
    const nav = page.getByRole("navigation", { name: "التنقل الرئيسي" });
    await expect(nav.getByRole("link")).toHaveCount(5);
    const box = (await nav.boundingBox())!;
    expect(Math.round(box.y + box.height)).toBe(844);
    await nav.getByRole("link", { name: "الأذكار" }).click();
    await expect(page).toHaveURL("/ar/adhkar/");
    await nav.getByRole("link", { name: "المزيد" }).click();
    await expect(page).toHaveURL("/ar/more/");
    await expect(page.getByTestId("section-tiles").getByRole("link")).toHaveCount(12);
    await page.setViewportSize({ width: 1280, height: 900 });
    const top = (await nav.boundingBox())!;
    expect(top.y).toBeLessThan(80);
  });

  test("every section on the More page opens", async ({ page, request }) => {
    for (const locale of ["ar", "en"]) {
      await page.goto(`/${locale}/more/`);
      const hrefs = await page
        .getByTestId("section-tiles")
        .getByRole("link")
        .evaluateAll((as) => as.map((a) => a.getAttribute("href")!));
      expect(hrefs).toHaveLength(12);
      for (const h of hrefs) expect((await request.get(h)).status(), h).toBe(200);
    }
  });
});

test.describe("adhkar", () => {
  test("morning/evening tabs, per-item counters that stop at the count, progress, reset, persistence", async ({
    page,
  }) => {
    const w = watchErrors(page);
    await page.goto("/ar/adhkar/#morning");
    await expect(page.getByTestId("session-morning")).toHaveAttribute("aria-pressed", "true");
    const items = page.getByTestId("dhikr");
    await expect(items).toHaveCount(27);
    await expect(page.getByTestId("adhkar-progress")).toHaveText("أتممت ٠ من ٢٧");
    const first = items.nth(0).getByTestId("dhikr-count");
    await first.click();
    await expect(first).toBeDisabled();
    await expect(items.nth(0)).toHaveClass(/done/);
    // al-Ikhlas: three times
    const ikhlas = items.nth(3).getByTestId("dhikr-count");
    const ikhlasShown = ikhlas.locator("span[aria-hidden]");
    await expect(ikhlasShown).toHaveText("٠ / ٣");
    for (let i = 0; i < 3; i++) await ikhlas.click();
    await expect(ikhlasShown).toHaveText("٣ / ٣");
    await expect(ikhlas).toBeDisabled();
    await expect(page.getByTestId("adhkar-progress")).toHaveText("أتممت ٢ من ٢٧");
    await page.reload();
    await expect(page.getByTestId("adhkar-progress")).toHaveText("أتممت ٢ من ٢٧");
    await page.getByTestId("session-evening").click();
    await expect(page).toHaveURL(/#evening$/);
    await expect(items).toHaveCount(25);
    await expect(page.getByTestId("adhkar-progress")).toHaveText("أتممت ٠ من ٢٥");
    await expect(items.nth(6)).toContainText("أمسينا");
    await page.getByTestId("session-morning").click();
    await page.getByTestId("adhkar-reset").click();
    await expect(page.getByTestId("adhkar-progress")).toHaveText("أتممت ٠ من ٢٧");
    w.assertClean();
  });

  test("English UI shows the Arabic text and labels counters", async ({ page }) => {
    await page.goto("/en/adhkar/#evening");
    await expect(page.getByText("This content is available in Arabic only.")).toBeVisible();
    await expect(page.getByRole("button", { name: "Count dhikr 1: 0 of 1" })).toBeVisible();
  });

  test("Hisn al-Muslim: chapters, filter, chapter pages with next/previous", async ({ page }) => {
    await page.goto("/ar/hisn/");
    await expect(page.getByTestId("hisn-list").locator("li")).toHaveCount(134);
    await page.getByLabel("ابحث في الأبواب").fill("الصباح");
    await expect(page.getByTestId("hisn-list").locator("li")).toHaveCount(1);
    await page.getByTestId("hisn-list").getByRole("link").click();
    await expect(page).toHaveURL("/ar/hisn/29/");
    await expect(page.locator("h1")).toHaveText("أذكار الصباح والمساء");
    await expect(page.getByTestId("hisn-items").locator("li")).toHaveCount(25);
    await page.getByTestId("hisn-next").click();
    await expect(page).toHaveURL("/ar/hisn/30/");
    await page.getByTestId("hisn-prev").click();
    await expect(page).toHaveURL("/ar/hisn/29/");
  });
});

test.describe("tasbih", () => {
  test("tap counts, target completes a round, undo, reset, target choice and persistence", async ({
    page,
  }) => {
    await page.goto("/en/tasbih/");
    const tap = page.getByTestId("tasbih-tap");
    for (let i = 0; i < 3; i++) await tap.click();
    await expect(page.getByTestId("tasbih-count")).toHaveText("3");
    await page.getByTestId("tasbih-undo").click();
    await expect(page.getByTestId("tasbih-count")).toHaveText("2");
    for (let i = 0; i < 31; i++) await tap.click();
    await expect(page.getByTestId("tasbih-count")).toHaveText("0");
    await expect(page.getByTestId("tasbih-rounds")).toHaveText("Completed rounds: 1");
    await tap.click();
    await page.reload();
    await expect(page.getByTestId("tasbih-count")).toHaveText("1");
    await expect(page.getByTestId("tasbih-rounds")).toHaveText("Completed rounds: 1");
    await page.getByTestId("tasbih-target-100").click();
    await expect(page.getByTestId("tasbih-target-100")).toHaveAttribute("aria-pressed", "true");
    await expect(tap).toHaveAccessibleName("Count: 0 of 100");
    await page.getByLabel("Dhikr").selectOption("takbir");
    await expect(page.locator(".tasbih-phrase")).toHaveText("الله أكبر");
    await page.getByTestId("tasbih-reset").click();
    await expect(page.getByTestId("tasbih-rounds")).toHaveText("Completed rounds: 0");
  });
});

test.describe("qibla compass", () => {
  test("no orientation sensor: falls back to the static bearing compass", async ({ page }) => {
    await page.goto("/en/qibla/");
    await expect(page.getByTestId("qibla-bearing")).toContainText("°");
    await expect(page.getByTestId("compass-status")).toContainText("No compass sensor", { timeout: 6000 });
    await expect(page.getByTestId("live-compass")).toHaveAttribute("data-mode", "unsupported");
    await expect(page.getByTestId("qibla-needle")).toHaveAttribute("transform", /^rotate\(/);
  });

  test("live heading from deviceorientationabsolute turns the rose and detects facing the Qibla", async ({
    page,
  }) => {
    await page.goto("/en/qibla/");
    const bearing = Number((await page.getByTestId("qibla-bearing").innerText()).match(/[\d.]+/)![0]);
    // A device whose top points east (heading 90°): alpha = 360 − 90.
    await page.evaluate(() =>
      window.dispatchEvent(
        new DeviceOrientationEvent("deviceorientationabsolute", { alpha: 270, absolute: true }),
      ),
    );
    await expect(page.getByTestId("live-compass")).toHaveAttribute("data-mode", "live");
    await expect(page.getByTestId("compass-heading")).toHaveText("Device heading: 90°");
    await expect(page.getByTestId("compass-dial")).toHaveAttribute("transform", "rotate(-90.00 100 100)");
    await expect(page.getByTestId("compass-status")).toHaveText(
      "Turn the device until the gold arrow points up",
    );
    await page.evaluate(
      (b) =>
        window.dispatchEvent(
          new DeviceOrientationEvent("deviceorientationabsolute", { alpha: 360 - b, absolute: true }),
        ),
      bearing,
    );
    await expect(page.getByTestId("compass-status")).toHaveText("You are facing the Qibla");
  });

  test("iOS-style permission request (granted, then denied)", async ({ page }) => {
    // Simulates iOS: requestPermission() exists and answers with the value stored in localStorage.
    await page.addInitScript(() => {
      Object.defineProperty(DeviceOrientationEvent, "requestPermission", {
        value: () => Promise.resolve(localStorage.getItem("test.perm") ?? "granted"),
        configurable: true,
      });
    });
    await page.goto("/ar/qibla/");
    await page.getByTestId("compass-enable").click();
    await page.evaluate(() => {
      const e = new Event("deviceorientation");
      Object.assign(e, { alpha: 0, webkitCompassHeading: 45 });
      window.dispatchEvent(e);
    });
    await expect(page.getByTestId("compass-heading")).toHaveText("اتجاه الجهاز: ٤٥°");
    await page.evaluate(() => localStorage.setItem("test.perm", "denied"));
    await page.reload();
    await page.getByTestId("compass-enable").click();
    await expect(page.getByTestId("compass-status")).toContainText("لم يُسمح باستخدام البوصلة");
  });
});

test.describe("Hajj & Umrah guide", () => {
  for (const locale of ["ar", "en"] as const) {
    test(`${locale}: pending-review notice, sections and round counters`, async ({ page }) => {
      await page.goto(`/${locale}/hajj/`);
      const notice = page.getByTestId("review-notice");
      await expect(notice).toBeVisible();
      await expect(notice).toContainText(
        locale === "ar" ? "بانتظار المراجعة الشرعية" : "Pending religious review",
      );
      await expect(page.locator("#umrah")).toBeVisible();
      await expect(page.getByText("لَبَّيْكَ اللَّهُمَّ لَبَّيْكَ").first()).toBeVisible();
      const tawaf = page.getByTestId("rounds-tawaf");
      const add = tawaf.getByRole("button").first();
      for (let i = 0; i < 7; i++) await add.click();
      await expect(add).toBeDisabled();
      await expect(page.getByTestId("rounds-tawaf-status")).toHaveClass(/alert-ok/);
      await page.reload();
      await expect(tawaf.getByRole("button").first()).toBeDisabled();
      await tawaf.getByRole("button").nth(2).click();
      await expect(tawaf.getByRole("button").first()).toBeEnabled();
    });
  }
});

test("system dark theme: new pages use the dark tokens", async ({ browser }) => {
  const ctx = await browser.newContext({ colorScheme: "dark" });
  const page = withHydration(await ctx.newPage());
  await page.goto("/ar/page/3/");
  expect(await page.evaluate(() => getComputedStyle(document.body).backgroundColor)).toBe("rgb(12, 23, 20)");
  expect(await page.getByTestId("mushaf-frame").evaluate((e) => getComputedStyle(e).backgroundColor)).toBe(
    "rgb(18, 26, 23)",
  ); // --color-paper dark #121A17
  await ctx.close();
});
