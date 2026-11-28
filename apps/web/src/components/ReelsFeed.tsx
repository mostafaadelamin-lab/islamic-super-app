"use client";
import { useCallback, useEffect, useRef, useState } from "react";
import { t, type Locale } from "@/lib/i18n";
import { localizeDigits } from "@/lib/digits";
import {
  BUNDLED_SOURCES,
  embedUrl,
  FEED_MAX_AGE_MS,
  fetchReelsFeed,
  inTab,
  LIVE_CHANNELS,
  liveEmbedUrl,
  liveWatchUrl,
  mixReels,
  PLAYER_TABS,
  posterUrl,
  REELS,
  reelsFeedStore,
  reelsPrefsStore,
  savedReelsStore,
  toggleSaved,
  visibleReels,
  type LiveChannel,
  type Reel,
  type ReelSource,
  type ReelTab,
} from "@/lib/reels";
import { VIDEO_API } from "@/lib/videos";
import { fetchChannelReels, userChannelsStore } from "@/lib/reel-channels";
import { useStore } from "@/hooks/useStore";
import { Icon } from "./Icon";

const EMPTY_TEXT = { loading: "reels.loading", failed: "reels.offline", idle: "reels.empty" } as const;

/** Share of a page that must be visible for it to count as the one in view. */
const IN_VIEW = 0.6;

/** The label of a videos tab. */
export function tabLabel(locale: Locale, tab: ReelTab): string {
  if (tab === "live") return t(locale, "reels.live.title");
  if (tab === "saved") return t(locale, "reels.saved");
  return t(locale, `reels.group.${tab}`);
}

/** The tag on a recitation: Makkah and Madinah imams both read «أئمة الحرمين». */
export function groupTag(locale: Locale, group: string | null | undefined): string | null {
  if (group === "makkah" || group === "madinah") return t(locale, "reels.group.haramain");
  if (group === "golden" || group === "famous") return t(locale, `reels.group.${group}`);
  return null;
}

/**
 * The recitations of the trusted reciters (from the site's API, cached 3 hours), the viewer's own channels, the
 * hidden reciters and the saved recitations: shared by the videos page and the full-screen player.
 */
