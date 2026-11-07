import { act, fireEvent, render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { readRepoJson } from "../repo";
import { filterSurahs, SurahIndex } from "@/components/SurahIndex";
import { GoToPage } from "@/components/GoToPage";
import { SurahReader } from "@/components/SurahReader";
import { arrowTarget, PageReader } from "@/components/PageReader";
import { lookupFrom, resolvePage, type MushafLinesFile } from "@/lib/mushaf";
import { SearchView, resetSearchIndexForTests, loadIndex } from "@/components/SearchView";
import { BookmarksView } from "@/components/BookmarksView";
import { ContinueReading } from "@/components/ContinueReading";
import { AyahMarker } from "@/components/AyahMarker";
import { bookmarksStore, addBookmark } from "@/lib/bookmarks";
import { lastReadStore, prefsStore } from "@/lib/settings";
import { surahMeta } from "@/lib/pages";
import { renderQuranText } from "@/lib/quran-render";
import { routerPush } from "../setup";
import { resetStores } from "./reset";

const quran = readRepoJson<{ surahs: { ayahs: string[]; en: string[] }[] }>(
  "content/quran/dist/quran.v1.json",
);
const ayahs = (s: number): string[] => quran.surahs[s - 1]!.ayahs;

beforeEach(() => {
  resetStores();
  vi.restoreAllMocks();
});

describe("SurahIndex", () => {
  it("lists 114 surahs and filters by name, number and Arabic", async () => {
    render(<SurahIndex locale="en" />);
    expect(screen.getByTestId("surah-list").querySelectorAll("li")).toHaveLength(114);
    const box = screen.getByLabelText("Filter surahs");
    await userEvent.type(box, "kahf");
    expect(screen.getByTestId("surah-list").querySelectorAll("li")).toHaveLength(1);
    // The surah opens in the Mushaf at its first page; a secondary link opens the list view.
    expect(screen.getByTestId("surah-open")).toHaveAttribute("href", "/en/page/293/");
    expect(screen.getByTestId("surah-open")).toHaveTextContent("Al-Kahf");
    expect(screen.getByRole("link", { name: "List view — Al-Kahf" })).toHaveAttribute(
      "href",
      "/en/surah/18/",
    );
    await userEvent.clear(box);
    await userEvent.type(box, "zzzz");
    expect(screen.getByText("No surah matches your filter")).toBeInTheDocument();
  });
  it("filter helper", () => {
    expect(filterSurahs("114").map((s) => s.n)).toEqual([114]);
    expect(filterSurahs("١١").map((s) => s.n)).toEqual([11, 110, 111, 112, 113, 114]);
    expect(filterSurahs("البقرة").map((s) => s.n)).toEqual([2]);
    expect(filterSurahs("al-fatiha").map((s) => s.n)).toEqual([1]);
    expect(filterSurahs("  ")).toHaveLength(114);
    expect(filterSurahs("cow").map((s) => s.n)).toEqual([2]);
  });
  it("uses Arabic-Indic digits in Arabic", () => {
    render(<SurahIndex locale="ar" />);
    expect(screen.getAllByTestId("surah-open")[1]).toHaveTextContent("٢٨٦ آية");
    expect(screen.getAllByTestId("surah-open")[1]).toHaveAttribute("href", "/ar/page/2/");
  });
});

describe("GoToPage", () => {
  it("validates and navigates", async () => {
    render(<GoToPage locale="en" />);
    const input = screen.getByLabelText("Go to page");
    await userEvent.type(input, "605");
    await userEvent.click(screen.getByRole("button", { name: "Go" }));
    expect(screen.getByRole("alert")).toHaveTextContent("1 to 604");
    expect(input).toHaveAttribute("aria-invalid", "true");
    expect(routerPush).not.toHaveBeenCalled();
    await userEvent.clear(input);
    await userEvent.type(input, "300{Enter}");
    expect(routerPush).toHaveBeenCalledWith("/en/page/300/");
    expect(screen.queryByRole("alert")).toBeNull();
  });
});

describe("AyahMarker", () => {
  it("Arabic-Indic for ar, western for en", () => {
    const { rerender } = render(<AyahMarker n={12} locale="ar" />);
    expect(screen.getByTestId("ayah-marker")).toHaveTextContent("۝١٢");
    expect(screen.getByText("الآية ١٢")).toHaveClass("sr-only");
    rerender(<AyahMarker n={12} locale="en" />);
    expect(screen.getByTestId("ayah-marker")).toHaveTextContent("(12)");
  });
});

describe("SurahReader", () => {
  const meta = surahMeta(18)!;
  it("renders every ayah with the display map applied and the canonical text unchanged", () => {
    render(<SurahReader locale="ar" meta={meta} ayahs={ayahs(18)} basmala={ayahs(1)[0]!} />);
    const articles = document.querySelectorAll("article.ayah");
    expect(articles).toHaveLength(110);
    expect(articles[1]!.querySelector("p.quran")!.textContent).toContain(renderQuranText(ayahs(18)[1]!));
    expect(ayahs(18)[1]).toContain("ٗ"); // canonical still uses KFGQPC code point
    expect(screen.getByRole("link", { name: /اقرأ في المصحف/ })).toHaveAttribute("href", "/ar/page/293/");
    expect(screen.getByRole("link", { name: /السورة التالية/ })).toHaveAttribute("href", "/ar/surah/19/");
    expect(screen.getByRole("link", { name: /السورة السابقة/ })).toHaveAttribute("href", "/ar/surah/17/");
  });
  it("adds and removes a bookmark", async () => {
    render(<SurahReader locale="en" meta={meta} ayahs={ayahs(18)} basmala={null} />);
    const btn = screen.getByTestId("bookmark-10");
    expect(btn).toHaveAttribute("data-bookmarked", "false");
    await userEvent.click(btn);
    expect(btn).toHaveAttribute("data-bookmarked", "true");
    expect(btn).toHaveTextContent("Remove bookmark");
    expect(bookmarksStore.get()["s18-a10"]).toMatchObject({ deleted: false });
    await userEvent.click(btn);
    expect(bookmarksStore.get()["s18-a10"]).toMatchObject({ deleted: true });
  });
  it("loads the English translation when toggled and persists the toggle", async () => {
    const fetchSpy = vi
      .spyOn(globalThis, "fetch")
      .mockResolvedValue(new Response(JSON.stringify(quran.surahs[111]!.en), { status: 200 }));
    render(<SurahReader locale="en" meta={surahMeta(112)!} ayahs={ayahs(112)} basmala={null} />);
    await userEvent.click(screen.getByTestId("translation-toggle"));
    expect(prefsStore.get().translation).toBe(true);
    await screen.findByText(quran.surahs[111]!.en[0]!);
    expect(fetchSpy).toHaveBeenCalledWith("/data/en/112.json");
    await userEvent.click(screen.getByTestId("translation-toggle"));
    expect(screen.queryByText(quran.surahs[111]!.en[0]!)).toBeNull();
  });
  it("shows a retry button when the translation fails to load", async () => {
    const fetchSpy = vi.spyOn(globalThis, "fetch").mockRejectedValueOnce(new TypeError("offline"));
    prefsStore.set((p) => ({ ...p, translation: true }));
    render(<SurahReader locale="en" meta={surahMeta(113)!} ayahs={ayahs(113)} basmala={null} />);
    const retry = await screen.findByRole("button", { name: "Retry" });
    fetchSpy.mockResolvedValueOnce(new Response(JSON.stringify(quran.surahs[112]!.en), { status: 200 }));
    await userEvent.click(retry);
    await screen.findByText(quran.surahs[112]!.en[0]!);
  });
  it("first and last surahs have only one neighbour link", () => {
    const { unmount } = render(
      <SurahReader locale="en" meta={surahMeta(1)!} ayahs={ayahs(1)} basmala={null} />,
    );
    expect(screen.queryByRole("link", { name: /Previous surah/ })).toBeNull();
    unmount();
    render(<SurahReader locale="en" meta={surahMeta(114)!} ayahs={ayahs(114)} basmala={null} />);
    expect(screen.queryByRole("link", { name: /Next surah/ })).toBeNull();
  });
  it("records the last-read position from the IntersectionObserver", () => {
    let cb: IntersectionObserverCallback = () => undefined;
    const observe = vi.fn();
    class FakeIO {
      constructor(c: IntersectionObserverCallback) {
        cb = c;
      }
      observe = observe;
      disconnect = vi.fn();
      unobserve = vi.fn();
      takeRecords = () => [];
    }
    vi.stubGlobal("IntersectionObserver", FakeIO);
    render(<SurahReader locale="en" meta={surahMeta(2)!} ayahs={ayahs(2)} basmala={null} />);
    expect(observe).toHaveBeenCalledTimes(286);
    const el = document.getElementById("a-6")!;
    act(() =>
      cb(
        [{ isIntersecting: true, target: el } as unknown as IntersectionObserverEntry],
        {} as IntersectionObserver,
      ),
    );
    expect(lastReadStore.get()).toMatchObject({ surah: 2, ayah: 6, page: 3 });
    vi.unstubAllGlobals();
  });
});

describe("PageReader (15-line Mushaf)", () => {
  const lines = readRepoJson<MushafLinesFile>("content/quran/dist/mushaf-lines.v1.json");
  const lookup = lookupFrom(quran.surahs.map((x) => x.ayahs));
  const initial = (page: number) => resolvePage(lines.pages[page - 1]!, lookup);
  it("renders the page header, 15 lines, surah bands and saves position", () => {
    render(<PageReader locale="ar" initial={initial(604)} />);
    expect(screen.getByRole("heading", { level: 1 })).toHaveTextContent("الصفحة ٦٠٤ من ٦٠٤");
    const page = screen.getByTestId("mushaf-page");
    expect(page.querySelectorAll(".m-line")).toHaveLength(15);
    const ayahKeys = new Set([...page.querySelectorAll<HTMLElement>(".seg")].map((e) => e.dataset.ayah));
    expect(ayahKeys.size).toBe(15); // 112:1–4, 113:1–5, 114:1–6
    expect(screen.getByText("سورة الناس")).toBeInTheDocument();
    expect(screen.getAllByTestId("basmala")).toHaveLength(3);
    expect(screen.getByTestId("next-page")).toBeDisabled();
    expect(screen.getByTestId("prev-page")).toBeEnabled();
    expect(screen.getByTestId("juz")).toHaveTextContent("الجزء ٣٠");
    expect(lastReadStore.get()).toMatchObject({ surah: 112, ayah: 1, page: 604 });
  });
  it("prev/next buttons and arrow keys turn pages (RTL: left = next) but not while typing", async () => {
    render(<PageReader locale="ar" initial={initial(2)} />);
    fireEvent.keyDown(window, { key: "ArrowLeft" });
    expect(routerPush).toHaveBeenLastCalledWith("/ar/page/3/");
    fireEvent.keyDown(window, { key: "ArrowRight" });
    expect(routerPush).toHaveBeenLastCalledWith("/ar/page/1/");
    routerPush.mockClear();
    fireEvent.keyDown(screen.getByRole("textbox"), { key: "ArrowLeft" });
    fireEvent.keyDown(window, { key: "ArrowLeft", ctrlKey: true });
    fireEvent.keyDown(window, { key: "Enter" });
    expect(routerPush).not.toHaveBeenCalled();
    await userEvent.click(screen.getByTestId("prev-page"));
    expect(routerPush).toHaveBeenLastCalledWith("/ar/page/1/");
    await userEvent.click(screen.getByTestId("next-page"));
    expect(routerPush).toHaveBeenLastCalledWith("/ar/page/3/");
  });
  it("arrowTarget", () => {
    expect(arrowTarget("ArrowRight", 5, "ltr")).toBe(6);
    expect(arrowTarget("ArrowLeft", 5, "ltr")).toBe(4);
    expect(arrowTarget("ArrowRight", 604, "ltr")).toBeNull();
    expect(arrowTarget("ArrowRight", 1, "rtl")).toBeNull();
    expect(arrowTarget("ArrowUp", 5, "rtl")).toBeNull();
  });
  it("first page: centred, previous disabled, list-view link", () => {
    render(<PageReader locale="en" initial={initial(1)} />);
    expect(screen.getByTestId("mushaf-page")).toHaveClass("centred");
    expect(screen.getByTestId("prev-page")).toBeDisabled();
    expect(screen.getByTestId("next-page")).toBeEnabled();
    expect(screen.getByRole("link", { name: /Al-Fatihah, ayah 1/ })).toHaveAttribute(
      "href",
      "/en/surah/1/#a-1",
    );
  });
  it("tapping an ayah selects it; bookmark and close actions", async () => {
    render(<PageReader locale="en" initial={initial(3)} />);
    await userEvent.click(screen.getByRole("button", { name: "Al-Baqarah, ayah 7 — ayah options" }));
    const bar = screen.getByTestId("ayah-actions");
    expect(bar).toHaveTextContent("Al-Baqarah, ayah 7");
    const segs = document.querySelectorAll('.seg[data-ayah="2:7"]');
    expect(segs.length).toBeGreaterThan(0);
    segs.forEach((e) => expect(e).toHaveClass("selected"));
    await userEvent.click(screen.getByTestId("act-bookmark"));
    expect(bookmarksStore.get()["s2-a7"]).toMatchObject({ deleted: false });
    expect(screen.getByTestId("act-bookmark")).toHaveAttribute("data-bookmarked", "true");
    await userEvent.click(screen.getByTestId("act-close"));
    expect(screen.queryByTestId("ayah-actions")).toBeNull();
    // tapping words of an ayah selects it too
    fireEvent.click(document.querySelector('.seg[data-ayah="2:10"]')!);
    expect(screen.getByTestId("ayah-actions")).toHaveTextContent("Al-Baqarah, ayah 10");
  });
});

describe("SearchView", () => {
  beforeEach(() => resetSearchIndexForTests());
  it("searches diacritic-insensitively and links to ayahs", async () => {
    vi.spyOn(globalThis, "fetch").mockResolvedValue(
      new Response(JSON.stringify(quran.surahs.map((s) => s.ayahs)), { status: 200 }),
    );
    render(<SearchView locale="en" />);
    const box = screen.getByLabelText("Search the Quran");
    await userEvent.type(box, "اياك نعبد");
    const results = await screen.findByTestId("search-results");
    const link = results.querySelector("a")!;
    expect(link).toHaveAttribute("href", "/en/page/1/#a-1-5"); // opens the Mushaf page, ayah selected
    expect(results.querySelector("p.quran")!.textContent).toBe(renderQuranText(ayahs(1)[4]!));
    expect(screen.getByText(/1 results/)).toBeInTheDocument();
    await userEvent.clear(box);
    await userEvent.type(box, "ا");
    await screen.findByText("Type at least 2 Arabic letters.");
    await userEvent.clear(box);
    await userEvent.type(box, "قققق");
    await screen.findByText("No results");
    expect(new URL(window.location.href).searchParams.get("q")).toBe("قققق");
  });
  it("shows how many results are displayed when there are many", async () => {
    vi.spyOn(globalThis, "fetch").mockResolvedValue(
      new Response(JSON.stringify(quran.surahs.map((s) => s.ayahs)), { status: 200 }),
    );
    window.history.replaceState(null, "", "/ar/search/?q=الله");
    render(<SearchView locale="ar" />);
    await screen.findByText(/تُعرض أول ٥٠ نتيجة/);
    expect(screen.getByTestId("search-results").querySelectorAll("li")).toHaveLength(50);
    window.history.replaceState(null, "", "/");
  });
  it("reports load errors with retry", async () => {
    const spy = vi.spyOn(globalThis, "fetch").mockResolvedValueOnce(new Response("", { status: 500 }));
    render(<SearchView locale="en" />);
    const retry = await screen.findByRole("button", { name: "Retry" });
    spy.mockResolvedValueOnce(new Response(JSON.stringify([["بسم"]]), { status: 200 }));
    await userEvent.click(retry);
    await waitFor(() => expect(screen.queryByRole("alert")).toBeNull());
    await expect(loadIndex()).resolves.toBeDefined();
  });
});

describe("BookmarksView and ContinueReading", () => {
  it("empty state", () => {
    render(<BookmarksView locale="en" />);
    expect(screen.getByTestId("bookmarks-empty")).toHaveTextContent("No bookmarks yet");
  });
  it("lists and removes bookmarks", async () => {
    bookmarksStore.set((s) => addBookmark(addBookmark(s, 2, 255, 1), 1, 1, 2));
    render(<BookmarksView locale="ar" />);
    const list = screen.getByTestId("bookmark-list");
    expect(list.querySelectorAll("li")).toHaveLength(2);
    expect(screen.getByRole("link", { name: "البقرة، الآية ٢٥٥" })).toHaveAttribute(
      "href",
      "/ar/surah/2/#a-255",
    );
    await userEvent.click(screen.getByRole("button", { name: /حذف — الفاتحة/ }));
    expect(list.querySelectorAll("li")).toHaveLength(1);
    expect(bookmarksStore.get()["s1-a1"]?.deleted).toBe(true);
  });
  it("continue reading shows last position or a hint", () => {
    const { rerender } = render(<ContinueReading locale="en" />);
    expect(screen.getByText(/your position is saved automatically/)).toBeInTheDocument();
    act(() => lastReadStore.set({ surah: 18, ayah: 10, page: 294, at: 1 }));
    rerender(<ContinueReading locale="en" />);
    expect(screen.getByTestId("continue-surah")).toHaveAttribute("href", "/en/surah/18/#a-10");
    expect(screen.getByTestId("continue-page")).toHaveAttribute("href", "/en/page/294/");
  });
});
