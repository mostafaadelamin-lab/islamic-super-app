/** Round counters of the Hajj/Umrah guide (Tawaf and Sa'i: 7 rounds; Jamarat: 7 pebbles). */
import { createStore } from "./store";

export const ROUND_TOOLS = ["tawaf", "sai", "jamarat"] as const;
export type RoundTool = (typeof ROUND_TOOLS)[number];
export const ROUNDS_TARGET = 7;
export type Rounds = Record<RoundTool, number>;
export const NO_ROUNDS: Rounds = { tawaf: 0, sai: 0, jamarat: 0 };

export function sanitizeRounds(raw: unknown): Rounds {
  const r = typeof raw === "object" && raw !== null ? (raw as Record<string, unknown>) : {};
  const one = (v: unknown): number =>
    typeof v === "number" && Number.isInteger(v) && v >= 0 ? Math.min(v, ROUNDS_TARGET) : 0;
  return { tawaf: one(r.tawaf), sai: one(r.sai), jamarat: one(r.jamarat) };
}

export function isRoundTool(v: unknown): v is RoundTool {
  return typeof v === "string" && (ROUND_TOOLS as readonly string[]).includes(v);
}

export function addRound(r: Rounds, tool: RoundTool, delta: 1 | -1): Rounds {
  return { ...r, [tool]: Math.max(0, Math.min(ROUNDS_TARGET, r[tool] + delta)) };
}

export const roundsStore = createStore<Rounds>("rattil.rounds", NO_ROUNDS, sanitizeRounds);
