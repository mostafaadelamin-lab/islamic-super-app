import { fireEvent, render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { KhatmaView } from "@/components/KhatmaView";
import { khatmaStore, planByDays } from "@/lib/khatma";
import { resetStores } from "./reset";

const NOW = new Date("2026-11-09T09:00:00Z");

beforeEach(() => {
  resetStores();
  vi.useFakeTimers({ shouldAdvanceTime: true, now: NOW });
});
afterEach(() => {
  vi.useRealTimers();
  vi.restoreAllMocks();
});

const user = () => userEvent.setup({ advanceTimers: vi.advanceTimersByTime });

describe("KhatmaView", () => {
  it("creates a 30-day khatma and marks wirds read", async () => {
    const u = user();
    render(<KhatmaView locale="en" />);
    expect(await screen.findByTestId("khatma-preview")).toHaveTextContent(
      "30 portions, about 21 pages a day",
    );
    expect(screen.getByText("You have not completed a khatma yet.")).toBeInTheDocument();
    await u.click(screen.getByTestId("khatma-start"));
    expect(khatmaStore.get().current).toMatchObject({ name: "My khatma", wirds: 30, done: 0 });
    expect(screen.getByTestId("khatma-percent")).toHaveTextContent("0%");
    expect(screen.getByText(/Current portion \(1 of 30\)/)).toBeInTheDocument();
    expect(screen.getByTestId("khatma-read")).toHaveAttribute("href", "/en/page/1/");
    expect(screen.getByText(/From surah Al-Fatihah ayah 1, page 1 to surah .* page 20/)).toBeInTheDocument();
    await u.click(screen.getByTestId("khatma-done"));
    expect(khatmaStore.get().current?.done).toBe(1);
    expect(screen.getByTestId("khatma-read")).toHaveAttribute("href", "/en/page/21/");
    expect(screen.queryByTestId("khatma-behind")).toBeNull();
    await u.click(screen.getByTestId("khatma-done"));
    expect(screen.getByTestId("khatma-ahead")).toHaveTextContent("1 portions ahead");
    await u.click(screen.getByText("Show all"));
    expect(screen.getByTestId("khatma-all").querySelectorAll("li")).toHaveLength(30);
  });

  it("pages-per-day mode", async () => {
    const u = user();
    render(<KhatmaView locale="en" />);
    await u.click(await screen.findByTestId("khatma-mode-pages"));
    fireEvent.change(screen.getByLabelText("Pages each day"), { target: { value: "10" } });
    expect(screen.getByTestId("khatma-preview")).toHaveTextContent("61 portions, about 10 pages a day");
  });

  it("late: shows how many days behind and reschedules", async () => {
    const u = user();
    khatmaStore.set({ current: { ...planByDays("K", "2026-11-01", 30), done: 2 }, history: [] });
    render(<KhatmaView locale="ar" />);
    expect(await screen.findByTestId("khatma-behind")).toHaveTextContent("متأخر ٦ يوم");
    await u.click(screen.getByTestId("khatma-reschedule"));
    expect(screen.queryByTestId("khatma-behind")).toBeNull();
    expect(khatmaStore.get().current).toMatchObject({ startDate: "2026-11-09", done: 0, wirds: 22 });
  });

  it("finishing moves it to the history; delete asks first", async () => {
    const u = user();
    khatmaStore.set({ current: { ...planByDays("K", "2026-11-08", 2), done: 1 }, history: [] });
    render(<KhatmaView locale="en" />);
    await u.click(await screen.findByTestId("khatma-done"));
    expect(screen.getByTestId("khatma-history")).toHaveTextContent(
      "K completed on 9 November 2026 in 2 days",
    );
    khatmaStore.set((s) => ({ ...s, current: planByDays("Z", "2026-11-09", 5) }));
    const confirm = vi.spyOn(window, "confirm").mockReturnValueOnce(false).mockReturnValueOnce(true);
    await u.click(await screen.findByTestId("khatma-delete"));
    expect(khatmaStore.get().current).not.toBeNull();
    await u.click(screen.getByTestId("khatma-delete"));
    expect(confirm).toHaveBeenCalledTimes(2);
    expect(khatmaStore.get().current).toBeNull();
  });
});
