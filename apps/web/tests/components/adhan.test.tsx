import { act, render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { AdhanAlerts, AdhanSettings } from "@/components/AdhanAlerts";
import { adhanStore, DEFAULT_ADHAN, nextAdhanAlert, nextAlert, sanitizeAdhan } from "@/lib/adhan-alerts";
import { prayerTimes } from "@/lib/prayer";
import { resetStores } from "./reset";

const NOW = new Date("2026-03-01T06:00:00Z"); // 09:00 in Makkah, before Dhuhr
const MAKKAH = { lat: 21.3891, lng: 39.8579, tz: "Asia/Riyadh", method: "makkah", asr: "standard" };
const today = prayerTimes({ year: 2026, month: 3, day: 1 }, MAKKAH.lat, MAKKAH.lng, "makkah");

beforeEach(() => {
  resetStores();
  vi.useFakeTimers({ shouldAdvanceTime: true, now: NOW });
});
afterEach(() => {
  vi.useRealTimers();
  vi.unstubAllGlobals();
  vi.restoreAllMocks();
});

const user = () => userEvent.setup({ advanceTimers: vi.advanceTimersByTime });

describe("adhan alert planning", () => {
  it("is off until enabled, then picks the next enabled prayer", () => {
    expect(nextAdhanAlert(NOW, MAKKAH, sanitizeAdhan({}))).toBeNull();
    const on = sanitizeAdhan({ enabled: true });
    expect(nextAdhanAlert(NOW, MAKKAH, on)).toEqual({ key: "dhuhr", at: today.times.dhuhr });
    const noDhuhr = sanitizeAdhan({ enabled: true, prayers: { dhuhr: false } });
    expect(nextAdhanAlert(NOW, MAKKAH, noDhuhr)?.key).toBe("asr");
    const fajrOnly = sanitizeAdhan({
      enabled: true,
      prayers: { dhuhr: false, asr: false, maghrib: false, isha: false },
    });
    const next = nextAdhanAlert(NOW, MAKKAH, fajrOnly);
    expect(next?.key).toBe("fajr");
    expect(next!.at.getTime()).toBeGreaterThan(NOW.getTime());
    const none = sanitizeAdhan({
      enabled: true,
      prayers: { fajr: false, dhuhr: false, asr: false, maghrib: false, isha: false },
    });
    expect(nextAdhanAlert(NOW, MAKKAH, none)).toBeNull();
  });

  it("sanitises stored prefs", () => {
    expect(
      sanitizeAdhan({ enabled: "yes", prayers: { fajr: false, sunrise: false, x: 1 }, sound: 0 }),
    ).toEqual({
      enabled: false,
      prayers: { fajr: false },
      sound: true,
      preMinutes: 0,
      iqamaEnabled: false,
      iqama: { fajr: 20, dhuhr: 15, asr: 15, maghrib: 10, isha: 15 },
    });
    const s = sanitizeAdhan({ preMinutes: 7, iqamaEnabled: true, iqama: { fajr: 500, dhuhr: "x", asr: 0 } });
    expect(s.preMinutes).toBe(0);
    expect(s.iqama).toMatchObject({ fajr: 60, dhuhr: 1, asr: 1, maghrib: 10 });
  });

  it("plans the reminder before the adhan and the iqama around each enabled prayer", () => {
    const on = sanitizeAdhan({ enabled: true, preMinutes: 10, iqamaEnabled: true });
    const pre = nextAlert(NOW, MAKKAH, on);
    expect(pre).toMatchObject({ kind: "pre", key: "dhuhr" });
    expect(pre!.at.getTime()).toBe(today.times.dhuhr.getTime() - 10 * 60_000);
    const adhan = nextAlert(new Date(pre!.at.getTime() + 1), MAKKAH, on);
    expect(adhan).toMatchObject({ kind: "adhan", key: "dhuhr", at: today.times.dhuhr });
    const iqama = nextAlert(new Date(today.times.dhuhr.getTime() + 1), MAKKAH, on);
    expect(iqama).toMatchObject({ kind: "iqama", key: "dhuhr" });
    expect(iqama!.at.getTime()).toBe(today.times.dhuhr.getTime() + 15 * 60_000);
    // Without the extras only adhans are planned (same as before).
    expect(nextAlert(NOW, MAKKAH, sanitizeAdhan({ enabled: true }))).toMatchObject({
      kind: "adhan",
      key: "dhuhr",
    });
    expect(nextAlert(NOW, MAKKAH, sanitizeAdhan({}))).toBeNull();
  });
});

describe("AdhanSettings", () => {
  it("enables alerts, asks for notification permission and stores per-prayer switches", async () => {
    const requestPermission = vi.fn().mockResolvedValue("granted");
    vi.stubGlobal("Notification", Object.assign(vi.fn(), { permission: "default", requestPermission }));
    const u = user();
    render(<AdhanSettings locale="ar" />);
    expect(screen.queryByTestId("adhan-fajr")).toBeNull();
    await u.click(screen.getByTestId("adhan-enable"));
    expect(requestPermission).toHaveBeenCalledOnce();
    expect(adhanStore.get().enabled).toBe(true);
    await u.click(screen.getByTestId("adhan-asr"));
    expect(adhanStore.get().prayers).toEqual({ asr: false });
    await u.click(screen.getByTestId("adhan-sound"));
    expect(adhanStore.get().sound).toBe(false);
    expect(screen.getByText(/CC0/)).toBeInTheDocument();
  });

  it("explains when the browser blocks notifications but still enables the in-page alert", async () => {
    vi.stubGlobal(
      "Notification",
      Object.assign(vi.fn(), { permission: "denied", requestPermission: vi.fn() }),
    );
    const u = user();
    render(<AdhanSettings locale="en" />);
    await u.click(screen.getByTestId("adhan-enable"));
    expect(screen.getByTestId("adhan-denied")).toBeInTheDocument();
    expect(adhanStore.get().enabled).toBe(true);
  });
});

describe("AdhanAlerts", () => {
  it("at Dhuhr shows a notification, plays the adhan and can be stopped", async () => {
    const shown: { title: string; body?: string }[] = [];
    const Notif = vi.fn(function (this: unknown, title: string, opts?: NotificationOptions) {
      shown.push({ title, body: opts?.body });
    });
    vi.stubGlobal("Notification", Object.assign(Notif, { permission: "granted" }));
    const play = vi.spyOn(HTMLMediaElement.prototype, "play").mockResolvedValue(undefined);
    const pause = vi.spyOn(HTMLMediaElement.prototype, "pause").mockImplementation(() => {});
    adhanStore.set({ ...DEFAULT_ADHAN, enabled: true });
    const u = user();
    render(<AdhanAlerts locale="en" />);
    expect(screen.queryByTestId("adhan-ringing")).toBeNull();
    await act(async () => {
      vi.setSystemTime(new Date(today.times.dhuhr.getTime() + 2000));
      await vi.advanceTimersByTimeAsync(5000);
    });
    expect(shown).toEqual([{ title: "Time for Dhuhr", body: "It is time for Dhuhr prayer" }]);
    expect(play).toHaveBeenCalledOnce();
    expect(screen.getByTestId("adhan-ringing")).toHaveTextContent("Time for Dhuhr");
    await u.click(screen.getByRole("button", { name: "Stop adhan" }));
    expect(pause).toHaveBeenCalled();
    expect(screen.queryByTestId("adhan-ringing")).toBeNull();
    // Does not ring again for the same prayer.
    await act(async () => {
      await vi.advanceTimersByTimeAsync(20_000);
    });
    expect(play).toHaveBeenCalledOnce();
  });

  it("stays silent when the prayer was missed while the computer slept, and when disabled", async () => {
    vi.stubGlobal("Notification", Object.assign(vi.fn(), { permission: "granted" }));
    const play = vi.spyOn(HTMLMediaElement.prototype, "play").mockResolvedValue(undefined);
    adhanStore.set({ ...DEFAULT_ADHAN, enabled: true });
    render(<AdhanAlerts locale="en" />);
    await act(async () => {
      vi.setSystemTime(new Date(today.times.dhuhr.getTime() + 20 * 60_000));
      await vi.advanceTimersByTimeAsync(5000);
    });
    expect(play).not.toHaveBeenCalled();
    expect(screen.queryByTestId("adhan-ringing")).toBeNull();
  });

  it("offers a play button when the browser blocks autoplay", async () => {
    vi.stubGlobal("Notification", Object.assign(vi.fn(), { permission: "granted" }));
    vi.spyOn(HTMLMediaElement.prototype, "play").mockRejectedValue(new Error("NotAllowedError"));
    adhanStore.set({ ...DEFAULT_ADHAN, enabled: true });
    render(<AdhanAlerts locale="ar" />);
    await act(async () => {
      vi.setSystemTime(new Date(today.times.dhuhr.getTime() + 1000));
      await vi.advanceTimersByTimeAsync(5000);
    });
    expect(screen.getByRole("button", { name: "شغّل الأذان" })).toBeInTheDocument();
  });
});
