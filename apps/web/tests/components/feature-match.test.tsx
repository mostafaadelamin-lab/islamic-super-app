import { act, fireEvent, render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { SaveAudioButton } from "@/components/SaveAudioButton";
import { LiveCompass } from "@/components/LiveCompass";
import { TasbihView } from "@/components/TasbihView";
import { PrayerMonth } from "@/components/PrayerMonth";
import { librarySavedStore, storySavedStore } from "@/lib/audio-offline";
import { tasbihStore, BEAD_STYLES } from "@/lib/tasbih";
import { accuracyFromEvent, turnAngle } from "@/lib/qibla";
import { monthImageHeight } from "@/lib/month-image";
import { resetStores } from "./reset";

/** The audio cache, in memory. */
function fakeCaches(): Map<string, Response> {
  const store = new Map<string, Response>();
  const cache = {
    match: (u: string) => Promise.resolve(store.get(u)),
    put: (u: string, r: Response) => (store.set(u, r), Promise.resolve()),
    delete: (u: string) => Promise.resolve(store.delete(u)),
  };
  vi.stubGlobal("caches", { open: () => Promise.resolve(cache) });
  vi.stubGlobal(
    "fetch",
    vi.fn(() => Promise.resolve(new Response("mp3", { status: 200 }))),
  );
  return store;
}

beforeEach(() => {
  resetStores();
  localStorage.clear();
  storySavedStore.reload();
  librarySavedStore.reload();
  tasbihStore.reload();
});
afterEach(() => {
  vi.unstubAllGlobals();
  vi.restoreAllMocks();
});

describe("offline save of story episodes and library surahs (as in the app)", () => {
  it.each([
    ["story episode", storySavedStore, "https://archive.org/download/x/ep1.mp3"],
    ["library surah", librarySavedStore, "https://server8.mp3quran.net/afs/036.mp3"],
  ])("saves a %s into the audio cache and deletes it again", async (_n, store, url) => {
    const cache = fakeCaches();
    const user = userEvent.setup();
    render(<SaveAudioButton locale="ar" store={store} url={url} testId="save" />);
    await user.click(await screen.findByTestId("save"));
    expect(await screen.findByText(/محفوظ/)).toBeInTheDocument();
    expect(cache.has(url)).toBe(true);
    expect(store.get()).toEqual([url]);
    await user.click(screen.getByTestId("save"));
    expect(cache.size).toBe(0);
    expect(store.get()).toEqual([]);
  });

  it("shows nothing where the browser cannot keep files", () => {
    vi.stubGlobal("caches", undefined);
    render(<SaveAudioButton locale="ar" store={storySavedStore} url="https://a.b/c.mp3" testId="save" />);
    expect(screen.queryByTestId("save")).toBeNull();
  });

  it("marks a failed download and keeps nothing", async () => {
    fakeCaches();
    vi.stubGlobal(
      "fetch",
      vi.fn(() => Promise.reject(new Error("offline"))),
    );
    render(<SaveAudioButton locale="ar" store={storySavedStore} url="https://a.b/c.mp3" testId="save" />);
    await userEvent.click(await screen.findByTestId("save"));
    expect(await screen.findByText(/⚠/)).toBeInTheDocument();
    expect(storySavedStore.get()).toEqual([]);
  });
});

describe("tasbih bead looks (the app's five)", () => {
  it("picks a look, which also switches to the beads, and keeps it", async () => {
    render(<TasbihView locale="ar" />);
    for (const look of BEAD_STYLES) expect(screen.getByTestId(`tasbih-style-${look}`)).toBeInTheDocument();
    expect(screen.getByTestId("tasbih-style-wood").textContent).toContain("خشب");
    await userEvent.click(screen.getByTestId("tasbih-style-pearl"));
    expect(tasbihStore.get()).toMatchObject({ style: "pearl", mode: "beads" });
    expect(screen.getByTestId("tasbih-tap").querySelector('[data-look="pearl"]')).not.toBeNull();
    expect(screen.getByTestId("tasbih-style-pearl").getAttribute("aria-pressed")).toBe("true");
  });
});

describe("live Qibla compass: turn hint and calibration (as in the app)", () => {
  it("turn angle and the iOS accuracy", () => {
    expect(turnAngle(136, 100)).toBe(36);
    expect(turnAngle(136, 170)).toBe(-34);
    expect(accuracyFromEvent({ alpha: 0, webkitCompassAccuracy: 12 })).toBe(12);
    expect(accuracyFromEvent({ alpha: 0, webkitCompassAccuracy: -1 })).toBe(-1);
    expect(accuracyFromEvent({ alpha: 0 })).toBeNull();
  });

  const orient = (heading: number, accuracy?: number): void => {
    const e = new Event("deviceorientation") as Event & Record<string, unknown>;
    e.alpha = 0;
    e.webkitCompassHeading = heading;
    if (accuracy !== undefined) e.webkitCompassAccuracy = accuracy;
    act(() => {
      window.dispatchEvent(e);
    });
  };

  it("says which way and how far to turn, the accuracy, and asks for calibration when it is poor", () => {
    // Makkah itself: no magnetic declination to speak of is needed for the check, use lat/lng with ~0.
    render(<LiveCompass locale="ar" bearing={90} lat={0} lng={0} />);
    const decl = Number(screen.getByTestId("live-compass").dataset.declination);
    orient(60 - decl, 8);
    expect(screen.getByTestId("compass-status").textContent).toBe("استدر يمينًا ٣٠°");
    expect(screen.getByTestId("compass-accuracy").textContent).toBe("دقة البوصلة الآن: ± ٨°");
    expect(screen.queryByTestId("compass-calibrate")).toBeNull();
    orient(120 - decl, 40);
    expect(screen.getByTestId("compass-status").textContent).toBe("استدر يسارًا ٣٠°");
    expect(screen.getByTestId("compass-calibrate").textContent).toContain("البوصلة تحتاج معايرة");
    orient(90 - decl, -1);
    expect(screen.getByTestId("compass-status").textContent).toBe("أنت متجه نحو القبلة");
    expect(screen.getByTestId("compass-calibrate")).toBeInTheDocument();
  });
});

describe("monthly calendar shared as a picture", () => {
  it("sizes the picture for the month", () => {
    expect(monthImageHeight(30)).toBeGreaterThan(monthImageHeight(29));
  });

  it("falls back to text where no picture can be drawn (no canvas)", async () => {
    const share = vi.fn(() => Promise.resolve());
    Object.defineProperty(navigator, "share", { value: share, configurable: true });
    render(<PrayerMonth locale="ar" />);
    fireEvent.click(await screen.findByTestId("month-share"));
    await vi.waitFor(() => expect(share).toHaveBeenCalled());
    const arg = (share.mock.calls[0] as unknown as [ShareData])[0];
    expect(arg.text).toContain("الفجر");
    Object.defineProperty(navigator, "share", { value: undefined, configurable: true });
  });
});
