"use client";
import { useState } from "react";
import { t, type Locale } from "@/lib/i18n";
import { localizeDigits } from "@/lib/digits";
import {
  cleanTitle,
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
import { VIDEOS_PAGE_CSS } from "./videos-page-css";

type View =
  | { kind: "home" }
  | { kind: "reciters" }
  | { kind: "player"; tab: ReelTab; sourceId: string | null; startId: string | null };


/**
 * The «فيديوهات» page: page 1 (owner 2026-11-28, layout option 2) = circles for the Haramain live streams and the
 * reciters, group chips and a three-column grid of tall video tiles; any tap opens page 2 = the full-screen player
 * ([ReelsFeed]) on that tab, reciter or video; page 3 = the reciters list with show/hide.
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
  const circlesTab: ReelTab = tab === "saved" ? "all" : tab;
  /** The viewer's own channels (no group): circles under «الكل» only. */
  const mine: ReelSource[] = data.myChannels.map((c) => ({
    id: `yt-${c.channelId}`,
    channelId: c.channelId,
    name: { ar: c.name, en: c.name },
    category: "recitation" as const,
    group: null,
  }));
  const reciters = [...data.sources, ...mine].filter(
    (s) => !data.hidden.has(s.id) && inTab(s.group, circlesTab),
  );
  const list = data.listFor(tab);

  return (
    <div className="videos-home" data-testid="videos-home">
      <style>{VIDEOS_PAGE_CSS}</style>
      <div className="videos-bar">
        <button type="button" className="btn" onClick={onReciters} data-testid="videos-reciters">
          <Icon name="reciter" /> {t(locale, "reels.reciters")}
        </button>
      </div>
      <div className="videos-stories" data-testid="videos-stories">
        {LIVE_CHANNELS.map((l) => (
          <LiveCircle key={l.id} live={l} locale={locale} onPick={() => onPlay("live", null, l.id)} />
        ))}
        {reciters.map((s) => (
          <ReciterCircle
            key={s.id}
            source={s}
            label={shortName(name(s.name))}
            newest={data.listFor(circlesTab, s.id)[0]}
            onPick={() => onPlay(circlesTab, s.id)}
          />
        ))}
      </div>
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
      {list.length === 0 ? (
        <EmptyGrid locale={locale} tab={tab} loading={data.feedState === "loading"} />
      ) : (
        <div className="videos-tiles" data-testid={`videos-section-${tab}`}>
          {list.map((r) => (
            <VideoTile key={r.id} reel={r} locale={locale} onPick={() => onPlay(tab, null, r.id)} />
          ))}
        </div>
      )}
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

function EmptyGrid({ locale, tab, loading }: { locale: Locale; tab: ReelTab; loading: boolean }) {
  if (tab === "saved") {
    return (
      <p className="reels-empty" data-testid="videos-saved-empty">
        {t(locale, "reels.savedEmpty")}
      </p>
    );
  }
  return <p className="muted small">{t(locale, loading ? "reels.groupLoading" : "reels.empty")}</p>;
}

/** A title before the reciter's name: matches "الشيخ عبد الباسط" (strips "الشيخ "), not "عبد الباسط". */
const TITLE_PREFIX = /^(الشيخ|القارئ|د\.|Sheikh|Dr\.)\s+/u;
const shortName = (name: string): string => name.replace(TITLE_PREFIX, "").trim();

/** The reciter's initial (shown until a frame of their newest recitation has loaded). */
function initial(name: string): string {
  return [...name][0] ?? "؟";
}

const thumbUrl = (r: Reel, quality: "default" | "hqdefault"): string =>
  `https://i.ytimg.com/vi/${r.ref}/${quality}.jpg`;

/** The live circles' short names (kept on this page, not in the shared i18n file: see VIDEOS_PAGE_CSS). */
const LIVE_SHORT = {
  makkah: { ar: "مكة", en: "Makkah" },
  madinah: { ar: "المدينة", en: "Madinah" },
} as const;

/** Owner 2026-11-28 (layout option 2): a Haramain live stream as a circle with a red ring. */
function LiveCircle({ live, locale, onPick }: { live: LiveChannel; locale: Locale; onPick: () => void }) {
  return (
    <button
      type="button"
      className={`videos-circle is-live live-${live.place}`}
      onClick={onPick}
      data-testid={`videos-live-${live.id}`}
      aria-label={t(locale, `reels.live.${live.place}`)}
    >
      <i aria-hidden="true">{LIVE_SHORT[live.place][locale === "ar" ? "ar" : "en"]}</i>
      <span className="live-dot-label">{t(locale, "reels.live.badge")}</span>
    </button>
  );
}

function ReciterCircle({
  source,
  label,
  newest,
  onPick,
}: {
  source: ReelSource;
  label: string;
  newest: Reel | undefined;
  onPick: () => void;
}) {
  return (
    <button type="button" className="videos-circle" onClick={onPick} data-testid={`videos-reciter-${source.id}`}>
      <i aria-hidden="true">
        {initial(label)}
        {newest?.platform === "youtube" ? (
          // eslint-disable-next-line @next/next/no-img-element
          <img src={thumbUrl(newest, "default")} alt="" loading="lazy" />
        ) : null}
      </i>
      <span>{label}</span>
    </button>
  );
}

/** A tall tile of the grid: the video's frame (cropped to 9:16) and the reciter's short name. */
function VideoTile({ reel, locale, onPick }: { reel: Reel; locale: Locale; onPick: () => void }) {
  const title = cleanTitle(locale === "ar" ? reel.title.ar : reel.title.en);
  const speaker = shortName(reel.speaker?.[locale === "ar" ? "ar" : "en"] ?? "");
  return (
    <button
      type="button"
      className="videos-tile"
      onClick={onPick}
      data-testid={`videos-card-${reel.id}`}
      aria-label={speaker ? `${title}، ${speaker}` : title}
    >
      {reel.platform === "youtube" ? (
        // eslint-disable-next-line @next/next/no-img-element
        <img src={thumbUrl(reel, "hqdefault")} alt="" loading="lazy" />
      ) : null}
      <Icon name="play" />
      {speaker ? <span>{speaker}</span> : null}
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
