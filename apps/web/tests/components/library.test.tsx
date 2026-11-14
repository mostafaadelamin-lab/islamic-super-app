import { fireEvent, render, screen } from "@testing-library/react";
import { RecitationLibrary } from "@/components/RecitationLibrary";
import { MP3_API } from "../mp3quran-fixture";

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
    return Promise.resolve(new Response(JSON.stringify(MP3_API[key])));
  });
};

describe("RecitationLibrary", () => {
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
    fireEvent.click(screen.getByTestId("library-back"));
    fireEvent.click(screen.getByTestId("library-tab-radios"));
    fireEvent.click(screen.getByTestId("library-radio-1"));
    expect(screen.getByTestId("library-audio").getAttribute("src")).toBe(
      "https://backup.qurango.net/radio/ibrahim_alakdar",
    );
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
