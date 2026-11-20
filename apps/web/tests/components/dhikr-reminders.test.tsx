import { act, render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import adhkar from "@/generated/adhkar.json";
import { DhikrReminderAlerts, DhikrRemindersView } from "@/components/DhikrReminders";
import {
  DEFAULT_DHIKR_REMINDERS,
  dhikrReminderStore,
  dhikrSlots,
  nextDhikrReminder,
  sanitizeDhikrReminders,
} from "@/lib/dhikr-reminders";
import { resetStores } from "./reset";

const TEXTS = (adhkar as { items: string[] }).items;
const NOW = new Date(2026, 10, 20, 9, 10); // 9:10 local

beforeEach(() => {
  resetStores();
  vi.useFakeTimers({ shouldAdvanceTime: true, now: NOW });
});
afterEach(() => {
  vi.useRealTimers();
  vi.restoreAllMocks();
});

describe("dhikr reminder planning (owner 2026-11-20)", () => {
  it("every 30 minutes from 8:00 to 23:00 and over midnight", () => {
    const s = dhikrSlots({ from: 480, to: 1380, every: 30 });
    expect(s.length).toBe(31);
    expect(s.at(-1)).toBe(1380);
    expect(dhikrSlots({ from: 1320, to: 60, every: 60 })).toEqual([1320, 1380, 0, 60]);
    expect(dhikrSlots({ from: 0, to: 0, every: 60 }).length).toBe(24);
  });

  it("off by default; the next one rotates through the chosen adhkar", () => {
    expect(nextDhikrReminder(NOW, DEFAULT_DHIKR_REMINDERS)).toBeNull();
    const on = sanitizeDhikrReminders({ enabled: true });
    const n = nextDhikrReminder(NOW, on)!;
    expect([n.at.getHours(), n.at.getMinutes()]).toEqual([9, 30]);
    // slot 3 (9:30) -> ids[3 % 3] = salat
    expect(n.id).toBe("salat");
    const late = nextDhikrReminder(new Date(2026, 10, 20, 23, 30), on)!;
    expect([late.at.getDate(), late.at.getHours()]).toEqual([21, 8]);
  });

  it("sanitises stored prefs", () => {
    const p = sanitizeDhikrReminders({ enabled: "yes", every: 1, ids: ["hasbi", "x", "salat"], from: 9999 });
    expect(p).toEqual({ ...DEFAULT_DHIKR_REMINDERS, every: 5, ids: ["salat", "hasbi"] });
  });
});

describe("dhikr reminders page and alert", () => {
  it("turns on, picks adhkar and the interval", async () => {
    const user = userEvent.setup({ advanceTimers: vi.advanceTimersByTime });
    render(<DhikrRemindersView locale="ar" />);
    await user.click(screen.getByTestId("dhikr-rem-on"));
    expect(dhikrReminderStore.get().enabled).toBe(true);
    expect(screen.getByTestId("dhikr-rem-summary")).toHaveTextContent("٣١");
    await user.click(screen.getByTestId("dhikr-rem-every-60"));
    expect(dhikrReminderStore.get().every).toBe(60);
    await user.click(screen.getByTestId("dhikr-rem-hasbi"));
    await user.click(screen.getByTestId("dhikr-rem-subhan"));
    expect(dhikrReminderStore.get().ids).toEqual(["salat", "istighfar", "hasbi"]);
    expect(screen.getByText(TEXTS[16]!)).toBeInTheDocument();
  });

  it("at the time, shows the dhikr and says it", async () => {
    const play = vi.spyOn(HTMLMediaElement.prototype, "play").mockResolvedValue(undefined);
    dhikrReminderStore.set((p) => ({ ...p, enabled: true }));
    render(<DhikrReminderAlerts locale="ar" />);
    expect(screen.queryByTestId("dhikr-ringing")).toBeNull();
    await act(async () => {
      vi.setSystemTime(new Date(2026, 10, 20, 9, 30, 2));
      vi.advanceTimersByTime(6000);
    });
    const banner = screen.getByTestId("dhikr-ringing");
    expect(banner).toHaveAttribute("data-id", "salat");
    expect(banner).toHaveTextContent(TEXTS[28]!);
    expect(play).toHaveBeenCalled();
  });
});
