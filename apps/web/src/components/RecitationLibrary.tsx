"use client";
import { useEffect, useRef, useState } from "react";
import { createPortal } from "react-dom";
import { t, type Locale } from "@/lib/i18n";
import { localizeDigits } from "@/lib/digits";
import { pauseOthers } from "@/lib/audio-focus";
import { normalizeArabic } from "@/lib/search";
import { SURAHS } from "@/lib/pages";
import {
  apiLanguage,
  filterRadios,
  filterReciters,
  loadLibrary,
  surahUrl,
  type Library,
  type Reciter,
} from "@/lib/mp3quran";
import { claimMediaSession, mediaSessionState } from "@/lib/element-media-session";
import { LIVE_RADIOS, isHls } from "@/lib/live-radios";
import { Icon } from "./Icon";
import { SleepTimer } from "./SleepTimer";

export interface Track {
  key: string;
  title: string;
  url: string;
  live: boolean;
  /** The reciter's surahs in order: when one ends the next one plays (owner, 2026-11-12). */
  playlist?: Track[];
}

/** The track after (or before) `track` in its list. */
export function stepTrack(track: Track, delta: 1 | -1): Track | null {
  const list = track.playlist ?? [];
  const i = list.findIndex((x) => x.key === track.key);
  return i < 0 ? null : (list[i + delta] ?? null);
}

type Tab = "reciters" | "radios";

function clock(sec: number, locale: Locale): string {
  const v = Math.max(0, Math.floor(Number.isFinite(sec) ? sec : 0));
  return localizeDigits(`${Math.floor(v / 60)}:${String(v % 60).padStart(2, "0")}`, locale);
}

/**
 * The player for the chosen surah or radio (one sound at a time). One hidden <audio> element plays (it stays
 * mounted, so going on to the next surah keeps working in the background); its buttons are shown in `slot`,
 * the row of the item playing (owner 2026-11-15: not at the top of the page), or at the top when that row is
 * not on screen (e.g. back on the reciters list).
 */
