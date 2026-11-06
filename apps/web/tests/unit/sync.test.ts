import {
  activeBookmarks,
  addBookmark,
  bookmarkId,
  dirtyBookmarks,
  isBookmarked,
  markAllDirty,
  mergeRemote,
  removeBookmark,
  sanitizeBookmarks,
  stripLocal,
  toggleBookmark,
  type Bookmark,
  type BookmarkState,
} from "@/lib/bookmarks";
import {
  ApiClient,
  ApiError,
  DEFAULT_ACCOUNT,
  normalizeBase,
  sanitizeAccount,
  syncBookmarks,
  type FetchLike,
} from "@/lib/sync";

const json = (status: number, body: unknown): Response =>
  new Response(body === undefined ? "" : JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });

function withoutServerField(b: Bookmark & { serverUpdated: number }): Bookmark {
  const copy: Partial<Bookmark & { serverUpdated: number }> = { ...b };
  delete copy.serverUpdated;
  return copy as Bookmark;
}

/** In-memory fake of the API's bookmark endpoints with server-side LWW. */
function fakeServer(initial: Bookmark[] = [], serverTime = 5000) {
  const items = new Map(initial.map((b) => [b.id, { ...b, serverUpdated: 0 }]));
  const calls: { method: string; url: string; body?: unknown; auth?: string }[] = [];
  const fetchImpl: FetchLike = async (url, init) => {
    const method = init?.method ?? "GET";
    const body = init?.body ? JSON.parse(String(init.body)) : undefined;
    const auth = (init?.headers as Record<string, string>)?.Authorization;
    calls.push({ method, url, body, auth });
    if (auth !== "Bearer tok") return json(401, { detail: "not authenticated" });
    const u = new URL(url);
    if (method === "GET" && u.pathname === "/v1/bookmarks") {
      const since = Number(u.searchParams.get("since") ?? 0);
      const list = [...items.values()]
        .filter((b) => b.serverUpdated >= since || since === 0)
        .map(withoutServerField);
      return json(200, { serverTime, items: list });
    }
    const m = /^\/v1\/bookmarks\/(.+)$/.exec(u.pathname);
    if (method === "PUT" && m) {
      if ("id" in body) return json(422, { detail: "Extra inputs are not permitted" });
      const id = decodeURIComponent(m[1] as string);
      const cur = items.get(id);
      if (!cur || body.updatedAt > cur.updatedAt)
        items.set(id, { ...body, id, serverUpdated: serverTime + 1 });
      return json(200, withoutServerField(items.get(id)!));
    }
    return json(404, { detail: "not found" });
  };
  return { fetchImpl, items, calls };
}

