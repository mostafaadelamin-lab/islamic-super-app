import { render, screen, fireEvent } from "@testing-library/react";
import { HajjServices } from "@/components/HajjServices";
import { HARAM_CROWD_LINKS, SHOW_HARAM_CROWD } from "@/lib/haram-crowd";

describe("HajjServices", () => {
  it("hides the crowd card for now (owner 2026-11-15) and plays the Haram live audio", () => {
    expect(SHOW_HARAM_CROWD).toBe(false);
    render(<HajjServices locale="ar" tawafHref="#umrah-step-2" />);
    expect(screen.queryByTestId("hajj-crowd")).toBeNull();
    expect(HARAM_CROWD_LINKS.official).toContain("alharamain.gov.sa");
    expect(screen.queryByTestId("library-now")).toBeNull();
    fireEvent.click(screen.getByTestId("hajj-live-makkah"));
    expect(screen.getByTestId("library-now")).toBeTruthy();
    expect(screen.getByText("خريطة الطواف وعدّاد الأشواط").closest("a")?.getAttribute("href")).toBe(
      "#umrah-step-2",
    );
  });
});
