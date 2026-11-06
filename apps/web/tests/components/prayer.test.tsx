import { act, render, screen, within } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { geoErrorKey, PrayerView } from "@/components/PrayerView";
import { NextPrayerCard } from "@/components/NextPrayerCard";
import { prayerStore } from "@/lib/settings";
import { prayerTimes, qiblaBearing } from "@/lib/prayer";
import { formatHHMM } from "@/lib/time";
import { resetStores } from "./reset";

const NOW = new Date("2026-03-01T06:00:00Z"); // 09:00 in Makkah, before Dhuhr

beforeEach(() => {
  resetStores();
  vi.useFakeTimers({ shouldAdvanceTime: true, now: NOW });
});
afterEach(() => {
  vi.useRealTimers();
  vi.unstubAllGlobals();
});

const user = () => userEvent.setup({ advanceTimers: vi.advanceTimersByTime });

describe("PrayerView", () => {
  it("shows today's six times for the default city (Makkah) and the next prayer", async () => {
    render(<PrayerView locale="en" />);
    const table = await screen.findByTestId("times");
    const rows = within(table).getAllByRole("row").slice(1);
    expect(rows.map((r) => r.getAttribute("data-prayer"))).toEqual([
      "fajr",
      "sunrise",
      "dhuhr",
      "asr",
      "maghrib",
      "isha",
    ]);
    const expected = prayerTimes({ year: 2026, month: 3, day: 1 }, 21.3891, 39.8579, "makkah");
    expect(within(rows[2]!).getByRole("cell")).toHaveTextContent(
      formatHHMM(expected.times.dhuhr, "Asia/Riyadh"),
    );
    expect(screen.getByTestId("next-prayer")).toHaveTextContent("Next prayer: Dhuhr");
    expect(rows[2]).toHaveClass("next");
    expect(screen.getByTestId("countdown").textContent).toMatch(/^\d+:\d\d:\d\d$/);
    expect(screen.getByText("Time zone: Asia/Riyadh")).toBeInTheDocument();
    expect(screen.queryByTestId("highlat-note")).toBeNull();
  });

  it("changes city, method and asr, and persists them", async () => {
    const u = user();
    render(<PrayerView locale="en" />);
    await u.selectOptions(screen.getByLabelText("City"), "c1");
    expect(prayerStore.get().cityId).toBe("c1");
    expect(screen.getByText("Time zone: Africa/Cairo")).toBeInTheDocument();
    expect(
      screen.getByRole("option", { name: /City default — Egyptian General Authority/ }),
    ).toBeInTheDocument();
    await u.selectOptions(screen.getByLabelText("Calculation method"), "isna");
    expect(prayerStore.get().method).toBe("isna");
    await u.selectOptions(screen.getByLabelText("Asr method"), "hanafi");
    expect(prayerStore.get().asr).toBe("hanafi");
    await u.selectOptions(screen.getByLabelText("Calculation method"), "");
    expect(prayerStore.get().method).toBeNull();
  });

  it("manual adjustments: buttons, input, limits and reset", async () => {
    const u = user();
    render(<PrayerView locale="en" />);
    await screen.findByTestId("times");
    const before = within(screen.getByTestId("times")).getAllByRole("row")[1]!.textContent;
    await u.click(screen.getByRole("button", { name: "Increase Fajr by one minute" }));
    expect(prayerStore.get().adjustments.fajr).toBe(1);
    expect(within(screen.getByTestId("times")).getAllByRole("row")[1]!.textContent).not.toBe(before);
    await u.click(screen.getByRole("button", { name: "Decrease Isha by one minute" }));
    expect(prayerStore.get().adjustments.isha).toBe(-1);
    const input = screen.getByLabelText("Asr") as HTMLInputElement;
    await u.clear(input);
    await u.type(input, "45");
    expect(prayerStore.get().adjustments.asr).toBe(30);
    expect(screen.getByRole("button", { name: "Increase Asr by one minute" })).toBeDisabled();
    await u.click(screen.getByRole("button", { name: "Reset adjustments" }));
    expect(prayerStore.get().adjustments).toEqual({});
  });

  it("shows the qibla bearing and compass", async () => {
    render(<PrayerView locale="ar" />);
    const deg = qiblaBearing(21.3891, 39.8579)
      .toFixed(1)
      .replace(/\d/g, (d) => "٠١٢٣٤٥٦٧٨٩"[Number(d)]!);
    expect(screen.getByTestId("qibla-bearing")).toHaveTextContent(deg);
    expect(screen.getByRole("img", { name: new RegExp(deg.replace(".", "\\.")) })).toBeInTheDocument();
  });

  it("shows the high-latitude note for London in midsummer", async () => {
    vi.setSystemTime(new Date("2026-06-21T10:00:00Z"));
    const u = user();
    render(<PrayerView locale="en" />);
    await u.selectOptions(screen.getByLabelText("City"), "c54");
    expect(await screen.findByTestId("highlat-note")).toHaveTextContent(
      "High-latitude rule applied to: Fajr, Isha",
    );
  });

  it("use my location: success", async () => {
    const getCurrentPosition = vi.fn((ok: PositionCallback) =>
      ok({ coords: { latitude: 51.50735, longitude: -0.12776 } } as GeolocationPosition),
    );
    vi.stubGlobal("navigator", { ...navigator, geolocation: { getCurrentPosition } });
    const u = user();
    render(<PrayerView locale="en" />);
    await u.click(screen.getByRole("button", { name: "Use my location" }));
    expect(prayerStore.get().custom).toMatchObject({ lat: 51.5074, lng: -0.1278 });
    expect(screen.getByRole("option", { name: "My location (51.51, -0.13)" })).toBeInTheDocument();
    expect((screen.getByLabelText("City") as HTMLSelectElement).value).toBe("__custom");
    await u.selectOptions(screen.getByLabelText("City"), "__custom");
    expect(prayerStore.get().custom).not.toBeNull();
    await u.selectOptions(screen.getByLabelText("City"), "c1");
    expect(prayerStore.get().custom).toBeNull();
  });

  it("use my location: permission denied is reported", async () => {
    const getCurrentPosition = vi.fn((_ok: PositionCallback, err: PositionErrorCallback) =>
      err({ code: 1, message: "denied" } as GeolocationPositionError),
    );
    vi.stubGlobal("navigator", { ...navigator, geolocation: { getCurrentPosition } });
    const u = user();
    render(<PrayerView locale="en" />);
    await u.click(screen.getByRole("button", { name: "Use my location" }));
    expect(screen.getByTestId("geo-error")).toHaveTextContent("Location permission was denied");
    expect(prayerStore.get().custom).toBeNull();
  });

  it("use my location: no geolocation API", async () => {
    vi.stubGlobal("navigator", { ...navigator, geolocation: undefined });
    const u = user();
    render(<PrayerView locale="en" />);
    await u.click(screen.getByRole("button", { name: "Use my location" }));
    expect(screen.getByTestId("geo-error")).toHaveTextContent("unavailable");
  });

  it("geoErrorKey", () => {
    expect(geoErrorKey(1)).toBe("prayer.geoDenied");
    expect(geoErrorKey(2)).toBe("prayer.geoUnavailable");
    expect(geoErrorKey(3)).toBe("prayer.geoTimeout");
    expect(geoErrorKey(undefined)).toBe("prayer.geoUnavailable");
  });

  it("shows an error for a polar location", async () => {
    vi.setSystemTime(new Date("2026-12-21T10:00:00Z"));
    act(() =>
      prayerStore.set((p) => ({ ...p, custom: { lat: 78.22, lng: 15.65, tz: "Arctic/Longyearbyen" } })),
    );
    render(<PrayerView locale="en" />);
    expect(await screen.findByRole("alert")).toHaveTextContent("Cannot compute prayer times");
  });

  it("countdown ticks every second", async () => {
    render(<PrayerView locale="en" />);
    const first = (await screen.findByTestId("countdown")).textContent;
    await act(async () => {
      vi.advanceTimersByTime(2000);
    });
    expect(screen.getByTestId("countdown").textContent).not.toBe(first);
  });
});

describe("NextPrayerCard", () => {
  it("shows next prayer and countdown in Arabic digits", async () => {
    render(<NextPrayerCard locale="ar" />);
    expect(await screen.findByTestId("home-countdown")).toHaveTextContent(/^[٠-٩]+:[٠-٩]{2}:[٠-٩]{2}$/);
    expect(screen.getByText(/الظهر/)).toBeInTheDocument();
    expect(screen.getByText("مكة المكرمة")).toBeInTheDocument();
    expect(screen.getByRole("link", { name: "كل مواقيت الصلاة" })).toHaveAttribute("href", "/ar/prayer/");
  });
  it("shows an error for impossible locations", async () => {
    vi.setSystemTime(new Date("2026-12-21T10:00:00Z"));
    act(() =>
      prayerStore.set((p) => ({ ...p, custom: { lat: 78.22, lng: 15.65, tz: "Arctic/Longyearbyen" } })),
    );
    render(<NextPrayerCard locale="en" />);
    expect(await screen.findByText(/Cannot compute prayer times/)).toBeInTheDocument();
  });
});
