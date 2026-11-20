/**
 * «تنبيهات الأذكار» (owner 2026-11-20), website side of the app feature: the user picks short adhkar and
 * how often they come between two times of the day. A browser can only do this while the site is open
 * (or installed and running): each one shows as a notification and, when sound is on, Sheikh Mishary
 * Alafasy says it (public/audio/dhikr, cut by tools/dhikr_reminder_clips.py).
 * Keep the list in step with the app (lib/domain/dhikr_reminders.dart).
 */
import { createStore } from "./store";
import { withBase } from "./base-path";

export interface DhikrReminderItem {
  id: string;
  /** Index of the text in adhkar.v1.json. */
  index: number;
}

export const DHIKR_REMINDER_ITEMS: readonly DhikrReminderItem[] = [
  { id: "salat", index: 28 },
  { id: "subhan", index: 33 },
  { id: "istighfar", index: 32 },
  { id: "tahlil", index: 27 },
  { id: "hasbi", index: 16 },
  { id: "subhanadad", index: 30 },
  { id: "hayy", index: 21 },
  { id: "radeetu", index: 20 },
];

export const dhikrClipSrc = (id: string): string => withBase(`/audio/dhikr/dhikr_${id}.mp3`);

export const DHIKR_INTERVALS = [15, 30, 60, 120] as const;
export const MIN_EVERY = 5;
export const MAX_EVERY = 12 * 60;
const DAY = 24 * 60;

export interface DhikrReminderPrefs {
  enabled: boolean;
  /** minutes between two reminders */
  every: number;
  /** daily window, minutes after midnight (the window may cross midnight; from == to = all day) */
  from: number;
  to: number;
  /** chosen adhkar, in the order they are said */
  ids: string[];
  /** say it aloud (a browser cannot tell whether the computer is muted) */
  sound: boolean;
}

export const DEFAULT_DHIKR_REMINDERS: DhikrReminderPrefs = {
  enabled: false,
  every: 30,
  from: 8 * 60,
  to: 23 * 60,
  ids: ["salat", "subhan", "istighfar"],
  sound: true,
};

const minuteOfDay = (v: unknown, d: number): number =>
  typeof v === "number" && Number.isInteger(v) && v >= 0 && v < DAY ? v : d;

export function sanitizeDhikrReminders(raw: unknown): DhikrReminderPrefs {
  const r = typeof raw === "object" && raw !== null ? (raw as Record<string, unknown>) : {};
  const every = typeof r.every === "number" && Number.isFinite(r.every) ? Math.round(r.every) : 30;
  const known = new Set(DHIKR_REMINDER_ITEMS.map((d) => d.id));
  const ids = Array.isArray(r.ids)
    ? DHIKR_REMINDER_ITEMS.map((d) => d.id).filter((id) => (r.ids as unknown[]).includes(id) && known.has(id))
    : DEFAULT_DHIKR_REMINDERS.ids;
  return {
    enabled: r.enabled === true,
    every: Math.min(MAX_EVERY, Math.max(MIN_EVERY, every)),
    from: minuteOfDay(r.from, DEFAULT_DHIKR_REMINDERS.from),
    to: minuteOfDay(r.to, DEFAULT_DHIKR_REMINDERS.to),
    ids,
    sound: r.sound !== false,
  };
}

export const dhikrReminderStore = createStore<DhikrReminderPrefs>(
  "rattil.dhikrReminders",
  DEFAULT_DHIKR_REMINDERS,
  sanitizeDhikrReminders,
);

/** Minutes after midnight of each reminder (same rule as the app, without its iOS cap). */
export function dhikrSlots(p: Pick<DhikrReminderPrefs, "from" | "to" | "every">): number[] {
  const step = Math.min(MAX_EVERY, Math.max(MIN_EVERY, p.every));
  const allDay = p.from === p.to;
  const span = allDay ? DAY : (((p.to - p.from) % DAY) + DAY) % DAY;
  const n = allDay ? Math.ceil(span / step) : Math.floor(span / step) + 1;
  return Array.from({ length: n }, (_, i) => (p.from + i * step) % DAY);
}

/** The next reminder strictly after [now] (local time), with the dhikr said at that slot. */
export function nextDhikrReminder(now: Date, p: DhikrReminderPrefs): { at: Date; id: string } | null {
  if (!p.enabled || p.ids.length === 0) return null;
  const slots = dhikrSlots(p);
  for (let day = 0; day <= 1; day++) {
    let best: { at: Date; id: string } | null = null;
    for (let i = 0; i < slots.length; i++) {
      const m = slots[i] ?? 0;
      const at = new Date(now.getFullYear(), now.getMonth(), now.getDate() + day, Math.floor(m / 60), m % 60);
      if (at.getTime() > now.getTime() && (best === null || at.getTime() < best.at.getTime()))
        best = { at, id: p.ids[i % p.ids.length] ?? "" };
    }
    if (best) return best;
  }
  return null;
}
