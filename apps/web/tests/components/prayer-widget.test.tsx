import { render, screen, within } from "@testing-library/react";
import { PrayerTimesWidget } from "@/components/PrayerTimesWidget";
import { resetStores } from "./reset";

beforeEach(() => resetStores());
afterEach(() => vi.useRealTimers());

describe("PrayerTimesWidget (the phone widget's layout on the home, owner 2026-11-22)", () => {
  it("lists the six times with the next prayer marked, and the day panel with a countdown", async () => {
    vi.useFakeTimers({ shouldAdvanceTime: true, now: new Date("2026-03-01T06:00:00Z") }); // 09:00 Makkah
    render(<PrayerTimesWidget locale="en" />);
    const card = await screen.findByTestId("prayer-widget");
    const rows = within(card).getAllByRole("listitem");
    expect(rows.map((r) => r.getAttribute("data-prayer"))).toEqual([
      "fajr",
      "sunrise",
      "dhuhr",
      "asr",
      "maghrib",
      "isha",
    ]);
    expect(rows[2]).toHaveClass("on");
    expect(rows.filter((r) => r.classList.contains("on"))).toHaveLength(1);
    expect(screen.getByTestId("prayer-widget-next")).toHaveTextContent("Dhuhr");
    expect(screen.getByTestId("prayer-widget-countdown").textContent).toMatch(/^\d+:\d\d:\d\d$/);
    expect(card).toHaveTextContent("Sunday");
  });

  it("after Isha shows tomorrow with Fajr marked", async () => {
    vi.useFakeTimers({ shouldAdvanceTime: true, now: new Date("2026-03-01T20:00:00Z") }); // 23:00 Makkah
    render(<PrayerTimesWidget locale="en" />);
    const card = await screen.findByTestId("prayer-widget");
    expect(within(card).getAllByRole("listitem")[0]).toHaveClass("on");
    expect(card).toHaveTextContent("Monday");
  });
});
