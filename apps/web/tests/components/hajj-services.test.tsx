import { render, screen, fireEvent } from "@testing-library/react";
import { HajjServices } from "@/components/HajjServices";
import { HARAM_CROWD_LINKS } from "@/lib/haram-crowd";

describe("HajjServices", () => {
  it("opens the official crowd sources in a new tab and plays the Haram live audio", () => {
    render(<HajjServices locale="ar" tawafHref="#umrah-step-2" />);
    const official = screen.getByTestId("hajj-crowd-official");
    expect(official.getAttribute("href")).toBe(HARAM_CROWD_LINKS.official);
    expect(official.getAttribute("target")).toBe("_blank");
    expect(screen.getByTestId("hajj-crowd-nusuk").getAttribute("href")).toBe(HARAM_CROWD_LINKS.nusuk);
    expect(screen.queryByTestId("library-now")).toBeNull();
    fireEvent.click(screen.getByTestId("hajj-live-makkah"));
    expect(screen.getByTestId("library-now")).toBeTruthy();
    expect(screen.getByText("خريطة الطواف وعدّاد الأشواط").closest("a")?.getAttribute("href")).toBe("#umrah-step-2");
  });
});
