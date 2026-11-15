"use client";
import { useState, type FormEvent } from "react";
import { t, type Locale } from "@/lib/i18n";
import { localizeDigits } from "@/lib/digits";
import {
  addCustom,
  clearHistory,
  current,
  historyRows,
  MAX_CUSTOM,
  MAX_CUSTOM_TEXT,
  removeCustom,
  reset,
  setTarget,
  tap,
  tasbihStore,
  TASBIH_COLORS,
  TASBIH_MODES,
  TASBIH_PHRASES,
  TASBIH_TARGETS,
  undo,
  type TasbihState,
} from "@/lib/tasbih";
import { isoDate } from "@/lib/time";
import { useStore } from "@/hooks/useStore";
import { Icon } from "./Icon";

const VIBRATE_TAP = 15;
const [BUZZ_MS, GAP_MS] = [60, 40] as const;
const VIBRATE_ROUND = [BUZZ_MS, GAP_MS, BUZZ_MS];
const TURN = 2 * Math.PI;
const QUARTER_TURN = Math.PI / 2;
const RING_R = 88;
const RING_C = TURN * RING_R;
/** The bead under the thumb is drawn a little larger. */
const CURRENT_BEAD_GROW = 2;
const CENTER = 100;
/** Beads drawn on the strand (one full strand is 33). */
const STRAND_BEADS = 33;
const BEAD_R = 6;
const CLICK_HZ = 1400;
const CLICK_S = 0.03;
const CLICK_GAIN = 0.12;
const HISTORY_SHOWN = 30;

function vibrate(pattern: number | number[]): void {
  try {
    navigator.vibrate?.(pattern);
  } catch {
    // not supported
  }
}

/** A short wooden "click" made with WebAudio (no recording). */
function click(): void {
  try {
    const Ctx =
      window.AudioContext ??
      (window as unknown as { webkitAudioContext?: typeof AudioContext }).webkitAudioContext;
    if (!Ctx) return;
    const ctx = new Ctx();
    const o = ctx.createOscillator();
    const g = ctx.createGain();
    o.frequency.value = CLICK_HZ;
    g.gain.value = CLICK_GAIN;
    o.connect(g).connect(ctx.destination);
    o.start();
    o.stop(ctx.currentTime + CLICK_S);
  } catch {
    // audio unavailable
  }
}

const today = (): string => {
  const d = new Date();
  return isoDate({ year: d.getFullYear(), month: d.getMonth() + 1, day: d.getDate() });
};

/** Display text of a dhikr: the built-in wording (always Arabic) or the user's own text. */
export function phraseText(s: TasbihState, id: string): string {
  return s.custom.find((c) => c.id === id)?.text ?? t("ar", `tasbih.p.${id}`);
}

