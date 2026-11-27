"use client";
import { useState } from "react";
import { t, type Locale } from "@/lib/i18n";
import { localizeDigits } from "@/lib/digits";
import {
  HOME_TABS,
  inTab,
  LIVE_CHANNELS,
  REEL_GROUPS,
  REELS,
  reelsPrefsStore,
  type LiveChannel,
  type Reel,
  type ReelSource,
  type ReelTab,
} from "@/lib/reels";
import { ChannelManager } from "./ChannelManager";
import { ReelsFeed, tabLabel, useReelsData } from "./ReelsFeed";
import { Icon } from "./Icon";

type View =
  | { kind: "home" }
  | { kind: "reciters" }
  | { kind: "player"; tab: ReelTab; sourceId: string | null; startId: string | null };

const ROW_MAX = 12;
/** Sections on the videos page under «الكل». */
const ALL_SECTIONS: readonly ReelTab[] = ["haramain", "golden", "famous"];

/**
 * The «فيديوهات» page (owner 2026-11-27, mockup): page 1 = the Haramain live streams, group chips and a row per
 * reciter group; any tap opens page 2 = the full-screen player ([ReelsFeed]) on that tab or reciter; page 3 = the
 * reciters list with show/hide.
 */
export function VideosHub({
  locale,
  reels = REELS,
  fetchImpl,
}: {
  locale: Locale;
  reels?: readonly Reel[];
  fetchImpl?: typeof fetch;
}) {
  const [view, setView] = useState<View>({ kind: "home" });
  const home = (): void => setView({ kind: "home" });
  const play = (tab: ReelTab, sourceId: string | null = null, startId: string | null = null): void =>
    setView({ kind: "player", tab, sourceId, startId });

  if (view.kind === "player") {
    return (
      <ReelsFeed
        locale={locale}
        reels={reels}
        fetchImpl={fetchImpl}
        tab={view.tab}
        sourceId={view.sourceId}
        startId={view.startId}
        onBack={home}
      />
    );
  }
  if (view.kind === "reciters") {
    return <RecitersList locale={locale} reels={reels} fetchImpl={fetchImpl} onBack={home} />;
  }
  return (
    <VideosHome
      locale={locale}
      reels={reels}
      fetchImpl={fetchImpl}
      onPlay={play}
      onReciters={() => setView({ kind: "reciters" })}
    />
  );
}

