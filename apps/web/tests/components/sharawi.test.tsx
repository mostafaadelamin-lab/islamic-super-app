import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { SharawiSection } from "@/components/SharawiSection";
import { SharawiView } from "@/components/SharawiView";
import { parseLessons } from "@/lib/lessons";
import { SECTIONS } from "@/components/SectionTiles";
import { parseSharawi, sharawiSavedStore } from "@/lib/sharawi";
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

  it("filters surahs, opens a surah and plays a lesson with the player under it", async () => {
    vi.spyOn(HTMLMediaElement.prototype, "play").mockResolvedValue(undefined);
    const user = userEvent.setup();
    render(<SharawiView locale="ar" loader={() => Promise.resolve(data)} />);
    expect(await screen.findByTestId("sharawi-note")).toHaveTextContent("١١١٦");
    await user.type(screen.getByTestId("sharawi-search"), "البقره");
    const surahs = screen.getByTestId("sharawi-surahs");
    expect(surahs.querySelectorAll("li > details")).toHaveLength(1);
    await user.click(screen.getByText("البقرة"));
    await user.click(await screen.findByTestId("sharawi-9"));
    const audio = screen.getByTestId("library-audio") as HTMLAudioElement;
    expect(audio.getAttribute("src")).toBe(data[2]!.lessons[0]!.url);
    // Owner 2026-11-16: the player sits under the lesson playing, not at the top of the page.
    const row = screen.getByTestId("sharawi-9").closest("li")!;
    expect(row.contains(screen.getByTestId("library-now"))).toBe(true);
    expect(screen.queryByTestId("library-now-top")).toBeNull();
    expect(screen.getByTestId("library-now")).toBeTruthy();
    vi.restoreAllMocks();
  });
});

describe("Sha'rawi offline save (website)", () => {
  it("saves a lesson into the audio cache and deletes it again", async () => {
    const store = new Map<string, Response>();
    const cache = {
      match: (u: string) => Promise.resolve(store.get(u)),
      put: (u: string, r: Response) => (store.set(u, r), Promise.resolve()),
      delete: (u: string) => Promise.resolve(store.delete(u)),
    };
    vi.stubGlobal("caches", { open: () => Promise.resolve(cache) });
    vi.stubGlobal(
      "fetch",
      vi.fn(() => Promise.resolve(new Response("mp3", { status: 200 }))),
    );
    const user = userEvent.setup();
    render(<SharawiView locale="ar" loader={() => Promise.resolve(data)} />);
    await user.click(await screen.findByText("الفاتحة"));
    await user.click(screen.getByTestId("sharawi-save-5"));
    expect(await screen.findByText(/محفوظ/)).toBeInTheDocument();
    expect(store.has(data[1]!.lessons[0]!.url)).toBe(true);
    expect(sharawiSavedStore.get()).toContain(5);
    await user.click(screen.getByTestId("sharawi-save-5"));
    expect(store.size).toBe(0);
    expect(sharawiSavedStore.get()).not.toContain(5);
    vi.unstubAllGlobals();
  });
});

describe("Sha'rawi section: three parts", () => {
  it("shows tafsir, the Prophet's life and prophets' stories (owner 2026-11-23)", async () => {
    const lessons = parseLessons(readRepoJson("content/lessons/dist/lessons.v1.json"));
    const tafsir = parseSharawi(readRepoJson("content/sharawi/dist/sharawi.v1.json"));
    expect(lessons.series.filter((s) => s.sheikh.id === "shaarawi")).toEqual([]);
    const user = userEvent.setup();
    render(
      <SharawiSection
        locale="ar"
        loader={() => Promise.resolve(tafsir)}
        lessonsLoader={() => Promise.resolve(lessons)}
      />,
    );
    expect(await screen.findByTestId("sharawi-note")).toBeInTheDocument();
    await user.click(screen.getByTestId("sharawi-part-seerah"));
    expect(await screen.findByTestId("lessons-hero")).toHaveTextContent("السيرة النبوية");
    expect(screen.getByTestId("lesson-seerah-shaarawi-1")).toBeInTheDocument();
    expect(screen.queryByTestId("lessons-back")).toBeNull();
    await user.click(screen.getByTestId("sharawi-part-anbiya"));
    expect(await screen.findByTestId("lessons-hero")).toHaveTextContent("قصص الأنبياء");
    await user.click(screen.getByTestId("sharawi-part-tafsir"));
    expect(await screen.findByTestId("sharawi-note")).toBeInTheDocument();
  });

  it("never shows the whole lesson catalogue in place of a Sha'rawi part (stale list, owner 2026-11-23)", async () => {
    const lessons = parseLessons(readRepoJson("content/lessons/dist/lessons.v1.json"));
    const old = { ...lessons, sharawi: [] };
    const user = userEvent.setup();
    render(
      <SharawiSection
        locale="ar"
        loader={() => Promise.resolve([])}
        lessonsLoader={() => Promise.resolve(old)}
      />,
    );
    await user.click(screen.getByTestId("sharawi-part-seerah"));
    expect(await screen.findByText("تعذّر تحميل قائمة السلاسل.")).toBeInTheDocument();
    expect(screen.queryByTestId("lessons-note")).toBeNull();
  });
});