export function useReelsData(locale: Locale, reels: readonly Reel[], fetchImpl?: typeof fetch) {
  const prefs = useStore(reelsPrefsStore);
  const cache = useStore(reelsFeedStore);
  const saved = useStore(savedReelsStore);
  const apiBase = VIDEO_API();
  const [feedState, setFeedState] = useState<"idle" | "loading" | "failed">("idle");

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

  // The viewer's own channels (as in the app): each one's newest recitations join the feed.
  const myChannels = useStore(userChannelsStore);
  const [channelReels, setChannelReels] = useState<Record<string, Reel[]>>({});
  useEffect(() => {
    const f = fetchImpl ?? (typeof fetch === "function" ? fetch.bind(globalThis) : null);
    if (!f) return;
    let live = true;
    const load = async (ch: (typeof myChannels)[number]): Promise<void> => {
      const items = await fetchChannelReels(ch, f);
      if (live) setChannelReels((m) => ({ ...m, [ch.channelId]: items }));
    };
    myChannels.filter((ch) => !channelReels[ch.channelId]).forEach((ch) => void load(ch));
    return () => {
      live = false;
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [myChannels, fetchImpl]);

  const hidden = new Set(prefs.hidden);
  const sources: ReelSource[] = cache?.sources.length ? cache.sources : [...BUNDLED_SOURCES];
  const groupOf = new Map(sources.map((s) => [s.id, s.group ?? null]));
  const bySource = (cache?.items ?? [])
    .filter((r) => !hidden.has(r.sourceId ?? ""))
    .reduce((m, r) => {
      const id = r.sourceId ?? "";
      const withGroup = r.group === undefined ? { ...r, group: groupOf.get(id) ?? null } : r;
      return m.set(id, [...(m.get(id) ?? []), withGroup]);
    }, new Map<string, Reel[]>());
  myChannels
    .map((ch) => [`yt-${ch.channelId}`, channelReels[ch.channelId] ?? []] as const)
    .filter(([id]) => !hidden.has(id) && !bySource.has(id))
    .forEach(([id, l]) => bySource.set(id, l));

  /** Recitations of a tab (or one reciter), mixed across reciters; curated reels join «الكل». */
  const listFor = (tab: ReelTab, sourceId?: string | null): Reel[] => {
    if (sourceId) return mixReels([bySource.get(sourceId) ?? []]);
    if (tab === "saved") return saved;
    if (tab === "live") return [];
    const lists = [...bySource.entries()].filter(([id]) => inTab(groupOf.get(id), tab)).map(([, l]) => l);
    const seen = new Set<string>();
    return [...mixReels(lists), ...(tab === "all" ? visibleReels(reels, false) : [])].filter((r) =>
      seen.has(r.id) ? false : (seen.add(r.id), true),
    );
  };
  const sourceName = (id: string | null | undefined): string => {
    const s = sources.find((x) => x.id === id);
    if (s) return locale === "ar" ? s.name.ar : s.name.en;
    return myChannels.find((c) => `yt-${c.channelId}` === id)?.name ?? "";
  };
  return { prefs, cache, saved, sources, hidden, feedState, refresh, listFor, sourceName, myChannels };
}

/**
 * The full-screen player: vertical, snap-scrolling recitations. Only the one in view gets a live player (iframe);
 * the others show a poster, so at most one video loads or plays at a time. Across the top: «الكل · أئمة الحرمين ·
 * الجيل الذهبي المصري · بث مباشر من الحرمين» (owner 2026-11-27); swiping stays inside the tab or reciter.
 */
export function ReelsFeed({
  locale,
  reels = REELS,
  fetchImpl,
  tab: tabProp = "all",
  sourceId: sourceProp = null,
  startId = null,
  onBack,
}: {
  locale: Locale;
  reels?: readonly Reel[];
  /** Replaced in tests. */
  fetchImpl?: typeof fetch;
  tab?: ReelTab;
  /** Only this reciter's recitations (opened from a reciter's picture). */
  sourceId?: string | null;
  /** The recitation or live stream to start on. */
  startId?: string | null;
  /** Back to the videos page. */
  onBack?: () => void;
}) {
  const data = useReelsData(locale, reels, fetchImpl);
  const { prefs, feedState, refresh, sourceName } = data;
  const [tab, setTab] = useState<ReelTab>(tabProp);
  const [sourceId, setSourceId] = useState<string | null>(sourceProp);
  const [undo, setUndo] = useState<{ id: string; name: string } | null>(null);
  const [shareNote, setShareNote] = useState(false);
  const isLive = tab === "live" && !sourceId;
  const list = isLive ? [] : data.listFor(tab, sourceId);
  const count = isLive ? LIVE_CHANNELS.length : list.length;
  const savedRefs = new Set(data.saved.map((r) => r.ref));

  const startIndex = (): number => {
    if (!startId) return 0;
    const i = isLive
      ? LIVE_CHANNELS.findIndex((l) => l.id === startId)
      : list.findIndex((r) => r.id === startId);
    return Math.max(0, i);
  };
  const [active, setActive] = useState(startIndex);
  const feed = useRef<HTMLDivElement>(null);
  const started = useRef(false);
  useEffect(() => {
    if (started.current || !startId) return;
    const i = startIndex();
    if (i > 0 || count > 0) started.current = true;
    if (i > 0) {
      setActive(i);
      feed.current?.querySelector<HTMLElement>(`[data-index="${i}"]`)?.scrollIntoView?.({ block: "start" });
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [count]);

  const selectTab = (next: ReelTab): void => {
    setTab(next);
    setSourceId(null);
    setActive(0);
    feed.current?.scrollTo?.({ top: 0 });
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
  const share = async (r: Reel, title: string): Promise<void> => {
    const nav = typeof navigator !== "undefined" ? navigator : null;
    try {
      if (nav?.share) {
        await nav.share({ title, url: r.url });
        return;
      }
      await nav?.clipboard?.writeText(r.url);
      setShareNote(true);
    } catch {
      // The viewer closed the share sheet.
    }
  };

  useEffect(() => {
    const root = feed.current;
    if (!root || typeof IntersectionObserver === "undefined") return;
    const io = new IntersectionObserver(
      (entries) =>
        entries
          .filter((e) => e.isIntersecting)
          .forEach((e) => setActive(Number((e.target as HTMLElement).dataset.index))),
      { root, threshold: IN_VIEW },
    );
    root.querySelectorAll<HTMLElement>("[data-index]").forEach((el) => io.observe(el));
    return () => io.disconnect();
  }, [count, tab, sourceId]);

  const go = useCallback(
    (delta: number) => {
      const i = Math.min(count - 1, Math.max(0, active + delta));
      feed.current
        ?.querySelector<HTMLElement>(`[data-index="${i}"]`)
        ?.scrollIntoView?.({ behavior: "smooth" });
      setActive(i);
    },
    [active, count],
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

  const livePage = (l: LiveChannel, i: number) => {
    const name = locale === "ar" ? l.name.ar : l.name.en;
    return (
      <article key={l.id} className="reel" data-index={i} data-live={l.id}>
        <div className="reel-frame">
          {i === active ? (
            <iframe
              src={liveEmbedUrl(l, origin)}
              title={name}
              allow="autoplay; encrypted-media; picture-in-picture; fullscreen"
              allowFullScreen
              referrerPolicy="strict-origin-when-cross-origin"
              loading="eager"
              data-testid="live-player"
            />
          ) : (
            <div className="reel-poster reel-poster-blank" aria-hidden="true">
              <Icon name="play" />
            </div>
          )}
        </div>
        <div className="reel-meta">
          <span className="live-badge">● {t(locale, "reels.live.badge")}</span>
          <strong className="reel-title">{name}</strong>
          <a
            href={liveWatchUrl(l)}
            target="_blank"
            rel="noopener noreferrer"
            className="reel-open"
          >
            {t(locale, "reels.open.youtube")}
          </a>
        </div>
      </article>
    );
  };

  const reelPage = (r: Reel, i: number) => {
    const near = i === active;
    const poster = posterUrl(r);
    const title = locale === "ar" ? r.title.ar : r.title.en;
    const speaker = r.speaker ? (locale === "ar" ? r.speaker.ar : r.speaker.en) : null;
    const tag = groupTag(locale, r.group);
    const isSaved = savedRefs.has(r.ref);
    return (
      <article
        key={r.id}
        className="reel"
        data-index={i}
        data-reel={r.id}
        data-status={r.status}
        aria-label={localizeDigits(t(locale, "reels.position", { n: i + 1, total: count }), locale)}
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
            <Poster src={poster} />
          )}
        </div>
        <div className="reel-meta">
          {tag ? (
            <span className="reel-group" data-testid={`reel-group-${r.id}`}>
              {tag}
            </span>
          ) : null}
          <strong className="reel-title">{title}</strong>
          {speaker ? <span>{speaker}</span> : null}
          <span className="reel-actions">
            <button
              type="button"
              className={`reel-action${isSaved ? " on" : ""}`}
              aria-pressed={isSaved}
              onClick={() => toggleSaved(r)}
              data-testid={`reel-save-${r.id}`}
            >
              <Icon name="bookmark" /> {t(locale, isSaved ? "reels.unsave" : "reels.save")}
            </button>
            <button
              type="button"
              className="reel-action"
              onClick={() => void share(r, title)}
              data-testid={`reel-share-${r.id}`}
            >
              <Icon name="share" /> {t(locale, "reels.share")}
            </button>
            <a href={r.url} target="_blank" rel="noopener noreferrer" className="reel-open">
              {t(locale, `reels.open.${r.platform}`)}
            </a>
            {r.status === "auto" && r.sourceId ? (
              <button
                type="button"
                className="reel-hide"
                onClick={() => hide(r)}
                data-testid={`reel-hide-${r.id}`}
              >
                {t(locale, "reels.hide")}
              </button>
            ) : null}
          </span>
        </div>
      </article>
    );
  };

  return (
    <div className="reels">
      <div className="reels-top">
        {onBack ? (
          <button type="button" className="reels-link" onClick={onBack} data-testid="reels-back">
            {t(locale, "reels.back")}
          </button>
        ) : null}
        {sourceId ? <strong data-testid="reels-reciter">{sourceName(sourceId)}</strong> : null}
      </div>
      <div className="reels-tabs" role="tablist" aria-label={t(locale, "reels.title")}>
        {PLAYER_TABS.map((k) => (
          <button
            key={k}
            type="button"
            role="tab"
            aria-selected={!sourceId && tab === k}
            className={`reels-tab${!sourceId && tab === k ? " on" : ""}`}
            onClick={() => selectTab(k)}
            data-testid={`reels-tab-${k}`}
          >
            {k === "live" ? (
              <span className="live-dot" aria-hidden="true">
                ●{" "}
              </span>
            ) : null}
            {tabLabel(locale, k)}
          </button>
        ))}
      </div>
      {undo ? (
        <p className="reels-undo" role="status" data-testid="reels-hidden">
          {t(locale, "reels.hidden", { name: undo.name })}{" "}
          <button type="button" className="reels-link" onClick={() => unhide(undo.id)}>
            {t(locale, "reels.undo")}
          </button>
        </p>
      ) : null}
      {shareNote ? (
        <p className="reels-undo" role="status" data-testid="reels-share-note">
          {t(locale, "reels.shareCopied")}
        </p>
      ) : null}
      {count === 0 ? (
        <div className="reels-empty" data-testid="reels-empty" aria-busy={feedState === "loading"}>
          <p>{t(locale, tab === "saved" ? "reels.savedEmpty" : EMPTY_TEXT[feedState])}</p>
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
          data-testid={isLive ? "reels-live" : "reels-feed"}
          tabIndex={0}
          role="region"
          aria-roledescription={t(locale, "reels.feed")}
          aria-label={t(locale, "reels.title")}
          onKeyDown={onKey}
        >
          {isLive ? LIVE_CHANNELS.map(livePage) : list.map((r, i) => reelPage(r, i))}
        </div>
      )}
      {count > 1 ? (
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
            {localizeDigits(`${active + 1} / ${count}`, locale)}
          </span>
          <button
            type="button"
            onClick={() => go(1)}
            disabled={active === count - 1}
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

/** YouTube's poster image, or a blank play card (Instagram has no public poster). */
function Poster({ src }: { src: string | null }) {
  if (!src) {
    return (
      <div className="reel-poster reel-poster-blank" aria-hidden="true">
        <Icon name="play" />
      </div>
    );
  }
  // eslint-disable-next-line @next/next/no-img-element
  return <img src={src} alt="" loading="lazy" className="reel-poster" />;
}
