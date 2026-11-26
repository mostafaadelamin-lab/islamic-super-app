import { act, render, screen, within } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { AdhkarView } from "@/components/AdhkarView";
import { HisnIndex } from "@/components/HisnIndex";
import { HisnItems } from "@/components/HisnItems";
import adhkar from "@/generated/adhkar.json";
import { HISN, HISN_SECTIONS } from "@/lib/hisn";
import { resetStores } from "./reset";
import { ADHKAR_AUTO_EXIT_MS } from "@/hooks/useAutoExit";
import { adhkarStore, countOne, sessionItems } from "@/lib/adhkar";
import { adhkarViewStore } from "@/lib/dhikr-share";
import { isoDate } from "@/lib/time";
import { countStatedIn } from "@/lib/hisn-count";

const ITEMS = (adhkar as { items: string[] }).items;
const TRAVEL_CHAPTER = 98;
const TRAVEL = HISN[TRAVEL_CHAPTER - 1]!;

beforeEach(() => {
  resetStores();
  window.location.hash = "#morning";
});
afterEach(() => vi.unstubAllGlobals());

describe("Hisn sections", () => {
  it("filters chapters by section", async () => {
    render(
      <HisnIndex
        locale="en"
        chapters={HISN.map(({ id, title }) => ({ id, title }))}
        sections={HISN_SECTIONS}
      />,
    );
    const list = screen.getByTestId("hisn-list");
    expect(within(list).getAllByRole("link")).toHaveLength(HISN.length);
    await userEvent.click(screen.getByTestId("hisn-section-travel"));
    const travel = HISN_SECTIONS.find((s) => s.id === "travel")!.chapters;
    expect(within(list).getAllByRole("link")).toHaveLength(travel.length);
    expect(list).toHaveTextContent(TRAVEL.title);
    await userEvent.click(screen.getByTestId("hisn-section-all"));
    expect(within(list).getAllByRole("link")).toHaveLength(HISN.length);
  });
});

describe("cards, share and report", () => {
  it("Hisn chapter: cards one at a time; share falls back to copying the unchanged text", async () => {
    const writeText = vi.fn(async () => undefined);
    vi.stubGlobal("navigator", { ...navigator, share: undefined, clipboard: { writeText } });
    render(<HisnItems locale="en" chapterId={2} title={HISN[1]!.title} items={HISN[1]!.items} />);
    expect(screen.getByTestId("hisn-items").children).toHaveLength(HISN[1]!.items.length);
    await userEvent.click(screen.getByTestId("view-cards"));
    expect(screen.getByTestId("card-pos")).toHaveTextContent(`1 / ${HISN[1]!.items.length}`);
    await userEvent.click(screen.getByTestId("card-next"));
    expect(screen.getByTestId("card-pos")).toHaveTextContent("2 /");
    await userEvent.click(screen.getByTestId("hisn-2-share"));
    expect(writeText).toHaveBeenCalledWith(expect.stringContaining(HISN[1]!.items[1]!));
    expect(screen.getByText("Copied — paste it where you like.")).toBeInTheDocument();
    const report = screen.getByTestId("hisn-2-report");
    expect(report.getAttribute("href")).toMatch(
      /\/en\/help\/?\?title=Mistake%20in%20a%20dhikr&message=.*#contact$/,
    );
    expect(decodeURIComponent(report.getAttribute("href")!)).toContain("(chapter 2) · 2");
  });

  it("morning adhkar in cards move on when a dhikr's count is complete", async () => {
    render(<AdhkarView locale="en" items={ITEMS} />);
    await userEvent.click(screen.getByTestId("view-cards"));
    expect(screen.getByTestId("card-pos")).toHaveTextContent(/^1 \//);
    const counter = screen.getByTestId("dhikr-count");
    const total = Number(counter.textContent!.split("/")[1]!.trim());
    for (let k = 0; k < total; k++) await userEvent.click(screen.getByTestId("dhikr-count"));
    expect(screen.getByTestId("card-pos")).toHaveTextContent(/^2 \//);
  });
});

describe("finishing a list goes back by itself", () => {
  const today = (): string => {
    const d = new Date();
    return isoDate({ year: d.getFullYear(), month: d.getMonth() + 1, day: d.getDate() });
  };

  it("morning: the last tap shows the tick, then scrolls back up to the adhkar list", async () => {
    const scrollTo = vi.fn();
    vi.stubGlobal("scrollTo", scrollTo);
    const list = sessionItems(ITEMS, "morning");
    // Everything but the last tap of the last dhikr.
    adhkarStore.set((p) => {
      let cur = p;
      for (const d of list) {
        const n = d === list[list.length - 1] ? d.count - 1 : d.count;
        for (let k = 0; k < n; k++) cur = countOne(cur, today(), "morning", d);
      }
      return cur;
    });
    adhkarViewStore.set(() => ({ mode: "list" }));
    render(<AdhkarView locale="en" items={ITEMS} />);
    vi.useFakeTimers();
    try {
      const counters = screen.getAllByTestId("dhikr-count");
      act(() => counters[counters.length - 1]!.click());
      expect(scrollTo).not.toHaveBeenCalled();
      act(() => vi.advanceTimersByTime(ADHKAR_AUTO_EXIT_MS));
      expect(scrollTo).toHaveBeenCalledWith(expect.objectContaining({ top: 0 }));
    } finally {
      vi.useRealTimers();
    }
  });

  it("a list already finished today does not jump", async () => {
    const scrollTo = vi.fn();
    vi.stubGlobal("scrollTo", scrollTo);
    adhkarStore.set((p) => {
      let cur = p;
      for (const d of sessionItems(ITEMS, "morning"))
        for (let k = 0; k < d.count; k++) cur = countOne(cur, today(), "morning", d);
      return cur;
    });
    vi.useFakeTimers();
    try {
      render(<AdhkarView locale="en" items={ITEMS} />);
      act(() => vi.advanceTimersByTime(ADHKAR_AUTO_EXIT_MS * 2));
      expect(scrollTo).not.toHaveBeenCalled();
    } finally {
      vi.useRealTimers();
    }
  });

  it("Hisn chapter cards: counters like the app; the last one goes back to the chapter list", async () => {
    const assign = vi.fn();
    vi.stubGlobal("location", { ...window.location, assign, origin: window.location.origin });
    render(<HisnItems locale="en" chapterId={TRAVEL_CHAPTER} title={TRAVEL.title} items={TRAVEL.items} />);
    await userEvent.click(screen.getByTestId("view-cards"));
    vi.useFakeTimers();
    try {
      for (let i = 0; i < TRAVEL.items.length; i++) {
        for (let k = 0; k < countStatedIn(TRAVEL.items[i]!); k++)
          act(() => screen.getByTestId(`hisn-count-${i + 1}`).click());
        if (i < TRAVEL.items.length - 1) act(() => screen.getByTestId("card-next").click());
      }
      expect(assign).not.toHaveBeenCalled();
      act(() => vi.advanceTimersByTime(ADHKAR_AUTO_EXIT_MS));
      expect(assign).toHaveBeenCalledWith(expect.stringMatching(/hisn\/?$/));
    } finally {
      vi.useRealTimers();
    }
  });
});

describe("countStatedIn", () => {
  it("reads the count a Hisn text states, ignoring diacritics; 1 otherwise", () => {
    expect(countStatedIn("سُبْحَانَ اللهِ (ثَلاثَ مَرَّاتٍ)")).toBe(3);
    expect(countStatedIn("لا إله إلا الله (مائة مرة)")).toBe(100);
    expect(countStatedIn("بسم الله")).toBe(1);
  });
});
