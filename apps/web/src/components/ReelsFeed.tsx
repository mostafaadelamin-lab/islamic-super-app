"use client";
import { useCallback, useEffect, useRef, useState } from "react";
import { t, type Locale } from "@/lib/i18n";
import { localizeDigits } from "@/lib/digits";
import {
  embedUrl,
  FEED_MAX_AGE_MS,
  fetchReelsFeed,
  mixReels,
  posterUrl,
  REELS,
  reelsFeedStore,
  reelsPrefsStore,
  visibleReels,
  type Reel,
} from "@/lib/reels";
import { VIDEO_API } from "@/lib/videos";
import { useStore } from "@/hooks/useStore";
import { Icon } from "./Icon";

/**
 * Vertical, snap-scrolling reels feed. Only the reel in view gets a live player (iframe); the others show a
 * poster, so at most one video loads or plays at a time.
 */
export function ReelsFeed({
  locale,
  reels = REELS,
  fetchImpl,
}: {
  locale: Locale;
  reels?: readonly Reel[];
  /** Replaced in tests. */
  fetchImpl?: typeof fetch;
}) {
  const prefs = useStore(reelsPrefsStore);
  const cache = useStore(reelsFeedStore);
  const apiBase = VIDEO_API();
  const [feedState, setFeedState] = useState<"idle" | "loading" | "failed">("idle");
  const [undo, setUndo] = useState<{ id: string; name: string } | null>(null);

  const refresh = useCallback(
    async (force: boolean) => {
      const c = reelsFeedStore.get();
      const now = Date.now();
      if (!force && c && c.base === apiBase && now - c.at < FEED_MAX_AGE_MS) return;
      const f = fetchImpl ?? (typeof fetch === "function" ? fetch.bind(globalThis) : null);
      if (!f) return;
      setFeedState("loading");
      try {
        reelsFeedStore.set(await fetchReelsFeed(apiBase, f, now));
        setFeedState("idle");
      } catch {
        setFeedState("failed");
      }
    },
    [apiBase, fetchImpl],
  );
  useEffect(() => {
    void refresh(false);
  }, [refresh]);

  const hidden = new Set(prefs.hidden);
  const autoItems = (cache?.items ?? []).filter((r) => !hidden.has(r.sourceId ?? ""));
  const bySource = new Map<string, Reel[]>();
  for (const r of autoItems) bySource.set(r.sourceId ?? "", [...(bySource.get(r.sourceId ?? "") ?? []), r]);
  const seen = new Set<string>();
  const list = [...mixReels([...bySource.values()]), ...visibleReels(reels, false)].filter((r) =>
    seen.has(r.id) ? false : (seen.add(r.id), true),
  );
  const sourceName = (id: string | null | undefined): string => {
    const s = cache?.sources.find((x) => x.id === id);
    return s ? (locale === "ar" ? s.name.ar : s.name.en) : "";
  };
  const hide = (r: Reel): void => {
    if (!r.sourceId) return;
    const id = r.sourceId;
    reelsPrefsStore.set((p) => ({ ...p, hidden: [...new Set([...p.hidden, id])] }));
    setUndo({ id, name: sourceName(id) });
    setActive(0);
  };
  const unhide = (id: string): void => {
    reelsPrefsStore.set((p) => ({ ...p, hidden: p.hidden.filter((h) => h !== id) }));
    setUndo(null);
  };
  const [active, setActive] = useState(0);
  const feed = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const root = feed.current;
    if (!root || typeof IntersectionObserver === "undefined") return;
    const io = new IntersectionObserver(
      (entries) => {
        for (const e of entries) {
          if (e.isIntersecting) setActive(Number((e.target as HTMLElement).dataset.index));
        }
      },
      { root, threshold: 0.6 },
    );
    root.querySelectorAll<HTMLElement>("[data-index]").forEach((el) => io.observe(el));
    return () => io.disconnect();
  }, [list.length]);

  const go = useCallback(
    (delta: number) => {
      const i = Math.min(list.length - 1, Math.max(0, active + delta));
      feed.current
        ?.querySelector<HTMLElement>(`[data-index="${i}"]`)
        ?.scrollIntoView?.({ behavior: "smooth" });
      setActive(i);
    },
    [active, list.length],
  );

  const onKey = (e: React.KeyboardEvent): void => {
    if (e.key === "ArrowDown" || e.key === "PageDown") {
      e.preventDefault();
      go(1);
    } else if (e.key === "ArrowUp" || e.key === "PageUp") {
      e.preventDefault();
      go(-1);
    }
  };

  const origin = typeof window !== "undefined" ? window.location.origin : undefined;

  return (
    <div className="reels">
      {undo ? (
        <p className="reels-undo" role="status" data-testid="reels-hidden">
          {t(locale, "reels.hidden", { name: undo.name })}{" "}
          <button type="button" className="reels-link" onClick={() => unhide(undo.id)}>
            {t(locale, "reels.undo")}
          </button>
        </p>
      ) : null}
      {list.length === 0 ? (
        <div className="reels-empty" data-testid="reels-empty" aria-busy={feedState === "loading"}>
          <p>
            {feedState === "loading"
              ? t(locale, "reels.loading")
              : feedState === "failed"
                ? t(locale, "reels.offline")
                : t(locale, "reels.empty")}
          </p>
          {feedState === "failed" ? (
            <button
              type="button"
              className="btn"
              onClick={() => void refresh(true)}
              data-testid="reels-retry"
            >
              {t(locale, "reels.retry")}
            </button>
          ) : null}
          {prefs.hidden.length > 0 && feedState !== "loading" ? (
            <button
              type="button"
              className="reels-link"
              onClick={() => {
                reelsPrefsStore.set((p) => ({ ...p, hidden: [] }));
                setUndo(null);
              }}
              data-testid="reels-show-hidden"
            >
              {t(locale, "reels.showHidden")}
            </button>
          ) : null}
        </div>
      ) : (
        <div
          ref={feed}
          className="reels-feed"
          data-testid="reels-feed"
          tabIndex={0}
          role="region"
          aria-roledescription={t(locale, "reels.feed")}
          aria-label={t(locale, "reels.title")}
          onKeyDown={onKey}
        >
          {list.map((r, i) => {
            const near = i === active;
            const poster = posterUrl(r);
            const title = locale === "ar" ? r.title.ar : r.title.en;
            const speaker = r.speaker ? (locale === "ar" ? r.speaker.ar : r.speaker.en) : null;
            return (
              <article
                key={r.id}
                className="reel"
                data-index={i}
                data-reel={r.id}
                data-status={r.status}
                aria-label={localizeDigits(
                  t(locale, "reels.position", { n: i + 1, total: list.length }),
                  locale,
                )}
              >
                <div className={`reel-frame reel-${r.platform}`}>
                  {near ? (
                    <iframe
                      src={embedUrl(r, origin)}
                      title={title}
                      allow="autoplay; encrypted-media; picture-in-picture; fullscreen"
                      allowFullScreen
                      referrerPolicy="strict-origin-when-cross-origin"
                      loading="eager"
                      data-testid="reel-player"
                    />
                  ) : poster ? (
                    // eslint-disable-next-line @next/next/no-img-element
                    <img src={poster} alt="" loading="lazy" className="reel-poster" />
                  ) : (
                    <div className="reel-poster reel-poster-blank" aria-hidden="true">
                      <Icon name="play" />
                    </div>
                  )}
                </div>
                {r.status === "pending" ? (
                  <p className="reel-banner" role="note" data-testid="reel-pending">
                    {t(locale, "reels.pending")}
                  </p>
                ) : null}
                <div className="reel-meta">
                  <strong className="reel-title">{title}</strong>
                  {speaker ? <span>{speaker}</span> : null}
                  <span className="reel-tags">
                    <span className="reel-chip">{t(locale, `reels.cat.${r.category}`)}</span>
                    <span className="reel-chip">{t(locale, `reels.platform.${r.platform}`)}</span>
                    {r.status === "auto" ? (
                      <span className="reel-chip reel-reviewed">{t(locale, "reels.trusted")}</span>
                    ) : null}
                    {r.status === "approved" && r.reviewer ? (
                      <span className="reel-chip reel-reviewed">
                        {t(locale, "reels.reviewedBy", { name: r.reviewer })}
                      </span>
                    ) : null}
                  </span>
                  <a href={r.url} target="_blank" rel="noopener noreferrer" className="reel-open">
                    {t(locale, `reels.open.${r.platform}`)}
                  </a>
                  {r.status === "auto" ? (
                    <button
                      type="button"
                      className="reel-hide"
                      onClick={() => hide(r)}
                      data-testid={`reel-hide-${r.id}`}
                    >
                      {t(locale, "reels.hide")}
                    </button>
                  ) : null}
                </div>
              </article>
            );
          })}
        </div>
      )}
      {list.length > 1 ? (
        <div className="reels-nav">
          <button
            type="button"
            onClick={() => go(-1)}
            disabled={active === 0}
            aria-label={t(locale, "reels.prev")}
          >
            ▲
          </button>
          <span aria-live="polite" data-testid="reels-position">
            {localizeDigits(`${active + 1} / ${list.length}`, locale)}
          </span>
          <button
            type="button"
            onClick={() => go(1)}
            disabled={active === list.length - 1}
            aria-label={t(locale, "reels.next")}
          >
            ▼
          </button>
        </div>
      ) : null}
      <p className="muted small">{t(locale, "reels.note")}</p>
    </div>
  );
}
