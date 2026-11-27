"use client";
import { useEffect, useState } from "react";
import { createPortal } from "react-dom";
import { t, type Locale } from "@/lib/i18n";
import { ADHKAR_BGS, SCALE_MAX, SCALE_MIN, adhkarLookStore, dhikrShown } from "@/lib/adhkar-look";
import { adhkarViewStore } from "@/lib/dhikr-share";
import { useStore } from "@/hooks/useStore";
import { Icon } from "./Icon";

/** Paints the chosen background behind an adhkar page and sets the dhikr text size (owner 2026-11-27). */
export function AdhkarLookFrame({ children }: { children: React.ReactNode }) {
  const look = useStore(adhkarLookStore);
  return (
    <div
      className={look.bg ? `adhkar-look bg-${look.bg}` : "adhkar-look"}
      data-testid={look.bg ? `adhkar-bg-${look.bg}` : undefined}
      style={{ "--dhikr-scale": String(look.scale) } as React.CSSProperties}
    >
      {children}
    </div>
  );
}

/** The dhikr text as the reader chose to see it (tashkeel on/off, display only). */
export function DhikrText({ text, className = "dhikr-text" }: { text: string; className?: string }) {
  const { tashkeel } = useStore(adhkarLookStore);
  return (
    <p className={className} lang="ar" dir="rtl">
      {dhikrShown(text, tashkeel)}
    </p>
  );
}

/** «إعدادات الأذكار»: the view, the background, tashkeel and the text size. */
export function AdhkarSettings({
  locale,
  open,
  onClose,
  view = true,
}: {
  locale: Locale;
  open: boolean;
  onClose: () => void;
  view?: boolean;
}) {
  const look = useStore(adhkarLookStore);
  const { mode } = useStore(adhkarViewStore);
  useEffect(() => {
    if (!open) return;
    const esc = (e: KeyboardEvent): void => {
      if (e.key === "Escape") onClose();
    };
    window.addEventListener("keydown", esc);
    return () => window.removeEventListener("keydown", esc);
  }, [open, onClose]);
  if (!open) return null;
  // Outside the page's chosen background: the sheet keeps the site's own colours.
  return createPortal(
    <div className="sheet-backdrop" onClick={onClose}>
      <section
        className="sheet adhkar-settings"
        role="dialog"
        aria-modal="true"
        aria-label={t(locale, "adhkar.settingsTitle")}
        data-testid="adhkar-settings"
        onClick={(e) => e.stopPropagation()}
      >
        <header className="row" style={{ justifyContent: "space-between" }}>
          <h2>{t(locale, "adhkar.settingsTitle")}</h2>
          <button
            type="button"
            className="btn btn-sm"
            aria-label={t(locale, "adhkar.mineCancel")}
            data-testid="adhkar-settings-close"
            onClick={onClose}
          >
            <Icon name="close" size={18} />
          </button>
        </header>
        {view ? (
          <>
            <h3>{t(locale, "adhkar.settingsView")}</h3>
            <div className="segmented" role="group">
              {(["cards", "list"] as const).map((m) => (
                <button
                  key={m}
                  type="button"
                  aria-pressed={mode === m}
                  data-testid={`adhkar-settings-${m}`}
                  onClick={() => adhkarViewStore.set(() => ({ mode: m }))}
                >
                  {t(locale, m === "cards" ? "dhikr.view.cards" : "dhikr.view.list")}
                </button>
              ))}
            </div>
          </>
        ) : null}
        <h3>{t(locale, "adhkar.settingsBg")}</h3>
        <div className="bg-picks">
          {ADHKAR_BGS.map((b) => (
            <button
              key={b || "app"}
              type="button"
              className={`bg-pick${look.bg === b ? " on" : ""}`}
              aria-pressed={look.bg === b}
              data-testid={`adhkar-bg-pick-${b || "app"}`}
              onClick={() => adhkarLookStore.set((l) => ({ ...l, bg: b }))}
            >
              <span className={`swatch bg-${b || "app"}`} />
              <span className="small">{t(locale, `adhkar.bg.${b || "app"}`)}</span>
            </button>
          ))}
        </div>
        <label className="row" style={{ justifyContent: "space-between", marginTop: "0.75rem" }}>
          <span>
            <strong>{t(locale, "adhkar.settingsTashkeel")}</strong>
            <br />
            <span className="muted small">{t(locale, "adhkar.settingsTashkeelHint")}</span>
          </span>
          <input
            type="checkbox"
            role="switch"
            data-testid="adhkar-settings-tashkeel"
            checked={look.tashkeel}
            onChange={(e) => adhkarLookStore.set((l) => ({ ...l, tashkeel: e.target.checked }))}
          />
        </label>
        <h3>{t(locale, "adhkar.settingsSize")}</h3>
        <div className="row size-row">
          <span aria-hidden="true">أ</span>
          <input
            type="range"
            min={SCALE_MIN}
            max={SCALE_MAX}
            step={0.1}
            value={look.scale}
            aria-label={t(locale, "adhkar.settingsSize")}
            data-testid="adhkar-settings-scale"
            onChange={(e) => adhkarLookStore.set((l) => ({ ...l, scale: Number(e.target.value) }))}
          />
          <span aria-hidden="true" style={{ fontSize: "1.6em" }}>
            أ
          </span>
        </div>
      </section>
    </div>,
    document.body,
  );
}

