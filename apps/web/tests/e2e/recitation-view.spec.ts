import AxeBuilder from "@axe-core/playwright";
import { mkdirSync, readFileSync, writeFileSync } from "node:fs";
import type { Page } from "@playwright/test";
import { expect, test } from "./fixtures";
import { EVIDENCE, SHOTS, noHorizontalOverflow } from "./helpers";
import { endItem, fakeMedia, isPlaying } from "./fake-media";

/**
 * What the reader sees while reciting: the highlight of the recited ayah must never hide text of the
 * neighbouring lines, and "Tafsir with recitation" shows the recited ayah's tafsir. Playback uses the fake
 * media element (the test ends each item itself), so nothing is fetched from everyayah.com.
 */
const TAFSIR = JSON.parse(
  readFileSync(new URL("../../../../content/tafsir/dist/muyassar.v1.json", import.meta.url), "utf8"),
) as { surahs: string[][] };
const stored = (s: number, a: number): string => TAFSIR.surahs[s - 1]![a - 1]!;

async function openMushaf(page: Page, path: string): Promise<void> {
  await page.goto(path);
  await expect(page.getByTestId("mushaf-stage")).toHaveAttribute("data-ready", "true");
  await page.evaluate(() => document.fonts.ready);
}
/** Selects an ayah by its end marker and plays from it, then closes the ayah sheet. */
async function playFrom(page: Page, marker: string): Promise<void> {
  await page.getByRole("button", { name: marker, exact: true }).click();
  await page.getByTestId("act-play").click();
  await page.getByTestId("act-close").click();
  await isPlaying(page);
}

interface Paint {
  ayah: string;
  blend: string;
  shadow: string;
  decoration: string;
  maxAlpha: number;
  /** the painted band and its own line box, in px */
  band: [number, number];
  line: [number, number];
  prevLineBottom: number | null;
  nextLineTop: number | null;
}
/** How each highlighted segment is painted: tint alpha, blend mode, and where the tint band lies. */
const paints = (page: Page, selector: string): Promise<Paint[]> =>
  page.evaluate((sel) => {
    const lines = [...document.querySelectorAll<HTMLElement>(".mushaf-page .m-line")];
    return [...document.querySelectorAll<HTMLElement>(sel)].map((el) => {
      const cs = getComputedStyle(el);
      const img = cs.backgroundImage;
      // alpha of every colour stop, e.g. "rgba(196, 140, 30, 0.3)" -> 0.3, "rgb(1, 2, 3)" -> 1
      const alphas = [...img.matchAll(/rgba?\(([^)]*)\)/g)].map((m) => {
        const parts = m[1]!.split(/[\s,/]+/).filter(Boolean);
        return parts.length > 3 ? Number.parseFloat(parts[3]!) : 1;
      });
      // the first stop position, e.g. "rgba(0, 0, 0, 0) 5.7px" -> 5.7 (the transparent overhang)
      const inset = Number.parseFloat(/([\d.]+)px/.exec(img)?.[1] ?? "0");
      const r = el.getBoundingClientRect();
      const line = el.closest<HTMLElement>(".m-line")!;
      const i = lines.indexOf(line);
      const lr = line.getBoundingClientRect();
      const style = cs as CSSStyleDeclaration & { webkitBoxDecorationBreak?: string };
      return {
        ayah: el.dataset.ayah ?? "",
        blend: cs.mixBlendMode,
        shadow: cs.boxShadow,
        decoration: cs.boxDecorationBreak || style.webkitBoxDecorationBreak || "",
        maxAlpha: Math.max(...alphas),
        band: [r.top + inset, r.bottom - inset] as [number, number],
        line: [lr.top, lr.bottom] as [number, number],
        prevLineBottom: i > 0 ? lines[i - 1]!.getBoundingClientRect().bottom : null,
        nextLineTop: i < lines.length - 1 ? lines[i + 1]!.getBoundingClientRect().top : null,
      };
    });
  }, selector);

function expectContained(list: Paint[], blend: string): void {
  expect(list.length).toBeGreaterThan(0);
  for (const p of list) {
    expect(p.maxAlpha, `tint of ${p.ayah} must be translucent`).toBeLessThan(0.35);
    expect(p.blend).toBe(blend);
    expect(p.shadow).toBe("none");
    expect(p.decoration).toBe("clone");
    // the tint stays inside the segment's own line box, so it never reaches the lines above or below
    expect(p.band[0]).toBeGreaterThanOrEqual(p.line[0] - 0.5);
    expect(p.band[1]).toBeLessThanOrEqual(p.line[1] + 0.5);
    if (p.prevLineBottom !== null) expect(p.band[0]).toBeGreaterThanOrEqual(p.prevLineBottom - 0.5);
    if (p.nextLineTop !== null) expect(p.band[1]).toBeLessThanOrEqual(p.nextLineTop + 0.5);
  }
}