/** Tasbih counter: per-dhikr counters, two modes, colours, sound, the user's own adhkar and a daily history. */
export function TasbihView({ locale }: { locale: Locale }) {
  const s = useStore(tasbihStore);
  const [flash, setFlash] = useState(false);
  const [draft, setDraft] = useState("");
  const c = current(s);
  const progress = c.count / c.target;
  const color = TASBIH_COLORS[s.color] ?? TASBIH_COLORS.emerald;
  const todayCount = s.history[today()]?.[s.phrase] ?? 0;
  const onTap = (): void => {
    const r = tap(tasbihStore.get(), today());
    tasbihStore.set(r.next);
    if (s.vibrate) vibrate(r.completed ? VIBRATE_ROUND : VIBRATE_TAP);
    if (s.sound) click();
    setFlash(r.completed);
  };
  const onAdd = (e: FormEvent): void => {
    e.preventDefault();
    tasbihStore.set((p) => addCustom(p, draft));
    setDraft("");
  };
  const label = (id: string): string =>
    s.custom.some((x) => x.id === id) ? phraseText(s, id) : t(locale, `tasbih.p.${id}`);
  const strand = Math.min(c.target, STRAND_BEADS);
  const onStrand = c.count % strand;
  const rows = historyRows(s).slice(0, HISTORY_SHOWN);

  return (
    <div className="tasbih" style={{ ["--tasbih-color" as string]: color }} data-color={s.color}>
      <div className="field">
        <label htmlFor="tasbih-phrase">{t(locale, "tasbih.phrase")}</label>
        <select
          id="tasbih-phrase"
          value={s.phrase}
          onChange={(e) => tasbihStore.set((p) => ({ ...p, phrase: e.target.value }))}
        >
          {[...TASBIH_PHRASES, ...s.custom.map((x) => x.id)].map((id) => (
            <option key={id} value={id}>
              {label(id)}
            </option>
          ))}
        </select>
      </div>
      <p className="tasbih-phrase" lang={s.custom.some((x) => x.id === s.phrase) ? undefined : "ar"}>
        {phraseText(s, s.phrase)}
      </p>
      <div className="segmented" role="group" aria-label={t(locale, "tasbih.mode")}>
        {TASBIH_MODES.map((m) => (
          <button
            key={m}
            type="button"
            aria-pressed={s.mode === m}
            data-testid={`tasbih-mode-${m}`}
            onClick={() => tasbihStore.set((p) => ({ ...p, mode: m }))}
          >
            {t(locale, `tasbih.mode.${m}`)}
          </button>
        ))}
      </div>
      <button
        type="button"
        className={`${s.mode === "beads" ? "bead strand" : "bead"}${flash ? " round-done" : ""}`}
        data-testid="tasbih-tap"
        data-mode={s.mode}
        onClick={onTap}
        onAnimationEnd={() => setFlash(false)}
      >
        <span className="sr-only">
          {t(locale, "tasbih.tap", {
            n: localizeDigits(c.count, locale),
            target: localizeDigits(c.target, locale),
          })}
        </span>
        <svg viewBox="0 0 200 200" aria-hidden="true">
          {s.mode === "beads" ? (
            Array.from({ length: strand }, (_, i) => {
              const a = (TURN * i) / strand - QUARTER_TURN;
              return (
                <circle
                  key={i}
                  cx={CENTER + RING_R * Math.cos(a)}
                  cy={CENTER + RING_R * Math.sin(a)}
                  r={i === onStrand ? BEAD_R + CURRENT_BEAD_GROW : BEAD_R}
                  className={i < onStrand ? "strand-bead done" : "strand-bead"}
                />
              );
            })
          ) : (
            <>
              <circle cx={CENTER} cy={CENTER} r={RING_R} className="ring-bg" />
              <circle
                cx={CENTER}
                cy={CENTER}
                r={RING_R}
                className="ring-fg"
                strokeDasharray={RING_C}
                strokeDashoffset={RING_C * (1 - progress)}
                transform={`rotate(-90 ${CENTER} ${CENTER})`}
              />
            </>
          )}
        </svg>
        <span className="bead-count" data-testid="tasbih-count" aria-hidden="true">
          {localizeDigits(c.count, locale)}
        </span>
        <span className="bead-target" aria-hidden="true">
          / {localizeDigits(c.target, locale)}
        </span>
      </button>
      <p className="tasbih-rounds" data-testid="tasbih-rounds" role="status">
        {t(locale, "tasbih.rounds", { n: localizeDigits(c.rounds, locale) })}
      </p>
      <p className="muted" data-testid="tasbih-today">
        {t(locale, "tasbih.today", { n: localizeDigits(todayCount, locale) })}
      </p>
      <div className="row tasbih-actions">
        <button
          type="button"
          className="btn"
          data-testid="tasbih-undo"
          onClick={() => tasbihStore.set((p) => undo(p, today()))}
        >
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
              aria-pressed={c.target === n}
              data-testid={`tasbih-target-${n}`}
              onClick={() => tasbihStore.set((p) => setTarget(p, n))}
            >
              {localizeDigits(n, locale)}
            </button>
          ))}
        </div>
      </fieldset>

      <fieldset className="field">
        <legend className="label">{t(locale, "tasbih.color")}</legend>
        <div className="swatches">
          {Object.entries(TASBIH_COLORS).map(([id, hex]) => (
            <button
              key={id}
              type="button"
              className="swatch"
              style={{ background: hex }}
              aria-pressed={s.color === id}
              aria-label={t(locale, `tasbih.colors.${id}`)}
              title={t(locale, `tasbih.colors.${id}`)}
              data-testid={`tasbih-color-${id}`}
              onClick={() => tasbihStore.set((p) => ({ ...p, color: id }))}
            />
          ))}
        </div>
      </fieldset>
      <div className="row tasbih-actions">
        <label className="check">
          <input
            type="checkbox"
            checked={s.sound}
            onChange={(e) => tasbihStore.set((p) => ({ ...p, sound: e.target.checked }))}
            data-testid="tasbih-sound"
          />{" "}
          {t(locale, "tasbih.sound")}
        </label>
        <label className="check">
          <input
            type="checkbox"
            checked={s.vibrate}
            onChange={(e) => tasbihStore.set((p) => ({ ...p, vibrate: e.target.checked }))}
            data-testid="tasbih-vibrate"
          />{" "}
          {t(locale, "tasbih.vibrate")}
        </label>
      </div>

      <section className="card tasbih-section" aria-labelledby="tasbih-mine-h">
        <h2 id="tasbih-mine-h">{t(locale, "tasbih.mine")}</h2>
        <form className="row" onSubmit={onAdd}>
          <input
            type="text"
            value={draft}
            maxLength={MAX_CUSTOM_TEXT}
            onChange={(e) => setDraft(e.target.value)}
            aria-label={t(locale, "tasbih.newDhikr")}
            placeholder={t(locale, "tasbih.newDhikr")}
            data-testid="tasbih-new"
          />
          <button
            type="submit"
            className="btn"
            disabled={!draft.trim() || s.custom.length >= MAX_CUSTOM}
            data-testid="tasbih-add"
          >
            {t(locale, "tasbih.add")}
          </button>
        </form>
        {s.custom.length > 0 ? (
          <ul className="plain-list" data-testid="tasbih-custom-list">
            {s.custom.map((x) => (
              <li key={x.id} className="row">
                <span>{x.text}</span>
                <button
                  type="button"
                  className="btn-link btn-danger"
                  aria-label={t(locale, "tasbih.remove", { name: x.text })}
                  onClick={() => tasbihStore.set((p) => removeCustom(p, x.id))}
                >
                  {t(locale, "tasbih.delete")}
                </button>
              </li>
            ))}
          </ul>
        ) : null}
      </section>

      <section className="card tasbih-section" aria-labelledby="tasbih-history-h">
        <h2 id="tasbih-history-h">{t(locale, "tasbih.history")}</h2>
        {rows.length === 0 ? (
          <p className="muted">{t(locale, "tasbih.historyEmpty")}</p>
        ) : (
          <>
            <table className="times" data-testid="tasbih-history">
              <tbody>
                {rows.map((r) => (
                  <tr key={`${r.day}-${r.phrase}`}>
                    <td>{localizeDigits(r.day, locale)}</td>
                    <td>{label(r.phrase)}</td>
                    <td className="time">{localizeDigits(r.count, locale)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
            <button
              type="button"
              className="btn"
              data-testid="tasbih-clear-history"
              onClick={() => {
                if (window.confirm(t(locale, "tasbih.clearConfirm"))) tasbihStore.set(clearHistory);
              }}
            >
              {t(locale, "tasbih.clearHistory")}
            </button>
          </>
        )}
      </section>
    </div>
  );
}