function VideosHome({
  locale,
  reels,
  fetchImpl,
  onPlay,
  onReciters,
}: {
  locale: Locale;
  reels: readonly Reel[];
  fetchImpl?: typeof fetch;
  onPlay: (tab: ReelTab, sourceId?: string | null, startId?: string | null) => void;
  onReciters: () => void;
}) {
  const data = useReelsData(locale, reels, fetchImpl);
  const [tab, setTab] = useState<ReelTab>("all");
  const name = (n: { ar: string; en: string }): string => (locale === "ar" ? n.ar : n.en);
  const visible = data.sources.filter((s) => !data.hidden.has(s.id));
  const sections = tab === "all" ? ALL_SECTIONS : [tab];
  /** The viewer's own channels (no group): their own row under «الكل». */
  const mine: ReelSource[] = data.myChannels
    .map((c) => ({
      id: `yt-${c.channelId}`,
      channelId: c.channelId,
      name: { ar: c.name, en: c.name },
      category: "recitation" as const,
      group: null,
    }))
    .filter((s) => !data.hidden.has(s.id));

  const section = (g: ReelTab) => {
    const reciters = visible.filter((s) => inTab(s.group, g));
    if (reciters.length === 0) return null;
    const list = data.listFor(g);
    return (
      <section key={g} className="videos-section" data-testid={`videos-section-${g}`}>
        <header className="videos-head">
          <h2>{tabLabel(locale, g)}</h2>
          {list.length > 0 ? (
            <button type="button" className="reels-link" onClick={() => onPlay(g)}>
              {t(locale, "reels.seeAll")}
            </button>
          ) : null}
        </header>
        <ReciterRow reciters={reciters} name={name} onPick={(s) => onPlay(g, s.id)} />
        {list.length === 0 ? (
          <p className="muted small">
            {t(locale, data.feedState === "loading" ? "reels.groupLoading" : "reels.empty")}
          </p>
        ) : (
          <VideoStrip
            reels={tab === "all" ? list.slice(0, ROW_MAX) : list}
            grid={tab !== "all"}
            locale={locale}
            onPick={(r) => onPlay(g, null, r.id)}
          />
        )}
      </section>
    );
  };

  return (
    <div className="videos-home" data-testid="videos-home">
      <div className="videos-bar">
        <button type="button" className="btn" onClick={onReciters} data-testid="videos-reciters">
          <Icon name="reciter" /> {t(locale, "reels.reciters")}
        </button>
      </div>
      {LIVE_CHANNELS.length > 0 ? (
        <section className="videos-section">
          <h2>{t(locale, "reels.live.title")}</h2>
          <div className="videos-live">
            {LIVE_CHANNELS.map((l) => (
              <LiveCard key={l.id} live={l} locale={locale} onPick={() => onPlay("live", null, l.id)} />
            ))}
          </div>
        </section>
      ) : null}
      <div className="reels-tabs videos-tabs" role="tablist">
        {HOME_TABS.map((k) => (
          <button
            key={k}
            type="button"
            role="tab"
            aria-selected={tab === k}
            className={`reels-tab${tab === k ? " on" : ""}`}
            onClick={() => setTab(k)}
            data-testid={`videos-tab-${k}`}
          >
            {tabLabel(locale, k)}
          </button>
        ))}
      </div>
      {tab === "saved" ? (
        <SavedList locale={locale} saved={data.saved} onPick={(r) => onPlay("saved", null, r.id)} />
      ) : (
        sections.map(section)
      )}
      {tab === "all" && mine.length > 0 ? (
        <section className="videos-section" data-testid="videos-section-mine">
          <h2>{t(locale, "reels.myChannels")}</h2>
          <ReciterRow reciters={mine} name={name} onPick={(s) => onPlay("all", s.id)} />
          <VideoStrip
            reels={mine.flatMap((s) => data.listFor("all", s.id)).slice(0, ROW_MAX)}
            grid={false}
            locale={locale}
            onPick={(r) => onPlay("all", r.sourceId ?? null, r.id)}
          />
        </section>
      ) : null}
      {data.feedState === "failed" && data.listFor("all").length === 0 ? (
        <div className="reels-empty" data-testid="reels-empty">
          <p>{t(locale, "reels.offline")}</p>
          <button
            type="button"
            className="btn"
            onClick={() => void data.refresh(true)}
            data-testid="reels-retry"
          >
            {t(locale, "reels.retry")}
          </button>
        </div>
      ) : null}
      <p className="muted small">{t(locale, "reels.note")}</p>
    </div>
  );
}

function SavedList({ locale, saved, onPick }: { locale: Locale; saved: Reel[]; onPick: (r: Reel) => void }) {
  if (saved.length === 0) {
    return (
      <p className="reels-empty" data-testid="videos-saved-empty">
        {t(locale, "reels.savedEmpty")}
      </p>
    );
  }
  return <VideoStrip reels={saved} grid locale={locale} onPick={onPick} />;
}

/** A title before the reciter's name: matches "الشيخ عبد الباسط" (strips "الشيخ "), not "عبد الباسط". */
const TITLE_PREFIX = /^(الشيخ|د\.|Sheikh)\s+/u;
const shortName = (name: string): string => name.replace(TITLE_PREFIX, "").trim();

/** The reciter's initial in a circle (YouTube profile pictures need an API key, so none are shown). */
function initial(name: string): string {
  return [...shortName(name)][0] ?? "؟";
}

function ReciterRow({
  reciters,
  name,
  onPick,
}: {
  reciters: ReelSource[];
  name: (n: { ar: string; en: string }) => string;
  onPick: (s: ReelSource) => void;
}) {
  return (
    <div className="videos-avatars">
      {reciters.map((s) => (
        <button
          key={s.id}
          type="button"
          className="videos-avatar"
          onClick={() => onPick(s)}
          data-testid={`videos-reciter-${s.id}`}
        >
          <i aria-hidden="true">{initial(name(s.name))}</i>
          <span>{shortName(name(s.name))}</span>
        </button>
      ))}
    </div>
  );
}