/** Number of glyph (dark) pixels in a screenshot, counted in the browser from the PNG. */
async function inkPixels(page: Page, png: Buffer): Promise<number> {
  return page.evaluate(async (b64) => {
    const img = new Image();
    img.src = `data:image/png;base64,${b64}`;
    await img.decode();
    const c = document.createElement("canvas");
    c.width = img.width;
    c.height = img.height;
    const ctx = c.getContext("2d")!;
    ctx.drawImage(img, 0, 0);
    const d = ctx.getImageData(0, 0, c.width, c.height).data;
    let n = 0;
    for (let i = 0; i < d.length; i += 4) if (0.299 * d[i]! + 0.587 * d[i + 1]! + 0.114 * d[i + 2]! < 90) n++;
    return n;
  }, png.toString("base64"));
}

/** The previous rules (opaque box + 2px spread, no blending): used only to show the bug in the evidence. */
const OLD_HIGHLIGHT = `.seg.playing{background:var(--color-accent-soft)!important;box-shadow:0 0 0 2px var(--color-accent-soft)!important;mix-blend-mode:normal!important}`;

test.describe("recitation highlight never hides text (fake media element)", () => {
  for (const [label, path, marker, width] of [
    ["1:7 on page 1", "/ar/page/1/", "الفاتحة، الآية ٧ — خيارات الآية", 390],
    ["2:3 on page 2", "/ar/page/2/", "البقرة، الآية ٣ — خيارات الآية", 390],
    ["2:3 on page 2 (430 px)", "/ar/page/2/", "البقرة، الآية ٣ — خيارات الآية", 430],
  ] as const) {
    test(`${label} @ ${width}px: translucent, blended, inside its own lines; no glyph pixels lost (fake media element)`, async ({
      page,
    }) => {
      await fakeMedia(page);
      await page.setViewportSize({ width, height: 844 });
      await openMushaf(page, path);
      const frame = page.getByTestId("mushaf-frame");
      const plain = await frame.screenshot(); // nothing highlighted
      // the selected-ayah highlight follows the same rules
      await page.getByRole("button", { name: marker, exact: true }).click();
      expectContained(await paints(page, ".mushaf-page .seg.selected"), "multiply");
      await page.getByTestId("act-play").click();
      await page.getByTestId("act-close").click();
      await isPlaying(page);
      const playing = await paints(page, ".mushaf-page .seg.playing");
      expectContained(playing, "multiply");
      expect(new Set(playing.map((p) => p.ayah)).size).toBe(1);
      await page.mouse.move(0, 0);
      const lit = await frame.screenshot();
      // every glyph pixel of the page is still drawn while the ayah is highlighted
      const [before, after] = [await inkPixels(page, plain), await inkPixels(page, lit)];
      expect(after).toBeGreaterThanOrEqual(before * 0.995);
      const slug = `${path.split("/")[3]}-${width}`;
      if (width === 390) {
        mkdirSync(SHOTS, { recursive: true });
        writeFileSync(`${SHOTS}/recitation-highlight-after-p${slug}.png`, lit);
        // evidence only: the old opaque highlight, re-applied, does hide glyph pixels
        await page.addStyleTag({ content: OLD_HIGHLIGHT });
        const old = await frame.screenshot();
        writeFileSync(`${SHOTS}/recitation-highlight-before-p${slug}.png`, old);
        expect(await inkPixels(page, old)).toBeLessThan(before);
      }
      await page.getByTestId("player-stop").click();
    });
  }

  test("dark theme: the tint is screened onto the dark paper, also translucent and contained (fake media element)", async ({
    page,
  }) => {
    await page.emulateMedia({ colorScheme: "dark" });
    await fakeMedia(page);
    await page.setViewportSize({ width: 390, height: 844 });
    await openMushaf(page, "/ar/page/2/");
    await playFrom(page, "البقرة، الآية ٣ — خيارات الآية");
    expectContained(await paints(page, ".mushaf-page .seg.playing"), "screen");
    await page.getByRole("button", { name: "البقرة، الآية ٤ — خيارات الآية", exact: true }).click();
    expectContained(await paints(page, ".mushaf-page .seg.selected"), "screen");
  });
});

async function axe(page: Page, slug: string): Promise<void> {
  type AxePage = ConstructorParameters<typeof AxeBuilder>[0]["page"];
  const r = await new AxeBuilder({ page: page as unknown as AxePage })
    .withTags(["wcag2a", "wcag2aa", "wcag21a", "wcag21aa", "best-practice"])
    .analyze();
  mkdirSync(`${EVIDENCE}/axe`, { recursive: true });
  writeFileSync(
    `${EVIDENCE}/axe/recitation-tafsir-${slug}.json`,
    JSON.stringify(
      {
        violations: r.violations.map((v) => ({ id: v.id, impact: v.impact ?? null, nodes: v.nodes.length })),
      },
      null,
      1,
    ),
  );
  const serious = r.violations.filter((v) => v.impact === "serious" || v.impact === "critical");
  expect(serious.map((v) => `${v.id}: ${v.nodes.map((n) => n.target.join(" ")).join(", ")}`)).toEqual([]);
}

