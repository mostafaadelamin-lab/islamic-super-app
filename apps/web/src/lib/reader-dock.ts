/**
 * The Mushaf reader's bottom player can be slid down to a small strip so it stops covering the page
 * (owner 2026-11-17). Remembered per browser, like the other reader preferences.
 */
import { createStore } from "./store";

export const readerDockMinStore = createStore<boolean>("rattil.reader.dockMin", false, (raw) => raw === true);

/** A drag on the handle longer than this (px) slides the player down / up instead of counting as a tap. */
export const DOCK_SWIPE_PX = 24;

/** Direction of a finished drag on the handle: positive dy = finger moved down. */
export function dockSwipe(dy: number, minimized: boolean): boolean | null {
  if (dy > DOCK_SWIPE_PX && !minimized) return true;
  if (dy < -DOCK_SWIPE_PX && minimized) return false;
  return null;
}

/**
 * Size of the Mushaf page on wide screens (laptops, desktops), as a multiple of "the whole page between the
 * site header and the player". Owner 2026-11-18: the page was very small on a laptop, so it starts larger and
 * scrolls; − / + in the reader, Ctrl + mouse wheel or a touchpad pinch change it, and the choice is kept.
 */
export const PAGE_SCALES = [1, 1.25, 1.5, 1.75, 2, 2.25, 2.5, 3] as const;
export const DEFAULT_PAGE_SCALE = 2;
// Owner 2026-11-20: the page still opened small (a size of 100% kept from before), in full screen too. A new key
// starts everyone at the big default once; − / + still change it and the new choice is kept.
export const readerPageScaleStore = createStore<number>(
  "rattil.reader.pageScale.v2",
  DEFAULT_PAGE_SCALE,
  (raw) => (typeof raw === "number" && (PAGE_SCALES as readonly number[]).includes(raw) ? raw : DEFAULT_PAGE_SCALE),
);
/** The next size up (+1) or down (−1); stays at the ends. */
export function stepPageScale(current: number, dir: 1 | -1): number {
  const i = PAGE_SCALES.findIndex((s) => s >= current - 1e-6);
  const at = i < 0 ? PAGE_SCALES.length - 1 : i;
  const next = Math.min(PAGE_SCALES.length - 1, Math.max(0, at + dir));
  return PAGE_SCALES[next]!;
}
