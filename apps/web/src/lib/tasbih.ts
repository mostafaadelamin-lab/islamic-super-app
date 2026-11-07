/** Tasbih (dhikr) counter with a target; persisted on the device. */
import { createStore } from "./store";

export const TASBIH_TARGETS: readonly number[] = [33, 99, 100, 1000];
export const TASBIH_PHRASES: readonly string[] = ["tasbih", "tahmid", "takbir", "tahlil", "istighfar"];
const MAX_COUNT = 1_000_000;
const DEFAULT_TARGET = 33;

export interface TasbihState {
  count: number;
  target: number;
  /** Completed rounds of `target`. */
  rounds: number;
  phrase: string;
}
export const DEFAULT_TASBIH: TasbihState = { count: 0, target: DEFAULT_TARGET, rounds: 0, phrase: "tasbih" };

const isCount = (v: unknown): v is number => typeof v === "number" && Number.isInteger(v) && v >= 0;

export function sanitizeTasbih(raw: unknown): TasbihState {
  const r = typeof raw === "object" && raw !== null ? (raw as Record<string, unknown>) : {};
  const target = isCount(r.target) && r.target >= 1 && r.target <= MAX_COUNT ? r.target : DEFAULT_TARGET;
  return {
    target,
    count: isCount(r.count) ? Math.min(r.count, target) : 0,
    rounds: isCount(r.rounds) ? Math.min(r.rounds, MAX_COUNT) : 0,
    phrase: typeof r.phrase === "string" && TASBIH_PHRASES.includes(r.phrase) ? r.phrase : "tasbih",
  };
}

/** One tap. Reaching the target completes a round and starts the next one from zero. */
export function tap(s: TasbihState): { next: TasbihState; completed: boolean } {
  const count = s.count + 1;
  if (count >= s.target) return { next: { ...s, count: 0, rounds: s.rounds + 1 }, completed: true };
  return { next: { ...s, count }, completed: false };
}

export function undo(s: TasbihState): TasbihState {
  return s.count > 0 ? { ...s, count: s.count - 1 } : s;
}

export function reset(s: TasbihState): TasbihState {
  return { ...s, count: 0, rounds: 0 };
}

export function setTarget(s: TasbihState, target: number): TasbihState {
  return sanitizeTasbih({ ...s, target, count: 0 });
}

export const tasbihStore = createStore<TasbihState>("rattil.tasbih", DEFAULT_TASBIH, sanitizeTasbih);
