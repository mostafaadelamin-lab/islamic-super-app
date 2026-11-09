import { render, screen, within } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { AdhkarView } from "@/components/AdhkarView";
import { HisnIndex } from "@/components/HisnIndex";
import { HisnItems } from "@/components/HisnItems";
import adhkar from "@/generated/adhkar.json";
import { HISN, HISN_SECTIONS } from "@/lib/hisn";
import { resetStores } from "./reset";

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
      <HisnIndex locale="en" chapters={HISN.map(({ id, title }) => ({ id, title }))} sections={HISN_SECTIONS} />,
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
    expect(report.getAttribute("href")).toMatch(/^mailto:\?subject=/);
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
