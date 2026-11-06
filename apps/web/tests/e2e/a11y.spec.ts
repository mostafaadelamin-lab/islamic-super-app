import AxeBuilder from "@axe-core/playwright";
import { expect, test } from "./fixtures";
import { mkdirSync, writeFileSync } from "node:fs";
import { EVIDENCE, MAIN_PAGES } from "./helpers";

// One file per scan: tests run in parallel workers, so a shared afterAll file would be overwritten.
const AXE_DIR = `${EVIDENCE}/axe`;
mkdirSync(AXE_DIR, { recursive: true });

for (const theme of ["light", "dark"] as const) {
  for (const locale of ["ar", "en"] as const) {
    for (const path of MAIN_PAGES) {
      test(`axe ${theme} /${locale}/${path}`, async ({ page }) => {
        await page.emulateMedia({ colorScheme: theme });
        await page.goto(`/${locale}/${path}`);
        await page.waitForLoadState("networkidle");
        await page.waitForTimeout(200);
        // @axe-core/playwright is typed against a newer playwright-core; the runtime API it uses is the same.
        type AxePage = ConstructorParameters<typeof AxeBuilder>[0]["page"];
        const r = await new AxeBuilder({ page: page as unknown as AxePage })
          .withTags(["wcag2a", "wcag2aa", "wcag21a", "wcag21aa", "best-practice"])
          .analyze();
        const slug = `${theme}-${locale}-${path.replace(/\//g, "_") || "home"}`;
        writeFileSync(
          `${AXE_DIR}/${slug}.json`,
          JSON.stringify(
            {
              url: `/${locale}/${path}`,
              theme,
              violations: r.violations.map((v) => ({
                id: v.id,
                impact: v.impact ?? null,
                nodes: v.nodes.length,
              })),
            },
            null,
            1,
          ),
        );
        const serious = r.violations.filter((v) => v.impact === "serious" || v.impact === "critical");
        expect(
          serious.map(
            (v) =>
              `${v.id}: ${v.nodes
                .map((n) => n.target.join(" "))
                .slice(0, 3)
                .join(", ")}`,
          ),
        ).toEqual([]);
      });
    }
  }
}
