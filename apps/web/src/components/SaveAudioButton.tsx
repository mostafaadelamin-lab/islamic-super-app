"use client";
import { useEffect, useState } from "react";
import { t, type Locale } from "@/lib/i18n";
import { deleteAudioFile, offlineSupported, saveAudioFile } from "@/lib/audio-offline";
import type { Store } from "@/lib/store";
import { useStore } from "@/hooks/useStore";
import { Icon } from "./Icon";

/** Download / delete button for one recording kept for offline listening (same look as Sharawi and Shabib). */
export function SaveAudioButton({
  locale,
  store,
  url,
  testId,
}: {
  locale: Locale;
  store: Store<string[]>;
  url: string;
  testId: string;
}) {
  const saved = useStore(store).includes(url);
  const [state, setState] = useState<"idle" | "saving" | "error">("idle");
  // Shown after mounting only, so the server-rendered page and the first client render agree.
  const [can, setCan] = useState(false);
  useEffect(() => setCan(offlineSupported()), []);
  if (!can) return null;
  const toggle = async (): Promise<void> => {
    if (saved) return deleteAudioFile(store, url);
    setState("saving");
    try {
      await saveAudioFile(store, url);
      setState("idle");
    } catch {
      setState("error");
    }
  };
  const label = saved ? "sharawi.delete" : state === "saving" ? "sharawi.saving" : "sharawi.save";
  return (
    <button
      type="button"
      className="btn btn-sm"
      data-testid={testId}
      disabled={state === "saving"}
      aria-label={t(locale, label)}
      title={t(locale, saved ? "sharawi.delete" : "sharawi.save")}
      onClick={() => void toggle()}
    >
      <Icon name={saved ? "trash" : "download"} />
      {saved
        ? ` ${t(locale, "sharawi.saved")}`
        : state === "saving"
          ? ` ${t(locale, "sharawi.saving")}`
          : state === "error"
            ? " ⚠"
            : ""}
    </button>
  );
}
