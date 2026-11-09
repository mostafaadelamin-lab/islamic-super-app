import { act, render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { AdhanAlerts, AdhanSettings, alertSound } from "@/components/AdhanAlerts";
import {
  adhanStore,
  DEFAULT_ADHAN,
  lastThirdStart,
  nextAdhanAlert,
  nextAlert,
  sanitizeAdhan,
} from "@/lib/adhan-alerts";
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
      soundFor: {},
      sunrise: false,
      lastThird: false,
      friday: null,
    });
    const x = sanitizeAdhan({ soundFor: { fajr: "tone", asr: "loud" }, friday: "25:00", sunrise: true });
    expect(x.soundFor).toEqual({ fajr: "tone" });
    expect(x.friday).toBeNull();
    expect(x.sunrise).toBe(true);
    expect(sanitizeAdhan({ friday: "09:30" }).friday).toBe("09:30");
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

describe("extra alerts", () => {
  it("plans sunrise, the last third of the night and the Friday reminder", () => {
    const fajrOnly = { fajr: true, dhuhr: false, asr: false, maghrib: false, isha: false };
    const sunrise = sanitizeAdhan({ enabled: true, prayers: fajrOnly, sunrise: true });
    const beforeSunrise = new Date(today.times.sunrise.getTime() - 60_000);
    expect(nextAlert(beforeSunrise, MAKKAH, sunrise)).toMatchObject({
      kind: "sunrise",
      at: today.times.sunrise,
    });

    const night = sanitizeAdhan({ enabled: true, prayers: fajrOnly, lastThird: true });
    const tomorrow = prayerTimes({ year: 2026, month: 3, day: 2 }, MAKKAH.lat, MAKKAH.lng, "makkah");
    const third = lastThirdStart(today.times.maghrib, tomorrow.times.fajr);
    expect(third.getTime()).toBeGreaterThan(today.times.isha.getTime());
    expect(third.getTime()).toBeLessThan(tomorrow.times.fajr.getTime());
    expect(nextAlert(new Date(today.times.isha.getTime() + 60_000), MAKKAH, night)).toMatchObject({
      kind: "lastThird",
      at: third,
    });

    // 2026-03-06 is a Friday; 10:00 in Makkah is 07:00 UTC.
    const ishaOnly = { fajr: false, dhuhr: false, asr: false, maghrib: false, isha: true };
    const friday = sanitizeAdhan({ enabled: true, prayers: ishaOnly, friday: "10:00" });
    expect(nextAlert(new Date("2026-03-05T22:00:00Z"), MAKKAH, friday)).toMatchObject({
      kind: "friday",
      at: new Date("2026-03-06T07:00:00Z"),
    });
  });

  it("follows each prayer's own sound", () => {
    const p = sanitizeAdhan({ sound: true, soundFor: { fajr: "tone", isha: "silent" } });
    expect(alertSound(p, "adhan", "fajr")).toBe("tone");
    expect(alertSound(p, "adhan", "isha")).toBe("silent");
    expect(alertSound(p, "adhan", "dhuhr")).toBe("adhan");
    expect(alertSound(p, "sunrise", "sunrise")).toBe("tone");
    expect(alertSound({ ...p, sound: false }, "iqama", "dhuhr")).toBe("silent");
  });
});

describe("AdhanSettings", () => {
  it("stores the per-prayer sound and the extra alerts", async () => {
    adhanStore.set({ ...DEFAULT_ADHAN, enabled: true });
    const u = user();
    render(<AdhanSettings locale="en" />);
    await u.selectOptions(screen.getByTestId("sound-fajr"), "tone");
    expect(adhanStore.get().soundFor).toEqual({ fajr: "tone" });
    await u.click(screen.getByTestId("alert-sunrise"));
    await u.click(screen.getByTestId("alert-lastThird"));
    await u.click(screen.getByTestId("alert-friday"));
    expect(adhanStore.get()).toMatchObject({ sunrise: true, lastThird: true, friday: "10:00" });
    expect(screen.getByTestId("alert-friday-time")).toHaveValue("10:00");
    await u.click(screen.getByTestId("alert-friday"));
    expect(adhanStore.get().friday).toBeNull();
  });

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

  it("rings a silent prayer without the recording and announces sunrise", async () => {
    vi.stubGlobal("Notification", Object.assign(vi.fn(), { permission: "granted" }));
    const play = vi.spyOn(HTMLMediaElement.prototype, "play").mockResolvedValue(undefined);
    adhanStore.set({ ...DEFAULT_ADHAN, enabled: true, soundFor: { dhuhr: "silent" } });
    render(<AdhanAlerts locale="en" />);
    await act(async () => {
      vi.setSystemTime(new Date(today.times.dhuhr.getTime() + 1000));
      await vi.advanceTimersByTimeAsync(5000);
    });
    expect(play).not.toHaveBeenCalled();
    expect(screen.getByTestId("adhan-ringing")).toHaveTextContent("Time for Dhuhr");
  });
});
