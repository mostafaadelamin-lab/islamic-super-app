import { act, render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { Header } from "@/components/Header";
import { prefsStore } from "@/lib/settings";
import { resetStores } from "./reset";

beforeEach(resetStores);

describe("Top bar tools (owner 2026-11-15)", () => {
  it("switches the site style and light / dark from the top bar", async () => {
    render(<Header locale="ar" />);
    const tools = screen.getByTestId("topbar-tools");
    expect(tools).toBeInTheDocument();
    await userEvent.click(screen.getByTestId("topbar-palette-madinah"));
    expect(prefsStore.get().palette).toBe("madinah");
    expect(screen.getByTestId("topbar-palette-madinah")).toHaveAttribute("aria-pressed", "true");
    await userEvent.click(screen.getByTestId("topbar-palette-emerald"));
    expect(prefsStore.get().palette).toBe("emerald");
    await userEvent.click(screen.getByTestId("topbar-theme"));
    expect(prefsStore.get().theme).toBe("dark");
    await userEvent.click(screen.getByTestId("topbar-theme"));
    expect(prefsStore.get().theme).toBe("light");
  });

  it("«ثبّت التطبيق» opens the browser's install prompt when it is offered", async () => {
    render(<Header locale="ar" />);
    const prompt = vi.fn(async () => undefined);
    const ev = Object.assign(new Event("beforeinstallprompt"), {
      prompt,
      userChoice: Promise.resolve({ outcome: "accepted" as const }),
    });
    act(() => {
      window.dispatchEvent(ev);
    });
    await userEvent.click(screen.getByTestId("topbar-install"));
    expect(prompt).toHaveBeenCalled();
    expect(screen.queryByTestId("topbar-install")).toBeNull();
  });

  it("without a prompt it shows how to install (iPhone: Add to Home Screen)", async () => {
    const ua = vi.spyOn(navigator, "userAgent", "get").mockReturnValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0)");
    render(<Header locale="ar" />);
    await userEvent.click(screen.getByTestId("topbar-install"));
    expect(screen.getByTestId("topbar-install-howto").textContent).toContain("إضافة إلى الشاشة الرئيسية");
    ua.mockRestore();
  });
});
