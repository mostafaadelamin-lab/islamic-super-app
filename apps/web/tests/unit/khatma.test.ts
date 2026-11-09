import { describe, expect, it } from "vitest";
import { khatmaProgress, markRead, sanitizeKhatma, startKhatma } from "@/lib/khatma";
import { buildQueue } from "@/lib/audio";

describe("khatma", () => {
  it("counts each page once and finds the first unread page", () => {
    let k = startKhatma(1000);
    for (const p of [1, 2, 2, 4, 0, 605, 1.5]) k = markRead(k, p)!;
    expect(k.read).toEqual([1, 2, 4]);
    expect(khatmaProgress(k)).toEqual({ done: 3, left: 601, pct: 0, next: 3 });
  });
  it("is complete only when all 604 pages are read", () => {
    let k = startKhatma(0);
    for (let p = 1; p <= 603; p++) k = markRead(k, p)!;
    expect(khatmaProgress(k)).toMatchObject({ done: 603, pct: 99, next: 604 });
    k = markRead(k, 604)!;
    expect(khatmaProgress(k)).toEqual({ done: 604, left: 0, pct: 100, next: null });
  });
  it("sanitizes stored data", () => {
    expect(sanitizeKhatma(null)).toBeNull();
    expect(sanitizeKhatma({ read: [1] })).toBeNull();
    expect(sanitizeKhatma({ startedAt: 5, read: [3, 3, "x", 700, 1] })).toEqual({
      startedAt: 5,
      read: [1, 3],
    });
    expect(markRead(null, 3)).toBeNull();
  });
});

describe("single-ayah recitation", () => {
  it("plays only the tapped ayah, without a basmala", () => {
    expect(buildQueue({ kind: "ayah", surah: 2, ayah: 1 })).toEqual([{ kind: "ayah", s: 2, a: 1 }]);
    expect(buildQueue({ kind: "ayah", surah: 2, ayah: 999 })).toEqual([]);
  });
});
