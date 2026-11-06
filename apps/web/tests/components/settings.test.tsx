import { act, fireEvent, render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { DisplaySettings } from "@/components/DisplaySettings";
import { AccountSync, errorMessage } from "@/components/AccountSync";
import { OfflineStatus } from "@/components/OfflineStatus";
import { ClientEffects, applyPrefs } from "@/components/ClientEffects";
import { RootRedirect } from "@/components/RootRedirect";
import { prefsStore, DEFAULT_PREFS } from "@/lib/settings";
import { addBookmark, bookmarksStore } from "@/lib/bookmarks";
import { accountStore, ApiError, type FetchLike } from "@/lib/sync";
import { handleSwMessage } from "@/lib/sw-client";
import { t } from "@/lib/i18n";
import { routerPush } from "../setup";
import { resetStores } from "./reset";

beforeEach(resetStores);
afterEach(() => vi.unstubAllGlobals());

describe("DisplaySettings", () => {
  it("switches language", async () => {
    render(<DisplaySettings locale="en" preview="ٱلۡحَمۡدُ" />);
    await userEvent.selectOptions(screen.getByLabelText("Language"), "ar");
    expect(prefsStore.get().locale).toBe("ar");
    expect(routerPush).toHaveBeenCalledWith("/ar/settings/");
  });
  it("theme radio buttons persist and apply", async () => {
    render(
      <>
        <DisplaySettings locale="en" preview="x" />
        <ClientEffects locale="en" />
      </>,
    );
    await userEvent.click(screen.getByRole("radio", { name: "Dark" }));
    expect(prefsStore.get().theme).toBe("dark");
    expect(document.documentElement.getAttribute("data-theme")).toBe("dark");
    expect(JSON.parse(localStorage.getItem("rattil.prefs")!).theme).toBe("dark");
    await userEvent.click(screen.getByRole("radio", { name: "Light" }));
    expect(document.documentElement.getAttribute("data-theme")).toBe("light");
    await userEvent.click(screen.getByRole("radio", { name: "System" }));
    expect(document.documentElement.hasAttribute("data-theme")).toBe(false);
  });
  it("font size buttons and slider are clamped to 18–40", async () => {
    render(
      <>
        <DisplaySettings locale="en" preview="x" />
        <ClientEffects locale="en" />
      </>,
    );
    await userEvent.click(screen.getByRole("button", { name: "Quran font size +" }));
    expect(prefsStore.get().fontSize).toBe(27);
    expect(document.documentElement.style.getPropertyValue("--quran-size")).toBe("27px");
    await userEvent.click(screen.getByRole("button", { name: "Quran font size −" }));
    expect(prefsStore.get().fontSize).toBe(26);
    const slider = screen.getByRole("slider");
    expect(slider).toHaveAttribute("min", "18");
    expect(slider).toHaveAttribute("max", "40");
    // jsdom does not implement range keyboard stepping; drive the change event directly
    fireEvent.change(slider, { target: { value: "40" } });
    expect(prefsStore.get().fontSize).toBe(40);
    expect(screen.getByRole("button", { name: "Quran font size +" })).toBeDisabled();
    fireEvent.change(slider, { target: { value: "18" } });
    expect(screen.getByRole("button", { name: "Quran font size −" })).toBeDisabled();
  });
  it("translation checkbox persists", async () => {
    render(<DisplaySettings locale="en" preview="x" />);
    await userEvent.click(screen.getByRole("checkbox", { name: /English translation/ }));
    expect(prefsStore.get().translation).toBe(true);
  });
  it("preview uses the display map", () => {
    render(<DisplaySettings locale="ar" preview={"قَيِّمٗا"} />);
    expect(screen.getByTestId("font-preview").textContent).toContain("قَيِّمࣰا");
  });
});

describe("ClientEffects / RootRedirect", () => {
  it("remembers the current locale", () => {
    render(<ClientEffects locale="en" />);
    expect(prefsStore.get().locale).toBe("en");
  });
  it("applyPrefs", () => {
    const el = document.createElement("html");
    applyPrefs({ ...DEFAULT_PREFS, theme: "dark", fontSize: 30 }, el);
    expect(el.getAttribute("data-theme")).toBe("dark");
    expect(el.style.getPropertyValue("--quran-size")).toBe("30px");
  });
  it("redirects to the saved locale", () => {
    const replace = vi.fn();
    vi.stubGlobal("location", { ...window.location, replace });
    prefsStore.set((p) => ({ ...p, locale: "en" }));
    render(<RootRedirect />);
    expect(replace).toHaveBeenCalledWith("/en/");
  });
  it("redirects to Arabic by default", () => {
    const replace = vi.fn();
    vi.stubGlobal("location", { ...window.location, replace });
    render(<RootRedirect />);
    expect(replace).toHaveBeenCalledWith("/ar/");
  });
});

const ok = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { "Content-Type": "application/json" } });