export function NowPlaying({
  locale,
  track,
  onTrack,
  slot = null,
}: {
  locale: Locale;
  track: Track;
  onTrack: (t: Track) => void;
  slot?: HTMLElement | null;
}) {
  const ref = useRef<HTMLAudioElement>(null);
  const [error, setError] = useState(false);
  const [playing, setPlaying] = useState(false);
  const [position, setPosition] = useState(0);
  const [duration, setDuration] = useState(0);
  useEffect(() => {
    setError(false);
    setPosition(0);
    setDuration(0);
    const el = ref.current;
    if (!el) return;
    let cancelled = false;
    let hls: { destroy: () => void } | null = null;
    // The user pressed play; a refusal (autoplay policy) leaves the play button.
    (async (): Promise<void> => {
      try {
        // Live HLS (the Holy Mosques): native in Safari; elsewhere hls.js feeds the <audio>, sound only.
        if (isHls(track.url) && !el.canPlayType("application/vnd.apple.mpegurl")) {
          const { default: Hls } = await import("hls.js");
          if (cancelled) return;
          if (!Hls.isSupported()) {
            setError(true);
            return;
          }
          const h = new Hls({ lowLatencyMode: false });
          hls = h;
          h.on(Hls.Events.ERROR, (_e, data) => {
            if (data.fatal) setError(true);
          });
          h.loadSource(track.url);
          h.attachMedia(el);
        } else {
          el.src = track.url;
        }
        await el.play();
      } catch {
        /* see above */
      }
    })();
    return () => {
      cancelled = true;
      hls?.destroy();
    };
  }, [track.key, track.url]);
  // Keep the playing item and its buttons in view.
  useEffect(() => {
    slot?.scrollIntoView?.({ block: "nearest", behavior: "smooth" });
  }, [slot]);

  const next = stepTrack(track, 1);
  const prev = stepTrack(track, -1);
  const toggle = (): void => {
    const el = ref.current;
    if (!el) return;
    if (el.paused) void Promise.resolve(el.play()).catch(() => undefined);
    else el.pause();
  };
  const seekable = !track.live && duration > 0;
  const controls = (
    <div
      className="nasheed-now"
      role="group"
      aria-label={t(locale, "audio.player")}
      data-testid="library-now"
    >
      {slot ? (
        <span className="sr-only">
          {t(locale, "library.nowPlaying")}: {track.title}
        </span>
      ) : null}
      <div className="nasheed-now-row">
        {track.playlist ? (
          <button
            type="button"
            className="btn btn-sm btn-icon"
            aria-label={t(locale, "nasheeds.prev")}
            data-testid="library-prev"
            disabled={!prev}
            onClick={() => prev && onTrack(prev)}
          >
            <Icon name={locale === "ar" ? "next" : "prev"} size={18} />
          </button>
        ) : null}
        <button
          type="button"
          className="btn btn-primary btn-icon nasheed-play"
          aria-label={playing ? t(locale, "audio.pause") : t(locale, "audio.play")}
          data-testid="library-toggle"
          onClick={toggle}
        >
          <Icon name={playing ? "pause" : "play"} size={22} />
        </button>
        {track.playlist ? (
          <button
            type="button"
            className="btn btn-sm btn-icon"
            aria-label={t(locale, "nasheeds.next")}
            data-testid="library-next"
            disabled={!next}
            onClick={() => next && onTrack(next)}
          >
            <Icon name={locale === "ar" ? "prev" : "next"} size={18} />
          </button>
        ) : null}
        {seekable ? (
          <>
            <span className="small nasheed-time">{clock(position, locale)}</span>
            <input
              type="range"
              min={0}
              max={Math.max(1, Math.round(duration))}
              value={Math.round(position)}
              aria-label={t(locale, "dhikr.seek")}
              data-testid="library-seek"
              onChange={(e) => {
                if (ref.current) ref.current.currentTime = Number(e.target.value);
              }}
            />
            <span className="small nasheed-time">{clock(duration, locale)}</span>
          </>
        ) : track.live ? (
          <span className="small muted">{t(locale, "library.live")}</span>
        ) : null}
      </div>
      {error ? (
        <p className="alert alert-error" role="alert" data-testid="library-play-error">
          {t(locale, "library.playError")}
        </p>
      ) : null}
      <SleepTimer locale={locale} />
    </div>
  );
  return (
    <>
      <audio
        ref={ref}
        preload="none"
        hidden
        data-testid="library-audio"
        onPlay={(e) => {
          setError(false);
          setPlaying(true);
          pauseOthers(e.currentTarget); // one sound at a time
          claimMediaSession(e.currentTarget, {
            title: track.title,
            next: next ? () => onTrack(next) : undefined,
            previous: prev ? () => onTrack(prev) : undefined,
          });
          mediaSessionState(true);
        }}
        onPause={() => {
          setPlaying(false);
          mediaSessionState(false);
        }}
        onTimeUpdate={(e) => setPosition(e.currentTarget.currentTime)}
        onDurationChange={(e) => {
          const d = e.currentTarget.duration;
          setDuration(Number.isFinite(d) ? d : 0);
        }}
        onEnded={() => {
          setPlaying(false);
          if (next) onTrack(next);
        }}
        onError={() => setError(true)}
      />
      {slot ? (
        createPortal(controls, slot)
      ) : (
        <section className="card series-now nasheed-now-top" data-testid="library-now-top">
          <strong>
            {t(locale, "library.nowPlaying")}: {track.title}
            {track.live ? ` · ${t(locale, "library.live")}` : ""}
          </strong>
          {controls}
        </section>
      )}
    </>
  );
}

/** Where the player's buttons go: under the row of the item playing. */
export function PlayerSlot({ onSlot }: { onSlot: (el: HTMLElement | null) => void }) {
  return <div className="nasheed-slot" ref={onSlot} data-testid="library-slot" />;
}

