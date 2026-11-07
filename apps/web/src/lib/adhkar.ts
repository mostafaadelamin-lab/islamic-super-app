/**
 * Morning and evening adhkar from content/adhkar/dist/adhkar.v1.json (34 items, one combined list in which the
 * morning wording "أصبحنا…" is followed by its evening counterpart "أمسينا…").
 *
 * The dataset has no session or repetition fields. SESSIONS assigns each item (by index) to the morning, the
 * evening or both, and gives its repetition count exactly as annotated in content/adhkar/hisn.json, chapter
 * "أذكار الصباح والمساء" (e.g. "( ثلاث مرات )", "(سبع مرات )", "( ثلاث مرات إذا أمسى)"). Items without an
 * annotation count once. Religious review of this mapping is pending, like the dataset itself.
 * A unit test pins every index to the opening words of its item so the mapping cannot drift silently.
 */
import sessionsJson from "@/data/adhkar-sessions.json";
import { createStore } from "./store";

export type Session = "morning" | "evening";
type When = "both" | Session;

interface SessionRow {
  when: When;
  count: number;
  hisn: number | null;
}
/** Per adhkar.v1 item index: when it is said, how many times, and the hisn item the count comes from. */
export const SESSIONS: readonly SessionRow[] = (sessionsJson as { items: SessionRow[] }).items;

export interface Dhikr {
  /** Index in adhkar.v1.json items. */
  id: number;
  text: string;
  count: number;
}

export function sessionItems(items: readonly string[], session: Session): Dhikr[] {
  return items
    .map((text, id) => ({ text, id, meta: SESSIONS[id] }))
    .filter(({ meta }) => meta !== undefined && (meta.when === "both" || meta.when === session))
    .map(({ text, id, meta }) => ({ id, text, count: (meta as SessionRow).count }));
}

/** Morning until Asr is not modelled; a simple local-hour rule picks the default tab (evening from 15:00). */
export const EVENING_FROM_HOUR = 15;
export const MORNING_FROM_HOUR = 3;
export function defaultSession(hour: number): Session {
  return hour >= EVENING_FROM_HOUR || hour < MORNING_FROM_HOUR ? "evening" : "morning";
}

/** Progress of one day: `${session}:${id}` → times said. Reset automatically on a new local date. */
export interface AdhkarProgress {
  date: string;
  done: Record<string, number>;
}
export const EMPTY_PROGRESS: AdhkarProgress = { date: "", done: {} };

export function sanitizeProgress(raw: unknown): AdhkarProgress {
  if (typeof raw !== "object" || raw === null) return EMPTY_PROGRESS;
  const r = raw as Record<string, unknown>;
  const done: Record<string, number> = {};
  if (typeof r.done === "object" && r.done !== null) {
    // Accepts keys like "morning:6" or "evening:29"; rejects "noon:1" and "morning:x".
    Object.entries(r.done as Record<string, unknown>)
      .filter(([k, v]) => /^(morning|evening):\d+$/.test(k) && typeof v === "number" && v > 0)
      .forEach(([k, v]) => {
        done[k] = Math.floor(v as number);
      });
  }
  return { date: typeof r.date === "string" ? r.date : "", done };
}

export function progressFor(p: AdhkarProgress, today: string): AdhkarProgress {
  return p.date === today ? p : { date: today, done: {} };
}

/** One tap on an item; never counts beyond its repetition count. */
export function countOne(p: AdhkarProgress, today: string, session: Session, d: Dhikr): AdhkarProgress {
  const cur = progressFor(p, today);
  const key = `${session}:${d.id}`;
  const n = cur.done[key] ?? 0;
  if (n >= d.count) return cur;
  return { date: today, done: { ...cur.done, [key]: n + 1 } };
}

export function resetSession(p: AdhkarProgress, today: string, session: Session): AdhkarProgress {
  const cur = progressFor(p, today);
  const done = Object.fromEntries(Object.entries(cur.done).filter(([k]) => !k.startsWith(`${session}:`)));
  return { date: today, done };
}

export function sessionSummary(
  p: AdhkarProgress,
  today: string,
  session: Session,
  list: readonly Dhikr[],
): { completed: number; total: number } {
  const cur = progressFor(p, today);
  const completed = list.filter((d) => (cur.done[`${session}:${d.id}`] ?? 0) >= d.count).length;
  return { completed, total: list.length };
}

export const adhkarStore = createStore<AdhkarProgress>("rattil.adhkar", EMPTY_PROGRESS, sanitizeProgress);
