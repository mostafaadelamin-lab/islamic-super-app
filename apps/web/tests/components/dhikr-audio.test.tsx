import { act, fireEvent, render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { HisnItems } from "@/components/HisnItems";
import { dhikrPlayer } from "@/components/DhikrAudio";
import { HISN } from "@/lib/hisn";
import { hisnExtras } from "@/lib/dhikr-extras";
import { resetStores } from "./reset";

const CH = HISN[1]!; // chapter 2, item 5 has a recording and a source hadith

beforeEach(() => {
  resetStores();
  vi.spyOn(HTMLMediaElement.prototype, "play").mockImplementation(function (this: HTMLMediaElement) {
    this.dispatchEvent(new Event("playing"));
    return Promise.resolve();
  });
  vi.spyOn(HTMLMediaElement.prototype, "pause").mockImplementation(function (this: HTMLMediaElement) {
    this.dispatchEvent(new Event("pause"));
  });
  vi.spyOn(HTMLMediaElement.prototype, "load").mockImplementation(() => {});
});
afterEach(() => {
  act(() => dhikrPlayer.stop());
  vi.restoreAllMocks();
});

describe("dhikr listening and source hadith (web)", () => {
  it("shows a play/pause bar while listening; stop and the end of the recording hide it", async () => {
    render(
      <HisnItems
        locale="ar"
        chapterId={2}
        title={CH.title}
        items={CH.items}
        extras={hisnExtras(2, CH.items.length)}
      />,
    );
    expect(screen.queryByTestId("dhikr-player")).toBeNull();
    await userEvent.click(screen.getByTestId("hisn-5-listen"));
    expect(screen.getByTestId("dhikr-player")).toBeInTheDocument();
    await userEvent.click(screen.getByTestId("dhikr-player-toggle"));
    expect(dhikrPlayer.get().playing).toBe(false);
    expect(screen.getByTestId("dhikr-player")).toBeInTheDocument(); // paused: the bar stays
    await userEvent.click(screen.getByTestId("dhikr-player-toggle"));
    expect(dhikrPlayer.get().playing).toBe(true);
    await userEvent.click(screen.getByTestId("dhikr-player-stop"));
    expect(screen.queryByTestId("dhikr-player")).toBeNull();
    await userEvent.click(screen.getByTestId("hisn-5-listen"));
    const audio = (HTMLMediaElement.prototype.play as unknown as { mock: { contexts: HTMLMediaElement[] } })
      .mock.contexts[0]!;
    act(() => {
      fireEvent(audio, new Event("ended"));
    });
    expect(screen.queryByTestId("dhikr-player")).toBeNull(); // no loop
  });

  it("the hadith button shows the source hadith", async () => {
    render(
      <HisnItems
        locale="ar"
        chapterId={2}
        title={CH.title}
        items={CH.items}
        extras={hisnExtras(2, CH.items.length)}
      />,
    );
    await userEvent.click(screen.getByTestId("hisn-5-hadith"));
    expect(screen.getByTestId("hisn-5-hadith-text")).toHaveTextContent("التخريج");
  });
});