function ReciterView({
  locale,
  reciter,
  rewaya,
  current,
  onPlay,
  onBack,
  onSlot,
}: {
  locale: Locale;
  reciter: Reciter;
  rewaya: number | null;
  current: string | null;
  onPlay: (t: Track) => void;
  onBack: () => void;
  onSlot: (el: HTMLElement | null) => void;
}) {
  const first = reciter.moshafs.find((m) => m.rewayaId === rewaya) ?? reciter.moshafs[0]!;
  const [moshafId, setMoshafId] = useState(first.id);
  const moshaf = reciter.moshafs.find((m) => m.id === moshafId) ?? first;
  const tracks: Track[] = moshaf.surahs.map((n) => {
    const s = SURAHS[n - 1]!;
    const name = locale === "ar" ? s.nameAr : s.translit;
    return {
      key: `${moshaf.id}:${n}`,
      url: surahUrl(moshaf, n),
      live: false,
      title: t(locale, "library.surahTitle", { reciter: reciter.name, surah: name }),
    };
  });
  tracks.forEach((x) => (x.playlist = tracks));
  return (
    <section className="card" data-testid="library-reciter" aria-labelledby="library-reciter-h">
      <p>
        <button type="button" className="btn btn-sm" onClick={onBack} data-testid="library-back">
          {t(locale, "library.back")}
        </button>
      </p>
      <h2 className="card-title" id="library-reciter-h">
        {reciter.name}
      </h2>
      <label className="field">
        <span>{t(locale, "library.rewaya")}</span>
        <select
          value={moshaf.id}
          onChange={(e) => setMoshafId(Number(e.target.value))}
          data-testid="library-moshaf"
        >
          {reciter.moshafs.map((m) => (
            <option key={m.id} value={m.id}>
              {m.name}
            </option>
          ))}
        </select>
      </label>
      <p className="muted small">
        {t(locale, "library.surahCount", { n: localizeDigits(moshaf.surahs.length, locale) })}
      </p>
      <ol className="episode-list">
        {moshaf.surahs.map((n, i) => {
          const s = SURAHS[n - 1]!;
          const name = locale === "ar" ? s.nameAr : s.translit;
          const key = `${moshaf.id}:${n}`;
          const on = current === key;
          return (
            <li key={n}>
              <button
                type="button"
                className="episode"
                aria-pressed={on}
                data-testid={`library-surah-${n}`}
                onClick={() => onPlay(tracks[i]!)}
              >
                <Icon name={on ? "pause" : "play"} />
                <span className="tile-text">
                  <strong>
                    {localizeDigits(n, locale)}. {name}
                  </strong>
                </span>
              </button>
              {on ? <PlayerSlot onSlot={onSlot} /> : null}
            </li>
          );
        })}
      </ol>
    </section>
  );
}

