import { render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { VideoSearch } from "@/components/VideoSearch";
import { NasheedsView } from "@/components/NasheedsView";
import { InstallApp } from "@/components/InstallApp";
import { SECTIONS } from "@/components/SectionTiles";
import { videoHistoryStore } from "@/lib/videos";
import { parseNasheeds } from "@/lib/nasheeds";
import { readRepoJson } from "../repo";
import { resetStores } from "./reset";

beforeEach(() => resetStores());

const hitsFetch = (calls: string[]) =>
  (async (u: string) => {
    calls.push(u);
    return new Response(
      JSON.stringify({
        schema: "video-search.v1",
        items: [
          { ref: "abcdefghijk", title: "تفسير سورة الكهف", channel: "قناة", channelId: null, trusted: true },
        ],
      }),
    );
  }) as unknown as typeof fetch;

describe("VideoSearch", () => {
  it("shows the feed until the viewer searches, then Islamic results, and remembers the search", async () => {
    const user = userEvent.setup();
    const calls: string[] = [];
    render(
      <VideoSearch locale="ar" fetchImpl={hitsFetch(calls)}>
        <p data-testid="feed">feed</p>
      </VideoSearch>,
    );
    expect(screen.getByTestId("feed")).toBeInTheDocument();
    await user.type(screen.getByTestId("video-search-input"), "الكهف{Enter}");
    expect(await screen.findByTestId("video-hit-abcdefghijk")).toHaveTextContent("تفسير سورة الكهف");
    expect(screen.queryByTestId("feed")).toBeNull();
    expect(calls).toEqual(["/api/videos/search?q=%D8%A7%D9%84%D9%83%D9%87%D9%81"]);
    expect(videoHistoryStore.get()).toEqual(["الكهف"]);
    await user.click(screen.getByTestId("video-hit-abcdefghijk"));
    expect(screen.getByTestId("video-player").querySelector("iframe")?.getAttribute("src")).toContain(
      "youtube-nocookie.com/embed/abcdefghijk",
    );
    await user.click(screen.getByTestId("video-search-close"));
    expect(screen.getByTestId("feed")).toBeInTheDocument();
  });

  it("lists past searches: tap to search again, or clear them", async () => {
    const user = userEvent.setup();
    videoHistoryStore.set(["موعظة", "تلاوة"]);
    const calls: string[] = [];
    render(
      <VideoSearch locale="ar" fetchImpl={hitsFetch(calls)}>
        <p>feed</p>
      </VideoSearch>,
    );
    const items = screen.getAllByTestId("video-history-item");
    expect(items.map((b) => b.textContent)).toEqual(["موعظة", "تلاوة"]);
    await user.click(items[1]!);
    await waitFor(() => expect(calls).toHaveLength(1));
    expect(videoHistoryStore.get()).toEqual(["تلاوة", "موعظة"]);
    await user.click(screen.getByTestId("video-search-close"));
    await user.click(screen.getByTestId("video-history-clear"));
    expect(videoHistoryStore.get()).toEqual([]);
    expect(screen.queryByTestId("video-history")).toBeNull();
  });

  it("says so when search cannot reach the server", async () => {
    const user = userEvent.setup();
    const down = (async () => new Response("x", { status: 502 })) as unknown as typeof fetch;
    render(
      <VideoSearch locale="en" fetchImpl={down}>
        <p>feed</p>
      </VideoSearch>,
    );
    await user.type(screen.getByTestId("video-search-input"), "quran{Enter}");
    expect(await screen.findByTestId("video-search-failed")).toBeInTheDocument();
  });
});

const nasheeds = parseNasheeds(readRepoJson("apps/mobile/assets/content/nasheeds.v2.json"));

describe("Nasheeds on the website", () => {
  it("has the same list as the mobile app, https audio only, and a section tile", () => {
    expect(nasheeds.length).toBeGreaterThan(20);
    expect(nasheeds.flatMap((m) => m.items).every((n) => n.url.startsWith("https://"))).toBe(true);
    expect(SECTIONS.some((s) => s.path === "nasheeds")).toBe(true);
  });

  it("finds a nasheed by title and plays it", async () => {
    const user = userEvent.setup();
    const first = nasheeds[0]!;
    const n = first.items[0]!;
    render(<NasheedsView locale="ar" loader={() => Promise.resolve(nasheeds)} />);
    expect(await screen.findByTestId("nasheeds-note")).toBeInTheDocument();
    await user.click(screen.getByText(first.name));
    await user.click(await screen.findByTestId(`nasheed-${n.id}`));
    expect(screen.getByTestId("nasheeds-audio").getAttribute("src")).toBe(n.url);
    await user.type(screen.getByTestId("nasheeds-search"), n.title);
    expect(screen.getByTestId("nasheeds-hits")).toHaveTextContent(n.title);
  });
});

describe("Install as an app (Windows desktop shortcut)", () => {
  it("explains how to install before the browser offers it, then shows the install button", async () => {
    render(<InstallApp locale="ar" />);
    expect(screen.getByTestId("install-howto")).toBeInTheDocument();
    const ev = Object.assign(new Event("beforeinstallprompt", { cancelable: true }), {
      prompt: vi.fn(async () => undefined),
      userChoice: Promise.resolve({ outcome: "accepted" as const }),
    });
    window.dispatchEvent(ev);
    const btn = await screen.findByTestId("install-button");
    await userEvent.click(btn);
    expect(ev.prompt).toHaveBeenCalled();
    expect(await screen.findByTestId("install-done")).toBeInTheDocument();
  });
});
