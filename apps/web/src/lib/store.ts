/** Minimal persisted store (localStorage + in-memory) with subscriptions and cross-tab updates. */
import { readJson, writeJson } from "./storage";

export interface Store<T> {
  get(): T;
  set(next: T | ((prev: T) => T)): void;
  subscribe(listener: () => void): () => void;
  readonly defaultValue: T;
  readonly key: string;
  /** Re-reads from storage (used after cross-tab changes and in tests). */
  reload(): void;
}

export function createStore<T>(key: string, defaultValue: T, sanitize: (raw: unknown) => T): Store<T> {
  let loaded = false;
  let value = defaultValue;
  const listeners = new Set<() => void>();
  const load = (): void => {
    value = sanitize(readJson<unknown>(key, defaultValue));
    loaded = true;
  };
  const emit = (): void => listeners.forEach((l) => l());
  const store: Store<T> = {
    key,
    defaultValue,
    get() {
      if (!loaded) load();
      return value;
    },
    set(next) {
      const prev = store.get();
      value = sanitize(typeof next === "function" ? (next as (p: T) => T)(prev) : next);
      writeJson(key, value);
      emit();
    },
    subscribe(listener) {
      listeners.add(listener);
      return () => listeners.delete(listener);
    },
    reload() {
      load();
      emit();
    },
  };
  if (typeof window !== "undefined") {
    window.addEventListener("storage", (e) => {
      if (e.key === key) store.reload();
    });
  }
  return store;
}
