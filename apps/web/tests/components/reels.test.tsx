import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { ReelsFeed } from "@/components/ReelsFeed";
import { reelsPrefsStore, type Reel } from "@/lib/reels";
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
  category: "lesson",
  title: { ar: "موعظة", en: "Reminder" },
  status: "pending",
  reviewer: null,
};

beforeEach(() => {
  resetStores();
  reelsPrefsStore.reload();
});

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
    expect(screen.getAllByText("Reviewed by Reviewer A")).toHaveLength(2);
    expect(screen.getAllByRole("link", { name: "Open on YouTube" })[0]).toHaveAttribute("href", base.url);
    expect(screen.getByTestId("reels-position")).toHaveTextContent("1 / 2");
  });
  it("reviewer mode reveals pending reels with a warning banner", async () => {
    render(<ReelsFeed locale="ar" reels={[base, pending]} />);
    expect(document.querySelectorAll("[data-reel]")).toHaveLength(1);
    await userEvent.click(screen.getByTestId("reels-reviewer"));
    expect(document.querySelectorAll("[data-reel]")).toHaveLength(2);
    expect(screen.getByTestId("reel-pending")).toHaveTextContent("لم تتم مراجعة");
    expect(reelsPrefsStore.get().reviewer).toBe(true);
  });
  it("arrow keys move between reels", async () => {
    render(<ReelsFeed locale="en" reels={[base, { ...pending, status: "approved", reviewer: "B" }]} />);
    screen.getByTestId("reels-feed").focus();
    await userEvent.keyboard("{ArrowDown}");
    expect(screen.getByTestId("reels-position")).toHaveTextContent("2 / 2");
    expect(screen.getByTestId("reel-player").getAttribute("src")).toContain("/embed/26dRG7OeL6Q?");
    expect(screen.getByText("Short lesson")).toBeInTheDocument();
  });
});
