/**
 * The single recitation player of the app (one HTMLAudioElement). State lives in a small observable store so
 * the player bar and the Mushaf reader (highlight, auto page turn) stay in sync across client navigations.
 */
import { surahName } from "./pages";
import { downloadsStore, isSaved, savedSource } from "./audio-offline";
import {
  afterEnded,
  audioStore,
  RECITERS,
  buildQueue,
  itemUrl,
  stepAyah,
  type Cursor,
  type PlayScope,
  type QueueItem,
} from "./audio";

export type PlayerStatus = "idle" | "loading" | "playing" | "paused" | "error";
export type PlayerError = "offline" | "network" | "blocked";

export interface PlayerState {
  queue: QueueItem[];
  cursor: Cursor;
  status: PlayerStatus;
  error: PlayerError | null;
  /** URL of the current item (for diagnostics and tests). */
  src: string | null;
}

const IDLE: PlayerState = {
  queue: [],
  cursor: { index: 0, plays: 0 },
  status: "idle",
  error: null,
  src: null,
};

let state: PlayerState = IDLE;
const listeners = new Set<() => void>();
let audio: HTMLAudioElement | null = null;
let unsubscribeSpeed: (() => void) | null = null;
/** blob: URL of the saved file being played, revoked when the next item loads. */
let blobUrl: string | null = null;
/** What the element was given for the current item (the stream URL, or a blob: URL of a saved copy). */
let elementSrc: string | null = null;

const ICON_SIZES = ["192", "512"] as const;

function setState(patch: Partial<PlayerState>): void {
  state = { ...state, ...patch };
  syncMediaSession();
  listeners.forEach((l) => l());
}

const mediaSession = (): MediaSession | null =>
  typeof navigator !== "undefined" && "mediaSession" in navigator ? navigator.mediaSession : null;

/** Lock-screen / notification controls and media keys (Media Session API, where the browser supports it). */
function syncMediaSession(): void {
  const ms = mediaSession();
  if (!ms) return;
  const item = state.queue[state.cursor.index];
  if (state.status === "idle" || !item) {
    ms.metadata = null;
    ms.playbackState = "none";
    return;
  }
  ms.playbackState = state.status === "paused" || state.status === "error" ? "paused" : "playing";
  if (typeof MediaMetadata === "undefined") return;
  const ar = typeof document !== "undefined" && document.documentElement.lang === "ar";
  const reciter = RECITERS.find((r) => r.folder === audioStore.get().reciter);
  const title =
    `${surahName(item.s, ar ? "ar" : "en")} ${item.kind === "basmala" ? "" : `${item.s}:${item.a}`}`.trim();
  if (ms.metadata?.title === title) return;
  ms.metadata = new MediaMetadata({
    title,
    artist: reciter ? (ar ? reciter.ar : reciter.en) : "",
    album: ar ? "رتّل" : "Rattil",
    artwork: ICON_SIZES.map((n) => ({ src: `/icon-${n}.png`, sizes: `${n}x${n}`, type: "image/png" })),
  });
}

function bindMediaKeys(): void {
  const ms = mediaSession();
  if (!ms) return;
  const handlers: [MediaSessionAction, () => void][] = [
    ["play", () => (state.status === "playing" || state.status === "loading" ? undefined : player.toggle())],
    ["pause", () => (state.status === "playing" || state.status === "loading" ? player.toggle() : undefined)],
    ["stop", () => player.stop()],
    ["nexttrack", () => player.step(1)],
    ["previoustrack", () => player.step(-1)],
  ];
  handlers.forEach(([action, fn]) => {
    try {
      ms.setActionHandler(action, fn);
    } catch {
      // the browser does not support this action
    }
  });
}

