import { readRepoJson } from "../repo";
import {
  adhkarStore,
  countOne,
  defaultSession,
  progressFor,
  resetSession,
  sanitizeProgress,
  SESSIONS,
  sessionItems,
  sessionSummary,
} from "@/lib/adhkar";
import {
  addCustom,
  clearHistory,
  current,
  DEFAULT_TASBIH,
  historyRows,
  MAX_CUSTOM_TEXT,
  NEW_COUNTER,
  removeCustom,
  reset,
  sanitizeTasbih,
  setTarget,
  tap,
  tasbihStore,
  undo,
} from "@/lib/tasbih";
import { angleDiff, headingFromEvent, isFacing, needleRotation, needsPermission, norm360 } from "@/lib/qibla";
import { qiblaBearing } from "@/lib/prayer";
import { addRound, isRoundTool, NO_ROUNDS, sanitizeRounds } from "@/lib/rounds";
import { HISN, hisnChapter } from "@/lib/hisn";
import { filterHisn } from "@/lib/hisn-filter";
import { gregorianDate, hijriDate } from "@/lib/dates";
import { clampHijriOffset, sanitizePrefs } from "@/lib/settings";

const adhkar = readRepoJson<{ items: string[] }>("content/adhkar/dist/adhkar.v1.json").items;
const hisn = readRepoJson<[string, string[]][]>("content/adhkar/hisn.json");
const strip = (s: string): string => s.replace(/[ً-ْٰـ]/g, "");

describe("adhkar sessions", () => {
  it("covers every dataset item exactly once", () => {
    expect(adhkar).toHaveLength(34);
    expect(SESSIONS).toHaveLength(adhkar.length);
  });
  it("morning wording only in the morning, evening wording only in the evening", () => {
    adhkar.forEach((text, i) => {
      const when = SESSIONS[i]!.when;
      const plain = strip(text);
      if (/^(أصبحنا|اللهم إني أصبحت|اللهم ما أصبح)/.test(plain)) expect(when).toBe("morning");
      if (/^(أمسينا|اللهم إني أمسيت|اللهم ما أمسى)/.test(plain)) expect(when).toBe("evening");
    });
    const morning = sessionItems(adhkar, "morning");
    const evening = sessionItems(adhkar, "evening");
    expect(morning.map((d) => d.id)).not.toContain(7);
    expect(evening.map((d) => d.id)).toContain(7);
    // End of al-Baqarah (item 2) is evening-only: "whoever recites the last two verses of al-Baqarah at night,
    // they suffice him" (al-Bukhari, Muslim); same as on mobile.
    expect(SESSIONS[2]!.when).toBe("evening");
    expect(morning.map((d) => d.id)).not.toContain(2);
    expect(morning.length).toBe(26); // 17 for both + 9 morning-only
    expect(evening.length).toBe(25); // 17 for both + 8 evening-only
  });
  it("repetition counts are the ones annotated in Hisn al-Muslim (chapter أذكار الصباح والمساء)", () => {
    const chapter = hisn.find(([t]) => t === "أذكار الصباح والمساء")![1];
    const ANNOTATION: Record<number, RegExp> = {
      3: /ثلاث مرات/,
      4: /أربع مرات/,
      7: /سبع مرات/,
      10: /عشر مرات/,
      100: /مائة مرة/,
    };
    SESSIONS.forEach((row) => {
      if (row.hisn === null) return expect(row.count).toBe(1);
      const src = chapter[row.hisn]!.replace(/[\u064B-\u0652\u0670\u0640]/g, ""); // annotations are vowelled since v1.0.10
      if (row.count === 1) expect(Object.values(ANNOTATION).some((re) => re.test(src))).toBe(false);
      else expect(src).toMatch(ANNOTATION[row.count]!);
    });
    expect(sessionItems(adhkar, "morning").find((d) => d.id === 16)?.count).toBe(7); // حسبي الله
  });
  it("counter: counts up to the item's count, then stops; resets on a new day", () => {
    const d = sessionItems(adhkar, "morning").find((x) => x.count === 3)!;
    let p = progressFor(adhkarStore.defaultValue, "2026-11-07");
    for (let i = 0; i < 5; i++) p = countOne(p, "2026-11-07", "morning", d);
    expect(p.done[`morning:${d.id}`]).toBe(3);
    expect(sessionSummary(p, "2026-11-07", "morning", [d])).toEqual({ completed: 1, total: 1 });
    expect(sessionSummary(p, "2026-11-08", "morning", [d])).toEqual({ completed: 0, total: 1 });
    expect(countOne(p, "2026-11-08", "morning", d).done).toEqual({ [`morning:${d.id}`]: 1 });
    const both = countOne(p, "2026-11-07", "evening", d);
    expect(resetSession(both, "2026-11-07", "morning").done).toEqual({ [`evening:${d.id}`]: 1 });
  });
  it("sanitizes stored progress and picks a default session", () => {
    expect(sanitizeProgress(null)).toEqual({ date: "", done: {} });
    expect(
      sanitizeProgress({
        date: "2026-01-01",
        done: { "morning:3": 2, "noon:1": 1, "evening:x": 2, "evening:4": -1 },
      }),
    ).toEqual({
      date: "2026-01-01",
      done: { "morning:3": 2 },
    });
    expect(defaultSession(7)).toBe("morning");
    expect(defaultSession(16)).toBe("evening");
    expect(defaultSession(1)).toBe("evening");
  });
});

