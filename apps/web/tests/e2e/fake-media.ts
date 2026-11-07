import type { Page } from "@playwright/test";
import { expect } from "./fixtures";

/**
 * A controllable stand-in for the app's single `new Audio()` element. Media timing differs between browsers
 * (Playwright Firefox fires 'ended' almost at once for route-fulfilled audio), so tests that check how the
 * player advances replace the element: play() records the source and reports 'playing', and only the test
 * ends an item, by dispatching 'ended' itself. Nothing is decoded and no request is made.
 */
export interface FakeMediaHandle {
  played: string[];
  src: string;
  paused: boolean;
  end(): void;
}
export async function fakeMedia(page: Page): Promise<void> {
  await page.addInitScript(() => {
    const played: string[] = [];
    const elements: FakeMedia[] = []; // the app creates exactly one
    class FakeMedia extends EventTarget {
      preload = "";
      paused = true;
      private source = "";
      constructor() {
        super();
        elements.push(this);
      }
      get src(): string {
        return this.source;
      }
      set src(v: string) {
        this.source = v;
        this.paused = true;
      }
      getAttribute(k: string): string | null {
        return k === "src" && this.source ? this.source : null;
      }
      removeAttribute(k: string): void {
        if (k === "src") this.source = "";
      }
      load(): void {}
      pause(): void {
        this.paused = true;
      }
      play(): Promise<void> {
        const src = this.source;
        played.push(src);
        this.paused = false;
        setTimeout(() => {
          if (!this.paused && this.source === src) this.dispatchEvent(new Event("playing"));
        }, 0);
        return Promise.resolve();
      }
    }
    const current = (): FakeMedia | undefined => elements.at(-1);
    const handle: FakeMediaHandle = {
      played,
      get src() {
        return current()?.src ?? "";
      },
      get paused() {
        return current()?.paused ?? true;
      },
      end() {
        const el = current();
        if (!el) throw new Error("no media element");
        el.paused = true;
        el.dispatchEvent(new Event("ended"));
      },
    };
    (window as unknown as { __media: FakeMediaHandle }).__media = handle;
    (window as unknown as { Audio: unknown }).Audio = FakeMedia;
  });
}
export const media = (page: Page): Promise<{ played: string[]; src: string; paused: boolean }> =>
  page.evaluate(() => {
    const m = (window as unknown as { __media: FakeMediaHandle }).__media;
    return { played: m.played.map((u) => u.split("/").slice(-2).join("/")), src: m.src, paused: m.paused };
  });
export const played = async (page: Page): Promise<string[]> => (await media(page)).played;
/** Ends the current item, as the real element does at the end of an ayah. */
export const endItem = (page: Page): Promise<void> =>
  page.evaluate(() => (window as unknown as { __media: FakeMediaHandle }).__media.end());
export const isPlaying = (page: Page): Promise<void> =>
  expect(page.getByTestId("player-toggle")).toHaveAttribute("data-state", "playing");
