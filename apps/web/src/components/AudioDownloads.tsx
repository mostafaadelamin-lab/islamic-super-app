"use client";
import { useEffect, useRef, useState } from "react";
import { t, type Locale } from "@/lib/i18n";
import { localizeDigits } from "@/lib/digits";
import { surahName } from "@/lib/pages";
import { audioStore, RECITERS, SURAH_COUNT } from "@/lib/audio";
import {
  deleteAll,
  deleteSurah,
  downloadSurah,
  downloadsStore,
  isSaved,
  offlineSupported,
  totalBytes,
} from "@/lib/audio-offline";
import { useStore } from "@/hooks/useStore";

const MB = 1_048_576;
const MB_DECIMALS = 1;
const SURAHS = Array.from({ length: SURAH_COUNT }, (_, i) => i + 1);

interface Busy {
  surah: number;
  done: number;
  total: number;
}

/** Save whole surahs of the chosen reciter for listening without a connection. */
export function AudioDownloads({ locale }: { locale: Locale }) {
  const prefs = useStore(audioStore);
  const dl = useStore(downloadsStore);
  const [surah, setSurah] = useState(1);
  const [busy, setBusy] = useState<Busy | null>(null);
  const [failed, setFailed] = useState(false);
  const [supported, setSupported] = useState(true);
  const abort = useRef<AbortController | null>(null);
  useEffect(() => setSupported(offlineSupported()), []);
  useEffect(() => () => abort.current?.abort(), []);

  const n = (v: number | string): string => localizeDigits(v, locale);
  const reciterName = (folder: string): string => {
    const r = RECITERS.find((x) => x.folder === folder);
    if (!r) return folder;
    return locale === "ar" ? r.ar : r.en;
  };
  const saved = isSaved(dl, prefs.reciter, surah);

  const start = async (): Promise<void> => {
    const ctrl = new AbortController();
    abort.current = ctrl;
    setFailed(false);
    setBusy({ surah, done: 0, total: 0 });
    try {
      await downloadSurah(prefs.reciter, surah, (done, total) => setBusy({ surah, done, total }), ctrl.signal);
    } catch {
      if (!ctrl.signal.aborted) setFailed(true);
    } finally {
      abort.current = null;
      setBusy(null);
    }
  };

  return (
    <section className="card" aria-labelledby="dl-h" data-testid="audio-downloads">
      <h2 id="dl-h" className="card-title">
        {t(locale, "downloads.title")}
      </h2>
      {!supported ? (
        <p className="muted">{t(locale, "downloads.unsupported")}</p>
      ) : (
        <>
          <p className="muted small">
            {t(locale, "downloads.intro", { reciter: reciterName(prefs.reciter) })}
          </p>
          <div className="field">
            <label htmlFor="dl-surah">{t(locale, "downloads.surah")}</label>
            <select
              id="dl-surah"
              value={surah}
              disabled={busy !== null}
              onChange={(e) => setSurah(Number(e.target.value))}
              data-testid="dl-surah"
            >
              {SURAHS.map((s) => (
                <option key={s} value={s}>
                  {n(s)}. {surahName(s, locale)}
                  {isSaved(dl, prefs.reciter, s) ? " ✓" : ""}
                </option>
              ))}
            </select>
          </div>
          {busy ? (
            <div className="dl-progress">
              <progress max={busy.total || 1} value={busy.done} aria-label={t(locale, "downloads.saving")} />
              <span data-testid="dl-progress">
                {t(locale, "downloads.progress", { done: n(busy.done), total: n(busy.total) })}
              </span>
              <button type="button" className="btn" onClick={() => abort.current?.abort()} data-testid="dl-cancel">
                {t(locale, "downloads.cancel")}
              </button>
            </div>
          ) : (
            <button
              type="button"
              className="btn btn-primary"
              disabled={saved}
              onClick={() => void start()}
              data-testid="dl-start"
            >
              {saved ? t(locale, "downloads.saved") : t(locale, "downloads.save")}
            </button>
          )}
          {failed ? (
            <p className="alert alert-error" role="alert" data-testid="dl-error">
              {t(locale, "downloads.failed")}
            </p>
          ) : null}

          <h3>{t(locale, "downloads.list")}</h3>
          {dl.saved.length === 0 ? (
            <p className="muted" data-testid="dl-empty">
              {t(locale, "downloads.none")}
            </p>
          ) : (
            <ul className="dl-list" data-testid="dl-list">
              {dl.saved.map((d) => (
                <li key={`${d.folder}-${d.surah}`}>
                  <span>
                    {surahName(d.surah, locale)} · {reciterName(d.folder)}
                    {d.bytes ? ` · ${n((d.bytes / MB).toFixed(MB_DECIMALS))} MB` : ""}
                  </span>
                  <button
                    type="button"
                    className="btn"
                    aria-label={t(locale, "downloads.delete", { surah: surahName(d.surah, locale) })}
                    onClick={() => void deleteSurah(d.folder, d.surah)}
                    data-testid={`dl-delete-${d.folder}-${d.surah}`}
                  >
                    ✕
                  </button>
                </li>
              ))}
            </ul>
          )}
          {dl.saved.length > 0 ? (
            <p>
              <span className="muted">
                {t(locale, "downloads.total", { mb: n((totalBytes(dl) / MB).toFixed(MB_DECIMALS)) })}
              </span>{" "}
              <button
                type="button"
                className="btn"
                onClick={() => {
                  if (window.confirm(t(locale, "downloads.deleteAllConfirm"))) void deleteAll();
                }}
                data-testid="dl-delete-all"
              >
                {t(locale, "downloads.deleteAll")}
              </button>
            </p>
          ) : null}
        </>
      )}
    </section>
  );
}
