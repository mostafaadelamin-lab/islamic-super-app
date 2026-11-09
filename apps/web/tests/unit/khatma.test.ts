import {
  addDaysIso,
  completeWird,
  DEFAULT_KHATMA_STATE,
  MUSHAF_PAGES,
  planByDays,
  planByPages,
  progress,
  reschedule,
  sanitizeKhatma,
  wirdPages,
} from "@/lib/khatma";

describe("khatma planning", () => {
  it("splits the 604 pages into contiguous whole-page wirds", () => {
    for (const days of [1, 7, 29, 30, 60, 365]) {
      const k = planByDays("x", "2026-11-09", days);
      expect(k.wirds).toBe(Math.min(days, 365));
      let next = 1;
      for (let i = 0; i < k.wirds; i++) {
        const { from, to } = wirdPages(k, i);
        expect(from).toBe(next);
        expect(to).toBeGreaterThanOrEqual(from);
        next = to + 1;
      }
      expect(next).toBe(MUSHAF_PAGES + 1);
    }
    expect(wirdPages(planByDays("x", "2026-11-09", 30), 0)).toEqual({ from: 1, to: 20 });
  });

  it("pages per day gives ceil(604 / p) wirds of at most p pages", () => {
    const k = planByPages("x", "2026-11-09", 20);
    expect(k.wirds).toBe(31);
    for (let i = 0; i < k.wirds; i++) {
      const { from, to } = wirdPages(k, i);
      expect(to - from + 1).toBeLessThanOrEqual(20);
    }
  });

  it("progress: percent, remaining, behind/ahead and end date", () => {
    const k = { ...planByDays("x", "2026-11-01", 30), done: 3 };
    const p = progress(k, "2026-11-09"); // 9th day: 8 past days due, 3 read
    expect(p.endDate).toBe("2026-11-30");
    expect(p.remainingWirds).toBe(27);
    expect(p.remainingDays).toBe(22);
    expect(p.behind).toBe(5);
    expect(p.ahead).toBe(0);
    expect(p.fraction).toBeCloseTo(wirdPages(k, 2).to / 604);
    const ahead = progress({ ...k, done: 12 }, "2026-11-09");
    expect(ahead.behind).toBe(0);
    expect(ahead.ahead).toBe(3);
    expect(progress(k, "2027-01-01").remainingDays).toBe(0);
  });

  it("reschedule spreads the unread pages over the days left", () => {
    const k = { ...planByDays("x", "2026-11-01", 30), done: 3 };
    const r = reschedule(k, "2026-11-09");
    expect(r.startDate).toBe("2026-11-09");
    expect(r.startPage).toBe(wirdPages(k, 3).from);
    expect(r.wirds).toBe(22);
    expect(r.done).toBe(0);
    expect(progress(r, "2026-11-09").behind).toBe(0);
    expect(addDaysIso(r.startDate, r.wirds - 1)).toBe("2026-11-30");
    // Past the end date: the rest in one day.
    expect(reschedule(k, "2026-12-15").wirds).toBe(1);
  });

  it("completing the last wird moves the khatma to the history", () => {
    let s = { ...DEFAULT_KHATMA_STATE, current: planByDays("Ramadan", "2026-11-01", 2) };
    s = completeWird(s, "2026-11-01");
    expect(s.current?.done).toBe(1);
    s = completeWird(s, "2026-11-03");
    expect(s.current).toBeNull();
    expect(s.history).toEqual([
      { name: "Ramadan", startDate: "2026-11-01", finishedDate: "2026-11-03", days: 3 },
    ]);
  });

  it("sanitises stored state", () => {
    expect(sanitizeKhatma(null)).toEqual(DEFAULT_KHATMA_STATE);
    expect(sanitizeKhatma({ current: { startDate: "x", wirds: 3 } }).current).toBeNull();
    const ok = sanitizeKhatma({
      current: { ...planByDays("a", "2026-11-01", 10), done: 4, reminder: "05:30" },
    });
    expect(ok.current).toMatchObject({ done: 4, reminder: "05:30" });
    expect(
      sanitizeKhatma({ current: { ...planByDays("a", "2026-11-01", 10), done: 11 } }).current,
    ).toBeNull();
  });
});
