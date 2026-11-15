import { act, render, screen } from "@testing-library/react";
import { UpdateBanner } from "@/components/UpdateBanner";
import { registerServiceWorker } from "@/lib/sw-client";

describe("New upload while the site is open (owner 2026-11-15)", () => {
  it("shows «تحديث جديد متاح» once a new version takes over, and checks for updates", async () => {
    const target = new EventTarget();
    const update = vi.fn(async () => undefined);
    const reg = { update, active: { postMessage: vi.fn() } };
    const sw = Object.assign(target, {
      controller: { postMessage: vi.fn() },
      register: vi.fn(async () => reg),
      ready: Promise.resolve(reg),
    });
    registerServiceWorker({ serviceWorker: sw } as unknown as Navigator);
    render(<UpdateBanner locale="ar" />);
    await act(async () => {
      await Promise.resolve();
    });
    expect(update).toHaveBeenCalled();
    expect(sw.register).toHaveBeenCalledWith("/sw.js", expect.objectContaining({ updateViaCache: "none" }));
    expect(screen.queryByTestId("update-banner")).toBeNull();
    act(() => {
      target.dispatchEvent(new Event("controllerchange"));
    });
    expect(screen.getByTestId("update-banner").textContent).toContain("تحديث جديد متاح");
  });
});
