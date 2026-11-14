/**
 * Tasbih (dhikr) counter. Each dhikr (the built-in ones and the user's own) keeps its own count, target and
 * rounds; taps are also added to a per-day history. Everything stays on this device.
 */
import { createStore } from "./store";

const [T33, T99, T100, T1000] = [33, 99, 100, 1000] as const;
export const TASBIH_TARGETS: readonly number[] = [T33, T99, T100, T1000];
export const TASBIH_PHRASES: readonly string[] = ["tasbih", "tahmid", "takbir", "tahlil", "istighfar"];
export type TasbihMode = "button" | "beads";
export const TASBIH_MODES: readonly TasbihMode[] = ["button", "beads"];
/** Bead colours (same values in the mobile app); the first is the Mushaf brown (default since 2026-11-14). */
export const TASBIH_COLORS: Readonly<Record<string, string>> = {
  brown: "#8A5A2B",
  emerald: "#0F5C4A",
  gold: "#A77B22",
  teal: "#1F7A7A",
  sky: "#2C6E9E",
  indigo: "#4B4F9E",
  plum: "#7A3E73",
  rose: "#A8455A",
  amber: "#B5651D",
  slate: "#4A5A63",
};
export const MAX_CUSTOM = 20;
export const MAX_CUSTOM_TEXT = 80;
/** Days of history kept. */
export const HISTORY_DAYS = 60;
const MAX_COUNT = 1_000_000;
const DEFAULT_TARGET = T33;
/** A calendar day: matches "2026-11-09", rejects "2026-11-9". */
const ISO_DATE_RE = /^\d{4}-\d\d-\d\d$/;
/** A custom dhikr id: matches "c12", rejects "tasbih" and "c". */
const CUSTOM_ID_RE = /^c\d{1,6}$/;
const ISO_DATE_LEN = 10;
const DAY_MS = 86_400_000;

export interface TasbihCounter {
  count: number;
  target: number;
  /** Completed rounds of `target`. */
  rounds: number;
}
export interface CustomDhikr {
  id: string;
  text: string;
}
export interface TasbihState {
  /** Selected dhikr: a built-in key or a custom id ("c1"). */
  phrase: string;
  counters: Record<string, TasbihCounter>;
  custom: CustomDhikr[];
  mode: TasbihMode;
  color: string;
  sound: boolean;
  vibrate: boolean;
  /** Taps per day ("YYYY-MM-DD") and dhikr. */
  history: Record<string, Record<string, number>>;
}

export const NEW_COUNTER: TasbihCounter = { count: 0, target: DEFAULT_TARGET, rounds: 0 };
export const DEFAULT_TASBIH: TasbihState = {
  phrase: "tasbih",
  counters: {},
  custom: [],
  mode: "button",
  color: "brown",
  sound: false,
  vibrate: true,
  history: {},
};

const isObj = (v: unknown): v is Record<string, unknown> => typeof v === "object" && v !== null;
const isCount = (v: unknown): v is number => typeof v === "number" && Number.isInteger(v) && v >= 0;

function sanitizeCounter(raw: unknown): TasbihCounter {
  const r = isObj(raw) ? raw : {};
  const target = isCount(r.target) && r.target >= 1 && r.target <= MAX_COUNT ? r.target : DEFAULT_TARGET;
  return {
    target,
    count: isCount(r.count) && r.count < target ? r.count : 0,
    rounds: isCount(r.rounds) ? Math.min(r.rounds, MAX_COUNT) : 0,
  };
}

export function sanitizeTasbih(raw: unknown): TasbihState {
  const r = isObj(raw) ? raw : {};
  const custom: CustomDhikr[] = (Array.isArray(r.custom) ? r.custom : [])
    .filter(
      (c): c is { id: string; text: string } =>
        isObj(c) && typeof c.id === "string" && typeof c.text === "string",
    )
    .filter((c) => CUSTOM_ID_RE.test(c.id) && c.text.trim() !== "")
    .slice(0, MAX_CUSTOM)
    .map((c) => ({ id: c.id, text: c.text.trim().slice(0, MAX_CUSTOM_TEXT) }));
  const ids = new Set([...TASBIH_PHRASES, ...custom.map((c) => c.id)]);
  const phrase = typeof r.phrase === "string" && ids.has(r.phrase) ? r.phrase : "tasbih";
  const legacy = !isObj(r.counters) && ("count" in r || "target" in r || "rounds" in r);
  // Before per-dhikr counters there was one shared counter: keep it on the selected dhikr.
  const counters: Record<string, TasbihCounter> = legacy
    ? { [phrase]: sanitizeCounter(r) }
    : Object.fromEntries(
        Object.entries(isObj(r.counters) ? r.counters : {})
          .filter(([k]) => ids.has(k))
          .map(([k, v]) => [k, sanitizeCounter(v)]),
      );
  const history = Object.fromEntries(
    Object.entries(isObj(r.history) ? r.history : {})
      .filter(([day, v]) => ISO_DATE_RE.test(day) && isObj(v))
      .map(([day, v]) => [
        day,
        Object.fromEntries(
          Object.entries(v as Record<string, unknown>).filter(([k, n]) => ids.has(k) && isCount(n) && n > 0),
        ) as Record<string, number>,
      ])
      .filter(([, row]) => Object.keys(row as object).length > 0),
  ) as Record<string, Record<string, number>>;
  return {
    phrase,
    counters,
    custom,
    mode: (TASBIH_MODES as readonly unknown[]).includes(r.mode) ? (r.mode as TasbihMode) : "button",
    color: typeof r.color === "string" && r.color in TASBIH_COLORS ? r.color : "brown",
    sound: r.sound === true,
    vibrate: r.vibrate !== false,
    history,
  };
}

