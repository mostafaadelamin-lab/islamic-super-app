"use client";
import { useEffect, useRef, useSyncExternalStore } from "react";
import { t, type Locale } from "@/lib/i18n";
import { localizeDigits } from "@/lib/digits";
import { surahName } from "@/lib/pages";
import { audioStore, RECITERS, REPEAT_CHOICES } from "@/lib/audio";
import { player } from "@/lib/audio-player";
import { useStore } from "@/hooks/useStore";
import { Icon } from "./Icon";

const ERROR_KEYS = { offline: "audio.errOffline", network: "audio.errNetwork", blocked: "audio.errBlocked" };

/** Recitation controls, docked above the bottom tab bar while something is queued. */
export function PlayerBar({ locale }: { locale: Locale }) {
  const ps = useSyncExternalStore(player.subscribe, player.get, player.getServer);
  const prefs = useStore(audioStore);
  const barRef = useRef<HTMLElement>(null);
  const shown = ps.status !== "idle";
  // Docked sheets and the page's bottom padding sit above the player: publish its real height (it wraps on
  // narrow phones) as --player-h.
  useEffect(() => {
    const el = barRef.current;
    if (!shown || !el) return;
    const body = document.body;
    const publish = (): void => body.style.setProperty("--player-h", `${Math.ceil(el.offsetHeight)}px`);
    publish();
    const ro = typeof ResizeObserver === "undefined" ? null : new ResizeObserver(publish);
    ro?.observe(el);
    return () => {
      ro?.disconnect();
      body.style.removeProperty("--player-h");
    };
  }, [shown]);
  if (!shown) return null;
  const item = ps.queue[ps.cursor.index];
  const surah = item ? surahName(item.s, locale) : "";
  const label =
    item?.kind === "basmala"
      ? t(locale, "audio.basmala", { surah })
      : t(locale, "quran.ayahRef", { surah, ayah: localizeDigits(item?.a ?? 0, locale) });
  const playing = ps.status === "playing" || ps.status === "loading";
  return (
    <section ref={barRef} className="player" aria-label={t(locale, "audio.player")} data-testid="player">
      <div className="player-row">
        <div className="player-now">
          <strong data-testid="player-now">{label}</strong>
          <span className="muted small" data-testid="player-status">
            {ps.status === "loading" ? t(locale, "audio.loading") : t(locale, "audio.onlineOnly")}
          </span>
        </div>
        <div className="player-buttons">
          <button
            type="button"
            className="btn btn-icon"
            aria-label={t(locale, "audio.prev")}
            data-testid="player-prev"
            onClick={() => player.step(-1)}
          >
            <Icon name={locale === "ar" ? "next" : "prev"} />
          </button>
          <button
            type="button"
            className="btn btn-icon btn-primary btn-round"
            aria-label={playing ? t(locale, "audio.pause") : t(locale, "audio.play")}
            data-testid="player-toggle"
            data-state={ps.status}
            onClick={() => player.toggle()}
          >
            <Icon name={playing ? "pause" : "play"} />
          </button>
          <button
            type="button"
            className="btn btn-icon"
            aria-label={t(locale, "audio.next")}
            data-testid="player-next"
            onClick={() => player.step(1)}
          >
            <Icon name={locale === "ar" ? "prev" : "next"} />
          </button>
          <button
            type="button"
            className="btn btn-icon"
            aria-label={t(locale, "audio.stop")}
            data-testid="player-stop"
            onClick={() => player.stop()}
          >
            <Icon name="stop" />
          </button>
        </div>
      </div>
      <div className="player-row player-opts">
        <label className="inline-field">
          <span>{t(locale, "audio.reciter")}</span>
          <select
            value={prefs.reciter}
            data-testid="player-reciter"
            onChange={(e) => {
              const reciter = e.target.value;
              audioStore.set((p) => ({ ...p, reciter }));
              player.reciterChanged();
            }}
          >
            {RECITERS.map((r) => (
              <option key={r.folder} value={r.folder}>
                {locale === "ar" ? r.ar : r.en}
              </option>
            ))}
          </select>
        </label>
        <label className="inline-field">
          <span>{t(locale, "audio.repeat")}</span>
          <select
            value={prefs.repeat}
            data-testid="player-repeat"
            onChange={(e) => audioStore.set((p) => ({ ...p, repeat: Number(e.target.value) }))}
          >
            {REPEAT_CHOICES.map((n) => (
              <option key={n} value={n}>
                {t(locale, "audio.times", { n: localizeDigits(n, locale) })}
              </option>
            ))}
          </select>
        </label>
        <label className="inline-field player-check">
          <input
            type="checkbox"
            checked={prefs.tafsir}
            data-testid="player-tafsir"
            onChange={(e) => {
              const tafsir = e.target.checked;
              audioStore.set((p) => ({ ...p, tafsir }));
            }}
          />
          <span>{t(locale, "audio.withTafsir")}</span>
        </label>
      </div>
      {ps.status === "error" && ps.error ? (
        <p className="alert alert-error player-error" role="alert" data-testid="player-error">
          {t(locale, ERROR_KEYS[ps.error])}
        </p>
      ) : null}
    </section>
  );
}