describe("tasbih", () => {
  const D1 = "2026-11-09";
  const D2 = "2026-11-10";
  beforeEach(() => {
    localStorage.clear();
    tasbihStore.reload();
  });
  it("counts to the target, completes a round and starts again", () => {
    let s = setTarget(DEFAULT_TASBIH, 3);
    s = tap(s, D1).next;
    s = tap(s, D1).next;
    expect(current(s).count).toBe(2);
    const r = tap(s, D1);
    expect(r.completed).toBe(true);
    expect(current(r.next)).toMatchObject({ count: 0, rounds: 1, target: 3 });
    expect(r.next.history).toEqual({ [D1]: { tasbih: 3 } });
  });
  it("keeps a separate counter per dhikr", () => {
    let s = tap(DEFAULT_TASBIH, D1).next;
    s = { ...s, phrase: "takbir" };
    expect(current(s)).toEqual(NEW_COUNTER);
    s = tap(setTarget(s, 100), D2).next;
    expect(s.counters).toEqual({
      tasbih: { count: 1, target: 33, rounds: 0 },
      takbir: { count: 1, target: 100, rounds: 0 },
    });
    expect(historyRows(s)).toEqual([
      { day: D2, phrase: "takbir", count: 1 },
      { day: D1, phrase: "tasbih", count: 1 },
    ]);
  });
  it("undo, reset and target change", () => {
    let s = tap(tap(DEFAULT_TASBIH, D1).next, D1).next;
    s = undo(s, D1);
    expect(current(s).count).toBe(1);
    expect(s.history[D1]).toEqual({ tasbih: 1 });
    s = undo(s, D1);
    expect(undo(s, D1)).toBe(s);
    expect(s.history).toEqual({});
    s = { ...s, counters: { tasbih: { count: 5, target: 33, rounds: 2 } } };
    expect(current(reset(s))).toMatchObject({ count: 0, rounds: 0 });
    expect(current(setTarget(s, 100))).toEqual({ target: 100, count: 0, rounds: 2 });
  });
  it("adds and removes the user's own adhkar", () => {
    let s = addCustom(DEFAULT_TASBIH, "  اللهم صل على محمد  ");
    expect(s.custom).toEqual([{ id: "c1", text: "اللهم صل على محمد" }]);
    expect(s.phrase).toBe("c1");
    s = tap(s, D1).next;
    expect(addCustom(s, "   ")).toBe(s);
    s = addCustom(s, "x".repeat(200));
    expect(s.custom[1]).toEqual({ id: "c2", text: "x".repeat(MAX_CUSTOM_TEXT) });
    s = removeCustom({ ...s, phrase: "c1" }, "c1");
    expect(s.phrase).toBe("tasbih");
    expect(s.custom.map((c) => c.id)).toEqual(["c2"]);
    expect(s.counters.c1).toBeUndefined();
    expect(s.history).toEqual({});
  });
  it("keeps 60 days of history and can clear it", () => {
    let s = tap(DEFAULT_TASBIH, "2026-01-01").next;
    s = tap(s, "2026-03-15").next;
    expect(Object.keys(s.history)).toEqual(["2026-03-15"]);
    expect(clearHistory(s).history).toEqual({});
  });
  it("sanitizes, migrates the old single counter and persists", () => {
    expect(sanitizeTasbih({ count: 50, target: 33, rounds: -1, phrase: "takbir" })).toMatchObject({
      phrase: "takbir",
      counters: { takbir: { count: 0, target: 33, rounds: 0 } },
    });
    expect(sanitizeTasbih({ count: 5, target: 99, rounds: 2 }).counters).toEqual({
      tasbih: { count: 5, target: 99, rounds: 2 },
    });
    const x = sanitizeTasbih({
      phrase: "c9",
      custom: [
        { id: "c9", text: "ذكر" },
        { id: "bad", text: "y" },
        { id: "c3", text: " " },
      ],
      counters: { c9: { count: 1, target: 0 }, nope: { count: 1 } },
      mode: "beads",
      color: "plum",
      sound: true,
      vibrate: false,
      history: { "2026-11-09": { c9: 4, tasbih: -1, zz: 2 }, junk: { c9: 1 } },
    });
    expect(x).toEqual({
      phrase: "c9",
      custom: [{ id: "c9", text: "ذكر" }],
      counters: { c9: { count: 1, target: 33, rounds: 0 } },
      mode: "beads",
      color: "plum",
      sound: true,
      vibrate: false,
      history: { "2026-11-09": { c9: 4 } },
    });
    expect(sanitizeTasbih({ mode: "x", color: "neon" })).toMatchObject({ mode: "button", color: "brown" });
    tasbihStore.set((p) => tap(p, D1).next);
    tasbihStore.reload();
    expect(current(tasbihStore.get()).count).toBe(1);
  });
});

