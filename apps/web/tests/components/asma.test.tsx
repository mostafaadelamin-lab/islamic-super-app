import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { AsmaView } from "@/components/AsmaView";
import { dhikrPlayer } from "@/components/DhikrAudio";
import asma from "@/generated/asma.json";
import asmaAudio from "@/generated/asma-audio.json";
import { act } from "react";
import { resetStores } from "./reset";

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

const NAMES = [
  {
    name: "الرحمن",
    group: null,
    text: "شرح",
    seeAlso: null,
    lessons: ["https://example.org/a.mp3", "https://example.org/b.mp3"],
  },
  { name: "المحيط", group: null, text: "شرح", seeAlso: null, lessons: [] },
];

describe("Names of Allah (web)", () => {
  it("has 99 names; 91 have Sheikh al-Nabulsi's lessons", () => {
    expect((asma as { names: unknown[] }).names).toHaveLength(99);
    expect(Object.keys((asmaAudio as { names: Record<string, string[]> }).names)).toHaveLength(91);
  });

  it("plays a lesson with the player bar, and searches names", async () => {
    render(<AsmaView locale="ar" names={NAMES} />);
    expect(screen.queryByTestId("asma-listen-1")).toBeNull();
    await userEvent.click(screen.getByTestId("asma-listen-0-2"));
    expect(dhikrPlayer.get().url).toBe("https://example.org/b.mp3");
    expect(screen.getByTestId("dhikr-player")).toBeInTheDocument();
    await userEvent.type(screen.getByTestId("asma-search"), "المحيط");
    expect(screen.queryByTestId("asma-0")).toBeNull();
    expect(screen.getByTestId("asma-1")).toBeInTheDocument();
  });
});
