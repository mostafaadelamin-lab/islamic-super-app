import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { ShabibView, shabibSubtitle, shabibTitle } from "@/components/ShabibView";
import { SECTIONS } from "@/components/SectionTiles";
import { SITE_GROUPS } from "@/lib/site-map";
import { parseShabib } from "@/lib/shabib";
import { readRepoJson } from "../repo";

const data = parseShabib(readRepoJson("content/shabib/dist/shabib.v1.json"));

describe("Sheikh Mohamed Ahmed Shabib", () => {
  it("parses his murattal and mujawwad tracks with https audio and unique ids", () => {
    expect(data.murattal).toHaveLength(16);
    expect(data.mujawwad).toHaveLength(70);
    const all = [...data.murattal, ...data.mujawwad];
    expect(new Set(all.map((x) => x.id)).size).toBe(all.length);
    for (const x of all) {
      expect(x.url).toMatch(/^https:\/\/[^ ]+\.mp3$/);
      expect(x.seconds).toBeGreaterThan(0);
      for (const n of x.surahs) expect(n).toBeGreaterThanOrEqual(1);
    }
    // mujawwad ordered by first surah
    const firsts = data.mujawwad.map((x) => x.surahs[0] ?? 200);
    expect([...firsts].sort((a, b) => a - b)).toEqual(firsts);
  });

  it("is not a section of its own (owner 2026-11-16: he sits inside the recitation library)", () => {
    expect(SECTIONS.some((s) => s.path === "shabib")).toBe(false);
    expect(SITE_GROUPS.some((g) => g.items.includes("shabib"))).toBe(false);
  });

  it("titles say when a murattal track is only part of the surah", () => {
    const baqarah = data.murattal.find((x) => x.surahs[0] === 2)!;
    expect(shabibTitle(baqarah, "ar")).toBe("ما تيسّر من سورة البقرة");
    const duha = data.murattal.find((x) => x.surahs[0] === 93)!;
    expect(shabibTitle(duha, "ar")).toBe("سور الضحى والشرح");
    const oct = data.mujawwad.find((x) => x.tag === "oct73")!;
    expect(shabibTitle(oct, "ar")).toBe("سور آل عمران والتكوير والعلق");
    expect(shabibSubtitle(oct, "ar")).toContain("فجر ٦ أكتوبر ١٩٧٣");
  });

  it("switches to the mujawwad tab, filters by surah and plays a track", async () => {
    const user = userEvent.setup();
    render(<ShabibView locale="ar" loader={() => Promise.resolve(data)} />);
    expect(await screen.findByTestId("shabib-note")).toHaveTextContent("١٦");
    expect(screen.getByTestId("shabib-list-murattal").children).toHaveLength(16);
    await user.click(screen.getByTestId("shabib-tab-mujawwad"));
    await user.type(screen.getByTestId("shabib-search"), "يوسف");
    const list = screen.getByTestId("shabib-list-mujawwad");
    const yusuf = data.mujawwad.filter((x) => x.surahs.includes(12));
    expect(list.children).toHaveLength(yusuf.length);
    await user.click(screen.getByTestId(`shabib-${yusuf[0]!.id}`));
    const audio = screen.getByTestId("shabib-audio") as HTMLAudioElement;
    expect(audio.getAttribute("src")).toBe(yusuf[0]!.url);
    expect(screen.getByTestId("shabib-now")).toHaveTextContent("سورة يوسف");
  });
});
