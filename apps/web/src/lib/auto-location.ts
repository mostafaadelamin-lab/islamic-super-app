/**
 * "Detect my location automatically" (the app's prayerAutoLocation): when the viewer uses their own position
 * (not a city from the list) and already allowed location for this site, the position is refreshed on each
 * visit so prayer times stay right after travelling. Never asks for permission by itself.
 */
import { createStore } from "./store";
import { prayerStore } from "./settings";
import { distanceM } from "./mosques";

export const autoLocationStore = createStore<boolean>(
  "rattil.prayer.autoLocation",
  true,
  (raw) => raw !== false,
);

/** Moves smaller than this keep the saved position (no needless re-render of every time). */
export const MIN_MOVE_M = 1000;

export async function refreshAutoLocation(
  nav: Navigator | undefined = globalThis.navigator,
): Promise<boolean> {
  if (!autoLocationStore.get()) return false;
  const custom = prayerStore.get().custom;
  if (!custom || !nav?.geolocation) return false;
  try {
    const st = await nav.permissions?.query({ name: "geolocation" as PermissionName });
    if (!st || st.state !== "granted") return false;
  } catch {
    return false;
  }
  return new Promise((resolve) => {
    nav.geolocation.getCurrentPosition(
      (pos) => {
        const lat = Math.round(pos.coords.latitude * 10000) / 10000;
        const lng = Math.round(pos.coords.longitude * 10000) / 10000;
        const now = prayerStore.get().custom;
        if (now && distanceM(now.lat, now.lng, lat, lng) < MIN_MOVE_M) return resolve(false);
        const tz = Intl.DateTimeFormat().resolvedOptions().timeZone || "UTC";
        prayerStore.set((p) => ({ ...p, custom: { lat, lng, tz } }));
        resolve(true);
      },
      () => resolve(false),
      { enableHighAccuracy: false, timeout: 15000, maximumAge: 600000 },
    );
  });
}
