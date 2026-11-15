/**
 * Lock-screen / notification controls (Media Session API) for the app's own <audio> elements: the recitation
 * library and Quran radios, al-Sha'rawi lessons and narrated stories. The browser keeps a page's media
 * playing in the background; the session gives it a title and play / pause / next buttons there, and the
 * element's "ended" handler goes on to the next item of its list.
 */
export interface ElementMedia {
  title: string;
  artist?: string;
  /** Next / previous item of the list (left out: no skip buttons, e.g. a live radio). */
  next?: () => void;
  previous?: () => void;
}

const ICON_SIZES = ["192", "512"] as const;
const POSITION_EVENTS = [
  "loadedmetadata",
  "durationchange",
  "play",
  "pause",
  "seeked",
  "ratechange",
] as const;

/** The element the session describes now, and how to stop following it. */
let followed: { el: HTMLAudioElement; stop: () => void } | null = null;

/**
 * Elapsed time, length and a moving seek bar on the lock screen / notification (owner 2026-11-15: it showed
 * 00:00 / 00:00 while a surah played). The system moves the bar itself from the last position it was given,
 * so the position is only sent when playback starts, pauses, jumps or changes speed. Live streams (no length)
 * have no bar.
 */
export function syncPositionState(el: HTMLMediaElement): void {
  if (typeof navigator === "undefined" || !("mediaSession" in navigator)) return;
  const ms = navigator.mediaSession;
  if (typeof ms.setPositionState !== "function") return;
  const duration = el.duration;
  try {
    if (!Number.isFinite(duration) || duration <= 0) {
      ms.setPositionState();
      return;
    }
    ms.setPositionState({
      duration,
      position: Math.min(Math.max(el.currentTime, 0), duration),
      playbackRate: el.playbackRate > 0 ? el.playbackRate : 1,
    });
  } catch {
    // an older browser rejected the state
  }
}

function follow(el: HTMLAudioElement): void {
  if (followed?.el === el) {
    syncPositionState(el);
    return;
  }
  followed?.stop();
  const onChange = (): void => {
    if (followed?.el === el) syncPositionState(el);
  };
  POSITION_EVENTS.forEach((ev) => el.addEventListener(ev, onChange));
  followed = { el, stop: () => POSITION_EVENTS.forEach((ev) => el.removeEventListener(ev, onChange)) };
  syncPositionState(el);
}

function seekTo(el: HTMLMediaElement, to: number): void {
  if (!Number.isFinite(el.duration)) return;
  el.currentTime = Math.min(Math.max(to, 0), el.duration);
}

export function claimMediaSession(el: HTMLAudioElement, media: ElementMedia): void {
  if (typeof navigator === "undefined" || !("mediaSession" in navigator)) return;
  const ms = navigator.mediaSession;
  const ar = typeof document !== "undefined" && document.documentElement.lang === "ar";
  if (typeof MediaMetadata !== "undefined") {
    ms.metadata = new MediaMetadata({
      title: media.title,
      artist: media.artist ?? (ar ? "رتّل وصلِّ" : "Rattil wa Salli"),
      album: ar ? "رتّل وصلِّ" : "Rattil wa Salli",
      artwork: ICON_SIZES.map((n) => ({ src: `/icon-${n}.png`, sizes: `${n}x${n}`, type: "image/png" })),
    });
  }
  ms.playbackState = el.paused ? "paused" : "playing";
  const handlers: [MediaSessionAction, MediaSessionActionHandler | null][] = [
    ["play", () => void el.play().catch(() => undefined)],
    ["pause", () => el.pause()],
    ["stop", () => el.pause()],
    ["nexttrack", media.next ?? null],
    ["previoustrack", media.previous ?? null],
    ["seekto", (d) => (d.seekTime === undefined ? undefined : seekTo(el, d.seekTime))],
    ["seekbackward", (d) => seekTo(el, el.currentTime - (d.seekOffset ?? 30))],
    ["seekforward", (d) => seekTo(el, el.currentTime + (d.seekOffset ?? 30))],
  ];
  for (const [action, fn] of handlers) {
    try {
      ms.setActionHandler(action, fn);
    } catch {
      // the browser does not support this action
    }
  }
  follow(el);
}

/** Keeps the session's play / pause state in step with the element. */
export function mediaSessionState(playing: boolean): void {
  if (typeof navigator === "undefined" || !("mediaSession" in navigator)) return;
  navigator.mediaSession.playbackState = playing ? "playing" : "paused";
}

/** Test hook. */
export function resetElementMediaSessionForTests(): void {
  followed?.stop();
  followed = null;
}
