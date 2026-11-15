"use client";
import { useEffect } from "react";
import type { Locale } from "@/lib/i18n";
import { DEFAULT_PALETTE, prefsStore, type Preferences } from "@/lib/settings";
import { useStore } from "@/hooks/useStore";
import { registerServiceWorker } from "@/lib/sw-client";
import { refreshAutoLocation } from "@/lib/auto-location";
import { installAudioFocus } from "@/lib/audio-focus";

export function applyPrefs(p: Preferences, root: HTMLElement = document.documentElement): void {
  if (p.theme === "system") root.removeAttribute("data-theme");
  else root.setAttribute("data-theme", p.theme);
  if (p.palette === DEFAULT_PALETTE) root.removeAttribute("data-palette");
  else root.setAttribute("data-palette", p.palette);
  root.style.setProperty("--quran-size", `${p.fontSize}px`);
}

/** Applies persisted preferences, remembers the current locale and registers the service worker. */
export function ClientEffects({ locale }: { locale: Locale }) {
  const prefs = useStore(prefsStore);
  useEffect(() => {
    applyPrefs(prefs);
  }, [prefs]);
  useEffect(() => {
    if (prefsStore.get().locale !== locale) prefsStore.set((p) => ({ ...p, locale }));
  }, [locale]);
  useEffect(() => {
    registerServiceWorker();
    void refreshAutoLocation(); // the app's "detect my location automatically"
    installAudioFocus(); // one sound at a time across the app
    // Marks the page as interactive (React has hydrated); used by e2e tests to
    // avoid interacting with server-rendered controls before handlers exist.
    document.documentElement.dataset.hydrated = "true";
  }, []);
  return null;
}
