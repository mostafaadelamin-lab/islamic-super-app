import { act, fireEvent, render, screen } from "@testing-library/react";
import { MaintenanceBanner, parseSiteStatus } from "@/components/MaintenanceBanner";

/** The bar checks site-status.json once a minute (CHECK_EVERY_MS in the component). */
const ONE_CHECK_LATER_MS = 60_000;

function serve(body: unknown, ok = true) {
  return vi.fn(async () => ({ ok, json: async () => body }) as Response);
}

async function flush() {
  await act(async () => {
    await Promise.resolve();
    await Promise.resolve();
  });
}

describe("Upload-in-progress bar (owner 2026-11-24)", () => {
  afterEach(() => {
    vi.unstubAllGlobals();
    vi.useRealTimers();
  });

  it("shows the Arabic notice at the top while site-status.json says updating", async () => {
    const fetchMock = serve({ updating: true });
    vi.stubGlobal("fetch", fetchMock);
    render(<MaintenanceBanner locale="ar" />);
    await flush();
    // The status file with a cache-busting stamp: matches "/site-status.json?t=1732451234567",
    // rejects "/site-status.json" and "/ar/site-status.json?t=1".
    expect(fetchMock).toHaveBeenCalledWith(expect.stringMatching(/^\/site-status\.json\?t=\d+$/), {
      cache: "no-store",
    });
    expect(screen.getByTestId("maintenance-banner").textContent).toContain("خدمات جديدة");
  });

  it("shows nothing when no upload is running or the file is missing", async () => {
    vi.stubGlobal("fetch", serve({ updating: false }));
    const { unmount } = render(<MaintenanceBanner locale="ar" />);
    await flush();
    expect(screen.queryByTestId("maintenance-banner")).toBeNull();
    unmount();
    vi.stubGlobal("fetch", serve(null, false));
    render(<MaintenanceBanner locale="en" />);
    await flush();
    expect(screen.queryByTestId("maintenance-banner")).toBeNull();
  });

  it("uses a custom message, goes away by itself when the upload ends, and can be closed", async () => {
    vi.useFakeTimers();
    let body: unknown = { updating: true, message_en: "Adding the new lessons section" };
    vi.stubGlobal(
      "fetch",
      vi.fn(async () => ({ ok: true, json: async () => body }) as Response),
    );
    render(<MaintenanceBanner locale="en" />);
    await flush();
    expect(screen.getByTestId("maintenance-banner").textContent).toContain("Adding the new lessons section");
    body = { updating: false };
    await act(async () => {
      await vi.advanceTimersByTimeAsync(ONE_CHECK_LATER_MS);
    });
    expect(screen.queryByTestId("maintenance-banner")).toBeNull();
    body = { updating: true };
    await act(async () => {
      await vi.advanceTimersByTimeAsync(ONE_CHECK_LATER_MS);
    });
    fireEvent.click(screen.getByTestId("maintenance-close"));
    expect(screen.queryByTestId("maintenance-banner")).toBeNull();
  });

  it("reads only a real true as updating", () => {
    expect(parseSiteStatus({ updating: "yes" }).updating).toBe(false);
    expect(parseSiteStatus(null).updating).toBe(false);
    expect(parseSiteStatus({ updating: true, message_ar: "  " })).toEqual({
      updating: true,
      message_ar: undefined,
      message_en: undefined,
    });
  });
});
