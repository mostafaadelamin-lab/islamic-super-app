/** Bookmark state with tombstones and last-write-wins merging. */
import { createStore } from "./store";

export interface Bookmark {
  id: string;
  surah: number;
  ayah: number;
  note?: string;
  updatedAt: number;
  deleted: boolean;
}
export interface LocalBookmark extends Bookmark {
  dirty: boolean;
}
export type BookmarkState = Record<string, LocalBookmark>;

export const ID_RE = /^[A-Za-z0-9_-]{1,64}$/;

export function bookmarkId(surah: number, ayah: number): string {
  return `s${surah}-a${ayah}`;
}

function isValidBookmark(v: unknown): v is Bookmark {
  if (typeof v !== "object" || v === null) return false;
  const b = v as Record<string, unknown>;
  return (
    typeof b.id === "string" &&
    ID_RE.test(b.id) &&
    Number.isInteger(b.surah) &&
    (b.surah as number) >= 1 &&
    (b.surah as number) <= 114 &&
    Number.isInteger(b.ayah) &&
    (b.ayah as number) >= 1 &&
    typeof b.updatedAt === "number" &&
    typeof b.deleted === "boolean" &&
    (b.note === undefined || b.note === null || typeof b.note === "string")
  );
}

export function sanitizeBookmarks(raw: unknown): BookmarkState {
  const out: BookmarkState = {};
  if (typeof raw !== "object" || raw === null) return out;
  for (const v of Object.values(raw as Record<string, unknown>)) {
    if (isValidBookmark(v)) {
      const b = v as Bookmark & { dirty?: unknown };
      out[b.id] = toLocal(b, b.dirty === true);
    }
  }
  return out;
}

function toLocal(b: Bookmark, dirty: boolean): LocalBookmark {
  const l: LocalBookmark = {
    id: b.id,
    surah: b.surah,
    ayah: b.ayah,
    updatedAt: b.updatedAt,
    deleted: b.deleted,
    dirty,
  };
  if (typeof b.note === "string" && b.note.length > 0) l.note = b.note.slice(0, 500);
  return l;
}

export function addBookmark(state: BookmarkState, surah: number, ayah: number, now: number): BookmarkState {
  const id = bookmarkId(surah, ayah);
  const prevNote = state[id]?.note;
  const next: Bookmark = {
    id,
    surah,
    ayah,
    updatedAt: Math.max(now, (state[id]?.updatedAt ?? 0) + 1),
    deleted: false,
  };
  if (prevNote) next.note = prevNote;
  return { ...state, [id]: toLocal(next, true) };
}

export function removeBookmark(state: BookmarkState, id: string, now: number): BookmarkState {
  const cur = state[id];
  if (!cur || cur.deleted) return state;
  return {
    ...state,
    [id]: { ...cur, deleted: true, updatedAt: Math.max(now, cur.updatedAt + 1), dirty: true },
  };
}

export function isBookmarked(state: BookmarkState, surah: number, ayah: number): boolean {
  const b = state[bookmarkId(surah, ayah)];
  return !!b && !b.deleted;
}

export function toggleBookmark(
  state: BookmarkState,
  surah: number,
  ayah: number,
  now: number,
): BookmarkState {
  return isBookmarked(state, surah, ayah)
    ? removeBookmark(state, bookmarkId(surah, ayah), now)
    : addBookmark(state, surah, ayah, now);
}

export function activeBookmarks(state: BookmarkState): LocalBookmark[] {
  return Object.values(state)
    .filter((b) => !b.deleted)
    .sort((x, y) => x.surah - y.surah || x.ayah - y.ayah);
}

export function dirtyBookmarks(state: BookmarkState): LocalBookmark[] {
  return Object.values(state).filter((b) => b.dirty);
}

/** Applies a remote item with last-write-wins on updatedAt. Remote wins ties (the server is authoritative). */
export function mergeRemote(state: BookmarkState, remote: Bookmark): BookmarkState {
  if (!isValidBookmark(remote)) return state;
  const local = state[remote.id];
  if (!local || remote.updatedAt > local.updatedAt) return { ...state, [remote.id]: toLocal(remote, false) };
  if (remote.updatedAt === local.updatedAt) return { ...state, [remote.id]: toLocal(remote, false) };
  return state; // local is newer; stays dirty and will be pushed
}

export function stripLocal(b: LocalBookmark): Bookmark {
  const out: Bookmark = {
    id: b.id,
    surah: b.surah,
    ayah: b.ayah,
    updatedAt: b.updatedAt,
    deleted: b.deleted,
  };
  if (b.note) out.note = b.note;
  return out;
}

export const bookmarksStore = createStore<BookmarkState>("rattil.bookmarks", {}, sanitizeBookmarks);

/** Marks every item for upload (used after signing in to an account). */
export function markAllDirty(state: BookmarkState): BookmarkState {
  const out: BookmarkState = {};
  for (const [k, v] of Object.entries(state)) out[k] = { ...v, dirty: true };
  return out;
}