function VideoStrip({
  reels,
  grid,
  locale,
  onPick,
}: {
  reels: Reel[];
  grid: boolean;
  locale: Locale;
  onPick: (r: Reel) => void;
}) {
  return (
    <div className={grid ? "videos-grid" : "videos-strip"}>
      {reels.map((r) => {
        const title = locale === "ar" ? r.title.ar : r.title.en;
        const speaker = r.speaker?.[locale === "ar" ? "ar" : "en"] ?? "";
        return (
          <button
            key={r.id}
            type="button"
            className="videos-card"
            onClick={() => onPick(r)}
            data-testid={`videos-card-${r.id}`}
          >
            <span className="videos-thumb">
              {r.platform === "youtube" ? (
                // eslint-disable-next-line @next/next/no-img-element
                <img src={`https://i.ytimg.com/vi/${r.ref}/mqdefault.jpg`} alt="" loading="lazy" />
              ) : null}
              <Icon name="play" />
            </span>
            <span className="videos-title">{title}</span>
            {grid && speaker ? <span className="muted small">{speaker}</span> : null}
          </button>
        );
      })}
    </div>
  );
}

function LiveCard({ live, locale, onPick }: { live: LiveChannel; locale: Locale; onPick: () => void }) {
  return (
    <button
      type="button"
      className={`videos-live-card live-${live.place}`}
      onClick={onPick}
      data-testid={`videos-live-${live.id}`}
    >
      <span className="live-badge">● {t(locale, "reels.live.badge")}</span>
      <Icon name="play" />
      <span>{t(locale, `reels.live.${live.place}`)}</span>
    </button>
  );
}

/** Page 3: every reciter by group, each with a show/hide switch; the viewer's own channels last. */
function RecitersList({
  locale,
  reels,
  fetchImpl,
  onBack,
}: {
  locale: Locale;
  reels: readonly Reel[];
  fetchImpl?: typeof fetch;
  onBack: () => void;
}) {
  const data = useReelsData(locale, reels, fetchImpl);
  const name = (n: { ar: string; en: string }): string => (locale === "ar" ? n.ar : n.en);
  const toggle = (id: string, show: boolean): void =>
    reelsPrefsStore.set((p) => ({
      ...p,
      hidden: show ? p.hidden.filter((h) => h !== id) : [...new Set([...p.hidden, id])],
    }));
  return (
    <div className="videos-reciters" data-testid="videos-reciters-list">
      <button type="button" className="reels-link" onClick={onBack} data-testid="reels-back">
        {t(locale, "reels.back")}
      </button>
      <h2>{t(locale, "reels.reciters")}</h2>
      <p className="muted">{t(locale, "reels.recitersHint")}</p>
      {REEL_GROUPS.map((g) => {
        const list = data.sources.filter((s) => s.group === g);
        if (list.length === 0) return null;
        return (
          <section key={g} data-testid={`reciters-group-${g}`}>
            <h3>
              {t(locale, `reels.group.${g}`)} ({localizeDigits(String(list.length), locale)})
            </h3>
            <ul className="reciters-list">
              {list.map((s) => {
                const shown = !data.hidden.has(s.id);
                return (
                  <li key={s.id}>
                    <label>
                      <input
                        type="checkbox"
                        checked={shown}
                        onChange={(e) => toggle(s.id, e.target.checked)}
                        data-testid={`reciter-toggle-${s.id}`}
                      />
                      <span>{name(s.name)}</span>
                      <span className={shown ? "reciter-on" : "muted"}>
                        {t(locale, shown ? "reels.shown" : "reels.hiddenLabel")}
                      </span>
                    </label>
                  </li>
                );
              })}
            </ul>
          </section>
        );
      })}
      <ChannelManager
        locale={locale}
        fetchImpl={fetchImpl}
        feedChannelIds={new Set(data.sources.map((s) => s.channelId).filter((c): c is string => !!c))}
      />
    </div>
  );
}
