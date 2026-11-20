/**
 * Parent lock for the videos page (Google Play Families policy: children use the
 * app and the site; videos come from YouTube / Instagram). Owner's choice, 2026-11-20.
 * The PIN is kept only as a salted SHA-256 hash in this browser. Same rules as the app.
 */
import { readStorage, removeStorage, writeStorage } from "./storage";

export const PARENT_PIN_KEY = "rattil.parentLock.pin";
export const PARENT_AGE_KEY = "rattil.parentLock.age";

export const isValidPin = (pin: string): boolean => /^\d{4}$/.test(pin);

export async function hashPin(pin: string): Promise<string> {
  const data = new TextEncoder().encode(`rattil.parentLock.${pin}`);
  const digest = await crypto.subtle.digest("SHA-256", data);
  return Array.from(new Uint8Array(digest), (b) => b.toString(16).padStart(2, "0")).join("");
}

export const readPinHash = (): string | null => readStorage(PARENT_PIN_KEY);
export const savePinHash = (hash: string): boolean => writeStorage(PARENT_PIN_KEY, hash);
export const clearPinHash = (): void => removeStorage(PARENT_PIN_KEY);

export async function pinMatches(pin: string, stored: string | null): Promise<boolean> {
  return stored !== null && (await hashPin(pin)) === stored;
}

/** "Forgot the PIN?": 6..9 × 12..19, hard for a young child. */
export function parentChallenge(rand: () => number = Math.random): [number, number] {
  return [6 + Math.floor(rand() * 4), 12 + Math.floor(rand() * 8)];
}

/** Opened with the PIN until the tab is hidden or the page is left. */
let open = false;
export const isParentLockOpen = (): boolean => open;
export const setParentLockOpen = (v: boolean): void => {
  open = v;
};

/** Neutral age-group screen (owner 2026-11-20: «أقل من 13» / «13 أو أكثر»). Stored only in this browser. */
export type ParentAge = "adult" | "child";
export const readParentAge = (): ParentAge | null => {
  const v = readStorage(PARENT_AGE_KEY);
  return v === "adult" || v === "child" ? v : null;
};
export const saveParentAge = (v: ParentAge): boolean => writeStorage(PARENT_AGE_KEY, v);
