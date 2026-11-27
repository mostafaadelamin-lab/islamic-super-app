import { describe, expect, it, beforeEach, afterEach } from "vitest";
import { render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { VideosHub } from "@/components/VideosHub";
import { reelsFeedStore, reelsPrefsStore } from "@/lib/reels";
import { SUGGESTED_CHANNELS, userChannelsStore } from "@/lib/reel-channels";
import { resetStores } from "./reset";

const CH = "UC" + "c".repeat(22);
const reel = (ref: string) => ({
  id: `yt-${ref}`,
  platform: "youtube",
  ref,
  url: `https://www.youtube.com/watch?v=${ref}`,
  title: { ar: "تلاوة سورة الملك", en: "Recitation" },
  speaker: { ar: "", en: "" },
  category: "recitation",
  source: null,
  status: "auto",
  reviewer: null,
  reviewedAt: null,
  sourceId: `yt-${CH}`,
  published: "2026-11-10T00:00:00Z",
});

function api(calls: string[]): typeof fetch {
  return ((url: string) => {
    calls.push(url);
    const j = (b: unknown) => Promise.resolve(new Response(JSON.stringify(b), { status: 200 }));
    if (url.includes("/v1/reels/feed")) return j({ schema: "reels-feed.v1", sources: [], items: [] });
    if (url.includes("/channels/search"))
      return j({
        schema: "channel-search.v1",
        query: "x",
        items: [{ id: CH, title: "قناة الدروس", subs: "١٠ آلاف" }],
      });
    if (url.includes("/v1/reels/channel"))
      return j({ schema: "reels-channel.v1", channelId: CH, items: [reel("CCCCCCCCCC1")] });
    return Promise.resolve(new Response("", { status: 404 }));
  }) as unknown as typeof fetch;
}

beforeEach(() => {
  resetStores();
  reelsPrefsStore.reload();
  reelsFeedStore.reload();
  userChannelsStore.reload();
});
afterEach(() => localStorage.clear());

describe("your channels (as in the app)", () => {
  it("finds a channel, adds it to the videos, and removes it", async () => {
    const calls: string[] = [];
    render(<VideosHub locale="ar" reels={[]} fetchImpl={api(calls)} />);
    await userEvent.click(screen.getByTestId("videos-reciters"));
    expect(screen.getByTestId("channel-manager").textContent).toContain("قنواتك");
    await userEvent.type(screen.getByTestId("channel-query"), "دروس");
    await userEvent.click(screen.getByTestId("channel-search-btn"));
    await userEvent.click(await screen.findByTestId(`channel-add-${CH}`));
    expect(userChannelsStore.get()).toEqual([{ channelId: CH, name: "قناة الدروس" }]);
    await userEvent.click(screen.getByTestId("reels-back"));
    await waitFor(() => expect(screen.getByTestId("videos-card-yt-CCCCCCCCCC1")).toBeInTheDocument());
    expect(calls.some((u) => u.includes(`/v1/reels/channel?id=${CH}`))).toBe(true);
    expect(screen.getByTestId("videos-section-mine")).toHaveTextContent("قناة الدروس");
    await userEvent.click(screen.getByTestId("videos-reciters"));
    await userEvent.click(screen.getByTestId(`channel-remove-${CH}`));
    expect(userChannelsStore.get()).toEqual([]);
    await userEvent.click(screen.getByTestId("reels-back"));
    expect(screen.queryByTestId("videos-section-mine")).toBeNull();
  });

  it("suggests no lesson channels any more (owner 2026-11-27: recitation only)", async () => {
    render(<VideosHub locale="ar" reels={[]} fetchImpl={api([])} />);
    await userEvent.click(screen.getByTestId("videos-reciters"));
    expect(SUGGESTED_CHANNELS).toHaveLength(0);
    expect(screen.queryByTestId("channel-suggested")).toBeNull();
  });
});
