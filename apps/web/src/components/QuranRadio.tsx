"use client";
import { useState, useSyncExternalStore } from "react";
import { t, type Locale } from "@/lib/i18n";
import { localizeDigits } from "@/lib/digits";
import { audioStore, RECITERS, SURAH_COUNT, type QueueItem } from "@/lib/audio";
import { player } from "@/lib/audio-player";
import { SLEEP_CHOICES, sleepTimer } from "@/lib/sleep-timer";
import { surahMeta } from "@/lib/pages";
import { useStore } from "@/hooks/useStore";
import { Icon } from "./Icon";

const UNLIMITED = 0;
/** Play-duration steps of the radio, in minutes: unlimited, then the sleep-timer choices. */
export const RADIO_DURATIONS: readonly number[] = [UNLIMITED, ...SLEEP_CHOICES];

/** The queue the radio started, so the card knows whether the shared player is playing the radio. */
let radioQueue: readonly QueueItem[] | null = null;

/** Random first surah of a radio session (1–114). */
export function randomSurah(rand: () => number = Math.random): number {
  return Math.min(SURAH_COUNT, Math.floor(rand() * SURAH_COUNT) + 1);
}

/**
 * Quran radio on the home page: continuous recitation of the whole Mushaf by the chosen reciter (streamed per
 * ayah from everyayah.com through the app's one player), with a play duration that stops it (sleep timer).
 */
export function QuranRadio({ locale }: { locale: Locale }) {
  const prefs = useStore(audioStore);
  const ps = useSyncExternalStore(player.subscribe, player.get, player.getServer);
  const sleep = useSyncExternalStore(sleepTimer.subscribe, sleepTimer.get, sleepTimer.getServer);
  const [chosen, setChosen] = useState(UNLIMITED);

  const isRadio = radioQueue !== null && ps.queue === radioQueue;
  const playing = isRadio && (ps.status === "playing" || ps.status === "loading");
  const minutes = isRadio && sleep.minutes !== null ? sleep.minutes : chosen;
  const step = RADIO_DURATIONS.indexOf(minutes);
  const current = isRadio ? player.current() : null;
  const meta = current ? surahMeta(current.s) : undefined;

  const setDuration = (delta: 1 | -1): void => {
    const i = Math.min(RADIO_DURATIONS.length - 1, Math.max(0, (step < 0 ? 0 : step) + delta));
    const n = RADIO_DURATIONS[i] ?? UNLIMITED;
    setChosen(n);
    if (isRadio) sleepTimer.set(n || null);
  };

  const onPlay = (): void => {
    if (isRadio) {
      player.toggle();
      return;
    }
    player.play({ kind: "quran", from: randomSurah() });
    radioQueue = player.get().queue;
    sleepTimer.set(chosen || null);
  };

  const durationLabel =
    minutes === UNLIMITED
      ? t(locale, "radio.unlimited")
      : t(locale, "radio.min", { n: localizeDigits(minutes, locale) });

  return (
    <section className="card home-radio" aria-labelledby="radio-h" data-testid="quran-radio">
      <div className="radio-col radio-reciter">
        <h2 id="radio-h" className="radio-label">
          {t(locale, "radio.title")}
        </h2>
        <label className="radio-select">
          <span className="sr-only">{t(locale, "audio.reciter")}</span>
          <Icon name="headphones" size={20} />
          <select
            value={prefs.reciter}
            data-testid="radio-reciter"
            onChange={(e) => {
              audioStore.set((p) => ({ ...p, reciter: e.target.value }));
              if (isRadio) player.reciterChanged();
            }}
          >
            {RECITERS.map((r) => (
              <option key={r.folder} value={r.folder}>
                {locale === "ar" ? r.ar : r.en}
              </option>
            ))}
          </select>
        </label>
      </div>
      <div className="radio-col radio-play">
        <span className="radio-label" aria-hidden="true">
          {t(locale, "radio.listen")}
        </span>
        <button
          type="button"
          className="radio-play-btn"
          onClick={onPlay}
          aria-label={playing ? t(locale, "audio.pause") : t(locale, "radio.listen")}
          aria-pressed={playing}
          data-testid="radio-play"
        >
          <Icon name={playing ? "pause" : "play"} size={26} />
        </button>
      </div>
      <div className="radio-col radio-duration">
        <span className="radio-label" id="radio-dur-l">
          {t(locale, "radio.duration")}
        </span>
        <div className="radio-stepper" role="group" aria-labelledby="radio-dur-l">
          <button
            type="button"
            onClick={() => setDuration(1)}
            aria-label={t(locale, "radio.longer")}
            disabled={step === RADIO_DURATIONS.length - 1}
            data-testid="radio-longer"
          >
            <Icon name="plus" size={18} />
          </button>
          <output data-testid="radio-duration" aria-live="polite">
            {durationLabel}
          </output>
          <button
            type="button"
            onClick={() => setDuration(-1)}
            aria-label={t(locale, "radio.shorter")}
            disabled={step <= 0}
            data-testid="radio-shorter"
          >
            <Icon name="minus" size={18} />
          </button>
        </div>
      </div>
      <p className="radio-status muted small" data-testid="radio-status">
        {meta
          ? t(locale, "radio.nowPlaying", { surah: locale === "ar" ? meta.nameAr : meta.translit })
          : t(locale, "radio.note")}
      </p>
    </section>
  );
}
