import { render, screen, within } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { FirstRunTour, TourReplayButton } from "@/components/FirstRunTour";
import { firstRunStore } from "@/lib/first-run";
import { adhanStore } from "@/lib/adhan-alerts";
import { prayerStore } from "@/lib/settings";
import { resetStores } from "./reset";

beforeEach(() => resetStores());
afterEach(() => vi.unstubAllGlobals());

async function toSetup(): Promise<void> {
  for (let i = 0; i < 5; i++) await userEvent.click(screen.getByTestId("tour-next"));
  expect(screen.getByTestId("tour-setup")).toBeInTheDocument();
}

describe("first visit tour (owner 2026-11-14)", () => {
  it("shows the features one by one; Skip goes to the setup, Start closes it for good", async () => {
    const { unmount } = render(<FirstRunTour locale="en" />);
    const dialog = await screen.findByRole("dialog");
    expect(within(dialog).getByText("Welcome to Rattil wa Salli")).toBeInTheDocument();
    expect(within(dialog).getByText("Page 1 of 6")).toBeInTheDocument();
    await userEvent.click(screen.getByTestId("tour-next"));
    expect(screen.getByText("The Holy Quran")).toBeInTheDocument();
    await userEvent.click(screen.getByTestId("tour-back"));
    expect(screen.getByText("Welcome to Rattil wa Salli")).toBeInTheDocument();
    await userEvent.click(screen.getByTestId("tour-skip"));
    expect(screen.getByTestId("tour-setup")).toBeInTheDocument();
    await userEvent.click(screen.getByTestId("tour-start"));
    expect(screen.queryByTestId("first-run")).toBeNull();
    expect(firstRunStore.get().done).toBe(true);
    unmount();
    render(<FirstRunTour locale="en" />);
    expect(screen.queryByTestId("first-run")).toBeNull();
  });

  it("Arabic, with Arabic digits", async () => {
    render(<FirstRunTour locale="ar" />);
    expect(await screen.findByText("أهلًا بك في «رتّل وصلِّ»")).toBeInTheDocument();
    expect(screen.getByText("الصفحة ١ من ٦")).toBeInTheDocument();
  });

  it("setup: location saves the position, adhan asks for notifications; honest about browsers", async () => {
    const requestPermission = vi.fn().mockResolvedValue("granted");
    vi.stubGlobal("Notification", Object.assign(vi.fn(), { permission: "default", requestPermission }));
    const getCurrentPosition = vi.fn((ok: PositionCallback) =>
      ok({ coords: { latitude: 30.04449, longitude: 31.23571 } } as GeolocationPosition),
    );
    Object.defineProperty(navigator, "geolocation", { value: { getCurrentPosition }, configurable: true });
    render(<FirstRunTour locale="en" />);
    await screen.findByRole("dialog");
    await toSetup();
    expect(screen.queryByTestId("tour-skip")).toBeNull();
    expect(screen.getByText(/browsers do not allow alerts with the site closed/)).toBeInTheDocument();
    expect(screen.getByText(/cannot override the phone's silent mode/)).toBeInTheDocument();

    // Owner: both are asked as soon as the setup opens, without another tap.
    expect(getCurrentPosition).toHaveBeenCalledTimes(1);
    expect(prayerStore.get().custom).toMatchObject({ lat: 30.0445, lng: 31.2357 });
    expect(screen.getByTestId("tour-location-done")).toBeInTheDocument();
    expect(requestPermission).toHaveBeenCalledTimes(1);
    expect(adhanStore.get().enabled).toBe(true);
    expect(await screen.findByTestId("tour-adhan-done")).toBeInTheDocument();

    await userEvent.click(screen.getByTestId("tour-start"));
    expect(screen.queryByTestId("first-run")).toBeNull();
    expect(firstRunStore.get().done).toBe(true);
  });

  it("location refused: says so and points to the city list", async () => {
    const getCurrentPosition = vi.fn((_ok: PositionCallback, err: PositionErrorCallback) =>
      err({ code: 1 } as GeolocationPositionError),
    );
    Object.defineProperty(navigator, "geolocation", { value: { getCurrentPosition }, configurable: true });
    render(<FirstRunTour locale="en" />);
    await screen.findByRole("dialog");
    await toSetup();
    expect(screen.getByRole("status")).toHaveTextContent("You can choose your city on the Prayer page.");
    expect(prayerStore.get().custom).toBeNull();
  });

  it("Escape closes it; Settings shows it again", async () => {
    render(
      <>
        <FirstRunTour locale="en" />
        <TourReplayButton locale="en" />
      </>,
    );
    await screen.findByRole("dialog");
    await userEvent.keyboard("{Escape}");
    expect(screen.queryByTestId("first-run")).toBeNull();
    vi.stubGlobal("scrollTo", vi.fn());
    await userEvent.click(screen.getByTestId("tour-replay"));
    expect(await screen.findByTestId("tour-slide-welcome")).toBeInTheDocument();
  });
});
