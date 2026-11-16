import { fireEvent, render, screen } from "@testing-library/react";
import { RecitationLibrary } from "@/components/RecitationLibrary";
import { MP3_API } from "../mp3quran-fixture";
import { readRepoJson } from "../repo";

const SHABIB = readRepoJson<unknown>("content/shabib/dist/shabib.v1.json");

beforeEach(() => {
  localStorage.clear();
  vi.spyOn(HTMLMediaElement.prototype, "play").mockResolvedValue(undefined);
});
afterEach(() => {
  vi.unstubAllGlobals();
  vi.restoreAllMocks();
});

const serve = (): void => {
  vi.stubGlobal("fetch", (url: string) => {
    const key = url.split("/").pop()!.split("?")[0] as keyof typeof MP3_API;
    if ((key as string) === "shabib.json") return Promise.resolve(new Response(JSON.stringify(SHABIB)));
    return Promise.resolve(new Response(JSON.stringify(MP3_API[key])));
  });
};

describe("RecitationLibrary", () => {
  it("lists Sheikh Mohamed Ahmed Shabib with the reciters, in name order, and opens him inside the library", async () => {
    serve();
    render(<RecitationLibrary locale="ar" />);
    const row = await screen.findByTestId("library-reciter-shabib");
    const names = [...screen.getByTestId("library-reciters").querySelectorAll("li strong")].map(
      (x) => x.textContent!,
    );
    expect(names).toContain("محمد أحمد شبيب");
    expect([...names].sort((a, b) => (a < b ? -1 : Number(a > b)))).toEqual(names);
    // only for Hafs (or all riwayat)
    fireEvent.change(screen.getByTestId("library-rewaya"), { target: { value: "2" } });
    expect(screen.queryByTestId("library-reciter-shabib")).toBeNull();
    fireEvent.change(screen.getByTestId("library-rewaya"), { target: { value: "" } });
    fireEvent.change(screen.getByTestId("library-search"), { target: { value: "شبيب" } });
    expect(screen.getByTestId("library-reciters").querySelectorAll("li")).toHaveLength(1);
    fireEvent.click(screen.getByTestId("library-reciter-shabib"));
    expect(screen.getByTestId("library-shabib").textContent).toContain("محمد أحمد شبيب");
    // Owner 2026-11-16: his recitation's player sits under its row, not at the top of the page.
    const first = await screen.findByTestId("shabib-m2");
    fireEvent.click(first);
    expect(screen.getByTestId("library-now").textContent).toContain("ما تيسّر من سورة البقرة");
    expect(first.closest("li")!.contains(screen.getByTestId("library-now"))).toBe(true);
    expect(screen.queryByTestId("library-now-top")).toBeNull();
    fireEvent.click(screen.getByTestId("library-back"));
    expect(screen.getByTestId("library-reciters")).toBeTruthy();
    // Back on the list: the buttons move to the top so they stay reachable.
    expect(screen.getByTestId("library-now-top")).toBeTruthy();
    expect(row).toBeTruthy();
  });

  it("filters by riwaya, opens a reciter, plays a surah and a radio", async () => {
    serve();
    render(<RecitationLibrary locale="ar" />);
    expect(await screen.findByTestId("library-reciter-153")).toBeTruthy();
    expect(screen.getByTestId("library-source").textContent).not.toContain("mp3quran");
    fireEvent.change(screen.getByTestId("library-rewaya"), { target: { value: "2" } });
    expect(screen.queryByTestId("library-reciter-153")).toBeNull();
    fireEvent.click(screen.getByTestId("library-reciter-7"));
    expect((screen.getByTestId("library-moshaf") as HTMLSelectElement).value).toBe("71");
    fireEvent.click(screen.getByTestId("library-surah-36"));
    expect(screen.getByTestId("library-audio").getAttribute("src")).toBe(
      "https://cdn.mp3quran.net/warsh/036.mp3",
    );
    expect(screen.getByTestId("library-now").textContent).toContain("سورة يس");
    // Owner 2026-11-15: the player sits in the row of the surah playing, not at the top of the page.
    const row = screen.getByTestId("library-surah-36").closest("li")!;
    expect(row.contains(screen.getByTestId("library-now"))).toBe(true);
    expect(screen.queryByTestId("library-now-top")).toBeNull();
    expect((screen.getByTestId("library-next") as HTMLButtonElement).disabled).toBe(true);
    fireEvent.click(screen.getByTestId("library-prev"));
    expect(screen.getByTestId("library-audio").getAttribute("src")).toBe(
      "https://cdn.mp3quran.net/warsh/001.mp3",
    );
    expect(
      screen.getByTestId("library-surah-1").closest("li")!.contains(screen.getByTestId("library-now")),
    ).toBe(true);
    fireEvent.click(screen.getByTestId("library-back"));
    // Its row is no longer listed: the buttons stay reachable at the top.
    expect(screen.getByTestId("library-now-top").textContent).toContain("سورة الفاتحة");
    fireEvent.click(screen.getByTestId("library-tab-radios"));
    fireEvent.click(screen.getByTestId("library-radio-1"));
    expect(screen.getByTestId("library-audio").getAttribute("src")).toBe(
      "https://backup.qurango.net/radio/ibrahim_alakdar",
    );
    expect(
      screen.getByTestId("library-radio-1").closest("li")!.contains(screen.getByTestId("library-now")),
    ).toBe(true);
  });

  it("lists the live Holy Mosques radios first and plays the Cairo radio", async () => {
    serve();
    render(<RecitationLibrary locale="ar" />);
    fireEvent.click(await screen.findByTestId("library-tab-radios"));
    const live = screen.getByTestId("library-live-radios").textContent ?? "";
    expect(live.indexOf("المسجد الحرام")).toBeGreaterThanOrEqual(0);
    expect(live.indexOf("المسجد النبوي")).toBeGreaterThan(live.indexOf("المسجد الحرام"));
    expect(live).not.toMatch(/holol|radiojar/i);
    fireEvent.click(screen.getByTestId("library-live-eg"));
    expect(screen.getByTestId("library-audio").getAttribute("src")).toBe(
      "https://stream.radiojar.com/8s5u5tpdtwzuv",
    );
    fireEvent.click(screen.getByTestId("library-live-makkah"));
    expect(screen.getByTestId("library-now").textContent).toContain("المسجد الحرام");
  });

  it("offline with nothing saved: an error and a retry", async () => {
    vi.stubGlobal("fetch", () => Promise.reject(new Error("offline")));
    render(<RecitationLibrary locale="en" />);
    expect(await screen.findByTestId("library-error")).toBeTruthy();
    serve();
    fireEvent.click(screen.getByTestId("library-retry"));
    expect(await screen.findByTestId("library-reciter-7")).toBeTruthy();
  });
});
