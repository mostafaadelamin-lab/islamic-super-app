import { act, fireEvent, render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { readRepoJson } from "../repo";
import { PageReader, SIDE_PANEL_QUERY } from "@/components/PageReader";
import { lookupFrom, resolvePage, type MushafLinesFile } from "@/lib/mushaf";
import { audioStore } from "@/lib/audio";
import {
  DEFAULT_PAGE_SCALE,
  PAGE_SCALES,
  readerPageScaleStore,
  stepPageScale,
} from "@/lib/reader-dock";
import { resetStores } from "./reset";

const quran = readRepoJson<{ surahs: { ayahs: string[] }[] }>("content/quran/dist/quran.v1.json");
const lines = readRepoJson<MushafLinesFile>("content/quran/dist/mushaf-lines.v1.json");
const lookup = lookupFrom(quran.surahs.map((x) => x.ayahs));

/** A laptop: the wide-screen media query matches. */
function wideScreen(): void {
  vi.stubGlobal("matchMedia", (q: string) => ({
    matches: q === SIDE_PANEL_QUERY,
    media: q,
    addEventListener: () => {},
    removeEventListener: () => {},
  }));
}

beforeEach(() => {
  resetStores();
  readerPageScaleStore.reload();
  audioStore.reload();
});
afterEach(() => vi.unstubAllGlobals());

describe("page size steps", () => {
  it("starts large and steps through the sizes, stopping at the ends", () => {
    expect(readerPageScaleStore.get()).toBe(DEFAULT_PAGE_SCALE);
    expect(stepPageScale(2, 1)).toBe(2.25);
    expect(stepPageScale(2, -1)).toBe(1.75);
    expect(stepPageScale(PAGE_SCALES[0], -1)).toBe(PAGE_SCALES[0]);
    expect(stepPageScale(3, 1)).toBe(3);
  });
});

describe("Mushaf on a laptop (owner 2026-11-18)", () => {
  it("− / + change the page size and keep it; Ctrl + wheel (touchpad pinch) does too", async () => {
    wideScreen();
    render(<PageReader locale="ar" initial={resolvePage(lines.pages[4]!, lookup)} />);
    expect(screen.getByTestId("reader-size-value")).toHaveTextContent("٢٠٠٪");
    await userEvent.click(screen.getByTestId("reader-size-up"));
    expect(readerPageScaleStore.get()).toBe(2.25);
    await userEvent.click(screen.getByTestId("reader-size-down"));
    await userEvent.click(screen.getByTestId("reader-size-down"));
    expect(screen.getByTestId("reader-size-value")).toHaveTextContent("١٧٥٪");
    act(() => void fireEvent.wheel(window, { ctrlKey: true, deltaY: -100 }));
    expect(readerPageScaleStore.get()).toBe(2);
    act(() => void fireEvent.wheel(window, { deltaY: -100 })); // a plain wheel only scrolls
    expect(readerPageScaleStore.get()).toBe(2);
    expect(JSON.parse(localStorage.getItem("rattil.reader.pageScale")!)).toBe(2);
  });

  it("not on phones: the page keeps its fitted size there", () => {
    render(<PageReader locale="ar" initial={resolvePage(lines.pages[4]!, lookup)} />);
    expect(screen.queryByTestId("reader-size")).toBeNull();
  });

  it("the reciter list opens from the player and picks a reciter", async () => {
    render(<PageReader locale="ar" initial={resolvePage(lines.pages[4]!, lookup)} />);
    expect(screen.queryByTestId("player-reciter-list")).toBeNull();
    await userEvent.click(screen.getByTestId("player-reciter"));
    expect(screen.getByTestId("player-reciter")).toHaveAttribute("aria-expanded", "true");
    await userEvent.click(screen.getByTestId("reciter-option-Husary_128kbps"));
    expect(audioStore.get().reciter).toBe("Husary_128kbps");
    expect(screen.queryByTestId("player-reciter-list")).toBeNull();
    expect(screen.getByTestId("player-reciter")).toHaveTextContent("الحصري");
    // Esc closes the list without changing the reciter
    await userEvent.click(screen.getByTestId("player-reciter"));
    await userEvent.keyboard("{Escape}");
    expect(screen.queryByTestId("player-reciter-list")).toBeNull();
    expect(audioStore.get().reciter).toBe("Husary_128kbps");
  });
});