describe("bookmark store logic", () => {
  it("adds, toggles and removes with tombstones", () => {
    let s: BookmarkState = {};
    s = addBookmark(s, 2, 255, 1000);
    expect(isBookmarked(s, 2, 255)).toBe(true);
    expect(s["s2-a255"]).toMatchObject({ surah: 2, ayah: 255, updatedAt: 1000, deleted: false, dirty: true });
    s = removeBookmark(s, "s2-a255", 2000);
    expect(isBookmarked(s, 2, 255)).toBe(false);
    expect(s["s2-a255"]).toMatchObject({ deleted: true, updatedAt: 2000, dirty: true });
    expect(activeBookmarks(s)).toEqual([]);
    expect(removeBookmark(s, "s2-a255", 3000)).toBe(s); // already deleted
    expect(removeBookmark(s, "missing", 3000)).toBe(s);
    s = toggleBookmark(s, 2, 255, 3000);
    expect(isBookmarked(s, 2, 255)).toBe(true);
    s = toggleBookmark(s, 2, 255, 3000);
    expect(isBookmarked(s, 2, 255)).toBe(false);
  });
  it("updatedAt strictly increases even if the clock goes backwards", () => {
    let s = addBookmark({}, 1, 1, 5000);
    s = removeBookmark(s, "s1-a1", 4000);
    expect(s["s1-a1"]?.updatedAt).toBe(5001);
    s = addBookmark(s, 1, 1, 10);
    expect(s["s1-a1"]?.updatedAt).toBe(5002);
  });
  it("sorts active bookmarks and lists dirty ones", () => {
    let s = addBookmark({}, 3, 5, 1);
    s = addBookmark(s, 1, 7, 2);
    s = addBookmark(s, 3, 1, 3);
    expect(activeBookmarks(s).map((b) => b.id)).toEqual(["s1-a7", "s3-a1", "s3-a5"]);
    expect(dirtyBookmarks(s)).toHaveLength(3);
  });
  it("ids are valid per the API contract", () => {
    expect(bookmarkId(114, 6)).toMatch(/^[A-Za-z0-9_-]{1,64}$/);
  });
  it("sanitises persisted data", () => {
    expect(sanitizeBookmarks(null)).toEqual({});
    expect(sanitizeBookmarks("x")).toEqual({});
    const s = sanitizeBookmarks({
      a: { id: "s1-a1", surah: 1, ayah: 1, updatedAt: 1, deleted: false, dirty: true, note: "hi" },
      b: { id: "bad id!", surah: 1, ayah: 1, updatedAt: 1, deleted: false },
      c: { id: "s200-a1", surah: 200, ayah: 1, updatedAt: 1, deleted: false },
      d: { id: "x", surah: 1, ayah: 1, updatedAt: "1", deleted: false },
    });
    expect(Object.keys(s)).toEqual(["s1-a1"]);
    expect(s["s1-a1"]).toMatchObject({ note: "hi", dirty: true });
  });
  it("mergeRemote applies last-write-wins", () => {
    const local = addBookmark({}, 1, 1, 100);
    const newer: Bookmark = { id: "s1-a1", surah: 1, ayah: 1, updatedAt: 200, deleted: true };
    const older: Bookmark = { ...newer, updatedAt: 50 };
    expect(mergeRemote(local, newer)["s1-a1"]).toMatchObject({ deleted: true, dirty: false, updatedAt: 200 });
    expect(mergeRemote(local, older)).toBe(local);
    expect(mergeRemote(local, { ...newer, updatedAt: 100 })["s1-a1"]?.dirty).toBe(false);
    expect(mergeRemote(local, { ...newer, id: "no spaces allowed" } as Bookmark)).toBe(local);
    const added = mergeRemote(
      {},
      { id: "s9-a9", surah: 9, ayah: 9, updatedAt: 1, deleted: false, note: "n" },
    );
    expect(added["s9-a9"]).toMatchObject({ note: "n", dirty: false });
  });
  it("stripLocal and markAllDirty", () => {
    const s = mergeRemote({}, { id: "s9-a9", surah: 9, ayah: 9, updatedAt: 1, deleted: false, note: "n" });
    expect(stripLocal(s["s9-a9"]!)).toEqual({
      id: "s9-a9",
      surah: 9,
      ayah: 9,
      updatedAt: 1,
      deleted: false,
      note: "n",
    });
    expect(markAllDirty(s)["s9-a9"]?.dirty).toBe(true);
  });
});

