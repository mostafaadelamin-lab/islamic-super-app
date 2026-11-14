/**
 * The viewer's own video channels, as in the app (ReelsFeed.userSources / ChannelSearchSheet): find a channel
 * on YouTube, add it to the videos, remove it again; plus the Islamic channels the app suggests.
 * Browsers cannot read YouTube directly, so search and each channel's videos go through the site's API
 * (/api/channels/search and /api/v1/reels/channel, see netlify/functions/videos.mjs and bluehost/api/videos.php).
 */
import suggestionsJson from "@/generated/reel-suggestions.json";
import { createStore } from "./store";
import { sanitizeReels, type Reel } from "./reels";
import { VIDEO_API } from "./videos";

export const CHANNEL_ID_RE = /^UC[A-Za-z0-9_-]{22}$/;
export const MAX_CHANNELS = 30;

export interface UserChannel {
  channelId: string;
  name: string;
}
export interface ChannelHit {
  id: string;
  title: string;
  subs: string | null;
}
export interface SuggestedChannel {
  channelId: string;
  category: string;
  name: { ar: string; en: string };
}

export const SUGGESTED_CHANNELS: readonly SuggestedChannel[] = (
  (suggestionsJson as { sources?: Partial<SuggestedChannel>[] }).sources ?? []
).filter(
  (s): s is SuggestedChannel =>
    typeof s.channelId === "string" && CHANNEL_ID_RE.test(s.channelId) && !!s.name,
);

export const userChannelsStore = createStore<UserChannel[]>("rattil.reels.channels", [], (raw) =>
  Array.isArray(raw)
    ? raw
        .filter(
          (c): c is UserChannel =>
            !!c &&
            typeof (c as UserChannel).channelId === "string" &&
            CHANNEL_ID_RE.test((c as UserChannel).channelId) &&
            typeof (c as UserChannel).name === "string",
        )
        .slice(0, MAX_CHANNELS)
    : [],
);

export function addChannel(channelId: string, name: string): void {
  if (!CHANNEL_ID_RE.test(channelId)) return;
  userChannelsStore.set((list) =>
    list.some((c) => c.channelId === channelId)
      ? list
      : [...list, { channelId, name: name.trim() || channelId }].slice(0, MAX_CHANNELS),
  );
}

export function removeChannel(channelId: string): void {
  userChannelsStore.set((list) => list.filter((c) => c.channelId !== channelId));
}

export async function searchChannels(query: string, fetchImpl: typeof fetch): Promise<ChannelHit[]> {
  const q = query.trim();
  if (!q) return [];
  const res = await fetchImpl(`${VIDEO_API()}/channels/search?${new URLSearchParams({ q }).toString()}`, {
    headers: { Accept: "application/json" },
  });
  if (!res.ok) throw new Error(`channel search: HTTP ${res.status}`);
  const body = (await res.json()) as { schema?: string; items?: unknown };
  if (body.schema !== "channel-search.v1" || !Array.isArray(body.items))
    throw new Error("channel search: schema");
  return body.items
    .filter(
      (h): h is ChannelHit =>
        !!h &&
        CHANNEL_ID_RE.test(String((h as ChannelHit).id)) &&
        typeof (h as ChannelHit).title === "string",
    )
    .map((h) => ({ id: h.id, title: h.title, subs: typeof h.subs === "string" ? h.subs : null }));
}

/** One added channel's newest videos, named after the channel; [] when it cannot be reached. */
export async function fetchChannelReels(ch: UserChannel, fetchImpl: typeof fetch): Promise<Reel[]> {
  try {
    const res = await fetchImpl(
      `${VIDEO_API()}/v1/reels/channel?${new URLSearchParams({ id: ch.channelId }).toString()}`,
      {
        headers: { Accept: "application/json" },
      },
    );
    if (!res.ok) return [];
    const body = (await res.json()) as { schema?: string; items?: unknown };
    if (body.schema !== "reels-channel.v1") return [];
    return sanitizeReels({ items: body.items })
      .filter((r) => r.status === "auto")
      .map((r) => ({ ...r, speaker: { ar: ch.name, en: ch.name } }));
  } catch {
    return [];
  }
}
