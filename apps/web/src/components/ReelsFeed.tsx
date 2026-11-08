"use client";
import { useCallback, useEffect, useRef, useState } from "react";
import { t, type Locale } from "@/lib/i18n";
import { localizeDigits } from "@/lib/digits";
import { embedUrl, posterUrl, REELS, reelsPrefsStore, visibleReels, type Reel } from "@/lib/reels";
import { useStore } from "@/hooks/useStore";

/**
 * Vertical, snap-scrolling reels feed. Only the reel in view gets a live player (iframe); the others show a
 * poster, so at most one video loads or plays at a time.
 */
export function ReelsFeed({ locale, reels = REELS }: { locale: Locale; reels?: readonly Reel[] }) {
  const prefs = useStore(reelsPrefsStore);
  const list = visibleReels(reels, prefs.reviewer);
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
      {list.length === 0 ? (
        <p className="reels-empty" data-testid="reels-empty">
          {t(locale, "reels.empty")}
        </p>
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
                  ) : (
                    // eslint-disable-next-line @next/next/no-img-element
                    <img src={poster} alt="" loading="lazy" className="reel-poster" />
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
                    {r.status === "approved" && r.reviewer ? (
                      <span className="reel-chip reel-reviewed">
                        {t(locale, "reels.reviewedBy", { name: r.reviewer })}
                      </span>
                    ) : null}
                  </span>
                  <a href={r.url} target="_blank" rel="noopener noreferrer" className="reel-open">
                    {t(locale, "reels.open")}
                  </a>
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
      <label className="reels-reviewer">
        <input
          type="checkbox"
          checked={prefs.reviewer}
          onChange={(e) => {
            reelsPrefsStore.set({ reviewer: e.target.checked });
            setActive(0);
          }}
          data-testid="reels-reviewer"
        />{" "}
        {t(locale, "reels.reviewerMode")}
        <span className="muted small"> — {t(locale, "reels.reviewerHint")}</span>
      </label>
    </div>
  );
}