describe("syncBookmarks (mocked fetch)", () => {
  it("first sync uploads local items and downloads remote ones", async () => {
    const remote: Bookmark = { id: "s36-a1", surah: 36, ayah: 1, updatedAt: 10, deleted: false };
    const srv = fakeServer([remote], 5000);
    let local = addBookmark({}, 2, 255, 100);
    local = removeBookmark(addBookmark(local, 1, 1, 100), "s1-a1", 150);
    const client = new ApiClient({ base: "http://api.test/", fetch: srv.fetchImpl, isOnline: () => true });
    const res = await syncBookmarks(client, "tok", local, 0);
    expect(res.pulled).toBe(1);
    expect(res.pushed).toBe(2);
    expect(res.lastSync).toBe(5000);
    expect(activeBookmarks(res.state).map((b) => b.id)).toEqual(["s2-a255", "s36-a1"]);
    expect(dirtyBookmarks(res.state)).toEqual([]);
    // tombstone was uploaded too
    expect(srv.items.get("s1-a1")).toMatchObject({ deleted: true, updatedAt: 150 });
    expect(srv.calls[0]).toMatchObject({ method: "GET", url: "http://api.test/v1/bookmarks?since=0" });
  });
  it("remote newer wins; local newer is pushed (LWW both ways)", async () => {
    const srv = fakeServer(
      [
        { id: "s1-a1", surah: 1, ayah: 1, updatedAt: 300, deleted: true },
        { id: "s1-a2", surah: 1, ayah: 2, updatedAt: 100, deleted: false },
      ],
      9000,
    );
    let local = addBookmark({}, 1, 1, 200); // older than server tombstone
    local = removeBookmark(addBookmark(local, 1, 2, 50), "s1-a2", 400); // newer local delete
    const client = new ApiClient({ base: "http://api.test", fetch: srv.fetchImpl, isOnline: () => true });
    const res = await syncBookmarks(client, "tok", local, 0);
    expect(res.state["s1-a1"]).toMatchObject({ deleted: true, updatedAt: 300, dirty: false });
    expect(res.state["s1-a2"]).toMatchObject({ deleted: true, updatedAt: 400, dirty: false });
    expect(srv.items.get("s1-a2")).toMatchObject({ deleted: true, updatedAt: 400 });
    expect(res.pushed).toBe(1);
  });
  it("adopts the server copy when the server kept a newer version during push", async () => {
    const newer: Bookmark = { id: "s5-a5", surah: 5, ayah: 5, updatedAt: 999, deleted: true };
    const fetchImpl: FetchLike = async (url, init) => {
      if ((init?.method ?? "GET") === "GET") return json(200, { serverTime: 1, items: [] });
      return json(200, newer);
    };
    const client = new ApiClient({ base: "http://api.test", fetch: fetchImpl, isOnline: () => true });
    const res = await syncBookmarks(client, "tok", addBookmark({}, 5, 5, 10), 0);
    expect(res.state["s5-a5"]).toMatchObject({ deleted: true, updatedAt: 999, dirty: false });
  });
  it("incremental sync passes since", async () => {
    const srv = fakeServer([], 7000);
    const client = new ApiClient({ base: "http://api.test", fetch: srv.fetchImpl, isOnline: () => true });
    await syncBookmarks(client, "tok", {}, 4242);
    expect(srv.calls[0]?.url).toBe("http://api.test/v1/bookmarks?since=4242");
  });
  it("offline: fails fast without calling fetch, state untouched", async () => {
    const fetchImpl = vi.fn<FetchLike>();
    const client = new ApiClient({ base: "http://api.test", fetch: fetchImpl, isOnline: () => false });
    await expect(syncBookmarks(client, "tok", {}, 0)).rejects.toMatchObject({ kind: "offline" });
    expect(fetchImpl).not.toHaveBeenCalled();
  });
  it("network/CORS failure becomes ApiError(network)", async () => {
    const client = new ApiClient({
      base: "http://api.test",
      fetch: () => Promise.reject(new TypeError("Failed to fetch")),
      isOnline: () => true,
    });
    await expect(syncBookmarks(client, "tok", {}, 0)).rejects.toMatchObject({
      kind: "network",
      message: "Failed to fetch",
    });
  });
  it("401 is reported with status and detail", async () => {
    const srv = fakeServer();
    const client = new ApiClient({ base: "http://api.test", fetch: srv.fetchImpl, isOnline: () => true });
    const err = await syncBookmarks(client, "bad", {}, 0).catch((e: unknown) => e);
    expect(err).toBeInstanceOf(ApiError);
    expect(err).toMatchObject({ kind: "http", status: 401, message: "not authenticated" });
  });
  it("a failed push leaves the item dirty for the next sync", async () => {
    let n = 0;
    const fetchImpl: FetchLike = async (_u, init) => {
      if ((init?.method ?? "GET") === "GET") return json(200, { serverTime: 1, items: [] });
      n++;
      return json(500, { detail: "boom" });
    };
    const client = new ApiClient({ base: "http://api.test", fetch: fetchImpl, isOnline: () => true });
    const local = addBookmark({}, 1, 1, 1);
    await expect(syncBookmarks(client, "tok", local, 0)).rejects.toMatchObject({ status: 500 });
    expect(n).toBe(1);
    expect(local["s1-a1"]?.dirty).toBe(true);
  });
});

