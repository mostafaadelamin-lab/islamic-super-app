"use client";
import { useState } from "react";
import { t, type Locale } from "@/lib/i18n";
import { localizeDigits } from "@/lib/digits";
import { reset, setTarget, tap, tasbihStore, TASBIH_PHRASES, TASBIH_TARGETS, undo } from "@/lib/tasbih";
import { useStore } from "@/hooks/useStore";
import { Icon } from "./Icon";

const VIBRATE_TAP = 15;
const VIBRATE_ROUND = [60, 40, 60];
const RING_R = 88;
const RING_C = 2 * Math.PI * RING_R;

function vibrate(pattern: number | number[]): void {
  try {
    navigator.vibrate?.(pattern);
  } catch {
    // not supported
  }
}

/** Tasbih counter: tap the bead, choose a target; count and rounds are kept on this device. */
export function TasbihView({ locale }: { locale: Locale }) {
  const s = useStore(tasbihStore);
  const [flash, setFlash] = useState(false);
  const progress = s.count / s.target;
  const onTap = (): void => {
    const r = tap(tasbihStore.get());
    tasbihStore.set(r.next);
    vibrate(r.completed ? VIBRATE_ROUND : VIBRATE_TAP);
    setFlash(r.completed);
  };
  return (
    <div className="tasbih">
      <div className="field">
        <label htmlFor="tasbih-phrase">{t(locale, "tasbih.phrase")}</label>
        <select
          id="tasbih-phrase"
          value={s.phrase}
          onChange={(e) => tasbihStore.set((p) => ({ ...p, phrase: e.target.value }))}
        >
          {TASBIH_PHRASES.map((p) => (
            <option key={p} value={p}>
              {t(locale, `tasbih.p.${p}`)}
            </option>
          ))}
        </select>
      </div>
      <p className="tasbih-phrase" lang="ar">
        {t("ar", `tasbih.p.${s.phrase}`)}
      </p>
      <button
        type="button"
        className={flash ? "bead round-done" : "bead"}
        data-testid="tasbih-tap"
        onClick={onTap}
        onAnimationEnd={() => setFlash(false)}
      >
        <span className="sr-only">
          {t(locale, "tasbih.tap", {
            n: localizeDigits(s.count, locale),
            target: localizeDigits(s.target, locale),
          })}
        </span>
        <svg viewBox="0 0 200 200" aria-hidden="true">
          <circle cx="100" cy="100" r={RING_R} className="ring-bg" />
          <circle
            cx="100"
            cy="100"
            r={RING_R}
            className="ring-fg"
            strokeDasharray={RING_C}
            strokeDashoffset={RING_C * (1 - progress)}
            transform="rotate(-90 100 100)"
          />
        </svg>
        <span className="bead-count" data-testid="tasbih-count" aria-hidden="true">
          {localizeDigits(s.count, locale)}
        </span>
        <span className="bead-target" aria-hidden="true">
          / {localizeDigits(s.target, locale)}
        </span>
      </button>
      <p className="tasbih-rounds" data-testid="tasbih-rounds" role="status">
        {t(locale, "tasbih.rounds", { n: localizeDigits(s.rounds, locale) })}
      </p>
      <div className="row tasbih-actions">
        <button type="button" className="btn" data-testid="tasbih-undo" onClick={() => tasbihStore.set(undo)}>
          <Icon name="undo" size={18} /> {t(locale, "tasbih.undo")}
        </button>
        <button
          type="button"
          className="btn"
          data-testid="tasbih-reset"
          onClick={() => tasbihStore.set(reset)}
        >
          <Icon name="reset" size={18} /> {t(locale, "tasbih.reset")}
        </button>
      </div>
      <fieldset className="field targets">
        <legend className="label">{t(locale, "tasbih.target")}</legend>
        <div className="segmented">
          {TASBIH_TARGETS.map((n) => (
            <button
              key={n}
              type="button"
              aria-pressed={s.target === n}
              data-testid={`tasbih-target-${n}`}
              onClick={() => tasbihStore.set((p) => setTarget(p, n))}
            >
              {localizeDigits(n, locale)}
            </button>
          ))}
        </div>
      </fieldset>
    </div>
  );
}
