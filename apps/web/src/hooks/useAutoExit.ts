"use client";
import { useEffect, useRef } from "react";

/** How long the "done" tick stays before a finished adhkar list leaves by itself (same as the app). */
export const ADHKAR_AUTO_EXIT_MS = 1200;

/**
 * Owner 2026-11-15: when the reader completes the last dhikr of a list, go back to the list it was
 * opened from, after a short moment so the last tap is seen to count. Only a completion that happens
 * while the list is shown counts (a list already finished today opens normally); `key` changing
 * (e.g. morning ↔ evening) starts over, and undoing it (reset) before the delay cancels it.
 */
export function useAutoExit(complete: boolean, key: string, exit: () => void): void {
  const was = useRef<{ key: string; complete: boolean } | null>(null);
  const exitRef = useRef(exit);
  exitRef.current = exit;
  useEffect(() => {
    const prev = was.current;
    was.current = { key, complete };
    if (!complete || !prev || prev.key !== key || prev.complete) return;
    const timer = window.setTimeout(() => exitRef.current(), ADHKAR_AUTO_EXIT_MS);
    return () => window.clearTimeout(timer);
  }, [complete, key]);
}