describe("ApiClient", () => {
  it("register/login/me send the right requests", async () => {
    const calls: [string, RequestInit | undefined][] = [];
    const fetchImpl: FetchLike = async (url, init) => {
      calls.push([url, init]);
      if (url.endsWith("/v1/auth/register")) return json(201, { id: 1, email: "a@b.co" });
      if (url.endsWith("/v1/auth/login"))
        return json(200, { access_token: "tok", token_type: "bearer", expires_in: 60 });
      return json(200, { id: 1, email: "a@b.co" });
    };
    const c = new ApiClient({ base: "http://api.test", fetch: fetchImpl, isOnline: () => true });
    await expect(c.register("a@b.co", "0123456789")).resolves.toEqual({ id: 1, email: "a@b.co" });
    await expect(c.login("a@b.co", "0123456789")).resolves.toMatchObject({ access_token: "tok" });
    await expect(c.me("tok")).resolves.toMatchObject({ email: "a@b.co" });
    expect(calls[0]?.[1]).toMatchObject({
      method: "POST",
      body: JSON.stringify({ email: "a@b.co", password: "0123456789" }),
    });
    expect((calls[2]?.[1]?.headers as Record<string, string>).Authorization).toBe("Bearer tok");
  });
  it("maps HTTP errors (detail string, detail object, no body)", async () => {
    const responses = [
      json(409, { detail: "email already registered" }),
      json(422, { detail: [{ msg: "bad" }] }),
      new Response("", { status: 500, statusText: "Internal Server Error" }),
      new Response("not json", { status: 502 }),
    ];
    const c = new ApiClient({
      base: "http://api.test",
      fetch: async () => responses.shift()!,
      isOnline: () => true,
    });
    await expect(c.register("a@b.co", "x")).rejects.toMatchObject({
      status: 409,
      message: "email already registered",
    });
    await expect(c.register("a@b.co", "x")).rejects.toMatchObject({
      status: 422,
      message: '[{"msg":"bad"}]',
    });
    await expect(c.register("a@b.co", "x")).rejects.toMatchObject({
      status: 500,
      message: "Internal Server Error",
    });
    await expect(c.register("a@b.co", "x")).rejects.toMatchObject({ status: 502, message: "HTTP 502" });
  });
  it("rejects invalid base URLs", () => {
    expect(() => normalizeBase("not a url")).toThrow(ApiError);
    expect(() => normalizeBase("ftp://x")).toThrow(ApiError);
    expect(normalizeBase(" http://127.0.0.1:8000/// ")).toBe("http://127.0.0.1:8000");
  });
  it("uses navigator.onLine and global fetch by default", async () => {
    const spy = vi.spyOn(globalThis, "fetch").mockResolvedValue(json(200, { status: "ok" }));
    const c = new ApiClient({ base: "http://api.test" });
    await expect(c.request("GET", "/health")).resolves.toEqual({ status: "ok" });
    spy.mockRestore();
    const online = vi.spyOn(navigator, "onLine", "get").mockReturnValue(false);
    await expect(new ApiClient({ base: "http://api.test" }).request("GET", "/health")).rejects.toMatchObject({
      kind: "offline",
    });
    online.mockRestore();
  });
  it("network errors that are not Error instances", async () => {
    const c = new ApiClient({
      base: "http://api.test",
      fetch: () => Promise.reject("nope"),
      isOnline: () => true,
    });
    await expect(c.request("GET", "/x")).rejects.toMatchObject({ kind: "network", message: "nope" });
  });
});

describe("account sanitising", () => {
  it("falls back to defaults", () => {
    expect(sanitizeAccount(null)).toEqual(DEFAULT_ACCOUNT);
    expect(sanitizeAccount({ apiBase: "", token: 5 })).toEqual(DEFAULT_ACCOUNT);
    expect(
      sanitizeAccount({ apiBase: "http://x", email: "e", token: "t", lastSync: 3, lastSyncAt: 4 }),
    ).toEqual({
      apiBase: "http://x",
      email: "e",
      token: "t",
      lastSync: 3,
      lastSyncAt: 4,
    });
  });
});
