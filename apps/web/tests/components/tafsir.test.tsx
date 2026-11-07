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

  it("on: follows the recited ayah (none for the basmala); a selection takes precedence; can be turned off", async () => {
    serveTafsir();
    audioStore.set((p) => ({ ...p, tafsir: true }));
    render(<PageReader locale="en" initial={resolvePage(lines.pages[1]!, lookup)} />);
    act(() => player.play({ kind: "page", page: 2 }));
    expect(screen.queryByTestId("recitation-tafsir")).toBeNull(); // the basmala has no tafsir entry
    end();
    const sheet = await screen.findByTestId("recitation-tafsir");
    expect(sheet).toHaveAccessibleName("Tafsir of the ayah being recited");
    expect((await screen.findByText(entry(2, 1))).dataset.testid).toBe("tafsir-text");
    expect(screen.queryByTestId("tafsir-next")).toBeNull(); // the player has its own next/previous
    end();
    expect((await screen.findByText(entry(2, 2))).dataset.testid).toBe("tafsir-text");
    expect(screen.getByTestId("tafsir")).toHaveAttribute("data-ayah", "2:2");
    await userEvent.click(screen.getByRole("button", { name: "Al-Baqarah, ayah 4 — ayah options" }));
    expect(screen.queryByTestId("recitation-tafsir")).toBeNull();
    expect(screen.getByTestId("tafsir")).toHaveAttribute("data-ayah", "2:4");
    await userEvent.click(screen.getByTestId("act-close"));
    expect(screen.getByTestId("recitation-tafsir")).toBeInTheDocument();
    act(() => audioStore.set((p) => ({ ...p, tafsir: false })));
    expect(screen.queryByTestId("recitation-tafsir")).toBeNull();
  });
});
