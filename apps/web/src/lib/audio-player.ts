/**
 * The single recitation player of the app (one HTMLAudioElement). State lives in a small observable store so
 * the player bar and the Mushaf reader (highlight, auto page turn) stay in sync across client navigations.
 */
import {
  afterEnded,
  audioStore,
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

function setState(patch: Partial<PlayerState>): void {
  state = { ...state, ...patch };
  listeners.forEach((l) => l());
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
  return el;
}

function fail(error: PlayerError): void {
  audio?.pause();
  setState({ status: "error", error });
}

async function resume(): Promise<void> {
  const el = element();
  setState({ status: "loading", error: null });
  try {
    await el.play();
  } catch (e: unknown) {
    const name = e instanceof DOMException ? e.name : "";
    if (name === "AbortError") return; // superseded by a newer load
    fail(name === "NotAllowedError" ? "blocked" : navigator.onLine === false ? "offline" : "network");
  }
}

function load(): void {
  const item = state.queue[state.cursor.index];
  if (!item) return;
  if (typeof navigator !== "undefined" && navigator.onLine === false) {
    setState({ status: "error", error: "offline", src: null });
    return;
  }
  const el = element();
  const src = itemUrl(item, audioStore.get().reciter);
  setState({ src });
  el.src = src;
  void resume();
}

/** Test hook: forget the audio element and state. */
export function resetPlayerForTests(): void {
  audio = null;
  state = IDLE;
  listeners.forEach((l) => l());
}
