"use client";
import { useEffect, useRef, useState } from "react";
import { t, type Locale } from "@/lib/i18n";
import { localizeDigits } from "@/lib/digits";
import { deleteAudioFile, dhikrSavedStore, offlineSupported, saveAudioFile } from "@/lib/audio-offline";
import { useStore } from "@/hooks/useStore";
import { Icon } from "./Icon";

/**
 * «استماع بدون إنترنت · حمّل الكل» at the top of a page of adhkar that can be heard (owner 2026-11-27, same as
 * the app): saves every recording of the page at once, with the progress, cancel, and delete once all are saved.
 */
export function DhikrOfflineCard({
  locale,
  group,
  urls,
}: {
  locale: Locale;
  group: string;
  urls: readonly string[];
}) {
  const saved = useStore(dhikrSavedStore);
  const [can, setCan] = useState(false);
  const [run, setRun] = useState<{ done: number; total: number } | null>(null);
  const [failed, setFailed] = useState(false);
  const stop = useRef(false);
  useEffect(() => setCan(offlineSupported()), []);
  const list = [...new Set(urls)];
  if (!can || list.length === 0) return null;
  const have = list.filter((u) => saved.includes(u)).length;
  const n = (v: number): string => localizeDigits(v, locale);

  const all = async (): Promise<void> => {
    const todo = list.filter((u) => !dhikrSavedStore.get().includes(u));
    stop.current = false;
    setFailed(false);
    setRun({ done: 0, total: todo.length });
    let done = 0;
    for (const u of todo) {
      if (stop.current) break;
      try {
        await saveAudioFile(dhikrSavedStore, u);
      } catch {
        setFailed(true);
        break;
      }
      setRun({ done: ++done, total: todo.length });
    }
    setRun(null);
  };

  let body: React.JSX.Element;
  if (run) {
    body = (
      <>
        <p className="row" style={{ justifyContent: "space-between" }}>
          <strong data-testid="dhikr-offline-progress">
            {t(locale, "dhikr.offlineProgress", { done: n(run.done), total: n(run.total) })}
          </strong>
          <button type="button" className="btn btn-sm" onClick={() => (stop.current = true)}>
            {t(locale, "dhikr.offlineCancel")}
          </button>
        </p>
        <progress max={Math.max(1, run.total)} value={run.done} />
      </>
    );
  } else if (have === list.length) {
    body = (
      <p className="row" style={{ justifyContent: "space-between" }}>
        <strong data-testid="dhikr-offline-done">
          <Icon name="check" size={18} /> {t(locale, "dhikr.offlineDone")}
        </strong>
        <button
          type="button"
          className="btn btn-sm"
          data-testid="dhikr-offline-delete"
          onClick={() => void Promise.all(list.map((u) => deleteAudioFile(dhikrSavedStore, u)))}
        >
          {t(locale, "dhikr.offlineDelete")}
        </button>
      </p>
    );
  } else {
    body = (
      <p className="row" style={{ justifyContent: "space-between" }}>
        <span>
          <strong>
            <Icon name="headphones" size={18} /> {t(locale, "dhikr.offlineTitle")}
          </strong>
          <br />
          <span className="muted small">
            {failed
              ? t(locale, "dhikr.offlineRetry")
              : t(locale, "dhikr.offlineCount", { n: n(list.length) })}
          </span>
        </span>
        <button
          type="button"
          className="btn btn-sm"
          data-testid="dhikr-offline-all"
          onClick={() => void all()}
        >
          <Icon name="download" size={16} /> {t(locale, "dhikr.offlineAll")}
        </button>
      </p>
    );
  }
  return (
    <section className="card dhikr-offline" data-testid={`dhikr-offline-${group}`}>
      {body}
    </section>
  );
}
