/**
 * Khatma (reading the whole Mushaf): which of the 604 pages were read since the khatma started.
 * A page counts as read once it has stayed open for KHATMA_DWELL_MS in the Mushaf reader.
 */
import { createStore } from "./store";
import { PAGE_COUNT } from "./pages";

export interface Khatma {
  startedAt: number;
  /** Pages read, ascending, each 1..604 once. */
  read: number[];
}

export const KHATMA_DWELL_MS = 4000;

export function sanitizeKhatma(raw: unknown): Khatma | null {
  if (typeof raw !== "object" || raw === null) return null;
  const r = raw as Record<string, unknown>;
  if (typeof r.startedAt !== "number" || !Number.isFinite(r.startedAt)) return null;
  const pages = Array.isArray(r.read) ? r.read : [];
  const read = [
    ...new Set(pages.filter((p): p is number => Number.isInteger(p) && p >= 1 && p <= PAGE_COUNT)),
  ];
  read.sort((a, b) => a - b);
  return { startedAt: r.startedAt, read };
}

export function startKhatma(now: number): Khatma {
  return { startedAt: now, read: [] };
}

export function markRead(k: Khatma | null, page: number): Khatma | null {
  if (!k || !Number.isInteger(page) || page < 1 || page > PAGE_COUNT || k.read.includes(page)) return k;
  return { ...k, read: [...k.read, page].sort((a, b) => a - b) };
}

export interface KhatmaProgress {
  done: number;
  left: number;
  /** Whole percent, 0..100 (100 only when every page is read). */
  pct: number;
  /** First page not read yet (null when complete). */
  next: number | null;
}

export function khatmaProgress(k: Khatma): KhatmaProgress {
  const done = k.read.length;
  const left = PAGE_COUNT - done;
  const pct = left === 0 ? 100 : Math.min(99, Math.floor((done * 100) / PAGE_COUNT));
  let next: number | null = null;
  for (let p = 1, i = 0; p <= PAGE_COUNT; p++) {
    if (k.read[i] === p) i++;
    else {
      next = p;
      break;
    }
  }
  return { done, left, pct, next };
}

export const khatmaStore = createStore<Khatma | null>("rattil.pageKhatma", null, sanitizeKhatma);
