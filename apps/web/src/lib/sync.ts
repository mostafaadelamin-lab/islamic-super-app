/** API client (packages/api-contracts/API.md) and bookmark synchronisation. */
import { dirtyBookmarks, mergeRemote, stripLocal, type Bookmark, type BookmarkState } from "./bookmarks";
import { createStore } from "./store";

export const DEFAULT_API_BASE = "http://127.0.0.1:8000";

export type ApiErrorKind = "offline" | "network" | "http" | "invalid";
export class ApiError extends Error {
  constructor(
    public readonly kind: ApiErrorKind,
    message: string,
    public readonly status?: number,
  ) {
    super(message);
    this.name = "ApiError";
  }
}

export type FetchLike = (input: string, init?: RequestInit) => Promise<Response>;

export function normalizeBase(raw: string): string {
  const s = raw.trim().replace(/\/+$/, "");
  let u: URL;
  try {
    u = new URL(s);
  } catch {
    throw new ApiError("invalid", "invalid URL");
  }
  if (u.protocol !== "http:" && u.protocol !== "https:") throw new ApiError("invalid", "URL must be http(s)");
  return s;
}

export interface ApiClientOptions {
  base: string;
  fetch?: FetchLike;
  isOnline?: () => boolean;
}

export class ApiClient {
  private readonly base: string;
  private readonly fetchImpl: FetchLike;
  private readonly isOnline: () => boolean;
  constructor(opts: ApiClientOptions) {
    this.base = normalizeBase(opts.base);
    this.fetchImpl = opts.fetch ?? ((i, init) => fetch(i, init));
    this.isOnline =
      opts.isOnline ?? (() => (typeof navigator === "undefined" ? true : navigator.onLine !== false));
  }

  async request<T>(method: string, path: string, body?: unknown, token?: string): Promise<T> {
    if (!this.isOnline()) throw new ApiError("offline", "offline");
    const headers: Record<string, string> = { Accept: "application/json" };
    if (body !== undefined) headers["Content-Type"] = "application/json";
    if (token) headers.Authorization = `Bearer ${token}`;
    let res: Response;
    try {
      res = await this.fetchImpl(this.base + path, {
        method,
        headers,
        body: body === undefined ? undefined : JSON.stringify(body),
      });
    } catch (e) {
      // fetch() rejects with TypeError on DNS/connection failures and CORS rejections alike.
      throw new ApiError("network", e instanceof Error ? e.message : String(e));
    }
    let data: unknown = null;
    const text = await res.text();
    if (text) {
      try {
        data = JSON.parse(text);
      } catch {
        data = null;
      }
    }
    if (!res.ok) {
      const detail =
        data && typeof data === "object" && "detail" in data
          ? typeof (data as { detail: unknown }).detail === "string"
            ? (data as { detail: string }).detail
            : JSON.stringify((data as { detail: unknown }).detail)
          : res.statusText || `HTTP ${res.status}`;
      throw new ApiError("http", detail, res.status);
    }
    return data as T;
  }

  register(email: string, password: string): Promise<{ id: string | number; email: string }> {
    return this.request("POST", "/v1/auth/register", { email, password });
  }
  login(
    email: string,
    password: string,
  ): Promise<{ access_token: string; token_type: string; expires_in: number }> {
    return this.request("POST", "/v1/auth/login", { email, password });
  }
  me(token: string): Promise<{ id: string | number; email: string }> {
    return this.request("GET", "/v1/me", undefined, token);
  }
  getBookmarks(token: string, since: number): Promise<{ serverTime: number; items: Bookmark[] }> {
    return this.request("GET", `/v1/bookmarks?since=${encodeURIComponent(String(since))}`, undefined, token);
  }
  /** The id travels in the path only; the body is the rest of the Bookmark (the API forbids extra fields). */
  putBookmark(token: string, b: Bookmark): Promise<Bookmark> {
    const { id, ...body } = b;
    return this.request("PUT", `/v1/bookmarks/${encodeURIComponent(id)}`, body, token);
  }
}

export interface SyncResult {
  state: BookmarkState;
  lastSync: number;
  pulled: number;
  pushed: number;
}

/**
 * Pull changes since lastSync and merge (LWW), then push every local item still dirty.
 * Tombstones (deleted:true) are synced like any other item.
 */
export async function syncBookmarks(
  client: ApiClient,
  token: string,
  state: BookmarkState,
  lastSync: number,
): Promise<SyncResult> {
  const remote = await client.getBookmarks(token, lastSync);
  let next = state;
  for (const item of remote.items ?? []) next = mergeRemote(next, item);
  let pushed = 0;
  for (const b of dirtyBookmarks(next)) {
    const stored = await client.putBookmark(token, stripLocal(b));
    pushed++;
    const cur = next[b.id];
    // If the server kept a newer version (LWW), adopt it; otherwise mark ours clean.
    if (cur && stored && typeof stored.updatedAt === "number" && stored.updatedAt >= cur.updatedAt) {
      next = mergeRemote({ ...next, [b.id]: { ...cur, dirty: false } }, stored);
    } else if (cur) {
      next = { ...next, [b.id]: { ...cur, dirty: false } };
    }
  }
  const serverTime = typeof remote.serverTime === "number" ? remote.serverTime : lastSync;
  return { state: next, lastSync: serverTime, pulled: remote.items?.length ?? 0, pushed };
}

export interface Account {
  apiBase: string;
  email: string | null;
  token: string | null;
  lastSync: number;
  lastSyncAt: number | null;
}
export const DEFAULT_ACCOUNT: Account = {
  apiBase: DEFAULT_API_BASE,
  email: null,
  token: null,
  lastSync: 0,
  lastSyncAt: null,
};
export function sanitizeAccount(raw: unknown): Account {
  if (typeof raw !== "object" || raw === null) return DEFAULT_ACCOUNT;
  const r = raw as Record<string, unknown>;
  return {
    apiBase: typeof r.apiBase === "string" && r.apiBase ? r.apiBase : DEFAULT_API_BASE,
    email: typeof r.email === "string" ? r.email : null,
    token: typeof r.token === "string" ? r.token : null,
    lastSync: typeof r.lastSync === "number" ? r.lastSync : 0,
    lastSyncAt: typeof r.lastSyncAt === "number" ? r.lastSyncAt : null,
  };
}
export const accountStore = createStore<Account>("rattil.account", DEFAULT_ACCOUNT, sanitizeAccount);
