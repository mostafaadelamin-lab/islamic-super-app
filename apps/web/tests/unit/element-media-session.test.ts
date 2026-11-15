import { afterEach, describe, expect, it, vi } from "vitest";
import { claimMediaSession, resetElementMediaSessionForTests } from "@/lib/element-media-session";
import { stepTrack, type Track } from "@/components/RecitationLibrary";

describe("background audio on the website (owner, 2026-11-12)", () => {
  afterEach(() => {
    vi.unstubAllGlobals();
    resetElementMediaSessionForTests();
  });

  it("a library surah is followed by the next one; the last has no next", () => {
    const list: Track[] = [1, 2, 3].map((n) => ({
      key: `m:${n}`,
      url: `u${n}`,
      live: false,
      title: `s${n}`,
    }));
    list.forEach((x) => (x.playlist = list));
    expect(stepTrack(list[0]!, 1)?.key).toBe("m:2");
    expect(stepTrack(list[2]!, 1)).toBeNull();
    expect(stepTrack(list[1]!, -1)?.key).toBe("m:1");
    expect(stepTrack({ key: "radio", url: "r", live: true, title: "r" }, 1)).toBeNull();
  });

  it("the lock screen gets the title and next/previous only when there is a list", () => {
    const handlers = new Map<string, unknown>();
    const ms = {
      metadata: null as unknown,
      playbackState: "none",
      setActionHandler: (a: string, fn: unknown) => handlers.set(a, fn),
    };
    vi.stubGlobal("navigator", { mediaSession: ms });
    vi.stubGlobal(
      "MediaMetadata",
      class {
        constructor(public init: { title: string }) {}
      },
    );
    const el = document.createElement("audio");
    const next = vi.fn();
    claimMediaSession(el, { title: "سورة البقرة", next });
    expect((ms.metadata as { init: { title: string } }).init.title).toBe("سورة البقرة");
    expect(handlers.get("nexttrack")).toBe(next);
    expect(handlers.get("previoustrack")).toBeNull();
    claimMediaSession(el, { title: "إذاعة" });
    expect(handlers.get("nexttrack")).toBeNull();
    expect(typeof handlers.get("pause")).toBe("function");
  });

  it("the lock screen shows the elapsed time and length, and its seek bar moves the audio (owner 2026-11-15)", () => {
    const handlers = new Map<string, (d: { seekTime?: number; seekOffset?: number }) => void>();
    const states: unknown[] = [];
    const ms = {
      metadata: null as unknown,
      playbackState: "none",
      setActionHandler: (a: string, fn: (d: { seekTime?: number }) => void) => handlers.set(a, fn),
      setPositionState: (s?: unknown) => states.push(s),
    };
    vi.stubGlobal("navigator", { mediaSession: ms });
    const el = document.createElement("audio");
    let duration = Number.NaN;
    Object.defineProperty(el, "duration", { get: () => duration });
    claimMediaSession(el, { title: "سورة البقرة" });
    expect(states.at(-1)).toBeUndefined(); // no length yet: no bar
    duration = 8600;
    el.currentTime = 120;
    el.dispatchEvent(new Event("durationchange"));
    expect(states.at(-1)).toEqual({ duration: 8600, position: 120, playbackRate: 1 });
    handlers.get("seekto")!({ seekTime: 600 });
    expect(el.currentTime).toBe(600);
    el.dispatchEvent(new Event("seeked"));
    expect(states.at(-1)).toEqual({ duration: 8600, position: 600, playbackRate: 1 });
    // Another player takes the session: the first one no longer updates it.
    const other = document.createElement("audio");
    claimMediaSession(other, { title: "إذاعة" });
    const n = states.length;
    el.dispatchEvent(new Event("seeked"));
    expect(states.length).toBe(n);
  });
});
