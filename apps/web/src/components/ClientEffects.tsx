"use client";
import { useEffect } from "react";
import type { Locale } from "@/lib/i18n";
import { prefsStore, type Preferences } from "@/lib/settings";
import { useStore } from "@/hooks/useStore";
import { registerServiceWorker } from "@/lib/sw-client";

export function applyPrefs(p: Preferences, root: HTMLElement = document.documentElement): void {
  if (p.theme === "system") root.removeAttribute("data-theme");
  else root.setAttribute("data-theme", p.theme);
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
  }, []);
  return null;
}