/** The ⚙ that opens «إعدادات الأذكار». */
export function AdhkarSettingsButton({
  locale,
  view = true,
  tile = false,
}: {
  locale: Locale;
  view?: boolean;
  tile?: boolean;
}) {
  const [open, setOpen] = useState(false);
  return (
    <>
      <button
        type="button"
        className={tile ? "tool-tile navy" : "btn btn-sm"}
        data-testid="adhkar-settings-open"
        title={t(locale, "adhkar.settingsTitle")}
        aria-label={tile ? undefined : t(locale, "adhkar.settingsTitle")}
        onClick={() => setOpen(true)}
      >
        <Icon name="settings" size={tile ? 22 : 18} />
        {tile ? <span>{t(locale, "adhkar.barSettings")}</span> : null}
      </button>
      <AdhkarSettings locale={locale} open={open} onClose={() => setOpen(false)} view={view} />
    </>
  );
}

/**
 * Owner 2026-11-27 (option 1): after the last dhikr, a full screen with a crescent and gold stars falling,
 * a strong vibration and no sound; «رجوع» or «من جديد».
 */
export function Celebration({
  locale,
  subtitle,
  onBack,
  onAgain,
}: {
  locale: Locale;
  subtitle: string;
  onBack: () => void;
  onAgain: () => void;
}) {
  useEffect(() => {
    try {
      navigator.vibrate?.([300, 120, 300, 120, 500]);
    } catch {
      /* no vibration on this device */
    }
    const esc = (e: KeyboardEvent): void => {
      if (e.key === "Escape") onBack();
    };
    window.addEventListener("keydown", esc);
    return () => window.removeEventListener("keydown", esc);
  }, [onBack]);
  const stars = Array.from({ length: 26 }, (_, i) => {
    const r = (k: number): number => ((Math.sin(i * 97.13 + k * 13.7) + 1) / 2) % 1;
    return { left: r(1) * 100, size: 10 + r(2) * 18, dur: 2.6 + r(3) * 3, delay: -r(4) * 5 };
  });
  return (
    <div className="celebration" role="dialog" aria-modal="true" data-testid="adhkar-celebration">
      {stars.map((s, i) => (
        <span
          key={i}
          className="celebration-star"
          aria-hidden="true"
          style={{
            left: `${s.left}%`,
            fontSize: `${s.size}px`,
            animationDuration: `${s.dur}s`,
            animationDelay: `${s.delay}s`,
          }}
        >
          ✦
        </span>
      ))}
      <div className="celebration-body">
        <span className="celebration-moon" aria-hidden="true" />
        <h2>{t(locale, "adhkar.doneTitle")}</h2>
        <p>{subtitle} ✓</p>
        <p className="row" style={{ justifyContent: "center" }}>
          <button
            type="button"
            className="btn celebration-back"
            data-testid="celebration-back"
            onClick={onBack}
          >
            {t(locale, "adhkar.doneBack")}
          </button>
          <button
            type="button"
            className="btn celebration-again"
            data-testid="celebration-again"
            onClick={onAgain}
          >
            <Icon name="reset" size={16} /> {t(locale, "adhkar.doneAgain")}
          </button>
        </p>
      </div>
    </div>
  );
}
