/**
 * One sound at a time (owner 2026-11-14): when any player of the app starts (Quran recitation, adhkar,
 * nasheeds, lessons, radios, the adhan), every other one pauses. Each player keeps its own position, so the
 * Quran recitation resumes from the ayah it stopped at.
 *
 * Players made with `new Audio()` (not in the page) register themselves; <audio> elements in the page are
 * found through the "play" event, which is caught on the document.
 */

interface Entry {
  el: HTMLMediaElement;
  /** How this player pauses itself (the Quran player also updates its own state). */
  pause: () => void;
}

const entries = new Set<Entry>();
let installed = false;

/** Pauses every playing sound except `except`. */
export function pauseOthers(except: HTMLMediaElement | null): void {
  const all = [...entries];
  all.filter((e) => e.el !== except && !e.el.paused).forEach((e) => e.pause());
  if (typeof document === "undefined") return;
  [...document.querySelectorAll<HTMLMediaElement>("audio, video")]
    .filter((m) => m !== except && !m.paused && !all.some((e) => e.el === m))
    .forEach((m) => m.pause());
}

function onDocumentPlay(e: Event): void {
  const el = e.target;
  if (el instanceof HTMLMediaElement) pauseOthers(el);
}

function install(): void {
  if (installed || typeof document === "undefined") return;
  installed = true;
  // "play" does not bubble; the capture phase still sees it for every element in the page.
  document.addEventListener("play", onDocumentPlay, true);
}

/** Registers a player; when it starts, the others pause. Returns a function that unregisters it. */
export function registerAudio(el: HTMLMediaElement, pause: () => void = () => el.pause()): () => void {
  install();
  const entry: Entry = { el, pause };
  entries.add(entry);
  // Detached elements (new Audio()) never reach the document listener.
  const onPlay = (): void => pauseOthers(el);
  if (!el.isConnected) el.addEventListener("play", onPlay);
  return () => {
    entries.delete(entry);
    el.removeEventListener("play", onPlay);
  };
}

/** Starts listening for the page's own <audio> elements (called once by the app shell). */
export function installAudioFocus(): void {
  install();
}

/** Test hook. */
export function resetAudioFocusForTests(): void {
  entries.clear();
  if (installed && typeof document !== "undefined")
    document.removeEventListener("play", onDocumentPlay, true);
  installed = false;
}
