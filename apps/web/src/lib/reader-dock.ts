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
