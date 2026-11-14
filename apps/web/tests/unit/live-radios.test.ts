import { LIVE_RADIOS, isHls } from "@/lib/live-radios";

describe("live radios", () => {
  it("has the two Holy Mosques first, as HLS sound streams over https", () => {
    expect(LIVE_RADIOS.map((r) => r.id).slice(0, 2)).toEqual(["makkah", "madinah"]);
    for (const r of LIVE_RADIOS) expect(r.url.startsWith("https://")).toBe(true);
    expect(isHls(LIVE_RADIOS[0]!.url)).toBe(true);
    expect(isHls(LIVE_RADIOS[1]!.url)).toBe(true);
    expect(isHls("https://stream.radiojar.com/8s5u5tpdtwzuv")).toBe(false);
    expect(isHls("not a url")).toBe(false);
  });
});
