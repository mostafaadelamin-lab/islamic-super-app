import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { SharePrompt, ShareAppButton } from "@/components/ShareApp";
import { sharePromptStore } from "@/lib/app-links";
import { resetStores } from "./reset";

const DAYS = ["2026-11-01", "2026-11-02", "2026-11-03", "2026-11-04"];

beforeEach(() => {
  resetStores();
  sharePromptStore.reload();
});
afterEach(() => vi.unstubAllGlobals());

describe("share the app", () => {
  it("the suggestion appears on the fifth day of use and 'Not now' ends it for good", async () => {
    sharePromptStore.set(() => ({ days: DAYS, done: false }));
    const { unmount } = render(<SharePrompt locale="en" />);
    expect(await screen.findByTestId("share-prompt")).toBeInTheDocument();
    await userEvent.click(screen.getByTestId("share-prompt-later"));
    expect(screen.queryByTestId("share-prompt")).toBeNull();
    expect(sharePromptStore.get().done).toBe(true);
    unmount();
    render(<SharePrompt locale="en" />);
    expect(screen.queryByTestId("share-prompt")).toBeNull();
  });

  it("not before", () => {
    render(<SharePrompt locale="en" />);
    expect(screen.queryByTestId("share-prompt")).toBeNull();
  });

  it("uses the share sheet with the app's website", async () => {
    const share = vi.fn(async () => undefined);
    vi.stubGlobal("navigator", { ...navigator, share });
    render(<ShareAppButton locale="en" />);
    await userEvent.click(screen.getByTestId("share-app"));
    expect(share).toHaveBeenCalledWith(expect.objectContaining({ url: "https://rattilwasalli.com" }));
  });
});
