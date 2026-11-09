import { render, screen, within } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { WorshipView } from "@/components/WorshipView";
import { worshipStore } from "@/lib/worship";
import { resetStores } from "./reset";

const NOW = new Date(2026, 10, 9, 10, 0); // 9 November 2026, local time

beforeEach(() => {
  resetStores();
  worshipStore.reload();
  vi.useFakeTimers({ shouldAdvanceTime: true, now: NOW });
});
afterEach(() => vi.useRealTimers());

const user = () => userEvent.setup({ advanceTimers: vi.advanceTimersByTime });

describe("WorshipView", () => {
  it("records today's prayers and fasting, shows totals and the streak, and edits an earlier day", async () => {
    const u = user();
    render(<WorshipView locale="en" />);
    expect(await screen.findByTestId("worship-month")).toHaveTextContent("November 2026");
    for (const k of ["fajr", "dhuhr", "asr", "maghrib", "isha"])
      await u.click(screen.getByTestId(`worship-${k}`));
    await u.click(screen.getByTestId("worship-fasting"));
    await u.type(screen.getByLabelText("Note"), "Monday fast");
    expect(worshipStore.get().days["2026-11-09"]).toEqual({
      prayers: { fajr: true, dhuhr: true, asr: true, maghrib: true, isha: true },
      fasting: true,
      note: "Monday fast",
    });
    expect(screen.getByTestId("worship-streak")).toHaveTextContent("Days in a row with all five prayers: 1");
    expect(screen.getByTestId("worship-week")).toHaveTextContent("5 of 35 prayers");
    expect(screen.getByTestId("worship-month-stats")).toHaveTextContent("Fasting days: 1");
    const grid = screen.getByTestId("worship-grid");
    expect(grid.querySelector('[data-day="2026-11-09"]')).toHaveClass("full");
    expect(grid.querySelector('[data-day="2026-11-10"]')).toBeDisabled();
    await u.click(grid.querySelector('[data-day="2026-11-08"]')!);
    expect(within(screen.getByTestId("worship-day")).getByRole("heading")).toHaveTextContent(
      "Sunday 8 November",
    );
    await u.click(screen.getByTestId("worship-fajr"));
    expect(worshipStore.get().days["2026-11-08"]?.prayers).toEqual({ fajr: true });
    expect(screen.getByTestId("worship-next")).toBeDisabled();
    await u.click(screen.getByTestId("worship-prev"));
    expect(screen.getByTestId("worship-month")).toHaveTextContent("October 2026");
  });
});
