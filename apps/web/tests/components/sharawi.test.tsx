import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { SharawiView } from "@/components/SharawiView";
import { SECTIONS } from "@/components/SectionTiles";
import { parseSharawi } from "@/lib/sharawi";
import { readRepoJson } from "../repo";

const data = parseSharawi(readRepoJson("content/sharawi/dist/sharawi.v1.json"));

describe("Sha'rawi audio tafsir", () => {
  it("parses every lesson with an encoded https archive.org url and valid ranges", () => {
    const lessons = data.flatMap((s) => s.lessons);
    expect(lessons).toHaveLength(1116);
    expect(new Set(lessons.map((l) => l.id)).size).toBe(1116);
    expect(data[0]!.surah).toBe(0);
    for (const l of lessons) {
      expect(l.url).toMatch(/^https:\/\/archive\.org\/download\/[^ ]+\.mp3$/);
      if (l.from !== undefined) expect(l.from).toBeLessThanOrEqual(l.to!);
    }
  });

  it("is listed under More", () => {
    expect(SECTIONS.some((s) => s.path === "sharawi")).toBe(true);
  });

  it("filters surahs, opens a surah and plays a lesson", async () => {
    const user = userEvent.setup();
    render(<SharawiView locale="ar" loader={() => Promise.resolve(data)} />);
    expect(await screen.findByTestId("sharawi-note")).toHaveTextContent("١١١٦");
    await user.type(screen.getByTestId("sharawi-search"), "البقره");
    const surahs = screen.getByTestId("sharawi-surahs");
    expect(surahs.querySelectorAll("li > details")).toHaveLength(1);
    await user.click(screen.getByText("البقرة"));
    await user.click(await screen.findByTestId("sharawi-9"));
    const audio = screen.getByTestId("sharawi-audio") as HTMLAudioElement;
    expect(audio.getAttribute("src")).toBe(data[2]!.lessons[0]!.url);
    expect(screen.getByTestId("sharawi-now")).toHaveTextContent("الدرس ١");
  });
});
