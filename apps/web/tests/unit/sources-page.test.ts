import { readFileSync, existsSync, readdirSync, statSync } from "node:fs";
import { join } from "node:path";
import { describe, expect, it } from "vitest";

// The sources page is kept ready but hidden (owner, 2026-11-15): reachable only by its URL.
const pub = join(__dirname, "../../public");
const html = readFileSync(join(pub, "sources.html"), "utf8");

function files(dir: string): string[] {
  return readdirSync(dir).flatMap((n) => {
    const p = join(dir, n);
    return statSync(p).isDirectory() ? files(p) : [p];
  });
}

describe("hidden sources page", () => {
  it("is not indexed by search engines", () => {
    expect(html).toContain('<meta name="robots" content="noindex, nofollow" />');
  });

  it("is not linked from the site", () => {
    const src = files(join(__dirname, "../../src")).filter((f) => /\.(tsx?|json|css)$/.test(f));
    for (const f of src) expect(readFileSync(f, "utf8"), f).not.toMatch(/sources\.html/);
  });

  it("carries the Waqf GPL notice for the mushaf line layout", () => {
    expect(html).toContain("quran-madina-html");
    expect(html).toContain("Waqf");
    expect(html).toMatch(/General Public License 2\.0/);
  });

  it("links only to licence files that ship with the site", () => {
    const local = [...html.matchAll(/href="(\/[^"#]+)"/g)].map((m) => m[1] ?? "");
    expect(local.length).toBeGreaterThan(0);
    for (const p of local) expect(existsSync(join(pub, p)), p).toBe(true);
  });
});