describe("AccountSync", () => {
  it("validates input before calling the server", async () => {
    const fetchImpl = vi.fn<FetchLike>();
    render(<AccountSync locale="en" fetchImpl={fetchImpl} />);
    await userEvent.click(screen.getByRole("button", { name: "Sign in" }));
    expect(screen.getByRole("alert")).toHaveTextContent("valid email");
    await userEvent.type(screen.getByLabelText("Email"), "a@b.co");
    await userEvent.type(screen.getByLabelText(/^Password/), "short");
    await userEvent.click(screen.getByRole("button", { name: "Create account" }));
    expect(screen.getByRole("alert")).toHaveTextContent("at least 10 characters");
    expect(fetchImpl).not.toHaveBeenCalled();
  });

  it("registers, signs in, syncs and signs out", async () => {
    const server: Record<string, unknown> = {};
    const fetchImpl = vi.fn<FetchLike>(async (url, init) => {
      const u = new URL(url);
      if (u.pathname === "/v1/auth/register") return ok({ id: 1, email: "a@b.co" }, 201);
      if (u.pathname === "/v1/auth/login")
        return ok({ access_token: "tok", token_type: "bearer", expires_in: 3600 });
      if (u.pathname === "/v1/bookmarks")
        return ok({
          serverTime: 777,
          items: [{ id: "s36-a1", surah: 36, ayah: 1, updatedAt: 5, deleted: false }],
        });
      if (init?.method === "PUT") {
        const b = JSON.parse(String(init.body));
        const id = decodeURIComponent(u.pathname.split("/").pop()!);
        server[id] = b;
        return ok({ ...b, id });
      }
      return ok({}, 404);
    });
    bookmarksStore.set((s) => addBookmark(s, 2, 255, 10));
    render(<AccountSync locale="en" fetchImpl={fetchImpl} />);
    await userEvent.type(screen.getByLabelText("Email"), "a@b.co");
    await userEvent.type(screen.getByLabelText(/^Password/), "0123456789");
    await userEvent.click(screen.getByRole("button", { name: "Create account" }));
    expect(await screen.findByTestId("signed-in")).toHaveTextContent("Signed in as a@b.co");
    expect(accountStore.get().token).toBe("tok");
    expect(screen.getByText("Last synced: never")).toBeInTheDocument();
    await userEvent.click(screen.getByRole("button", { name: "Sync now" }));
    expect(await screen.findByText("Sync complete: 1 received, 1 sent.")).toBeInTheDocument();
    expect(server["s2-a255"]).toMatchObject({ surah: 2, ayah: 255, deleted: false });
    expect(bookmarksStore.get()["s36-a1"]).toBeDefined();
    expect(accountStore.get().lastSync).toBe(777);
    expect(screen.queryByText("Last synced: never")).toBeNull();
    await userEvent.click(screen.getByRole("button", { name: "Sign out" }));
    expect(accountStore.get().token).toBeNull();
    expect(screen.getByRole("button", { name: "Sign in" })).toBeInTheDocument();
  });

  it("shows server errors (409, 401) and network/CORS errors visibly", async () => {
    const responses: (() => Promise<Response>)[] = [
      async () => ok({ detail: "email already registered" }, 409),
      async () => Promise.reject(new TypeError("Failed to fetch")),
      async () => ok({ detail: "bad credentials" }, 401),
    ];
    const fetchImpl: FetchLike = () => responses.shift()!();
    render(<AccountSync locale="en" fetchImpl={fetchImpl} />);
    await userEvent.type(screen.getByLabelText("Email"), "a@b.co");
    await userEvent.type(screen.getByLabelText(/^Password/), "0123456789");
    await userEvent.click(screen.getByRole("button", { name: "Create account" }));
    expect(await screen.findByRole("alert")).toHaveTextContent(
      "The server answered 409: email already registered",
    );
    await userEvent.click(screen.getByRole("button", { name: "Sign in" }));
    expect(await screen.findByRole("alert")).toHaveTextContent(
      /Could not reach the server .*CORS.*Failed to fetch/,
    );
    await userEvent.click(screen.getByRole("button", { name: "Sign in" }));
    expect(await screen.findByRole("alert")).toHaveTextContent("401: bad credentials");
  });

  it("offline sync is reported; an expired token signs the user out", async () => {
    accountStore.set((a) => ({ ...a, token: "tok", email: "a@b.co" }));
    const online = vi.spyOn(navigator, "onLine", "get").mockReturnValue(false);
    const fetchImpl = vi.fn<FetchLike>(async () => ok({ detail: "token expired" }, 401));
    render(<AccountSync locale="en" fetchImpl={fetchImpl} />);
    await userEvent.click(screen.getByRole("button", { name: "Sync now" }));
    expect(await screen.findByRole("alert")).toHaveTextContent("You are offline");
    expect(fetchImpl).not.toHaveBeenCalled();
    online.mockRestore();
    await userEvent.click(screen.getByRole("button", { name: "Sync now" }));
    await waitFor(() => expect(accountStore.get().token).toBeNull());
    expect(screen.getByRole("alert")).toHaveTextContent("401: token expired");
  });

  it("saves a valid API URL and rejects an invalid one", async () => {
    render(<AccountSync locale="en" />);
    const input = screen.getByLabelText("API base URL");
    expect(input).toHaveValue("http://127.0.0.1:8000");
    await userEvent.clear(input);
    await userEvent.type(input, "nope");
    await userEvent.click(screen.getByRole("button", { name: "Save URL" }));
    expect(screen.getByRole("alert")).toHaveTextContent("not a valid http(s) address");
    await userEvent.clear(input);
    await userEvent.type(input, "https://api.example.org/");
    await userEvent.click(screen.getByRole("button", { name: "Save URL" }));
    expect(accountStore.get().apiBase).toBe("https://api.example.org");
    expect(screen.getByRole("status")).toHaveTextContent("Saved.");
  });

  it("errorMessage covers every kind", () => {
    expect(errorMessage("en", new ApiError("invalid", "x"))).toMatch(/not a valid/);
    expect(errorMessage("en", new ApiError("http", "boom"))).toBe("The server answered ?: boom");
    expect(errorMessage("ar", new Error("x"))).toBe(t("ar", "common.error"));
  });
});

describe("OfflineStatus", () => {
  it("reports unsupported browsers", () => {
    render(<OfflineStatus locale="en" />);
    expect(screen.getByTestId("offline-status")).toHaveTextContent("does not support offline mode");
  });
  it("shows progress and completion from the service worker", () => {
    const ready = new Promise(() => undefined);
    vi.stubGlobal("navigator", { ...navigator, serviceWorker: { ready } });
    render(<OfflineStatus locale="en" />);
    act(() => handleSwMessage({ type: "precache-progress", done: 5, total: 10, complete: false }));
    expect(screen.getByTestId("offline-status")).toHaveTextContent("5 of 10 files");
    expect(screen.getByRole("progressbar")).toHaveAttribute("value", "5");
    act(() => handleSwMessage({ type: "precache-progress", done: 10, total: 10, complete: true }));
    expect(screen.getByTestId("offline-status")).toHaveTextContent("works offline");
    act(() => handleSwMessage({ type: "precache-progress", done: 0, total: 0, complete: false }));
    expect(screen.getByTestId("offline-status")).toHaveTextContent("Preparing");
  });
});
