/** Service-worker registration and offline-precache progress reporting. */
export interface OfflineStatus {
  supported: boolean;
  done: number;
  total: number;
  complete: boolean;
}

type Listener = (s: OfflineStatus) => void;
const listeners = new Set<Listener>();
let last: OfflineStatus = { supported: true, done: 0, total: 0, complete: false };

export function currentOfflineStatus(): OfflineStatus {
  return last;
}

export function handleSwMessage(data: unknown): void {
  if (typeof data !== "object" || data === null) return;
  const d = data as Record<string, unknown>;
  if (d.type !== "precache-progress") return;
  last = {
    supported: true,
    done: typeof d.done === "number" ? d.done : 0,
    total: typeof d.total === "number" ? d.total : 0,
    complete: d.complete === true,
  };
  listeners.forEach((l) => l(last));
}

export function subscribeOfflineStatus(l: Listener): () => void {
  listeners.add(l);
  return () => listeners.delete(l);
}

function pageLocale(): string {
  return typeof document !== "undefined" && document.documentElement.lang === "en" ? "en" : "ar";
}

let started = false;
export function registerServiceWorker(nav: Navigator | undefined = globalThis.navigator): void {
  if (started) return;
  started = true;
  if (!nav || !("serviceWorker" in nav)) {
    last = { ...last, supported: false };
    listeners.forEach((l) => l(last));
    return;
  }
  const sw = nav.serviceWorker;
  sw.addEventListener("message", (e: MessageEvent) => handleSwMessage(e.data));
  sw.register("/sw.js", { scope: "/" })
    .then(() => sw.ready)
    .then((reg) => {
      reg.active?.postMessage({ type: "precache-all", locale: pageLocale() });
    })
    .catch(() => {
      /* No service worker (e.g. `next dev`): the app still works online. */
    });
}

/** Asks the active worker to report progress (and resume precaching if interrupted). */
export function requestOfflineStatus(nav: Navigator | undefined = globalThis.navigator): void {
  if (!nav || !("serviceWorker" in nav)) return;
  nav.serviceWorker.ready
    .then((reg) => reg.active?.postMessage({ type: "precache-all", locale: pageLocale() }))
    .catch(() => undefined);
}