export const player = {
  get(): PlayerState {
    return state;
  },
  getServer(): PlayerState {
    return IDLE;
  },
  subscribe(l: () => void): () => void {
    listeners.add(l);
    return () => listeners.delete(l);
  },
  current(): QueueItem | null {
    return state.queue[state.cursor.index] ?? null;
  },
  play(scope: PlayScope): void {
    const queue = buildQueue(scope);
    if (queue.length === 0) return;
    setState({ queue, cursor: { index: 0, plays: 0 }, error: null });
    load();
  },
  toggle(): void {
    if (state.status === "playing" || state.status === "loading") {
      audio?.pause();
      setState({ status: "paused" });
    } else if (state.queue.length > 0) {
      if (state.status === "error" || !audio?.src) load();
      else void resume();
    }
  },
  stop(): void {
    if (audio) {
      audio.pause();
      audio.removeAttribute("src");
      audio.load();
    }
    setState(IDLE);
  },
  step(delta: 1 | -1): void {
    const i = stepAyah(state.queue, state.cursor.index, delta);
    if (i === null) return;
    setState({ cursor: { index: i, plays: 0 }, error: null });
    load();
  },
  /** Re-loads the current item with the newly chosen reciter. */
  reciterChanged(): void {
    if (state.queue.length > 0 && state.status !== "paused") load();
  },
};

function element(): HTMLAudioElement {
  if (audio) return audio;
  const el = new Audio();
  el.preload = "auto";
  el.addEventListener("playing", () => setState({ status: "playing", error: null }));
  el.addEventListener("waiting", () => {
    if (state.status === "playing") setState({ status: "loading" });
  });
  el.addEventListener("ended", () => {
    // Advance only at the genuine end of the item being played: never while paused, stopped or failed, and
    // never for a late event of an earlier source, so the cursor cannot skip ayahs.
    if ((state.status !== "playing" && state.status !== "loading") || el.src !== elementSrc) return;
    const next = afterEnded(state.queue, state.cursor, audioStore.get().repeat);
    if (!next) {
      setState(IDLE);
      return;
    }
    setState({ cursor: next });
    load();
  });
  el.addEventListener("error", () => {
    if (!el.getAttribute("src")) return; // stop() clears the source
    fail(typeof navigator !== "undefined" && navigator.onLine === false ? "offline" : "network");
  });
  audio = el;
  unsubscribeSpeed = audioStore.subscribe(() => applySpeed(el));
  bindMediaKeys();
  return el;
}

function fail(error: PlayerError): void {
  audio?.pause();
  setState({ status: "error", error });
}

/** Applies the chosen playback speed (kept across items: a new src resets playbackRate in some browsers). */
function applySpeed(el: HTMLAudioElement): void {
  const { speed } = audioStore.get();
  el.defaultPlaybackRate = speed;
  el.playbackRate = speed;
}

async function resume(): Promise<void> {
  const el = element();
  applySpeed(el);
  setState({ status: "loading", error: null });
  try {
    await el.play();
  } catch (e: unknown) {
    const name = e instanceof DOMException ? e.name : "";
    if (name === "AbortError") return; // superseded by a newer load
    if (name === "NotAllowedError") fail("blocked");
    else fail(navigator.onLine === false ? "offline" : "network");
  }
}

function start(el: HTMLAudioElement, from: string): void {
  if (blobUrl && blobUrl !== from) URL.revokeObjectURL(blobUrl);
  blobUrl = from.startsWith("blob:") ? from : null;
  elementSrc = from;
  el.src = from;
  void resume();
}

function load(): void {
  const item = state.queue[state.cursor.index];
  if (!item) return;
  const { reciter } = audioStore.get();
  const src = itemUrl(item, reciter);
  const offline = typeof navigator !== "undefined" && navigator.onLine === false;
  if (isSaved(downloadsStore.get(), reciter, item.s)) {
    const el = element();
    setState({ src, status: "loading", error: null });
    void savedSource(src)
      .catch(() => null)
      .then((local) => {
        if (state.src !== src) return; // superseded while looking in the cache
        if (!local && offline) setState({ status: "error", error: "offline", src: null });
        else start(el, local ?? src);
      });
    return;
  }
  if (offline) {
    setState({ status: "error", error: "offline", src: null });
    return;
  }
  const el = element();
  setState({ src });
  start(el, src);
}

/** Test hook: forget the audio element and state. */
export function resetPlayerForTests(): void {
  blobUrl = null;
  elementSrc = null;
  unsubscribeSpeed?.();
  unsubscribeSpeed = null;
  audio = null;
  state = IDLE;
  listeners.forEach((l) => l());
}
