import {
  DEFAULT_WORSHIP,
  MAX_NOTE,
  monthStats,
  sanitizeWorship,
  setFasting,
  setNote,
  streak,
  togglePrayer,
  weekStats,
  type WorshipState,
} from "@/lib/worship";

const ALL = ["fajr", "dhuhr", "asr", "maghrib", "isha"];
const full = (s: WorshipState, day: string): WorshipState => ALL.reduce((a, k) => togglePrayer(a, day, k), s);
const TODAY = { year: 2026, month: 11, day: 9 };

describe("worship tracker", () => {
  it("toggles prayers, fasting and a note; an empty day is dropped", () => {
    let s = togglePrayer(DEFAULT_WORSHIP, "2026-11-09", "fajr");
    expect(s.days["2026-11-09"]?.prayers).toEqual({ fajr: true });
    s = togglePrayer(s, "2026-11-09", "fajr");
    expect(s.days).toEqual({});
    s = setFasting(s, "2026-11-08", true);
    s = setNote(s, "2026-11-08", "x".repeat(300));
    expect(s.days["2026-11-08"]).toEqual({ prayers: {}, fasting: true, note: "x".repeat(MAX_NOTE) });
    expect(setNote(setFasting(s, "2026-11-08", false), "2026-11-08", " ").days).toEqual({});
  });

  it("weekly and monthly totals", () => {
    let s = full(DEFAULT_WORSHIP, "2026-11-09");
    s = togglePrayer(s, "2026-11-03", "asr");
    s = setFasting(s, "2026-11-02", true);
    s = full(s, "2026-10-31");
    expect(weekStats(s, TODAY)).toEqual({ days: 7, prayed: 6, possible: 35, fullDays: 1, fasted: 0 });
    expect(monthStats(s, 2026, 11, TODAY)).toEqual({
      days: 9,
      prayed: 6,
      possible: 45,
      fullDays: 1,
      fasted: 1,
    });
    expect(monthStats(s, 2026, 10, TODAY)).toMatchObject({ days: 31, prayed: 5, fullDays: 1 });
  });

  it("streak counts full days back from today, or from yesterday while today is incomplete", () => {
    let s = full(full(full(DEFAULT_WORSHIP, "2026-11-06"), "2026-11-07"), "2026-11-08");
    expect(streak(s, TODAY)).toBe(3);
    s = full(s, "2026-11-09");
    expect(streak(s, TODAY)).toBe(4);
    s = togglePrayer(s, "2026-11-07", "isha");
    expect(streak(s, TODAY)).toBe(2);
    expect(streak(DEFAULT_WORSHIP, TODAY)).toBe(0);
  });

  it("sanitizes stored data", () => {
    expect(
      sanitizeWorship({
        days: {
          "2026-11-09": { prayers: { fajr: true, sunrise: true, dhuhr: "yes" }, fasting: 1, note: 5 },
          "2026-11-08": { prayers: {}, fasting: false, note: "" },
          bad: { fasting: true },
        },
      }),
    ).toEqual({ days: { "2026-11-09": { prayers: { fajr: true }, fasting: false, note: "" } } });
    expect(sanitizeWorship(null)).toEqual({ days: {} });
  });
});
