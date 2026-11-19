import { readFileSync } from "node:fs";
import { join } from "node:path";
import { describe, expect, it } from "vitest";

// Owner 2026-11-19: the static pages (opened from the site or the installed Windows app)
// had no way back to the app. Each one carries a back button at the top and the bottom.
const pub = join(__dirname, "../../public");

describe.each(["privacy-policy.html", "sources.html"])("%s", (name) => {
  const html = readFileSync(join(pub, name), "utf8");

  it("has a sticky back bar that opens the app home", () => {
    expect(html).toContain('<header class="back-bar">');
    expect(html).toMatch(/position: sticky/);
    const backs = [...html.matchAll(/<a class="back-btn" href="\/ar\/" data-back>/g)];
    expect(backs.length).toBe(2);
    expect(html).toContain("رجوع للتطبيق");
  });

  it("goes back in history only when the visitor came from this site", () => {
    expect(html).toContain("history.back()");
    expect(html).toContain("new URL(document.referrer).origin === location.origin");
  });
});

it("store copy of the privacy policy matches the website one", () => {
  const a = readFileSync(join(pub, "privacy-policy.html"), "utf8");
  const b = readFileSync(join(__dirname, "../../../../docs/store/privacy-policy.html"), "utf8");
  expect(b).toBe(a);
});
