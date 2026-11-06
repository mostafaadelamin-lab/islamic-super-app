"use client";
import { useEffect, useState } from "react";

const cache = new Map<number, string[]>();

export type TranslationState =
  { status: "off" } | { status: "loading" } | { status: "ready"; lines: string[] } | { status: "error" };

/** Lazily loads /data/en/<surah>.json when `enabled`. */
export function useTranslation(surah: number, enabled: boolean, reloadKey = 0): TranslationState {
  const [state, setState] = useState<TranslationState>(() => {
    const hit = cache.get(surah);
    return enabled && hit ? { status: "ready", lines: hit } : { status: enabled ? "loading" : "off" };
  });
  useEffect(() => {
    if (!enabled) {
      setState({ status: "off" });
      return;
    }
    const hit = cache.get(surah);
    if (hit) {
      setState({ status: "ready", lines: hit });
      return;
    }
    let cancelled = false;
    setState({ status: "loading" });
    fetch(`/data/en/${surah}.json`)
      .then((r) => {
        if (!r.ok) throw new Error(String(r.status));
        return r.json() as Promise<string[]>;
      })
      .then((lines) => {
        cache.set(surah, lines);
        if (!cancelled) setState({ status: "ready", lines });
      })
      .catch(() => {
        if (!cancelled) setState({ status: "error" });
      });
    return () => {
      cancelled = true;
    };
  }, [surah, enabled, reloadKey]);
  return state;
}