const recitedTafsir = async (page: Page, s: number, a: number): Promise<void> => {
  const sheet = page.getByTestId("recitation-tafsir");
  await expect(sheet.getByTestId("tafsir")).toHaveAttribute("data-ayah", `${s}:${a}`);
  await expect(sheet.getByTestId("tafsir-text")).toBeVisible();
  expect(await sheet.getByTestId("tafsir-text").textContent()).toBe(stored(s, a));
};

test.describe("tafsir with recitation (fake media element)", () => {
  for (const theme of ["light", "dark"] as const) {
    test(`Arabic phone (${theme}): off by default; on follows ayah by ayah and across a page turn; persisted; axe (fake media element)`, async ({
      page,
    }) => {
      await page.emulateMedia({ colorScheme: theme });
      await fakeMedia(page);
      await page.setViewportSize({ width: 390, height: 844 });
      await openMushaf(page, "/ar/page/2/");
      await playFrom(page, "البقرة، الآية ٤ — خيارات الآية");
      const toggle = page.getByTestId("player-tafsir");
      await expect(toggle).not.toBeChecked();
      await expect(page.getByRole("checkbox", { name: "التفسير مع التلاوة" })).toBeVisible();
      await expect(page.getByTestId("recitation-tafsir")).toHaveCount(0);
      await expect(page.getByTestId("tafsir")).toHaveCount(0);
      await toggle.check();
      await recitedTafsir(page, 2, 4);
      await expect(page.getByTestId("recitation-tafsir")).toHaveAccessibleName("تفسير الآية المتلوّة");
      // the line being recited stays above the docked sheet and the player
      const seg = await page.locator(".mushaf-page .seg.playing").last().boundingBox();
      const sheet = await page.getByTestId("recitation-tafsir").boundingBox();
      expect(seg!.y + seg!.height).toBeLessThanOrEqual(sheet!.y + 1);
      await noHorizontalOverflow(page);
      await axe(page, `${theme}-ar-phone`);
      await endItem(page); // 2:5, still page 2
      await recitedTafsir(page, 2, 5);
      await endItem(page); // 2:6 is on page 3: the page turns and the tafsir follows
      await expect(page).toHaveURL("/ar/page/3/");
      await recitedTafsir(page, 2, 6);
      const seg3 = await page.locator(".mushaf-page .seg.playing").last().boundingBox();
      const sheet3 = await page.getByTestId("recitation-tafsir").boundingBox();
      expect(seg3!.y + seg3!.height).toBeLessThanOrEqual(sheet3!.y + 1);
      // turning it off hides the tafsir while recitation goes on
      await toggle.uncheck();
      await expect(page.getByTestId("recitation-tafsir")).toHaveCount(0);
      await isPlaying(page);
      await toggle.check();
      await page.getByTestId("player-stop").click();
      await expect(page.getByTestId("recitation-tafsir")).toHaveCount(0);
      // persisted, and shown in Settings
      await page.goto("/ar/settings/");
      await expect(page.getByTestId("settings-recitation-tafsir")).toBeChecked();
      expect(await page.evaluate(() => JSON.parse(localStorage.getItem("rattil.audio")!).tafsir)).toBe(true);
    });
  }

  test("English desktop: turned on in Settings; Arabic-only note; a selected ayah takes precedence (fake media element)", async ({
    page,
  }) => {
    await fakeMedia(page);
    await page.setViewportSize({ width: 1280, height: 900 });
    await page.goto("/en/settings/");
    await page.getByLabel("Tafsir with recitation").check();
    await openMushaf(page, "/en/page/604/");
    await page.getByTestId("play-surah").click(); // al-Ikhlas: basmala first, which has no tafsir
    await isPlaying(page);
    await expect(page.getByTestId("recitation-tafsir")).toHaveCount(0);
    await endItem(page);
    await recitedTafsir(page, 112, 1);
    await expect(page.getByTestId("recitation-tafsir").getByTestId("tafsir-arabic-only")).toBeVisible();
    await axe(page, "light-en-desktop");
    await page.getByRole("button", { name: "Al-Falaq, ayah 2 — ayah options", exact: true }).click();
    await expect(page.getByTestId("recitation-tafsir")).toHaveCount(0);
    await expect(page.getByTestId("tafsir")).toHaveAttribute("data-ayah", "113:2");
    await page.getByTestId("act-close").click();
    await endItem(page);
    await recitedTafsir(page, 112, 2);
    await noHorizontalOverflow(page);
    await page.getByTestId("player-stop").click();
  });
});