/** The selected dhikr's counter. */
export function current(s: TasbihState): TasbihCounter {
  return s.counters[s.phrase] ?? NEW_COUNTER;
}

const withCounter = (s: TasbihState, c: TasbihCounter): TasbihState => ({
  ...s,
  counters: { ...s.counters, [s.phrase]: c },
});

function addHistory(s: TasbihState, today: string, delta: number): TasbihState["history"] {
  const row = { ...(s.history[today] ?? {}) };
  const n = (row[s.phrase] ?? 0) + delta;
  if (n > 0) row[s.phrase] = n;
  else delete row[s.phrase];
  const cutoff = new Date(Date.parse(today) - HISTORY_DAYS * DAY_MS).toISOString().slice(0, ISO_DATE_LEN);
  const kept = Object.fromEntries(Object.entries(s.history).filter(([d]) => d > cutoff && d !== today));
  return Object.keys(row).length > 0 ? { ...kept, [today]: row } : kept;
}

/** One tap on `today` ("YYYY-MM-DD"). Reaching the target completes a round and starts the next one from zero. */
export function tap(s: TasbihState, today: string): { next: TasbihState; completed: boolean } {
  const c = current(s);
  const count = c.count + 1;
  const completed = count >= c.target;
  const counter = completed ? { ...c, count: 0, rounds: c.rounds + 1 } : { ...c, count };
  return { next: { ...withCounter(s, counter), history: addHistory(s, today, 1) }, completed };
}

export function undo(s: TasbihState, today: string): TasbihState {
  const c = current(s);
  if (c.count === 0) return s;
  return { ...withCounter(s, { ...c, count: c.count - 1 }), history: addHistory(s, today, -1) };
}

/** Clears the selected dhikr's count and rounds (its history stays). */
export function reset(s: TasbihState): TasbihState {
  return withCounter(s, { ...current(s), count: 0, rounds: 0 });
}

export function setTarget(s: TasbihState, target: number): TasbihState {
  return withCounter(s, sanitizeCounter({ ...current(s), target, count: 0 }));
}

/** Adds the user's own dhikr and selects it; unchanged when empty or the list is full. */
export function addCustom(s: TasbihState, text: string): TasbihState {
  const clean = text.trim().slice(0, MAX_CUSTOM_TEXT);
  if (!clean || s.custom.length >= MAX_CUSTOM) return s;
  const n = Math.max(0, ...s.custom.map((c) => Number(c.id.slice(1)))) + 1;
  const id = `c${n}`;
  return { ...s, custom: [...s.custom, { id, text: clean }], phrase: id };
}

export function removeCustom(s: TasbihState, id: string): TasbihState {
  const counters = Object.fromEntries(Object.entries(s.counters).filter(([k]) => k !== id));
  const history = Object.fromEntries(
    Object.entries(s.history)
      .map(([d, row]) => [d, Object.fromEntries(Object.entries(row).filter(([k]) => k !== id))] as const)
      .filter(([, row]) => Object.keys(row).length > 0),
  );
  return {
    ...s,
    custom: s.custom.filter((c) => c.id !== id),
    counters,
    history,
    phrase: s.phrase === id ? "tasbih" : s.phrase,
  };
}

export function clearHistory(s: TasbihState): TasbihState {
  return { ...s, history: {} };
}

/** History rows, newest day first, each dhikr of the day on its own row. */
export function historyRows(s: TasbihState): { day: string; phrase: string; count: number }[] {
  return Object.keys(s.history)
    .sort()
    .reverse()
    .flatMap((day) =>
      Object.entries(s.history[day] ?? {}).map(([phrase, count]) => ({ day, phrase, count })),
    );
}

export const tasbihStore = createStore<TasbihState>("rattil.tasbih", DEFAULT_TASBIH, sanitizeTasbih);
