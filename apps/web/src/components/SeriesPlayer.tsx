"use client";
import Link from "next/link";
import { useEffect, useRef, useState } from "react";
import { t, type Locale } from "@/lib/i18n";
import { href } from "@/lib/locale-path";
import { localizeDigits } from "@/lib/digits";
import { player } from "@/lib/audio-player";
import { minutes, type Episode, type Series } from "@/lib/stories";
import { claimMediaSession, mediaSessionState } from "@/lib/element-media-session";
import { Icon } from "./Icon";
import { SleepTimer } from "./SleepTimer";

const POS_KEY = "rattil.storyPos";

function readPositions(): Record<string, number> {
  try {
    const v = JSON.parse(localStorage.getItem(POS_KEY) ?? "{}") as unknown;
    return typeof v === "object" && v !== null ? (v as Record<string, number>) : {};
  } catch {
    return {};
  }
}
function savePosition(key: string, sec: number): void {
  try {
    const all = readPositions();
    if (sec > 5) all[key] = Math.floor(sec);
    else delete all[key];
    localStorage.setItem(POS_KEY, JSON.stringify(all));
  } catch {
    /* storage unavailable: resume is a convenience only */
  }
}

/** An audio-only narrated series: episode list and one native audio player (seek, resume, sleep timer). */
export function SeriesPlayer({ locale, series }: { locale: Locale; series: Series }) {
  const episodes = series.episodes;
  const [current, setCurrent] = useState<Episode | null>(null);
  const [error, setError] = useState(false);
  const audioRef = useRef<HTMLAudioElement>(null);
  const lastSave = useRef(0);
  const L = (x: { ar: string; en: string }): string => (locale === "ar" ? x.ar : x.en);
  const posKey = (e: Episode): string => `${series.id}/${e.id}`;

  useEffect(() => {
    const el = audioRef.current;
    if (!el || !current) return;
    setError(false);
    const resumeAt = readPositions()[posKey(current)];
    const onMeta = (): void => {
      if (resumeAt && resumeAt < (el.duration || Infinity) - 10) el.currentTime = resumeAt;
    };
    el.addEventListener("loadedmetadata", onMeta, { once: true });
    void el.play().catch(() => undefined); // the user pressed play; a refusal leaves the native controls
    return () => el.removeEventListener("loadedmetadata", onMeta);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [current?.id]);

  return (
    <section
      className="card series"
      aria-labelledby={`series-${series.id}`}
      data-testid={`series-${series.id}`}
    >
      <h2 className="card-title" id={`series-${series.id}`}>
        <Icon name="headphones" /> {L(series.title)} — {L(series.narrator)}
      </h2>
      {episodes.length === 0 ? (
        <p className="muted" data-testid="series-hidden">
          {t(locale, "stories.seriesHidden", { title: L(series.title), narrator: L(series.narrator) })}
        </p>
      ) : (
        <>
          <p className="muted small">
            {t(locale, "stories.episodes", { count: localizeDigits(episodes.length, locale) })} ·{" "}
            {t(locale, "stories.onlineOnly")}
          </p>
          {current ? (
            <div className="series-now" data-testid="series-now">
              <strong>
                {t(locale, "stories.nowPlaying")}: {L(current.title)}
              </strong>
              <audio
                ref={audioRef}
                src={current.url}
                controls
                preload="metadata"
                data-testid="series-audio"
                onTimeUpdate={(e) => {
                  const now = Date.now();
                  if (now - lastSave.current < 5000) return;
                  lastSave.current = now;
                  savePosition(posKey(current), e.currentTarget.currentTime);
                }}
                onPause={(e) => {
                  savePosition(posKey(current), e.currentTarget.currentTime);
                  mediaSessionState(false);
                }}
                onEnded={() => savePosition(posKey(current), 0)}
                onPlay={(e) => {
                  setError(false);
                  player.stop(); // one voice at a time
                  claimMediaSession(e.currentTarget, { title: L(current.title), artist: L(series.narrator) });
                  mediaSessionState(true);
                }}
                onError={() => setError(true)}
              />
              {error ? (
                <p className="alert alert-error" role="alert" data-testid="series-error">
                  {t(locale, "stories.episodeError")}
                </p>
              ) : null}
              <div className="row">
                <SleepTimer locale={locale} />
                {current.story ? (
                  <Link className="btn btn-sm" href={href(locale, `stories/${current.story}`)}>
                    {t(locale, "stories.readVerses")}
                  </Link>
                ) : null}
              </div>
            </div>
          ) : null}
          <ol className="episode-list">
            {episodes.map((e) => {
              const m = minutes(e.durationSec);
              const on = current?.id === e.id;
              return (
                <li key={e.id} data-episode={e.id} aria-current={on ? "true" : undefined}>
                  <button
                    type="button"
                    className="episode"
                    data-testid={`episode-${e.id}`}
                    onClick={() => setCurrent(e)}
                    aria-pressed={on}
                  >
                    <Icon name={on ? "pause" : "play"} />
                    <span className="tile-text">
                      <strong>{L(e.title)}</strong>
                      <span className="muted small">
                        {m ? t(locale, "stories.minutes", { n: localizeDigits(m, locale) }) : null}
                      </span>
                    </span>
                  </button>
                </li>
              );
            })}
          </ol>
        </>
      )}
      <p className="muted small">
        {t(locale, "stories.seriesSource", { source: series.source, licence: series.licence })}
      </p>
    </section>
  );
}
