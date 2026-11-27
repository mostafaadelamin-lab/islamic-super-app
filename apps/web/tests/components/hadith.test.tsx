import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import { readRepoJson } from "../repo";
import { HadithFavourites, HadithReader, PAGE_SIZE } from "@/components/HadithReader";
import { readFileSync } from "node:fs";
import { displayText, hadithFavStore, resetExplainedCache } from "@/lib/hadith";

interface Chunk {
  ahadith: string[];
}
// as shown: the sunnah.com books join the source's line breaks with spaces
const text = (book: string, n: number): string =>
  displayText(
    readRepoJson<Chunk>(`content/hadith/dist/${book}/${Math.floor((n - 1) / 500)}.json`).ahadith[
      (n - 1) % 500
    ]!,
  );

beforeEach(() => {
  localStorage.clear();
  hadithFavStore.reload();
  window.location.hash = "";
  resetExplainedCache();
  vi.stubGlobal("fetch", (url: string) => {
    const ex = /\/data\/hadith\/explained\/([a-z]+)\.json$/.exec(url);
    if (ex)
      return Promise.resolve(
        new Response(readFileSync(`public/data/hadith/explained/${ex[1]}.json`, "utf8")),
      );
    const f = /\/data\/hadith\/([a-z]+)\/(refs|from-alamiyya)\.json$/.exec(url);
    if (f)
      return Promise.resolve(
        new Response(JSON.stringify(readRepoJson(`content/hadith/dist/${f[1]}/${f[2]}.json`))),
      );
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
  it("shows the app's simplified explanation, grade and benefits where there is one", async () => {
    render(<HadithReader locale="ar" bookId="malik" />);
    const ex = await screen.findByTestId("hadith-explain-5");
    expect(ex.textContent).toContain("الشرح المبسّط");
    expect(ex.querySelector(".hadith-explain-text")!.textContent!.length).toBeGreaterThan(20);
    expect(ex.textContent).not.toContain("من فوائد الحديث");
    fireEvent.click(screen.getByTestId("hadith-explain-more-5"));
    expect(ex.textContent).toContain("الدرجة: صحيح");
    expect(ex.textContent).toContain("من فوائد الحديث");
    expect(screen.queryByTestId("hadith-explain-1")).toBeNull();
  });

  it("lists only the hadiths that have a simplified explanation", async () => {
    const map = JSON.parse(readFileSync("public/data/hadith/explained/malik.json", "utf8")) as {
      map: Record<string, string>;
    };
    const nums = Object.keys(map.map)
      .map(Number)
      .sort((a, b) => a - b);
    render(<HadithReader locale="ar" bookId="malik" />);
    const count = await screen.findByTestId("hadith-explained-count", {}, { timeout: 5000 });
    expect(count.textContent).toContain("لها شرح مبسّط");
    fireEvent.click(screen.getByTestId("hadith-explained-only"));
    await waitFor(() => expect(shown()).toEqual(nums.slice(0, PAGE_SIZE)), { timeout: 5000 });
    for (const k of shown()) expect(await screen.findByTestId(`hadith-explain-${k}`)).toBeTruthy();
    expect(screen.getAllByTestId("hadith")[0]!.querySelector(".hadith-text")!.textContent).toBe(
      text("malik", nums[0]!).trim(),
    );
    fireEvent.click(screen.getByTestId("hadith-explained-next"));
    await waitFor(() => expect(shown()[0]).toBe(nums[PAGE_SIZE]));
    fireEvent.click(screen.getByText("العودة إلى الكتاب"));
    await waitFor(() => expect(shown()[0]).toBe(1));
  });

  it("shows twenty hadiths unchanged, pages, and jumps to a number", async () => {
    render(<HadithReader locale="ar" bookId="malik" />);
    expect(screen.queryByTestId("hadith-review")).toBeNull();
    await waitFor(() => expect(shown()).toHaveLength(PAGE_SIZE));
    expect(shown()[0]).toBe(1);
    expect(screen.getAllByTestId("hadith")[0]!.querySelector(".hadith-text")!.textContent).toBe(
      text("malik", 1).trim(),
    );
    expect((screen.getByTestId("hadith-prev") as HTMLButtonElement).disabled).toBe(true);
    fireEvent.click(screen.getByTestId("hadith-next"));
    await waitFor(() => expect(shown()[0]).toBe(21));
    // Muwatta Malik has sunnah.com's running numbers since 1.2.25: «1861» is its last entry (1,860)
    fireEvent.change(screen.getByTestId("hadith-go"), { target: { value: "1861" } });
    fireEvent.click(screen.getByTestId("hadith-go-btn"));
    await waitFor(() => expect(shown().at(-1)).toBe(1860));
    expect(shown()[0]).toBe(1841);
    expect((screen.getByTestId("hadith-next") as HTMLButtonElement).disabled).toBe(true);
    expect(window.location.hash).toBe("#1860");
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
