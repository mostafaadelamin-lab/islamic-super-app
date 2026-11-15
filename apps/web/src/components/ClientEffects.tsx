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
  syncThemeColor(root);
}

/**
 * The browser bar and the title bar of the installed app (Windows / Android PWA) take the chosen
 * style's colour (owner 2026-11-15), not the fixed default from the page head.
 */
export function syncThemeColor(root: HTMLElement = document.documentElement): void {
  const css = getComputedStyle(root);
  const dark =
    root.getAttribute("data-theme") === "dark" ||
    (root.getAttribute("data-theme") !== "light" &&
      window.matchMedia?.("(prefers-color-scheme: dark)").matches);
  const color = (css.getPropertyValue(dark ? "--color-bg" : "--color-primary") || "").trim();
  if (!color) return;
  const metas = [...document.querySelectorAll<HTMLMetaElement>('meta[name="theme-color"]')];
  const meta =
    metas[0] ??
    document.head.appendChild(Object.assign(document.createElement("meta"), { name: "theme-color" }));
  metas.slice(1).forEach((m) => m.remove());
  meta.removeAttribute("media");
  meta.content = color;
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
