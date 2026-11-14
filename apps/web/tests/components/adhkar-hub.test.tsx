import { describe, expect, it } from "vitest";
import { render, screen, act } from "@testing-library/react";
import { AdhkarHub } from "@/components/AdhkarHub";
import { HisnIndex } from "@/components/HisnIndex";

describe("AdhkarHub (the app's adhkar page)", () => {
  it("links daily adhkar and duas to their Hisn al-Muslim sections and plays Alafasy's adhkar", () => {
    render(<AdhkarHub locale="ar" />);
    expect(screen.getByText("الأذكار اليومية")).toBeInTheDocument();
    expect(screen.getByText("الأدعية")).toBeInTheDocument();
    expect(screen.getByTestId("adhkar-hub-sleep").getAttribute("href")).toBe("/ar/hisn/#sleep");
    expect(screen.getByTestId("adhkar-hub-travel").getAttribute("href")).toBe("/ar/hisn/#travel");
    for (const s of ["morning", "evening"]) {
      const audio = screen.getByTestId(`adhkar-audio-${s}`).querySelector("audio");
      expect(audio?.getAttribute("src")).toBe(`/audio/adhkar_${s}_alafasy.mp3`);
      expect(audio?.getAttribute("preload")).toBe("none");
    }
    expect(screen.getAllByText(/مشاري راشد العفاسي/)).toHaveLength(2);
  });

  it("Hisn al-Muslim opens the section named in the URL hash", () => {
    window.location.hash = "#sleep";
    render(
      <HisnIndex
        locale="ar"
        chapters={[
          { id: 3, title: "أذكار الاستيقاظ" },
          { id: 40, title: "دعاء السفر" },
        ]}
        sections={[
          { id: "sleep", chapters: [3] },
          { id: "travel", chapters: [40] },
        ]}
      />,
    );
    expect(screen.getByTestId("hisn-section-sleep").getAttribute("aria-pressed")).toBe("true");
    expect(screen.queryByText("دعاء السفر")).toBeNull();
    act(() => {
      window.location.hash = "#travel";
      window.dispatchEvent(new HashChangeEvent("hashchange"));
    });
    expect(screen.getByText("دعاء السفر")).toBeInTheDocument();
    window.location.hash = "";
  });
});
