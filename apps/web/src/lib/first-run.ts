/** First visit (owner 2026-11-14): the welcome tour and the setup of location and adhan alerts, once. */
import { createStore } from "./store";

export interface FirstRunPrefs {
  /** True once the tour was finished or skipped. */
  done: boolean;
}

export const FIRST_RUN_DEFAULT: FirstRunPrefs = { done: false };

export function sanitizeFirstRun(raw: unknown): FirstRunPrefs {
  const r = (raw ?? {}) as Partial<FirstRunPrefs>;
  return { done: r.done === true };
}

export const firstRunStore = createStore<FirstRunPrefs>(
  "rattil.firstRun",
  FIRST_RUN_DEFAULT,
  sanitizeFirstRun,
);

/** Settings > "App tour": shows the tour again. */
export function replayTour(): void {
  firstRunStore.set({ done: false });
}

/** The tour's slides: icon (Rattil icon set) and the i18n keys of title and text. */
export const TOUR_SLIDES = [
  { icon: "star", key: "welcome" },
  { icon: "quran", key: "quran" },
  { icon: "prayer", key: "prayer" },
  { icon: "dua", key: "adhkar" },
  { icon: "headphones", key: "listen" },
] as const;
