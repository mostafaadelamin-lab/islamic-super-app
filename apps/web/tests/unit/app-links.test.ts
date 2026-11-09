import { APP_LINKS, SHARE_PROMPT_AFTER_DAYS, sharePromptStore, shareAppData, visit } from "@/lib/app-links";

const day = (n: number): string => `2026-11-${String(n).padStart(2, "0")}`;

describe("share-app suggestion", () => {
  it("shows once the site was opened on five different days, and never after it was answered", () => {
    const start = sharePromptStore.defaultValue;
    const after = Array.from({ length: SHARE_PROMPT_AFTER_DAYS }, (_, i) => i + 1).reduce(
      (acc, n) => {
        const r = visit(acc.s, day(n));
        return { s: r.next, shows: [...acc.shows, r.show] };
      },
      { s: start, shows: [] as boolean[] },
    );
    expect(after.shows).toEqual([false, false, false, false, true]);
    // the same day again does not count twice
    expect(visit(visit(start, day(1)).next, day(1)).next.days).toEqual([day(1)]);
    expect(visit({ ...after.s, done: true }, day(SHARE_PROMPT_AFTER_DAYS + 1)).show).toBe(false);
  });

  it("shares the site's own address while no website link is set", () => {
    expect(APP_LINKS.website).toBeNull();
    expect(shareAppData("Rattil", "https://example.test/ar/")).toMatchObject({
      text: "Rattil",
      url: "https://example.test/ar/",
    });
  });
});
