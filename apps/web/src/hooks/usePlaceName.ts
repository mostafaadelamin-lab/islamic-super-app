"use client";
import { useEffect } from "react";
import type { Locale } from "@/lib/i18n";
import { prayerStore } from "@/lib/settings";
import { currentPlaceName, placeLabel, placeNameStore, refreshPlaceName } from "@/lib/place-names";
import { useStore } from "./useStore";

/** "مصر - مدينتي" for the viewer's own position (null for a chosen city, or while the name is unknown). */
export function usePlaceName(locale: Locale): string | null {
  const custom = useStore(prayerStore).custom;
  const saved = useStore(placeNameStore);
  const name = currentPlaceName(saved, custom, locale);
  useEffect(() => {
    if (custom && !name?.area) void refreshPlaceName().catch(() => undefined);
  }, [custom, name?.area]);
  return custom ? placeLabel(name) : null;
}
