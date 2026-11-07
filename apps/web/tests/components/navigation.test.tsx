import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { MainNav } from "@/components/MainNav";
import { LanguageSwitch } from "@/components/LanguageSwitch";
import { Header } from "@/components/Header";
import { Footer } from "@/components/Footer";
import { Compass } from "@/components/Compass";
import { prefsStore } from "@/lib/settings";
import { setPath } from "../setup";
import { resetStores } from "./reset";

beforeEach(resetStores);

describe("MainNav", () => {
  it("renders all destinations and marks the current one", () => {
    setPath("/en/surah/2/");
    render(<MainNav locale="en" />);
    const links = screen.getAllByRole("link");
    expect(links.map((l) => l.getAttribute("href"))).toEqual([
      "/en/",
      "/en/quran/",
      "/en/prayer/",
      "/en/adhkar/",
      "/en/more/",
    ]);
    expect(screen.getByRole("link", { name: "Quran" })).toHaveAttribute("aria-current", "page");
    expect(screen.getByRole("link", { name: "Home" })).not.toHaveAttribute("aria-current");
  });
  it("home is current only on the home path", () => {
    setPath("/ar");
    render(<MainNav locale="ar" />);
    expect(screen.getByRole("link", { name: "الرئيسية" })).toHaveAttribute("aria-current", "page");
    expect(screen.getByRole("navigation")).toHaveAccessibleName("التنقل الرئيسي");
  });
  it("prayer page marks prayer", () => {
    setPath("/ar/prayer/");
    render(<MainNav locale="ar" />);
    expect(screen.getByRole("link", { name: "الصلاة" })).toHaveAttribute("aria-current", "page");
  });
  it("sub-sections mark their tab (Mushaf page → Quran, Hisn → Adhkar, Settings → More)", () => {
    for (const [path, name] of [
      ["/en/page/3/", "Quran"],
      ["/en/hisn/4/", "Adhkar"],
      ["/en/tasbih/", "Adhkar"],
      ["/en/qibla/", "Prayer"],
      ["/en/settings/", "More"],
      ["/en/hajj/", "More"],
    ] as const) {
      setPath(path);
      const { unmount } = render(<MainNav locale="en" />);
      expect(screen.getByRole("link", { name })).toHaveAttribute("aria-current", "page");
      expect(screen.getAllByRole("link").filter((l) => l.getAttribute("aria-current"))).toHaveLength(1);
      unmount();
    }
  });
});

describe("LanguageSwitch", () => {
  it("links to the same page in the other language and persists the choice", async () => {
    setPath("/ar/page/3/");
    render(<LanguageSwitch locale="ar" />);
    const link = screen.getByRole("link", { name: /تغيير اللغة:\s*English/ });
    expect(link).toHaveAttribute("href", "/en/page/3/");
    expect(link).toHaveTextContent("English");
    link.addEventListener("click", (e) => e.preventDefault());
    await userEvent.click(link);
    expect(prefsStore.get().locale).toBe("en");
  });
});

describe("Header/Footer", () => {
  it("header has brand, nav and switch", () => {
    setPath("/en/");
    render(<Header locale="en" />);
    expect(screen.getByRole("link", { name: "Rattil" })).toHaveAttribute("href", "/en/");
    expect(screen.getByTestId("lang-switch")).toHaveAttribute("href", "/ar/");
  });
  it("footer states the app is free and links to about", () => {
    render(<Footer locale="en" />);
    expect(screen.getByText(/no ads, no subscriptions, no purchases/)).toBeInTheDocument();
    expect(screen.getByRole("link", { name: "About" })).toHaveAttribute("href", "/en/about/");
  });
});

describe("Compass", () => {
  it("rotates the needle to the bearing and is labelled", () => {
    render(<Compass bearing={136.25} label="Qibla 136°" />);
    expect(screen.getByRole("img", { name: "Qibla 136°" })).toBeInTheDocument();
    expect(screen.getByTestId("qibla-needle")).toHaveAttribute("transform", "rotate(136.25 100 100)");
  });
});
