/**
 * «أذكاري» (owner 2026-11-26): adhkar the visitor adds to the morning / evening list — their own text, how many
 * times, and in which session(s). Kept in this browser only, never sent anywhere. Same as the app.
 */
import type { Dhikr, Session } from "./adhkar";
import { createStore } from "./store";

/** Ids of user-added adhkar start here, so their counters never share a key with adhkar.v1.json items. */
export const USER_DHIKR_BASE = 100000;
export const USER_DHIKR_MAX_COUNT = 1000;
export const USER_DHIKR_MAX_LENGTH = 2000;
export const QUICK_COUNTS: readonly number[] = [1, 3, 7, 10, 33, 100];

export interface UserDhikr {
  id: number;
  text: string;
  count: number;
  sessions: Session[];
}

const clampCount = (n: number): number => Math.min(USER_DHIKR_MAX_COUNT, Math.max(1, Math.floor(n)));

export function sanitizeUserAdhkar(raw: unknown): UserDhikr[] {
  if (!Array.isArray(raw)) return [];
  const out: UserDhikr[] = [];
  for (const x of raw) {
    if (typeof x !== "object" || x === null) continue;
    const r = x as Record<string, unknown>;
    const text = typeof r.text === "string" ? r.text.trim().slice(0, USER_DHIKR_MAX_LENGTH) : "";
    const sessions = Array.isArray(r.sessions)
      ? (["morning", "evening"] as const).filter((s) => (r.sessions as unknown[]).includes(s))
      : [];
    if (typeof r.id !== "number" || r.id < 1 || !text || sessions.length === 0) continue;
    if (out.some((d) => d.id === Math.floor(r.id as number))) continue;
    out.push({
      id: Math.floor(r.id),
      text,
      count: clampCount(typeof r.count === "number" ? r.count : 1),
      sessions: [...sessions],
    });
  }
  return out;
}

export const userAdhkarStore = createStore<UserDhikr[]>("rattil.adhkar.custom", [], sanitizeUserAdhkar);

/** The visitor's adhkar for [session], as list items after the book's ones. */
export function userItems(list: readonly UserDhikr[], session: Session): Dhikr[] {
  return list
    .filter((d) => d.sessions.includes(session))
    .map((d) => ({ id: USER_DHIKR_BASE + d.id, text: d.text, count: d.count, custom: true }));
}

/** Adds a new dhikr ([id] undefined) or replaces the one with [id]. Empty text or no session: unchanged. */
export function saveUserDhikr(
  list: readonly UserDhikr[],
  d: { id?: number; text: string; count: number; sessions: readonly Session[] },
): UserDhikr[] {
  const text = d.text.trim().slice(0, USER_DHIKR_MAX_LENGTH);
  if (!text || d.sessions.length === 0) return [...list];
  const id = d.id ?? list.reduce((m, x) => Math.max(m, x.id), 0) + 1;
  const next: UserDhikr = { id, text, count: clampCount(d.count), sessions: [...d.sessions] };
  return list.some((x) => x.id === id) ? list.map((x) => (x.id === id ? next : x)) : [...list, next];
}

export function deleteUserDhikr(list: readonly UserDhikr[], id: number): UserDhikr[] {
  return list.filter((x) => x.id !== id);
}
