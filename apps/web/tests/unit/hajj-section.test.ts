import { HARAM_CROWD_LINKS } from "@/lib/haram-crowd";
import { SITE_GROUPS, itemHref, locate } from "@/lib/site-map";

describe("Hajj & Umrah section", () => {
  it("has its own menu: Umrah, the three kinds of Hajj and live audio (owner 2026-11-15)", () => {
    const g = SITE_GROUPS.find((x) => x.path === "hajj");
    expect(g?.items).toEqual(["hajj-umrah", "hajj-ifrad", "hajj-qiran", "hajj-tamattu", "hajj-live"]);
    expect(itemHref("ar", "hajj-umrah").endsWith("/hajj/#umrah")).toBe(true);
    expect(itemHref("ar", "hajj-ifrad").endsWith("/hajj/#hajj-ifrad")).toBe(true);
    expect(itemHref("ar", "hajj-crowd").endsWith("/hajj/#crowd")).toBe(true);
    expect(itemHref("ar", "hajj-live").endsWith("/hajj/#live")).toBe(true);
    expect(locate("hajj/")?.group.path).toBe("hajj");
  });

  it("links crowd levels to the official sources only (no numbers of our own)", () => {
    expect(new URL(HARAM_CROWD_LINKS.official).hostname).toBe("alharamain.gov.sa");
    expect(new URL(HARAM_CROWD_LINKS.nusuk).hostname).toBe("www.nusuk.sa");
  });
});