describe("qibla compass math", () => {
  it("normalises angles and differences", () => {
    expect(norm360(-10)).toBe(350);
    expect(norm360(725)).toBe(5);
    expect(angleDiff(10, 350)).toBe(20);
    expect(angleDiff(350, 10)).toBe(-20);
    expect(angleDiff(180, 0)).toBe(180);
  });
  it("heading from iOS webkitCompassHeading and from absolute alpha", () => {
    expect(headingFromEvent({ alpha: 10, webkitCompassHeading: 90 })).toBe(90);
    expect(headingFromEvent({ alpha: 90, absolute: true })).toBe(270);
    expect(headingFromEvent({ alpha: 0, absolute: true })).toBe(0);
    expect(headingFromEvent({ alpha: 90, absolute: true }, 90)).toBe(0);
    expect(headingFromEvent({ alpha: 90, absolute: false })).toBeNull(); // relative orientation: no north
    expect(headingFromEvent({ alpha: null, absolute: true })).toBeNull();
  });
  it("needle rotation and facing", () => {
    const cairo = qiblaBearing(30.0444, 31.2357); // ~136°
    expect(needleRotation(cairo, null)).toBeCloseTo(cairo);
    expect(needleRotation(cairo, cairo)).toBe(0);
    expect(needleRotation(10, 350)).toBe(20);
    expect(isFacing(cairo, cairo + 4)).toBe(true);
    expect(isFacing(cairo, cairo + 6)).toBe(false);
    expect(isFacing(cairo, null)).toBe(false);
    expect(isFacing(2, 358)).toBe(true);
  });
  it("detects the iOS permission API", () => {
    expect(needsPermission(Object.assign(() => undefined, { requestPermission: () => undefined }))).toBe(
      true,
    );
    expect(needsPermission(() => undefined)).toBe(false);
    expect(needsPermission(undefined)).toBe(false);
  });
});

describe("hajj round counters", () => {
  it("counts 0..7 per tool", () => {
    let r = NO_ROUNDS;
    for (let i = 0; i < 9; i++) r = addRound(r, "tawaf", 1);
    expect(r.tawaf).toBe(7);
    expect(addRound(NO_ROUNDS, "sai", -1).sai).toBe(0);
    expect(sanitizeRounds({ tawaf: 9, sai: "x", jamarat: 2 })).toEqual({ tawaf: 7, sai: 0, jamarat: 2 });
    expect(isRoundTool("sai")).toBe(true);
    expect(isRoundTool("x")).toBe(false);
  });
});

describe("Hisn al-Muslim", () => {
  it("keeps the source chapters and items in order", () => {
    expect(HISN).toHaveLength(hisn.length);
    expect(hisnChapter(1)!.title).toBe(hisn[0]![0]);
    expect(hisnChapter(29)!.items).toEqual(hisn[28]![1]);
    expect(hisnChapter(0)).toBeUndefined();
  });
  it("filters chapter titles ignoring diacritics", () => {
    const r = filterHisn("الوضوء", HISN);
    expect(r.length).toBeGreaterThanOrEqual(2);
    expect(r.every((c) => c.title.includes("الوضوء"))).toBe(true);
    expect(filterHisn("  ", HISN)).toHaveLength(HISN.length);
  });
});

describe("dates", () => {
  const d = new Date("2026-11-07T12:00:00Z");
  it("formats Hijri (Umm al-Qura) and Gregorian dates", () => {
    expect(hijriDate(d, "Asia/Riyadh", "en")).toMatch(/1448/);
    expect(hijriDate(d, "Asia/Riyadh", "ar")).toMatch(/١٤٤٨/);
    expect(gregorianDate(d, "Africa/Cairo", "en")).toContain("2026");
    expect(gregorianDate(d, "Africa/Cairo", "ar")).toContain("٢٠٢٦");
  });
  it("Hijri date: Umm al-Qura plus the user's manual offset (-2..+2 days)", () => {
    const d = new Date("2026-02-18T12:00:00Z"); // 1 Ramadan 1447 by Umm al-Qura
    expect(hijriDate(d, "Asia/Riyadh", "en", 0)).toBe("Ramadan 1, 1447 AH");
    expect(hijriDate(d, "Asia/Riyadh", "en", -1)).toBe("Shaʻban 29, 1447 AH");
    expect(hijriDate(d, "Asia/Riyadh", "en", 1)).toBe("Ramadan 2, 1447 AH");
    expect(clampHijriOffset(5)).toBe(2);
    expect(clampHijriOffset(-9)).toBe(-2);
    expect(clampHijriOffset("x")).toBe(0);
    expect(sanitizePrefs({ hijriOffset: 1 }).hijriOffset).toBe(1);
    expect(sanitizePrefs({}).hijriOffset).toBe(0);
  });
});
