/**
 * Sleep timer for listening before sleep: after N minutes it stops the recitation player and pauses every
 * <audio> element on the page (narrated episodes). One timer for the whole app.
 */
import { player } from "./audio-player";

export const SLEEP_CHOICES: readonly number[] = [15, 30, 45, 60];

export interface SleepState {
  endsAt: number | null;
  /** The chosen duration while the timer runs. */
  minutes: number | null;
}
const OFF: SleepState = { endsAt: null, minutes: null };
let state: SleepState = OFF;
let timer: ReturnType<typeof setTimeout> | null = null;
const listeners = new Set<() => void>();
const emit = (): void => listeners.forEach((l) => l());

function fire(): void {
  timer = null;
  state = OFF;
  player.stop();
  if (typeof document !== "undefined") document.querySelectorAll("audio").forEach((a) => a.pause());
  emit();
}

export const sleepTimer = {
  get: (): SleepState => state,
  getServer: (): SleepState => OFF,
  subscribe(l: () => void): () => void {
    listeners.add(l);
    return () => listeners.delete(l);
  },
  /** Starts (or replaces) the timer; null cancels it. */
  set(min: number | null, now: number = Date.now()): void {
    if (timer) clearTimeout(timer);
    timer = null;
    state = min ? { endsAt: now + min * 60_000, minutes: min } : OFF;
    if (min) timer = setTimeout(fire, min * 60_000);
    emit();
  },
  /** Whole minutes left (rounded up), or null when off. */
  minutesLeft(now: number = Date.now()): number | null {
    return state.endsAt === null ? null : Math.max(0, Math.ceil((state.endsAt - now) / 60_000));
  },
};
