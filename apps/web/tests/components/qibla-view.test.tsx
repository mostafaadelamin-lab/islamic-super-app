import { describe, expect, it } from "vitest";
import { render, screen } from "@testing-library/react";
import { QiblaView } from "@/components/QiblaView";

describe("QiblaView (as in the app)", () => {
  it("shows the distance to the Kaaba, tips and the Google Qibla Finder check", () => {
    render(<QiblaView locale="ar" />);
    expect(screen.getByTestId("qibla-distance").textContent).toMatch(/المسافة إلى الكعبة: [٠-٩]+ كم/);
    expect(screen.getByText("لقراءة دقيقة")).toBeInTheDocument();
    expect(screen.getByTestId("qibla-map-check").getAttribute("href")).toBe("https://qiblafinder.withgoogle.com/");
  });
});
