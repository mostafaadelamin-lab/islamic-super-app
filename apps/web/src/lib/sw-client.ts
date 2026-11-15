import { withBase } from "@/lib/base-path";

/** Service-worker registration and offline-precache progress reporting. */
export interface OfflineStatus {
  supported: boolean;
  done: number;
  total: number;
  complete: boolean;
  /** The visitor asked to save the whole site for offline use. */
  saved: boolean;
  /** Size of the whole site for this language, in MB. */
  mb: number;
}

type Listener = (s: OfflineStatus) => void;
const listeners = new Set<Listener>();
let last: OfflineStatus = { supported: true, done: 0, total: 0, complete: false, saved: false, mb: 0 };

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
    saved: d.saved === true,
    mb: typeof d.mb === "number" ? d.mb : 0,
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

/** A newer version of the site was uploaded and is now ready (owner 2026-11-15: users must see updates). */
const updateListeners = new Set<() => void>();
let updateReady = false;
export function subscribeUpdate(l: () => void): () => void {
  updateListeners.add(l);
  if (updateReady) l();
  return () => updateListeners.delete(l);
}
function announceUpdate(): void {
  updateReady = true;
  updateListeners.forEach((l) => l());
}
const UPDATE_CHECK_MS = 30 * 60 * 1000;

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
  // A page that was already run by a worker gets a new one only when a new upload is live.
  const hadController = Boolean(sw.controller);
  sw.addEventListener("controllerchange", () => {
    sw.controller?.postMessage({ type: "precache-status", locale: pageLocale() });
    if (hadController) announceUpdate();
  });
  sw.register(withBase("/sw.js"), { scope: withBase("/"), updateViaCache: "none" })
    .then((reg) => {
      // Look for a new upload now, when the page comes back to the screen, and every half hour.
      const check = (): void => {
        reg.update().catch(() => undefined);
      };
      check();
      document.addEventListener("visibilitychange", () => {
        if (document.visibilityState === "visible") check();
      });
      setInterval(check, UPDATE_CHECK_MS);
      return sw.ready;
    })
    .then((reg) => {
      // Only a report: the whole site is saved only when the visitor asks (owner 2026-11-15: site slow).
      reg.active?.postMessage({ type: "precache-status", locale: pageLocale() });
    })
    .catch(() => {
      /* No service worker (e.g. `next dev`): the app still works online. */
    });
}

function postToWorker(type: string, nav: Navigator | undefined): void {
  if (!nav || !("serviceWorker" in nav)) return;
  nav.serviceWorker.ready
    .then((reg) => reg.active?.postMessage({ type, locale: pageLocale() }))
    .catch(() => undefined);
}

/** Asks the active worker to report progress (it resumes saving if the visitor had asked for it). */
export function requestOfflineStatus(nav: Navigator | undefined = globalThis.navigator): void {
  postToWorker("precache-status", nav);
}

/** The visitor asks to save the whole site on the device for offline use. */
export function saveSiteOffline(nav: Navigator | undefined = globalThis.navigator): void {
  postToWorker("precache-all", nav);
}
