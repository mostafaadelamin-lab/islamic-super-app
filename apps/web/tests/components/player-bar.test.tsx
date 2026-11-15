import { render, screen } from "@testing-library/react";
import { afterEach, describe, expect, it, vi } from "vitest";
import { PlayerBar } from "@/components/PlayerBar";
import { player, type PlayerState } from "@/lib/audio-player";

vi.mock("next/navigation", () => ({ usePathname: () => "/ar/more/" }));

describe("bottom recitation player (owner 2026-11-15)", () => {
  afterEach(() => vi.restoreAllMocks());

  it("its title takes you back to the Mushaf page at the ayah being recited", () => {
    const st: PlayerState = {
      queue: [{ kind: "ayah", s: 2, a: 255 }],
      cursor: { index: 0, plays: 0 },
      status: "playing",
      error: null,
      src: null,
    };
    vi.spyOn(player, "get").mockReturnValue(st);
    render(<PlayerBar locale="ar" />);
    const link = screen.getByTestId("player-open");
    expect(link.getAttribute("href")).toMatch(/\/ar\/page\/42\/?#a-2-255$/);
    expect(link.getAttribute("title")).toBe("افتح المصحف عند الآية التي تُتلى");
  });
});
