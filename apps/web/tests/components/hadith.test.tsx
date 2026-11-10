import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import { readRepoJson } from "../repo";
import { HadithFavourites, HadithReader, PAGE_SIZE } from "@/components/HadithReader";
import { hadithFavStore } from "@/lib/hadith";

interface Chunk {
  ahadith: string[];
}
const text = (book: string, n: number): string =>
  readRepoJson<Chunk>(`content/hadith/dist/${book}/${Math.floor((n - 1) / 500)}.json`).ahadith[
    (n - 1) % 500
  ]!;

beforeEach(() => {
  localStorage.clear();
  hadithFavStore.reload();
  window.location.hash = "";
  vi.stubGlobal("fetch", (url: string) => {
    const m = /\/data\/hadith\/([a-z]+)\/(\d+)\.json$/.exec(url)!;
    if (m[1] === "darimi") return Promise.resolve(new Response("", { status: 404 }));
    return Promise.resolve(
      new Response(JSON.stringify(readRepoJson(`content/hadith/dist/${m[1]}/${m[2]}.json`))),
    );
  });
});
afterEach(() => vi.unstubAllGlobals());

const shown = (): number[] => screen.getAllByTestId("hadith").map((e) => Number(e.dataset.n));

describe("HadithReader", () => {
  it("shows twenty hadiths unchanged, pages, and jumps to a number", async () => {
    render(<HadithReader locale="ar" bookId="malik" />);
    expect(screen.getByTestId("hadith-review").textContent).toContain("قيد المراجعة الشرعية");
    await waitFor(() => expect(shown()).toHaveLength(PAGE_SIZE));
    expect(shown()[0]).toBe(1);
    expect(screen.getAllByTestId("hadith")[0]!.querySelector(".hadith-text")!.textContent).toBe(
      text("malik", 1).trim(),
    );
    expect((screen.getByTestId("hadith-prev") as HTMLButtonElement).disabled).toBe(true);
    fireEvent.click(screen.getByTestId("hadith-next"));
    await waitFor(() => expect(shown()[0]).toBe(21));
    fireEvent.change(screen.getByTestId("hadith-go"), { target: { value: "1594" } });
    fireEvent.click(screen.getByTestId("hadith-go-btn"));
    await waitFor(() => expect(shown().at(-1)).toBe(1594));
    expect(shown()[0]).toBe(1581);
    expect((screen.getByTestId("hadith-next") as HTMLButtonElement).disabled).toBe(true);
    expect(window.location.hash).toBe("#1594");
  });

  it("searches the book and goes back", async () => {
    render(<HadithReader locale="ar" bookId="bukhari" />);
    await waitFor(() => expect(shown()).toHaveLength(PAGE_SIZE));
    fireEvent.change(screen.getByTestId("hadith-query"), { target: { value: "انما الاعمال بالنيات" } });
    fireEvent.click(screen.getByTestId("hadith-search-btn"));
    await waitFor(() => expect(screen.getByTestId("hadith-results")).toBeTruthy(), { timeout: 5000 });
    expect(shown()[0]).toBe(1);
    fireEvent.click(screen.getByTestId("hadith-clear"));
    expect(screen.queryByTestId("hadith-results")).toBeNull();
  });

  it("says so when a part can't load", async () => {
    render(<HadithReader locale="en" bookId="darimi" />);
    expect(await screen.findByTestId("hadith-error")).toBeTruthy();
  });
});

describe("HadithFavourites", () => {
  it("saves a hadith and lists it with its book", async () => {
    const { unmount } = render(<HadithFavourites locale="ar" />);
    expect(screen.getByTestId("hadith-fav-empty")).toBeTruthy();
    unmount();
    render(<HadithReader locale="ar" bookId="muslim" />);
    await waitFor(() => expect(shown()).toHaveLength(PAGE_SIZE));
    fireEvent.click(screen.getAllByTestId("hadith-fav")[2]!);
    expect(hadithFavStore.get().keys).toEqual(["muslim:3"]);
    expect(screen.getAllByTestId("hadith-fav")[2]!.getAttribute("aria-pressed")).toBe("true");
    render(<HadithFavourites locale="ar" />);
    const list = await screen.findByTestId("hadith-favourites");
    await waitFor(() => expect(list.querySelectorAll("[data-testid=hadith]")).toHaveLength(1));
    expect(list.textContent).toContain("صحيح مسلم");
  });
});
