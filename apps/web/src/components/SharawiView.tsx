"use client";
import { useEffect, useMemo, useState } from "react";
import { t, type Locale } from "@/lib/i18n";
import { localizeDigits } from "@/lib/digits";
import { surahName } from "@/lib/pages";
import { offlineSupported } from "@/lib/audio-offline";
import {
  deleteLesson,
  loadSharawi,
  saveLesson,
  sharawiSavedStore,
  type SharawiLesson,
  type SharawiSurah,
} from "@/lib/sharawi";
import { useStore } from "@/hooks/useStore";
import { Icon } from "./Icon";
import { NowPlaying, PlayerSlot, type Track } from "./RecitationLibrary";

const norm = (s: string): string =>
  s
    .toLowerCase()
    .replace(/[ً-ْـ]/g, "")
    .replace(/[أإآٱ]/g, "ا")
    .replace(/ى/g, "ي")
    .replace(/ة/g, "ه");

/**
 * Al-Sha'rawi audio tafsir: pick a surah, then a lesson. The player's buttons sit under the lesson playing
 * (owner 2026-11-16: not at the top of the page), or at the top when its surah is closed.
 */
export function SharawiView({
  locale,
  loader = loadSharawi,
}: {
  locale: Locale;
  loader?: () => Promise<SharawiSurah[]>;
}) {
  const [data, setData] = useState<SharawiSurah[] | null>(null);
  const [failed, setFailed] = useState(false);
  const [query, setQuery] = useState("");
  const [open, setOpen] = useState<number | null>(null);
  const [track, setTrack] = useState<Track | null>(null);
  const [slot, setSlot] = useState<HTMLElement | null>(null);
  const saved = useStore(sharawiSavedStore);
  const [busy, setBusy] = useState<Record<number, "saving" | "error">>({});
  const canSave = typeof window !== "undefined" && offlineSupported();
  const toggleSave = async (l: SharawiLesson): Promise<void> => {
    if (saved.includes(l.id)) return deleteLesson(l);
    setBusy((b) => ({ ...b, [l.id]: "saving" }));
    try {
      await saveLesson(l);
      setBusy((b) => {
        const rest = { ...b };
        delete rest[l.id];
        return rest;
      });
    } catch {
      setBusy((b) => ({ ...b, [l.id]: "error" }));
    }
  };
  const n = (v: number): string => localizeDigits(v, locale);
  const name = (s: number): string => (s === 0 ? t(locale, "sharawi.intro") : surahName(s, locale));

  useEffect(() => {
    loader().then(setData, () => setFailed(true));
  }, [loader]);

  const list = useMemo(() => {
    const q = norm(query.trim());
    if (!data || !q) return data ?? [];
    return data.filter((s) => norm(name(s.surah)).includes(q) || String(s.surah) === q || n(s.surah) === q);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [data, query, locale]);

  if (failed) return <p className="alert alert-error">{t(locale, "sharawi.loadError")}</p>;
  if (!data) return <p className="muted">…</p>;
  const total = data.reduce((a, s) => a + s.lessons.length, 0);
  const title = (l: SharawiLesson): string =>
    `${name(l.surah)} · ${t(locale, "sharawi.lesson", { n: n(l.index) })}`;
  /** A surah's lessons in order: a lesson goes straight on to the next. */
  const tracksOf = (lessons: SharawiLesson[]): Track[] => {
    const own: Track[] = lessons.map((l) => ({
      key: `sharawi:${l.id}`,
      title: title(l),
      url: l.url,
      live: false,
    }));
    own.forEach((x) => (x.playlist = own));
    return own;
  };
  const sub = (l: SharawiLesson): string =>
    [
      l.from && l.to
        ? l.from === l.to
          ? t(locale, "sharawi.ayah", { n: n(l.from) })
          : t(locale, "sharawi.ayahs", { from: n(l.from), to: n(l.to) })
        : "",
      l.seconds ? t(locale, "sharawi.minutes", { n: n(Math.round(l.seconds / 60)) }) : "",
    ]
      .filter(Boolean)
      .join(" · ");

  return (
    <>
      <p className="muted" data-testid="sharawi-note">
        {t(locale, "sharawi.note", { n: n(total) })}
      </p>
      {track ? (
        <NowPlaying
          locale={locale}
          track={track}
          onTrack={setTrack}
          onClose={() => setTrack(null)}
          slot={slot}
        />
      ) : null}
      <input
        type="search"
        className="input"
        value={query}
        placeholder={t(locale, "sharawi.search")}
        aria-label={t(locale, "sharawi.search")}
        data-testid="sharawi-search"
        onChange={(e) => setQuery(e.target.value)}
      />
      {list.length === 0 ? <p className="muted">{t(locale, "sharawi.noMatch")}</p> : null}
      <ul className="story-list" data-testid="sharawi-surahs">
        {list.map((s) => (
          <li key={s.surah}>
            <details open={open === s.surah} onToggle={(e) => e.currentTarget.open && setOpen(s.surah)}>
              <summary className="story-item" data-surah={s.surah}>
                <span className="tile-icon">
                  <Icon name="book" />
                </span>
                <span className="tile-text">
                  <strong>{name(s.surah)}</strong>
                  <span className="muted small">
                    {t(locale, "sharawi.lessons", { n: n(s.lessons.length) })}
                  </span>
                </span>
              </summary>
              {open === s.surah ? (
                <ol className="episode-list">
                  {s.lessons.map((l) => {
                    const on = track?.key === `sharawi:${l.id}`;
                    const isSaved = saved.includes(l.id);
                    const state = busy[l.id];
                    return (
                      <li
                        key={l.id}
                        aria-current={on ? "true" : undefined}
                        className={on ? "row has-player" : "row"}
                      >
                        <button
                          type="button"
                          className="episode"
                          data-testid={`sharawi-${l.id}`}
                          aria-pressed={on}
                          onClick={() => {
                            const tr = tracksOf(s.lessons).find((x) => x.key === `sharawi:${l.id}`);
                            if (tr) setTrack(tr);
                          }}
                        >
                          <Icon name={on ? "pause" : "play"} />
                          <span className="tile-text">
                            <strong>{t(locale, "sharawi.lesson", { n: n(l.index) })}</strong>
                            <span className="muted small">{sub(l)}</span>
                          </span>
                        </button>
                        {canSave ? (
                          <button
                            type="button"
                            className="btn btn-sm"
                            data-testid={`sharawi-save-${l.id}`}
                            disabled={state === "saving"}
                            aria-label={t(
                              locale,
                              isSaved
                                ? "sharawi.delete"
                                : state === "saving"
                                  ? "sharawi.saving"
                                  : "sharawi.save",
                            )}
                            title={t(locale, isSaved ? "sharawi.delete" : "sharawi.save")}
                            onClick={() => void toggleSave(l)}
                          >
                            <Icon name={isSaved ? "trash" : "download"} />
                            {isSaved ? ` ${t(locale, "sharawi.saved")}` : state === "error" ? " ⚠" : ""}
                          </button>
                        ) : null}
                        {on ? <PlayerSlot onSlot={setSlot} /> : null}
                      </li>
                    );
                  })}
                </ol>
              ) : null}
            </details>
          </li>
        ))}
      </ul>
    </>
  );
}
