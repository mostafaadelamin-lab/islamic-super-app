"use client";
import { useEffect, useRef, useState, useSyncExternalStore } from "react";
import { t, type Locale } from "@/lib/i18n";
import { localizeDigits } from "@/lib/digits";
import { audioStore, RECITERS, SURAH_COUNT, type QueueItem } from "@/lib/audio";
import { player } from "@/lib/audio-player";
import { SLEEP_CHOICES, sleepTimer } from "@/lib/sleep-timer";
import { surahMeta } from "@/lib/pages";
import { useStore } from "@/hooks/useStore";
import { createStore } from "@/lib/store";
import { LIVE_RADIOS, isHls, type LiveRadio } from "@/lib/live-radios";
import { Icon } from "./Icon";

/** The station the home radio plays (owner, 2026-11-14: Cairo Quran radio by default, as in the app). */
export const DEFAULT_STATION = "eg";
export const MUSHAF_STATION = "mushaf";
export const radioStationStore = createStore<string>("rattil.radioStation", DEFAULT_STATION, (raw) =>
  typeof raw === "string" && (raw === MUSHAF_STATION || LIVE_RADIOS.some((r) => r.id === raw))
    ? raw
    : DEFAULT_STATION,
);
/** Stations in the home card: the Cairo radio first, then the other live radios. */
export const HOME_STATIONS: readonly LiveRadio[] = [
  ...LIVE_RADIOS.filter((r) => r.id === DEFAULT_STATION),
  ...LIVE_RADIOS.filter((r) => r.id !== DEFAULT_STATION),
];

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
  const station = useStore(radioStationStore);
  const ps = useSyncExternalStore(player.subscribe, player.get, player.getServer);
  const sleep = useSyncExternalStore(sleepTimer.subscribe, sleepTimer.get, sleepTimer.getServer);
  const [chosen, setChosen] = useState(UNLIMITED);
  const live = station === MUSHAF_STATION ? null : (LIVE_RADIOS.find((r) => r.id === station) ?? null);

  // Live station: a sound-only <audio> (hls.js for the Holy Mosques' HLS streams outside Safari).
  const audioRef = useRef<HTMLAudioElement>(null);
  const hlsRef = useRef<{ destroy: () => void } | null>(null);
  const stopTimer = useRef<ReturnType<typeof setTimeout> | null>(null);
  const [liveState, setLiveState] = useState<"idle" | "loading" | "playing" | "error">("idle");

  const stopLive = (): void => {
    if (stopTimer.current) clearTimeout(stopTimer.current);
    stopTimer.current = null;
    hlsRef.current?.destroy();
    hlsRef.current = null;
    const el = audioRef.current;
    if (el) {
      el.pause();
      el.removeAttribute("src");
      el.load();
    }
    setLiveState("idle");
  };
  const armTimer = (n: number): void => {
    if (stopTimer.current) clearTimeout(stopTimer.current);
    stopTimer.current = n ? setTimeout(stopLive, n * 60_000) : null;
  };
  const startLive = async (r: LiveRadio): Promise<void> => {
    const el = audioRef.current;
    if (!el) return;
    player.stop(); // one voice at a time
    setLiveState("loading");
    try {
      if (isHls(r.url) && !el.canPlayType("application/vnd.apple.mpegurl")) {
        const { default: Hls } = await import("hls.js");
        if (!Hls.isSupported()) throw new Error("hls");
        const h = new Hls({ lowLatencyMode: false });
        hlsRef.current = h;
        h.on(Hls.Events.ERROR, (_e, data) => {
          if (data.fatal) setLiveState("error");
        });
        h.loadSource(r.url);
        h.attachMedia(el);
      } else {
        el.src = r.url;
      }
      await el.play();
      setLiveState("playing");
      armTimer(chosen);
    } catch {
      setLiveState("error");
    }
  };
  // The app's recitation player started (e.g. a surah): the live radio gives way.
  useEffect(() => {
    if (ps.status === "playing" && liveState !== "idle") stopLive();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [ps.status]);
  useEffect(() => () => stopLive(), []);

  const isRadio = radioQueue !== null && ps.queue === radioQueue;
  const liveOn = live !== null && (liveState === "playing" || liveState === "loading");
  const playing = live ? liveOn : isRadio && (ps.status === "playing" || ps.status === "loading");
  const minutes = !live && isRadio && sleep.minutes !== null ? sleep.minutes : chosen;
  const step = RADIO_DURATIONS.indexOf(minutes);
  const current = !live && isRadio ? player.current() : null;
  const meta = current ? surahMeta(current.s) : undefined;

  const setDuration = (delta: 1 | -1): void => {
    const i = Math.min(RADIO_DURATIONS.length - 1, Math.max(0, (step < 0 ? 0 : step) + delta));
    const n = RADIO_DURATIONS[i] ?? UNLIMITED;
    setChosen(n);
    if (live && liveOn) armTimer(n);
    else if (isRadio) sleepTimer.set(n || null);
  };

  const onPlay = (): void => {
    if (live) {
      if (liveOn) stopLive();
      else void startLive(live);
      return;
    }
    if (isRadio) {
      player.toggle();
      return;
    }
    player.play({ kind: "quran", from: randomSurah() });
    radioQueue = player.get().queue;
    sleepTimer.set(chosen || null);
  };

  const onStation = (id: string): void => {
    if (id === station) return;
    stopLive();
    if (isRadio) player.stop();
    radioStationStore.set(id);
  };

  const durationLabel =
    minutes === UNLIMITED
      ? t(locale, "radio.unlimited")
      : t(locale, "radio.min", { n: localizeDigits(minutes, locale) });

  let status: string;
  if (live) {
    const name = locale === "ar" ? live.ar : live.en;
    status =
      liveState === "error"
        ? t(locale, "radio.liveError")
        : liveOn
          ? `${t(locale, "library.nowPlaying")}: ${name} · ${t(locale, "library.live")}`
          : t(locale, "radio.liveNote");
  } else {
    status = meta
      ? t(locale, "radio.nowPlaying", { surah: locale === "ar" ? meta.nameAr : meta.translit })
      : t(locale, "radio.note");
  }

  return (
    <section className="card home-radio" aria-labelledby="radio-h" data-testid="quran-radio">
      <div className="radio-col radio-reciter">
        <h2 id="radio-h" className="radio-label">
          {t(locale, "radio.title")}
        </h2>
        <label className="radio-select">
          <span className="sr-only">{t(locale, "radio.station")}</span>
          <Icon name="headphones" size={20} />
          <select value={station} data-testid="radio-station" onChange={(e) => onStation(e.target.value)}>
            {HOME_STATIONS.map((r) => (
              <option key={r.id} value={r.id}>
                {locale === "ar" ? r.ar : r.en}
              </option>
            ))}
            <option value={MUSHAF_STATION}>{t(locale, "radio.mushaf")}</option>
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
      {live ? null : (
        <label className="radio-select radio-reciter-row">
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
      )}
      <p className="radio-status muted small" data-testid="radio-status" role="status">
        {status}
      </p>
      {}
      <audio
        ref={audioRef}
        preload="none"
        hidden
        data-testid="radio-live-audio"
        onPause={() => setLiveState((s) => (s === "playing" ? "idle" : s))}
      />
    </section>
  );
}
