"use client";
import { useState, type ReactNode } from "react";
import { t, type Locale } from "@/lib/i18n";
import {
  addToHistory,
  embedVideoUrl,
  searchVideos,
  thumbUrl,
  videoHistoryStore,
  watchUrl,
  type VideoHit,
} from "@/lib/videos";
import { useStore } from "@/hooks/useStore";
import { Icon } from "./Icon";
import { useBackLayer } from "@/lib/back-nav";

/**
 * Search box over the videos page: Islamic videos only (trusted channels first; see netlify/lib/videos-core.mjs).
 * The viewer's searches are remembered in this browser; with no search the trusted channels' feed shows.
 */
export function VideoSearch({
  locale,
  children,
  fetchImpl,
}: {
  locale: Locale;
  children: ReactNode;
  /** Replaced in tests. */
  fetchImpl?: typeof fetch;
}) {
  const history = useStore(videoHistoryStore);
  const [input, setInput] = useState("");
  const [query, setQuery] = useState<string | null>(null);
  const [state, setState] = useState<"idle" | "loading" | "failed">("idle");
  const [hits, setHits] = useState<VideoHit[]>([]);
  const [playing, setPlaying] = useState<VideoHit | null>(null);
  const [focused, setFocused] = useState(false);

  const run = async (raw: string): Promise<void> => {
    const q = raw.trim();
    if (!q) return;
    setInput(q);
    setQuery(q);
    setPlaying(null);
    videoHistoryStore.set((h) => addToHistory(h, q));
    const f = fetchImpl ?? fetch.bind(globalThis);
    setState("loading");
    try {
      setHits(await searchVideos(q, f));
      setState("idle");
    } catch {
      setHits([]);
      setState("failed");
    }
  };
  const close = (): void => {
    setQuery(null);
    setInput("");
    setHits([]);
    setPlaying(null);
    setState("idle");
  };
  // The results close with «رجوع» and the phone's back, back to the videos (owner 2026-11-24).
  useBackLayer(query !== null, close);

  const showHistory = history.length > 0 && (query === null || focused) && state !== "loading";
  return (
    <>
      <form
        className="video-search"
        role="search"
        data-testid="video-search"
        onSubmit={(e) => {
          e.preventDefault();
          void run(input);
        }}
      >
        <input
          type="search"
          className="input"
          value={input}
          enterKeyHint="search"
          placeholder={t(locale, "videos.searchHint")}
          aria-label={t(locale, "videos.searchHint")}
          data-testid="video-search-input"
          onChange={(e) => setInput(e.target.value)}
          onFocus={() => setFocused(true)}
          onBlur={() => setTimeout(() => setFocused(false), 200)}
        />
        <button type="submit" className="btn btn-primary" data-testid="video-search-go">
          <Icon name="search" /> {t(locale, "videos.search")}
        </button>
        {query !== null ? (
          <button type="button" className="btn" data-testid="video-search-close" onClick={close}>
            {t(locale, "videos.backToFeed")}
          </button>
        ) : null}
      </form>
      {showHistory ? (
        <section
          className="video-history"
          data-testid="video-history"
          aria-label={t(locale, "videos.history")}
        >
          <div className="row">
            <strong className="small">{t(locale, "videos.history")}</strong>
            <button
              type="button"
              className="btn btn-sm"
              data-testid="video-history-clear"
              onClick={() => videoHistoryStore.set([])}
            >
              {t(locale, "videos.clearHistory")}
            </button>
          </div>
          <ul className="chips">
            {history.map((h) => (
              <li key={h} className="chip">
                <button
                  type="button"
                  className="chip-text"
                  data-testid="video-history-item"
                  onClick={() => void run(h)}
                >
                  {h}
                </button>
                <button
                  type="button"
                  className="chip-x"
                  aria-label={t(locale, "videos.removeHistory", { q: h })}
                  onClick={() => videoHistoryStore.set((list) => list.filter((x) => x !== h))}
                >
                  ×
                </button>
              </li>
            ))}
          </ul>
        </section>
      ) : null}
      {query === null ? (
        children
      ) : (
        <section data-testid="video-results" aria-busy={state === "loading"}>
          <p className="muted small">{t(locale, "videos.searchNote")}</p>
          {playing ? (
            <div className="card video-now" data-testid="video-player">
              <div className="video-frame">
                <iframe
                  key={playing.ref}
                  src={embedVideoUrl(playing.ref)}
                  title={playing.title}
                  allow="autoplay; encrypted-media; picture-in-picture; fullscreen"
                  allowFullScreen
                  referrerPolicy="strict-origin-when-cross-origin"
                />
              </div>
              <strong>{playing.title}</strong>
              <a className="small" href={watchUrl(playing.ref)} target="_blank" rel="noopener noreferrer">
                {t(locale, "reels.open.youtube")}
              </a>
            </div>
          ) : null}
          {state === "loading" ? <p className="muted">{t(locale, "videos.searching")}</p> : null}
          {state === "failed" ? (
            <p className="alert alert-error" data-testid="video-search-failed">
              {t(locale, "videos.searchFailed")}
            </p>
          ) : null}
          {state === "idle" && hits.length === 0 ? (
            <p className="muted" data-testid="video-search-none">
              {t(locale, "videos.noResults")}
            </p>
          ) : null}
          <ul className="video-results">
            {hits.map((h) => (
              <li key={h.ref}>
                <button
                  type="button"
                  className="video-hit"
                  data-testid={`video-hit-${h.ref}`}
                  aria-pressed={playing?.ref === h.ref}
                  onClick={() => {
                    setPlaying(h);
                    window.scrollTo?.({ top: 0, behavior: "smooth" });
                  }}
                >
                  {/* eslint-disable-next-line @next/next/no-img-element -- static export: YouTube's own thumbnail */}
                  <img src={thumbUrl(h.ref)} alt="" loading="lazy" width={160} height={90} />
                  <span className="tile-text">
                    <strong>{h.title}</strong>
                    <span className="muted small">
                      {[h.channel, h.duration].filter(Boolean).join(" · ")}
                      {h.trusted ? ` · ${t(locale, "reels.trusted")}` : ""}
                    </span>
                  </span>
                </button>
              </li>
            ))}
          </ul>
        </section>
      )}
    </>
  );
}
