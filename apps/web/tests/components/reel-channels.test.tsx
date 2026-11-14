import { describe, expect, it, beforeEach, afterEach } from "vitest";
import { render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { ReelsFeed } from "@/components/ReelsFeed";
import { reelsFeedStore, reelsPrefsStore } from "@/lib/reels";
import { SUGGESTED_CHANNELS, userChannelsStore } from "@/lib/reel-channels";
import { resetStores } from "./reset";

const CH = "UC" + "c".repeat(22);
const reel = (ref: string) => ({
  id: `yt-${ref}`,
  platform: "youtube",
  ref,
  url: `https://www.youtube.com/watch?v=${ref}`,
  title: { ar: "درس", en: "Lesson" },
  speaker: { ar: "", en: "" },
  category: "lesson",
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
      return j({ schema: "channel-search.v1", query: "x", items: [{ id: CH, title: "قناة الدروس", subs: "١٠ آلاف" }] });
    if (url.includes("/v1/reels/channel")) return j({ schema: "reels-channel.v1", channelId: CH, items: [reel("CCCCCCCCCC1")] });
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
    render(<ReelsFeed locale="ar" reels={[]} fetchImpl={api(calls)} />);
    expect(screen.getByTestId("channel-manager").textContent).toContain("قنواتك");
    await userEvent.type(screen.getByTestId("channel-query"), "دروس");
    await userEvent.click(screen.getByTestId("channel-search-btn"));
    await userEvent.click(await screen.findByTestId(`channel-add-${CH}`));
    expect(userChannelsStore.get()).toEqual([{ channelId: CH, name: "قناة الدروس" }]);
    await waitFor(() => expect(document.querySelectorAll("[data-reel]")).toHaveLength(1));
    expect(calls.some((u) => u.includes(`/v1/reels/channel?id=${CH}`))).toBe(true);
    expect(screen.getAllByText("قناة الدروس").length).toBeGreaterThan(0);
    await userEvent.click(screen.getByTestId(`channel-remove-${CH}`));
    expect(userChannelsStore.get()).toEqual([]);
    await waitFor(() => expect(document.querySelectorAll("[data-reel]")).toHaveLength(0));
  });

  it("lists the app's suggested Islamic channels with an add button", () => {
    render(<ReelsFeed locale="ar" reels={[]} fetchImpl={api([])} />);
    expect(SUGGESTED_CHANNELS.length).toBeGreaterThan(5);
    const first = SUGGESTED_CHANNELS[0]!;
    expect(screen.getByTestId("channel-suggested").textContent).toContain(first.name.ar);
    expect(screen.getByTestId(`channel-add-${first.channelId}`)).toBeInTheDocument();
  });
});
