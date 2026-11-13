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
  const handlers: [MediaSessionAction, (() => void) | null][] = [
    ["play", () => void el.play().catch(() => undefined)],
    ["pause", () => el.pause()],
    ["stop", () => el.pause()],
    ["nexttrack", media.next ?? null],
    ["previoustrack", media.previous ?? null],
  ];
  for (const [action, fn] of handlers) {
    try {
      ms.setActionHandler(action, fn);
    } catch {
      // the browser does not support this action
    }
  }
}

/** Keeps the session's play / pause state in step with the element. */
export function mediaSessionState(playing: boolean): void {
  if (typeof navigator === "undefined" || !("mediaSession" in navigator)) return;
  navigator.mediaSession.playbackState = playing ? "playing" : "paused";
}
