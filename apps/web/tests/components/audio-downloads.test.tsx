import { render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { AudioDownloads } from "@/components/AudioDownloads";
import { AudioSettings } from "@/components/AudioSettings";
import { audioStore } from "@/lib/audio";
import { downloadsStore } from "@/lib/audio-offline";
import { resetStores } from "./reset";

const OK = 200;
const BYTES = 8;
const IKHLAS = "112";
const FAST = "1.5";

class FakeCache {
  store = new Map<string, Response>();
  async match(url: string): Promise<Response | undefined> {
    return this.store.get(url)?.clone();
  }
  async put(url: string, res: Response): Promise<void> {
    this.store.set(url, res);
  }
  async delete(url: string): Promise<boolean> {
    return this.store.delete(url);
  }
}

beforeEach(resetStores);
afterEach(() => vi.unstubAllGlobals());

describe("AudioDownloads", () => {
  it("says so when the browser cannot save audio", () => {
    render(<AudioDownloads locale="en" />);
    expect(
      screen.getByText("This browser cannot save recitations for offline listening."),
    ).toBeInTheDocument();
  });

  it("saves a surah, lists it and deletes it", async () => {
    const cache = new FakeCache();
    vi.stubGlobal("caches", { open: async () => cache, delete: async () => true });
    vi.stubGlobal(
      "fetch",
      vi.fn(async () => new Response(new Uint8Array(BYTES), { status: OK })),
    );
    render(<AudioDownloads locale="en" />);
    expect(await screen.findByTestId("dl-empty")).toBeInTheDocument();
    await userEvent.selectOptions(screen.getByTestId("dl-surah"), IKHLAS);
    await userEvent.click(screen.getByTestId("dl-start"));
    await waitFor(() => expect(screen.getByTestId("dl-list")).toHaveTextContent("Al-Ikhlas"));
    expect(screen.getByTestId("dl-start")).toHaveTextContent("Saved");
    expect(downloadsStore.get().saved).toHaveLength(1);
    await userEvent.click(screen.getByRole("button", { name: "Delete Al-Ikhlas" }));
    await waitFor(() => expect(downloadsStore.get().saved).toEqual([]));
    expect(cache.store.size).toBe(0);
  });
});

describe("AudioSettings speed", () => {
  it("stores the chosen playback speed", async () => {
    render(<AudioSettings locale="en" />);
    await userEvent.selectOptions(screen.getByLabelText("Speed"), FAST);
    expect(audioStore.get().speed).toBe(Number(FAST));
  });
});
