"use client";
import { useState } from "react";
import { t, type Locale } from "@/lib/i18n";
import {
  addChannel,
  removeChannel,
  searchChannels,
  SUGGESTED_CHANNELS,
  userChannelsStore,
  type ChannelHit,
} from "@/lib/reel-channels";
import { useStore } from "@/hooks/useStore";
import { Icon } from "./Icon";

/** The app's channel sheet: search YouTube for a channel and add it, your channels, suggested channels. */
export function ChannelManager({
  locale,
  feedChannelIds,
  fetchImpl,
}: {
  locale: Locale;
  /** Channels already in the feed (the trusted list), shown as added. */
  feedChannelIds: ReadonlySet<string>;
  fetchImpl?: typeof fetch;
}) {
  const mine = useStore(userChannelsStore);
  const [q, setQ] = useState("");
  const [state, setState] = useState<"idle" | "loading" | "done">("idle");
  const [hits, setHits] = useState<ChannelHit[]>([]);
  const have = new Set([...feedChannelIds, ...mine.map((c) => c.channelId)]);
  const name = (n: { ar: string; en: string }): string => (locale === "ar" ? n.ar : n.en);

  const run = async (): Promise<void> => {
    const f = fetchImpl ?? (typeof fetch === "function" ? fetch.bind(globalThis) : null);
    if (!f || !q.trim()) return;
    setState("loading");
    try {
      setHits(await searchChannels(q, f));
    } catch {
      setHits([]);
    }
    setState("done");
  };

  const add = (id: string, title: string) =>
    have.has(id) ? (
      <span className="muted" aria-label={t(locale, "reels.added")} data-testid={`channel-added-${id}`}>
        <Icon name="checkCircle" />
      </span>
    ) : (
      <button
        type="button"
        className="btn btn-sm"
        onClick={() => addChannel(id, title)}
        data-testid={`channel-add-${id}`}
      >
        <Icon name="plus" size={16} /> {t(locale, "reels.addChannel")}
      </button>
    );

  const suggestions = SUGGESTED_CHANNELS.filter((s) => !have.has(s.channelId));

  return (
    <details className="card channel-manager" data-testid="channel-manager">
      <summary>
        <Icon name="reels" size={18} /> {t(locale, "reels.myChannels")}
        {mine.length ? ` (${mine.length.toLocaleString(locale === "ar" ? "ar-EG" : "en")})` : ""}
      </summary>
      <form
        className="row"
        role="search"
        onSubmit={(e) => {
          e.preventDefault();
          void run();
        }}
      >
        <label className="field">
          <span>{t(locale, "reels.searchChannelHint")}</span>
          <input type="search" value={q} onChange={(e) => setQ(e.target.value)} data-testid="channel-query" />
        </label>
        <button type="submit" className="btn" disabled={state === "loading"} data-testid="channel-search-btn">
          <Icon name="search" size={16} /> {t(locale, "reels.searchChannel")}
        </button>
      </form>
      {state === "loading" ? <p className="muted">{t(locale, "reels.loading")}</p> : null}
      {state === "done" && hits.length === 0 ? (
        <p className="muted" data-testid="channel-none">
          {t(locale, "reels.searchNone")}
        </p>
      ) : null}
      {hits.length > 0 ? (
        <ul className="channel-list" data-testid="channel-results">
          {hits.map((h) => (
            <li key={h.id}>
              <span>
                <strong>{h.title}</strong>
                {h.subs ? <span className="muted small"> · {h.subs}</span> : null}
              </span>
              {add(h.id, h.title)}
            </li>
          ))}
        </ul>
      ) : null}
      {mine.length > 0 ? (
        <>
          <h3>{t(locale, "reels.myChannels")}</h3>
          <ul className="channel-list" data-testid="channel-mine">
            {mine.map((c) => (
              <li key={c.channelId}>
                <strong>{c.name}</strong>
                <button
                  type="button"
                  className="btn btn-sm"
                  onClick={() => removeChannel(c.channelId)}
                  data-testid={`channel-remove-${c.channelId}`}
                >
                  <Icon name="trash" size={16} /> {t(locale, "reels.removeChannel")}
                </button>
              </li>
            ))}
          </ul>
        </>
      ) : null}
      {suggestions.length > 0 ? (
        <>
          <h3>{t(locale, "reels.suggested")}</h3>
          <ul className="channel-list" data-testid="channel-suggested">
            {suggestions.map((s) => (
              <li key={s.channelId}>
                <strong>{name(s.name)}</strong>
                {add(s.channelId, name(s.name))}
              </li>
            ))}
          </ul>
        </>
      ) : null}
    </details>
  );
}
