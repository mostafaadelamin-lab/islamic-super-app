"use client";
/**
 * One way back for the whole site (owner 2026-11-24: «رجوع» went to the home page instead of the page
 * before, and the phone's back did something else again).
 *
 * Every history entry of this site is stamped with how many site pages lie behind it (`rattilDepth`).
 * «رجوع» goes back in the browser history when there is a page of this site behind; only a page opened
 * from outside (a shared link, a new tab) falls back to the page above it, or home.
 *
 * Views opened inside a page (a reciter, a lesson series, a hadith level, an ayah panel…) are "layers":
 * each one adds a history entry, so «رجوع», the small back buttons and the phone's back button all close
 * the layer first and only then leave the page.
 */
import { useEffect, useId, useRef } from "react";

const DEPTH = "rattilDepth";
const LAYER = "rattilLayer";

type Stamped = Record<string, unknown> & { [DEPTH]?: number; [LAYER]?: string };

const state = (): Stamped | null => {
  const s: unknown = typeof window === "undefined" ? null : window.history.state;
  return s && typeof s === "object" ? (s as Stamped) : null;
};

/**
 * The current entry's state for a pushState / replaceState of our own: it keeps this file's stamps, and
 * leaves Next's marker out so Next copies its own back in and learns the new address.
 */
export function keptState(): Stamped {
  const rest: Stamped = { ...(state() ?? {}) };
  delete rest.__NA;
  return rest;
}

/** How many entries of this site lie behind the current one (0: opened from outside). */
export function backDepth(): number {
  const d = state()?.[DEPTH];
  if (typeof d === "number") return Math.max(d, 0);
  // Not stamped yet, but reached inside this tab after a stamped page: one deeper.
  return last >= 0 ? last + 1 : 0;
}

let last = -1;

function sameOriginReferrer(): boolean {
  try {
    return !!document.referrer && new URL(document.referrer).origin === window.location.origin;
  } catch {
    return false;
  }
}

/**
 * Stamps the current entry (called after every page change). A new entry is one deeper than the page
 * before; an entry met again (back / forward / reload) keeps its number.
 */
export function stampEntry(): void {
  const s = state();
  const d = s?.[DEPTH];
  if (typeof d === "number") {
    last = d;
    return;
  }
  // The first page of this tab: deeper only when it was opened from a page of this site
  // (a full page load, e.g. from the static privacy page or after an update).
  let next = last + 1;
  if (last < 0) next = sameOriginReferrer() ? 1 : 0;
  last = next;
  window.history.replaceState({ ...(s ?? {}), [DEPTH]: next }, "");
}

/** Keeps the depth known after the browser's own back / forward. */
export function onTraverse(): void {
  const d = state()?.[DEPTH];
  if (typeof d === "number") last = d;
}

/** A page-level handler for «رجوع» when nothing of this site is behind (e.g. /lessons#series opened
 *  from a link closes the series). Returns true when it handled it. */
let rootBack: (() => boolean) | null = null;
export function setRootBack(fn: (() => boolean) | null): void {
  rootBack = fn;
}

/** «رجوع»: the page before on this site; otherwise the page's own first step back, else [fallback]. */
export function goBack(fallback: () => void): void {
  if (backDepth() > 0) {
    window.history.back();
    return;
  }
  if (rootBack?.()) return;
  fallback();
}

/** Adds a history entry for a view opened inside the page; [url] changes the address too (a #hash). */
export function pushLayer(id: string, url?: string): void {
  window.history.pushState({ ...keptState(), [DEPTH]: backDepth() + 1, [LAYER]: id }, "", url);
  last = backDepth();
}

/**
 * Closes a view kept in the address (#…): back when [pushLayer] opened it, otherwise (opened from a link)
 * the address just loses its #. Returns false when no such view is open.
 */
export function closeHashLayer(id: string): boolean {
  if (!window.location.hash) return false;
  if (isLayer(id)) {
    window.history.back();
  } else {
    window.history.replaceState(keptState(), "", window.location.pathname + window.location.search);
    window.dispatchEvent(new HashChangeEvent("hashchange"));
  }
  return true;
}

/** True when the current entry is the one [pushLayer] added for [id]. */
export function isLayer(id?: string): boolean {
  const l = state()?.[LAYER];
  return id === undefined ? typeof l === "string" : l === id;
}

/**
 * A view inside a page that the back buttons close first: while [open] is true it owns a history entry.
 * Closing it from the page (its own button) removes that entry; the browser's or phone's back closes it.
 */
export function useBackLayer(open: boolean, close: () => void): void {
  const id = `layer${useId()}`;
  const closeRef = useRef(close);
  closeRef.current = close;
  const depth = useRef<number | null>(null);

  useEffect(() => {
    if (open && depth.current === null) {
      pushLayer(id);
      depth.current = backDepth();
    } else if (!open && depth.current !== null) {
      depth.current = null;
      if (isLayer(id)) window.history.back();
    }
  }, [open, id]);

  useEffect(() => {
    const onPop = (): void => {
      if (depth.current !== null && backDepth() < depth.current) {
        depth.current = null;
        closeRef.current();
      }
    };
    window.addEventListener("popstate", onPop);
    return () => window.removeEventListener("popstate", onPop);
  }, []);
}

/** After a reload the views inside a page are closed, so an entry left for one is dropped. */
export function dropStaleLayer(): void {
  const l = state()?.[LAYER];
  if (typeof l === "string" && l.startsWith("layer")) window.history.back();
}