/** mp3quran.net reciters (every riwaya) and Quran radios, streamed. */
export function RecitationLibrary({ locale }: { locale: Locale }) {
  const [lib, setLib] = useState<Library | null>(null);
  const [failed, setFailed] = useState(false);
  const [tab, setTab] = useState<Tab>("reciters");
  const [query, setQuery] = useState("");
  const [rewaya, setRewaya] = useState<number | null>(null);
  const [reciter, setReciter] = useState<Reciter | null>(null);
  const [track, setTrack] = useState<Track | null>(null);
  const [slot, setSlot] = useState<HTMLElement | null>(null);

  const load = async (refresh: boolean): Promise<void> => {
    setFailed(false);
    try {
      setLib(await loadLibrary(apiLanguage(locale), { refresh }));
    } catch {
      setFailed(true);
    }
  };
  // eslint-disable-next-line react-hooks/exhaustive-deps
  useEffect(() => void load(false), [locale]);

  const source = (
    <p className="muted small" data-testid="library-source">
      {t(locale, "library.source")}
    </p>
  );

  if (failed) {
    return (
      <div className="card">
        <p className="alert alert-error" role="alert" data-testid="library-error">
          {t(locale, "library.loadError")}
        </p>
        <button type="button" className="btn" onClick={() => void load(true)} data-testid="library-retry">
          {t(locale, "library.retry")}
        </button>
      </div>
    );
  }
  if (!lib) return <p className="muted">{t(locale, "common.loading")}</p>;

  const reciters = filterReciters(lib, query, rewaya, normalizeArabic);
  const radios = filterRadios(lib, query, normalizeArabic);
  return (
    <>
      {track ? <NowPlaying locale={locale} track={track} onTrack={setTrack} slot={slot} /> : null}
      {reciter ? (
        <ReciterView
          key={reciter.id}
          locale={locale}
          reciter={reciter}
          rewaya={rewaya}
          current={track?.key ?? null}
          onPlay={setTrack}
          onBack={() => setReciter(null)}
          onSlot={setSlot}
        />
      ) : (
        <section className="card">
          <div className="row" role="tablist">
            {(["reciters", "radios"] as const).map((id) => (
              <button
                key={id}
                type="button"
                role="tab"
                aria-selected={tab === id}
                className={tab === id ? "btn btn-primary" : "btn"}
                onClick={() => setTab(id)}
                data-testid={`library-tab-${id}`}
              >
                {t(locale, `library.${id}`)}
              </button>
            ))}
          </div>
          <label className="field">
            <span>{t(locale, "library.search")}</span>
            <input
              type="search"
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              data-testid="library-search"
            />
          </label>
          {tab === "reciters" ? (
            <>
              <label className="field">
                <span>{t(locale, "library.rewaya")}</span>
                <select
                  value={rewaya ?? ""}
                  onChange={(e) => setRewaya(e.target.value ? Number(e.target.value) : null)}
                  data-testid="library-rewaya"
                >
                  <option value="">{t(locale, "library.allRiwayat")}</option>
                  {lib.riwayat.map((w) => (
                    <option key={w.id} value={w.id}>
                      {w.name}
                    </option>
                  ))}
                </select>
              </label>
              {reciters.length === 0 ? <p className="muted">{t(locale, "library.empty")}</p> : null}
              <ul className="episode-list" data-testid="library-reciters">
                {reciters.map((r) => (
                  <li key={r.id}>
                    <button
                      type="button"
                      className="episode"
                      onClick={() => setReciter(r)}
                      data-testid={`library-reciter-${r.id}`}
                    >
                      <Icon name="headphones" />
                      <span className="tile-text">
                        <strong>{r.name}</strong>
                        <span className="muted small">
                          {r.moshafs
                            .filter((m) => rewaya === null || m.rewayaId === rewaya)
                            .map((m) => m.name)
                            .join(" · ")}
                        </span>
                      </span>
                    </button>
                  </li>
                ))}
              </ul>
            </>
          ) : (
            <>
              <h3 className="small">{t(locale, "library.liveRadios")}</h3>
              <ul className="episode-list" data-testid="library-live-radios">
                {LIVE_RADIOS.map((r) => {
                  const key = `live:${r.id}`;
                  const title = locale === "ar" ? r.ar : r.en;
                  return (
                    <li key={r.id}>
                      <button
                        type="button"
                        className="episode"
                        aria-pressed={track?.key === key}
                        onClick={() => setTrack({ key, url: r.url, live: true, title })}
                        data-testid={`library-live-${r.id}`}
                      >
                        <Icon name={track?.key === key ? "pause" : "play"} />
                        <span className="tile-text">
                          <strong>{title}</strong>
                          <span className="muted small">{t(locale, "library.live")}</span>
                        </span>
                      </button>
                      {track?.key === key ? <PlayerSlot onSlot={setSlot} /> : null}
                    </li>
                  );
                })}
              </ul>
              <h3 className="small">{t(locale, "library.moreRadios")}</h3>
              {radios.length === 0 ? <p className="muted">{t(locale, "library.empty")}</p> : null}
              <ul className="episode-list" data-testid="library-radios">
                {radios.map((r) => {
                  const key = `radio:${r.id}`;
                  return (
                    <li key={r.id}>
                      <button
                        type="button"
                        className="episode"
                        aria-pressed={track?.key === key}
                        onClick={() => setTrack({ key, url: r.url, live: true, title: r.name })}
                        data-testid={`library-radio-${r.id}`}
                      >
                        <Icon name={track?.key === key ? "pause" : "play"} />
                        <span className="tile-text">
                          <strong>{r.name}</strong>
                          <span className="muted small">{t(locale, "library.live")}</span>
                        </span>
                      </button>
                      {track?.key === key ? <PlayerSlot onSlot={setSlot} /> : null}
                    </li>
                  );
                })}
              </ul>
            </>
          )}
        </section>
      )}
      {source}
    </>
  );
}
