import { renderQuranText } from "@/lib/quran-render";
import { act, render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { readRepoJson } from "../repo";
import { TafsirPanel } from "@/components/TafsirPanel";
import { SurahReader } from "@/components/SurahReader";
import { PageReader } from "@/components/PageReader";
import { surahMeta } from "@/lib/pages";
import { lookupFrom, resolvePage, type MushafLinesFile } from "@/lib/mushaf";
import { resetTafsirForTests } from "@/lib/tafsir";
import { audioStore } from "@/lib/audio";
import { player, resetPlayerForTests } from "@/lib/audio-player";
import { routerPush } from "../setup";
import { resetStores } from "./reset";

const tafsir = readRepoJson<{ surahs: string[][] }>("content/tafsir/dist/muyassar.v1.json");
const quran = readRepoJson<{ surahs: { ayahs: string[] }[] }>("content/quran/dist/quran.v1.json");
const entry = (s: number, a: number): string => tafsir.surahs[s - 1]![a - 1]!;

/** Serves /data/tafsir/muyassar/<s>.json from the stored content; other URLs fail. */
function serveTafsir() {
  return vi.spyOn(globalThis, "fetch").mockImplementation((input) => {
    const m = /\/data\/tafsir\/muyassar\/(\d+)\.json$/.exec(String(input));
    if (!m) return Promise.reject(new TypeError("not served"));
    return Promise.resolve(new Response(JSON.stringify(tafsir.surahs[Number(m[1]) - 1]), { status: 200 }));
  });
}

beforeEach(() => {
  resetStores();
  resetTafsirForTests();
  vi.restoreAllMocks();
});

describe("TafsirPanel", () => {
  it("Arabic: title, source, the stored text verbatim, previous/next across surahs", async () => {
    serveTafsir();
    render(<TafsirPanel locale="ar" surah={112} ayah={4} />);
    expect(screen.getByRole("heading", { name: "التفسير الميسر" })).toBeInTheDocument();
    expect(screen.getByTestId("tafsir-source")).toHaveTextContent("مجمع الملك فهد لطباعة المصحف الشريف");
    expect(screen.getByTestId("tafsir-loading")).toBeInTheDocument();
    expect((await screen.findByTestId("tafsir-text")).textContent).toBe(entry(112, 4));
    expect(screen.getByTestId("tafsir-ref")).toHaveTextContent("تفسير الإخلاص، الآية ٤");
    expect(screen.queryByTestId("tafsir-arabic-only")).toBeNull();
    await userEvent.click(screen.getByTestId("tafsir-next"));
    expect(await screen.findByText(entry(113, 1))).toHaveAttribute("data-testid", "tafsir-text");
    expect(screen.getByTestId("tafsir-ref")).toHaveTextContent("الفلق، الآية ١");
    await userEvent.click(screen.getByTestId("tafsir-prev"));
    expect(await screen.findByText(entry(112, 4))).toBeInTheDocument();
  });

  it("English: Arabic-only note; the text stays Arabic (lang/dir); bounds disable the buttons", async () => {
    serveTafsir();
    render(<TafsirPanel locale="en" surah={1} ayah={1} />);
    expect(screen.getByTestId("tafsir-arabic-only")).toHaveTextContent("available in Arabic only");
    const text = await screen.findByTestId("tafsir-text");
    expect(text.textContent).toBe(entry(1, 1));
    expect(text).toHaveAttribute("lang", "ar");
    expect(text).toHaveAttribute("dir", "rtl");
    expect(screen.getByTestId("tafsir-prev")).toBeDisabled();
    expect(screen.getByTestId("tafsir-next")).toBeEnabled();
  });

  it("offline: explains that the tafsir is not saved yet, and retries", async () => {
    const spy = vi.spyOn(globalThis, "fetch").mockRejectedValue(new TypeError("offline"));
    const online = vi.spyOn(navigator, "onLine", "get").mockReturnValue(false);
    render(<TafsirPanel locale="en" surah={2} ayah={255} />);
    expect(await screen.findByTestId("tafsir-error")).toHaveTextContent("You are offline");
    online.mockReturnValue(true);
    spy.mockResolvedValueOnce(new Response("", { status: 500 }));
    await userEvent.click(screen.getByTestId("tafsir-retry"));
    expect(await screen.findByTestId("tafsir-error")).toHaveTextContent("could not be loaded");
    spy.mockResolvedValueOnce(new Response(JSON.stringify(tafsir.surahs[1]), { status: 200 }));
    await userEvent.click(screen.getByTestId("tafsir-retry"));
    expect((await screen.findByTestId("tafsir-text")).textContent).toBe(entry(2, 255));
  });

  it("controlled: previous/next call onStep instead of moving on their own", async () => {
    serveTafsir();
    const onStep = vi.fn();
    render(<TafsirPanel locale="ar" surah={2} ayah={1} onStep={onStep} />);
    await screen.findByTestId("tafsir-text");
    await userEvent.click(screen.getByTestId("tafsir-prev"));
    await userEvent.click(screen.getByTestId("tafsir-next"));
    expect(onStep.mock.calls).toEqual([[[1, 7]], [[2, 2]]]);
    expect(screen.getByTestId("tafsir")).toHaveAttribute("data-ayah", "2:1");
  });
});

describe("tafsir in the readers", () => {
  it("Mushaf: selecting an ayah shows its tafsir; next moves the selection and turns the page", async () => {
    serveTafsir();
    const lines = readRepoJson<MushafLinesFile>("content/quran/dist/mushaf-lines.v1.json");
    const lookup = lookupFrom(quran.surahs.map((x) => x.ayahs));
    render(<PageReader locale="ar" initial={resolvePage(lines.pages[1]!, lookup)} />);
    await userEvent.click(screen.getByRole("button", { name: "البقرة، الآية ٤ — خيارات الآية" }));
    // Simple menu (owner 2026-11-15): the tafsir opens from its button.
    expect(screen.queryByTestId("tafsir-text")).toBeNull();
    await userEvent.click(screen.getByTestId("act-tafsir"));
    expect((await screen.findByTestId("tafsir-text")).textContent).toBe(entry(2, 4));
    await userEvent.click(screen.getByTestId("tafsir-next"));
    expect((await screen.findByText(entry(2, 5))).dataset.testid).toBe("tafsir-text");
    document.querySelectorAll('.seg[data-ayah="2:5"]').forEach((e) => expect(e).toHaveClass("selected"));
    // 2:6 is on page 3; the Mushaf data is not loaded in this test, so the reader navigates there
    await userEvent.click(screen.getByTestId("tafsir-next"));
    expect(routerPush).toHaveBeenLastCalledWith("/ar/page/3/#a-2-6");
  });

  it("list view: a Tafsir button per ayah opens the panel under it", async () => {
    serveTafsir();
    const meta = surahMeta(112)!;
    render(<SurahReader locale="en" meta={meta} ayahs={quran.surahs[111]!.ayahs} basmala={null} />);
    const toggle = screen.getByTestId("tafsir-toggle-1");
    expect(toggle).toHaveAttribute("aria-expanded", "false");
    expect(toggle).toHaveAccessibleName("Tafsir — ayah 1");
    await userEvent.click(toggle);
    expect(toggle).toHaveAttribute("aria-expanded", "true");
    expect((await screen.findByTestId("tafsir-text")).textContent).toBe(entry(112, 1));
    await userEvent.click(toggle);
    expect(screen.queryByTestId("tafsir")).toBeNull();
  });
});

/** jsdom cannot play media: a minimal element that the test ends itself. */
class FakeAudio extends EventTarget {
  static last: FakeAudio | null = null;
  preload = "";
  src = "";
  constructor() {
    super();
    FakeAudio.last = this;
  }
  getAttribute(k: string): string | null {
    return k === "src" && this.src ? this.src : null;
  }
  removeAttribute(): void {
    this.src = "";
  }
  load(): void {}
  pause(): void {}
  play(): Promise<void> {
    queueMicrotask(() => this.dispatchEvent(new Event("playing")));
    return Promise.resolve();
  }
}

describe("tafsir with recitation", () => {
  const lines = readRepoJson<MushafLinesFile>("content/quran/dist/mushaf-lines.v1.json");
  const lookup = lookupFrom(quran.surahs.map((x) => x.ayahs));
  beforeEach(() => {
    localStorage.clear();
    audioStore.reload();
    resetPlayerForTests();
    vi.stubGlobal("Audio", FakeAudio);
    vi.spyOn(navigator, "onLine", "get").mockReturnValue(true);
  });
  afterEach(() => {
    act(() => player.stop());
    vi.unstubAllGlobals();
  });
  const end = () => act(() => void FakeAudio.last!.dispatchEvent(new Event("ended")));

  it("off by default: recitation shows no tafsir", async () => {
    serveTafsir();
    render(<PageReader locale="ar" initial={resolvePage(lines.pages[1]!, lookup)} />);
    act(() => player.play({ kind: "page", page: 2 }));
    end(); // basmala → 2:1
    expect(player.current()).toEqual({ kind: "ayah", s: 2, a: 1 });
    expect(screen.queryByTestId("recitation-tafsir")).toBeNull();
    expect(screen.queryByTestId("tafsir")).toBeNull();
  });

  it("on: the page and its tafsir in two halves, following the recitation; 'Hide tafsir' turns it off", async () => {
    serveTafsir();
    audioStore.set((p) => ({ ...p, tafsir: true }));
    render(<PageReader locale="en" initial={resolvePage(lines.pages[1]!, lookup)} />);
    expect(screen.queryByTestId("duo-tafsir")).toBeNull(); // nothing is playing yet
    act(() => player.play({ kind: "page", page: 2 }));
    expect(screen.getByTestId("duo-tafsir")).toBeInTheDocument();
    expect(screen.getByTestId("mushaf-stage")).toBeVisible(); // the whole page stays on screen
    end();
    expect(await screen.findByText(entry(2, 1))).toBeInTheDocument();
    const playing = (): string | null =>
      screen.getByTestId("duo-tafsir").querySelector(".rd-ayah.playing")?.getAttribute("data-ayah") ?? null;
    expect(playing()).toBe("2:1");
    end();
    expect(playing()).toBe("2:2");
    await userEvent.click(screen.getByTestId("duo-close"));
    expect(audioStore.get().tafsir).toBe(false);
    expect(screen.queryByTestId("duo-tafsir")).toBeNull();
    expect(screen.getByTestId("mushaf-stage")).toBeVisible();
  });

  it("tapping an ayah: listen to it alone, or 'Listen with tafsir' from it (page and tafsir halves)", async () => {
    serveTafsir();
    render(<PageReader locale="en" initial={resolvePage(lines.pages[2]!, lookup)} />);
    await userEvent.click(screen.getByRole("button", { name: "Al-Baqarah, ayah 7 — ayah options" }));
    // Simple menu (owner 2026-11-15): five buttons; the ways to listen open from "Listen".
    // ... in the bottom strip with the player and the page slider, not floating over the page.
    expect(screen.getByTestId("ayah-sheet").closest(".rd-dock")).not.toBeNull();
    expect(screen.queryByTestId("act-play-ayah")).toBeNull();
    await userEvent.click(screen.getByTestId("act-tafsir"));
    expect(await screen.findByText(entry(2, 7))).toBeInTheDocument(); // its tafsir is in the sheet
    await userEvent.click(screen.getByTestId("act-listen"));
    await userEvent.click(screen.getByTestId("act-play-ayah"));
    expect(player.get().queue).toEqual([{ kind: "ayah", s: 2, a: 7 }]);
    await userEvent.click(screen.getByTestId("act-play-tafsir"));
    expect(audioStore.get().tafsir).toBe(true);
    expect(player.current()).toEqual({ kind: "ayah", s: 2, a: 7 });
    expect(screen.queryByTestId("ayah-sheet")).toBeNull();
    expect(screen.getByTestId("duo-tafsir").querySelector(".rd-ayah.playing")).toHaveAttribute(
      "data-ayah",
      "2:7",
    );
    expect(await screen.findByText(entry(2, 7))).toBeInTheDocument();
  });
  it("«التفسير» beside the page without listening; full screen keeps it, a tap on an ayah shows its tafsir (owner 2026-11-18)", async () => {
    serveTafsir();
    render(<PageReader locale="en" initial={resolvePage(lines.pages[2]!, lookup)} />);
    expect(screen.queryByTestId("duo-tafsir")).toBeNull();
    await userEvent.click(screen.getByTestId("reader-side-tafsir"));
    expect(screen.getByTestId("reader-side-tafsir")).toHaveAttribute("aria-pressed", "true");
    expect(screen.getByTestId("duo-tafsir")).toBeInTheDocument();
    expect(player.get().status).toBe("idle"); // nothing plays
    expect(await screen.findByText(entry(2, 6))).toBeInTheDocument();
    expect(screen.getByTestId("duo-tafsir")).toHaveTextContent("Tafsir beside the page");
    // full screen: the page and the tafsir stay, with their own buttons above the page
    await userEvent.click(screen.getByTestId("reader-full"));
    expect(document.querySelector(".mushaf-reader")).toHaveClass("rd-full", "rd-duo");
    expect(screen.getByTestId("duo-tafsir")).toBeInTheDocument();
    expect(screen.getByTestId("reader-full-tools")).toBeInTheDocument();
    await userEvent.click(screen.getByRole("button", { name: "Al-Baqarah, ayah 9 — ayah options" }));
    expect(document.querySelector(".mushaf-reader")).toHaveClass("rd-full"); // still full screen
    expect(screen.queryByTestId("ayah-sheet")).toBeNull();
    expect(screen.getByTestId("duo-tafsir").querySelector(".rd-ayah.selected")).toHaveAttribute(
      "data-ayah",
      "2:9",
    );
    // hide the tafsir from the full-screen strip: the page alone, still full screen
    await userEvent.click(screen.getByTestId("full-side-tafsir"));
    expect(screen.queryByTestId("duo-tafsir")).toBeNull();
    expect(document.querySelector(".mushaf-reader")).toHaveClass("rd-full");
    await userEvent.click(screen.getByTestId("reader-exit-full"));
    expect(document.querySelector(".mushaf-reader")).not.toHaveClass("rd-full");
  });

  it("full screen while listening with tafsir keeps both halves and a play / pause button", async () => {
    serveTafsir();
    audioStore.set((p) => ({ ...p, tafsir: true }));
    render(<PageReader locale="en" initial={resolvePage(lines.pages[1]!, lookup)} />);
    act(() => player.play({ kind: "page", page: 2 }));
    end();
    await userEvent.click(screen.getByTestId("reader-full"));
    expect(document.querySelector(".mushaf-reader")).toHaveClass("rd-full", "rd-duo");
    expect(screen.getByTestId("duo-tafsir")).toHaveTextContent("Listen with tafsir");
    expect(screen.getByTestId("mini-toggle")).toBeInTheDocument();
    expect(screen.getByTestId("duo-tafsir").querySelector(".rd-ayah.playing")).toHaveAttribute(
      "data-ayah",
      "2:1",
    );
  });
});
