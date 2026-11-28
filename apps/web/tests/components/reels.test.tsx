import { render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { ReelsFeed } from "@/components/ReelsFeed";
import { VideosHub } from "@/components/VideosHub";
import { reelsFeedStore, reelsPrefsStore, savedReelsStore, type Reel } from "@/lib/reels";
import { resetStores } from "./reset";

const base: Reel = {
  id: "yt-hTtlD-u4_HI",
  platform: "youtube",
  ref: "hTtlD-u4_HI",
  url: "https://www.youtube.com/watch?v=hTtlD-u4_HI",
  title: { ar: "تلاوة", en: "Recitation" },
  speaker: { ar: "الشيخ", en: "Sheikh" },
  category: "recitation",
  source: null,
  status: "approved",
  reviewer: "Reviewer A",
  reviewedAt: "2026-11-09",
};
const pending: Reel = {
  ...base,
  id: "yt-26dRG7OeL6Q",
  ref: "26dRG7OeL6Q",
  url: "https://www.youtube.com/watch?v=26dRG7OeL6Q",
  title: { ar: "تلاوة ثانية", en: "Second recitation" },
  status: "pending",
  reviewer: null,
};

const offline = (() => Promise.reject(new Error("offline"))) as unknown as typeof fetch;

beforeEach(() => {
  resetStores();
  reelsPrefsStore.reload();
  vi.stubGlobal("fetch", offline);
});
afterEach(() => vi.unstubAllGlobals());

describe("ReelsFeed", () => {
  it("shows an empty state when nothing is reviewed", () => {
    render(<ReelsFeed locale="en" reels={[pending]} />);
    expect(screen.getByTestId("reels-empty")).toBeInTheDocument();
    expect(screen.queryByTestId("reel-player")).toBeNull();
  });
  it("plays only the reel in view, through the official embed", () => {
    render(
      <ReelsFeed locale="en" reels={[base, { ...pending, status: "approved", reviewer: "Reviewer A" }]} />,
    );
    const players = screen.getAllByTestId("reel-player");
    expect(players).toHaveLength(1);
    expect(players[0]?.getAttribute("src")).toMatch(
      /^https:\/\/www\.youtube-nocookie\.com\/embed\/hTtlD-u4_HI\?/,
    );
    expect(screen.queryByText("Reviewed by Reviewer A")).toBeNull();
    expect(screen.getAllByRole("link", { name: "Open on YouTube" })[0]).toHaveAttribute("href", base.url);
    expect(screen.getByTestId("reels-position")).toHaveTextContent("1 / 2");
  });
  it("never shows pending (unreviewed) reels and has no reviewer switch (owner, 2026-11-13)", () => {
    render(<ReelsFeed locale="ar" reels={[base, pending]} />);
    expect(document.querySelectorAll("[data-reel]")).toHaveLength(1);
    expect(screen.queryByTestId("reels-reviewer")).toBeNull();
    expect(screen.queryByTestId("reel-pending")).toBeNull();
  });
  it("plays Instagram reels through Instagram's official embed, with a blank poster off-screen", async () => {
    const ig: Reel = {
      ...base,
      id: "ig-C1a2B3c4D5e",
      platform: "instagram",
      ref: "C1a2B3c4D5e",
      url: "https://www.instagram.com/reel/C1a2B3c4D5e/",
      title: { ar: "تلاوة", en: "Recitation clip" },
    };
    render(<ReelsFeed locale="en" reels={[ig, base]} />);
    expect(screen.getByTestId("reel-player").getAttribute("src")).toBe(
      "https://www.instagram.com/reel/C1a2B3c4D5e/embed/",
    );
    expect(screen.queryByText("Advice & admonition")).toBeNull();
    expect(screen.getByRole("link", { name: "Open on Instagram" })).toHaveAttribute("href", ig.url);
    screen.getByTestId("reels-feed").focus();
    await userEvent.keyboard("{ArrowDown}");
    expect(screen.getByTestId("reel-player").getAttribute("src")).toContain(
      "youtube-nocookie.com/embed/hTtlD-u4_HI",
    );
    expect(document.querySelector(".reel-poster-blank")).not.toBeNull();
  });
  it("arrow keys move between reels", async () => {
    render(<ReelsFeed locale="en" reels={[base, { ...pending, status: "approved", reviewer: "B" }]} />);
    screen.getByTestId("reels-feed").focus();
    await userEvent.keyboard("{ArrowDown}");
    expect(screen.getByTestId("reels-position")).toHaveTextContent("2 / 2");
    expect(screen.getByTestId("reel-player").getAttribute("src")).toContain("/embed/26dRG7OeL6Q?");
    expect(screen.queryByText("Religious lesson")).toBeNull();
  });
});

const yasser = "yt-UCYuUcfXvsHapABTcPRWCEoQ";
const autoReel = (ref: string, published: string, sourceId = yasser): Reel => ({
  id: `yt-${ref}`,
  platform: "youtube",
  ref,
  url: `https://www.youtube.com/watch?v=${ref}`,
  title: { ar: `تلاوة ${ref}`, en: `Recitation ${ref}` },
  speaker: { ar: "الشيخ ياسر الدوسري", en: "Sheikh Yasser Al-Dosari" },
  category: "recitation",
  source: null,
  status: "auto",
  reviewer: null,
  reviewedAt: null,
  sourceId,
  published,
});
const feedBody = {
  schema: "reels-feed.v1",
  sources: [
    {
      id: yasser,
      channelId: "UCYuUcfXvsHapABTcPRWCEoQ",
      name: { ar: "الشيخ ياسر الدوسري", en: "Sheikh Yasser Al-Dosari" },
      category: "recitation",
      group: "makkah",
    },
  ],
  items: [autoReel("AAAAAAAAAA1", "2026-11-08T10:00:00Z"), autoReel("BBBBBBBBBB2", "2026-11-09T10:00:00Z")],
};
const okFetch = (calls: string[] = []): typeof fetch =>
  (async (url: string) => {
    calls.push(url);
    return new Response(JSON.stringify(feedBody), { status: 200 });
  }) as unknown as typeof fetch;

describe("ReelsFeed: automatic reels from trusted channels", () => {
  it("asks the API for the feed and shows the channel's newest reels first, marked trusted", async () => {
    const calls: string[] = [];
    render(<ReelsFeed locale="en" reels={[pending]} fetchImpl={okFetch(calls)} />);
    await waitFor(() => expect(screen.getByTestId("reels-feed")).toBeInTheDocument());
    expect(calls).toEqual(["/api/v1/reels/feed"]);
    expect(screen.getByTestId("reel-player").getAttribute("src")).toContain("/embed/BBBBBBBBBB2?");
    expect(screen.queryByText("Trusted channel")).toBeNull();
    expect(screen.queryByTestId("reel-pending")).toBeNull();
    // cached: a second mount does not fetch again
    render(<ReelsFeed locale="en" reels={[]} fetchImpl={okFetch(calls)} />);
    expect(calls).toHaveLength(1);
  });
  it("hides a channel, with undo", async () => {
    render(<ReelsFeed locale="ar" reels={[]} fetchImpl={okFetch()} />);
    await waitFor(() => expect(screen.getByTestId("reels-feed")).toBeInTheDocument());
    await userEvent.click(screen.getByTestId("reel-hide-yt-BBBBBBBBBB2"));
    expect(screen.queryByTestId("reels-feed")).toBeNull();
    expect(screen.getByTestId("reels-hidden")).toHaveTextContent("تم إخفاء الشيخ ياسر الدوسري");
    expect(reelsPrefsStore.get().hidden).toEqual([yasser]);
    await userEvent.click(screen.getByRole("button", { name: "تراجع" }));
    expect(screen.getByTestId("reels-feed")).toBeInTheDocument();
    expect(reelsPrefsStore.get().hidden).toEqual([]);
  });
  it("server unreachable: says so and retries", async () => {
    let online = false;
    const f = (async (url: string) => {
      if (!online) throw new Error("offline");
      return okFetch()(url);
    }) as unknown as typeof fetch;
    render(<ReelsFeed locale="en" reels={[]} fetchImpl={f} />);
    await waitFor(() => expect(screen.getByTestId("reels-retry")).toBeInTheDocument());
    expect(screen.getByTestId("reels-empty")).toHaveTextContent("Could not reach YouTube");
    online = true;
    await userEvent.click(screen.getByTestId("reels-retry"));
    await waitFor(() => expect(screen.getByTestId("reels-feed")).toBeInTheDocument());
    expect(reelsFeedStore.get()?.items).toHaveLength(2);
  });
});

describe("videos page (owner 2026-11-27): live, chips, groups, player tabs, save, reciters", () => {
  it("shows the live streams, the chips and the Haramain row; a card opens the player in that tab", async () => {
    render(<VideosHub locale="ar" reels={[]} fetchImpl={okFetch()} />);
    expect(screen.getByTestId("videos-live-live-makkah")).toBeInTheDocument();
    expect(screen.getByTestId("videos-live-live-madinah")).toBeInTheDocument();
    for (const k of ["all", "haramain", "golden", "famous", "saved"]) {
      expect(screen.getByTestId(`videos-tab-${k}`)).toBeInTheDocument();
    }
    await waitFor(() => expect(screen.getByTestId("videos-card-yt-BBBBBBBBBB2")).toBeInTheDocument());
    expect(screen.getByTestId("videos-section-haramain")).toHaveTextContent("أئمة الحرمين");
    await userEvent.click(screen.getByTestId("videos-card-yt-AAAAAAAAAA1"));
    expect(screen.getByTestId("reel-player").getAttribute("src")).toContain("/embed/AAAAAAAAAA1?");
    for (const k of ["all", "haramain", "golden", "live"]) {
      expect(screen.getByTestId(`reels-tab-${k}`)).toBeInTheDocument();
    }
    expect(screen.getByTestId("reels-tab-haramain")).toHaveAttribute("aria-selected", "true");
    expect(screen.getByTestId("reel-group-yt-AAAAAAAAAA1")).toHaveTextContent("أئمة الحرمين");
    await userEvent.click(screen.getByTestId("reels-tab-golden"));
    expect(screen.queryByTestId("reel-player")).toBeNull();
    await userEvent.click(screen.getByTestId("reels-tab-live"));
    expect(screen.getByTestId("live-player").getAttribute("src")).toContain("/embed/IsJTAdC3-Jw?");
    await userEvent.click(screen.getByTestId("reels-back"));
    expect(screen.getByTestId("videos-home")).toBeInTheDocument();
  });
  it("saves a recitation; «المحفوظة» lists it", async () => {
    savedReelsStore.set([]);
    render(<VideosHub locale="ar" reels={[]} fetchImpl={okFetch()} />);
    await waitFor(() => expect(screen.getByTestId("videos-card-yt-BBBBBBBBBB2")).toBeInTheDocument());
    await userEvent.click(screen.getByTestId("videos-card-yt-BBBBBBBBBB2"));
    await userEvent.click(screen.getByTestId("reel-save-yt-BBBBBBBBBB2"));
    expect(savedReelsStore.get().map((r) => r.ref)).toEqual(["BBBBBBBBBB2"]);
    await userEvent.click(screen.getByTestId("reels-back"));
    await userEvent.click(screen.getByTestId("videos-tab-saved"));
    expect(screen.getByTestId("videos-card-yt-BBBBBBBBBB2")).toBeInTheDocument();
  });
  it("reciters list: grouped, unchecking hides a reciter", async () => {
    render(<VideosHub locale="ar" reels={[]} fetchImpl={okFetch()} />);
    await userEvent.click(screen.getByTestId("videos-reciters"));
    await waitFor(() => expect(screen.getByTestId("reciters-group-makkah")).toBeInTheDocument());
    await userEvent.click(screen.getByTestId(`reciter-toggle-${yasser}`));
    expect(reelsPrefsStore.get().hidden).toEqual([yasser]);
  });
});
