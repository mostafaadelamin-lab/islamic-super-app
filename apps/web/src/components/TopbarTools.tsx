"use client";
import { useEffect, useState } from "react";
import { t, type Locale } from "@/lib/i18n";
import { PALETTES, prefsStore, type PalettePref } from "@/lib/settings";
import { tokens } from "@/generated/tokens";
import { useStore } from "@/hooks/useStore";
import { Icon } from "./Icon";
import { isIos, useInstall } from "./InstallApp";

const PALETTE_KEYS: Record<PalettePref, string> = {
  emerald: "settings.paletteEmerald",
  madinah: "settings.paletteMadinah",
};

const systemDark = (): boolean => window.matchMedia?.("(prefers-color-scheme: dark)").matches === true;

/**
 * Website top bar tools (owner 2026-11-15): the site style (two colour styles), light / dark,
 * and «ثبّت التطبيق» (the browser's install prompt; on iPhone the Add to Home Screen steps).
 */
export function TopbarTools({ locale }: { locale: Locale }) {
  const prefs = useStore(prefsStore);
  const { installed, canPrompt, install } = useInstall();
  const [dark, setDark] = useState(false);
  const [howTo, setHowTo] = useState<string | null>(null);
  useEffect(() => {
    setDark(prefs.theme === "dark" || (prefs.theme === "system" && systemDark()));
  }, [prefs.theme]);

  const onInstall = async (): Promise<void> => {
    if (canPrompt) {
      await install();
      return;
    }
    setHowTo(t(locale, isIos() ? "pwa.iosHowTo" : "pwa.howTo"));
  };

  return (
    <span className="topbar-tools" data-testid="topbar-tools">
      <span className="tb-group" role="group" aria-label={t(locale, "settings.palette")}>
        {PALETTES.map((id) => (
          <button
            key={id}
            type="button"
            className="tb-chip"
            aria-pressed={prefs.palette === id}
            data-testid={`topbar-palette-${id}`}
            onClick={() => prefsStore.set((p) => ({ ...p, palette: id }))}
          >
            <i
              className="tb-dot"
              aria-hidden="true"
              style={{
                background: `linear-gradient(90deg, ${tokens.palettes[id].brand.heroTop}, ${tokens.palettes[id].brand.gold})`,
              }}
            />
            {t(locale, PALETTE_KEYS[id])}
          </button>
        ))}
      </span>
      <button
        type="button"
        className="tb-chip"
        data-testid="topbar-theme"
        aria-pressed={dark}
        onClick={() => prefsStore.set((p) => ({ ...p, theme: dark ? "light" : "dark" }))}
      >
        <Icon name={dark ? "sun" : "moon"} size={14} />
        {t(locale, dark ? "settings.themeLight" : "settings.themeDark")}
      </button>
      {installed ? null : (
        <span className="tb-install">
          <button
            type="button"
            className="tb-chip tb-chip-gold"
            data-testid="topbar-install"
            onClick={() => void onInstall()}
          >
            <Icon name="download" size={14} />
            {t(locale, "pwa.installShort")}
          </button>
          {howTo ? (
            <span className="tb-howto" role="dialog" data-testid="topbar-install-howto">
              <span>{howTo}</span>
              <button type="button" className="btn btn-primary" onClick={() => setHowTo(null)}>
                {t(locale, "reader.hintClose")}
              </button>
            </span>
          ) : null}
        </span>
      )}
    </span>
  );
}
