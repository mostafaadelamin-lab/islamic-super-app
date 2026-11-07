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
import { DEFAULT_TASBIH, reset, sanitizeTasbih, setTarget, tap, tasbihStore, undo } from "@/lib/tasbih";
import { angleDiff, headingFromEvent, isFacing, needleRotation, needsPermission, norm360 } from "@/lib/qibla";
import { qiblaBearing } from "@/lib/prayer";
import { addRound, isRoundTool, NO_ROUNDS, sanitizeRounds } from "@/lib/rounds";
import { HISN, hisnChapter } from "@/lib/hisn";
import { filterHisn } from "@/lib/hisn-filter";
import { gregorianDate, hijriDate } from "@/lib/dates";

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
    expect(morning.length).toBe(26); // 17 for both + 9 morning-only
    expect(evening.length).toBe(25); // 17 for both + 8 evening-only
    // The last two ayahs of al-Baqarah are read at night ("من قرأ بالآيتين من آخر سورة البقرة في ليلة كفتاه",
    // al-Bukhari and Muslim); the mobile app already lists them in the evening only.
    expect(SESSIONS[2]?.when).toBe("evening");
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
      const src = chapter[row.hisn]!;
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
  beforeEach(() => {
    localStorage.clear();
    tasbihStore.reload();
  });
  it("counts to the target, completes a round and starts again", () => {
    let s = { ...DEFAULT_TASBIH, target: 3 };
    s = tap(s).next;
    s = tap(s).next;
    expect(s.count).toBe(2);
    const r = tap(s);
    expect(r.completed).toBe(true);
    expect(r.next).toMatchObject({ count: 0, rounds: 1 });
  });
  it("undo, reset and target change", () => {
    const s = { ...DEFAULT_TASBIH, count: 5, rounds: 2 };
    expect(undo(s).count).toBe(4);
    expect(undo({ ...s, count: 0 }).count).toBe(0);
    expect(reset(s)).toMatchObject({ count: 0, rounds: 0 });
    expect(setTarget(s, 100)).toMatchObject({ target: 100, count: 0, rounds: 2 });
  });
  it("sanitizes and persists", () => {
    expect(sanitizeTasbih({ count: 50, target: 33, rounds: -1, phrase: "x" })).toEqual({
      count: 33,
      target: 33,
      rounds: 0,
      phrase: "tasbih",
    });
    expect(sanitizeTasbih({ target: 0 })).toMatchObject({ target: 33 });
    tasbihStore.set((p) => tap(p).next);
    tasbihStore.reload();
    expect(tasbihStore.get().count).toBe(1);
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
});
