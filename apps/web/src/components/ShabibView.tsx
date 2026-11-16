"use client";
import { useEffect, useMemo, useState } from "react";
import { t, type Locale } from "@/lib/i18n";
import { localizeDigits } from "@/lib/digits";
import { surahName } from "@/lib/pages";
import { normalizeArabic } from "@/lib/search";
import { offlineSupported } from "@/lib/audio-offline";
import {
  deleteShabib,
  loadShabib,
  saveShabib,
  shabibSavedStore,
  type Shabib,
  type ShabibKind,
  type ShabibTrack,
} from "@/lib/shabib";
import { useStore } from "@/hooks/useStore";
import { Icon } from "./Icon";
import type { Track } from "./RecitationLibrary";

/** The library track key of one recitation. */
export const shabibKey = (x: ShabibTrack): string => `shabib:${x.id}`;

/** "سورة يوسف" / "ما تيسر من سورة البقرة" / "سور الصف والجمعة" / "قصار السور". */
export function shabibTitle(x: ShabibTrack, locale: Locale): string {
  if (x.surahs.length === 0) return t(locale, "shabib.shortSurahs");
  const names = x.surahs.map((n) => surahName(n, locale));
  if (names.length === 1)
    return t(locale, x.part ? "shabib.fromSurah" : "shabib.surah", { name: names[0] ?? "" });
  return t(locale, "shabib.surahs", { names: names.join(locale === "ar" ? " و" : ", ") });
}

export function shabibSubtitle(x: ShabibTrack, locale: Locale): string {
  const n = (v: number): string => localizeDigits(v, locale);
  return [
    x.tag && x.tag !== "short" ? t(locale, `shabib.tag.${x.tag}`) : "",
    x.year ? n(x.year) : "",
    x.seconds ? t(locale, "sharawi.minutes", { n: n(Math.max(1, Math.round(x.seconds / 60))) }) : "",
  ]
    .filter(Boolean)
    .join(" · ");
}

/**
 * Sheikh Mohamed Ahmed Shabib inside the recitation library: his murattal surahs and his mujawwad recitations.
 * The library's player plays them; its buttons sit under the recitation playing (owner 2026-11-16: not at the top).
 */
export function ShabibView({
  locale,
  loader = loadShabib,
  current = null,
  onPlay,
  onSlot,
}: {
  locale: Locale;
  loader?: () => Promise<Shabib>;
  /** Key of the library track playing. */
  current?: string | null;
  onPlay: (t: Track) => void;
  onSlot: (el: HTMLElement | null) => void;
}) {
  const [data, setData] = useState<Shabib | null>(null);
  const [failed, setFailed] = useState(false);
  const [kind, setKind] = useState<ShabibKind>("murattal");
  const [query, setQuery] = useState("");
  const saved = useStore(shabibSavedStore);
  const [busy, setBusy] = useState<Record<string, "saving" | "error">>({});
  const canSave = typeof window !== "undefined" && offlineSupported();
  const n = (v: number): string => localizeDigits(v, locale);

  useEffect(() => {
    loader().then(setData, () => setFailed(true));
  }, [loader]);

  const list = useMemo(() => {
    const all = data?.[kind] ?? [];
    const q = normalizeArabic(query.trim().toLowerCase());
    if (!q) return all;
    return all.filter(
      (x) =>
        normalizeArabic(shabibTitle(x, locale).toLowerCase()).includes(q) ||
        x.surahs.some((s) => String(s) === q || n(s) === q),
    );
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [data, kind, query, locale]);

  if (failed) return <p className="alert alert-error">{t(locale, "shabib.loadError")}</p>;
  if (!data) return <p className="muted">{t(locale, "common.loading")}</p>;

  const toggleSave = async (x: ShabibTrack): Promise<void> => {
    if (saved.includes(x.id)) return deleteShabib(x);
    setBusy((b) => ({ ...b, [x.id]: "saving" }));
    try {
      await saveShabib(x);
      setBusy((b) => {
        const rest = { ...b };
        delete rest[x.id];
        return rest;
      });
    } catch {
      setBusy((b) => ({ ...b, [x.id]: "error" }));
    }
  };
  /** Library tracks, the whole list of one kind in order: one recitation goes straight on to the next. */
  const tracksOf = (k: ShabibKind): Track[] => {
    const own: Track[] = data[k].map((x) => ({
      key: shabibKey(x),
      title: `${t(locale, "shabib.reciter")} · ${shabibTitle(x, locale)}`,
      url: x.url,
      live: false,
    }));
    own.forEach((x) => (x.playlist = own));
    return own;
  };
  const tracks = tracksOf(kind);

  return (
    <>
      <p className="muted" data-testid="shabib-note">
        {t(locale, "shabib.note", { m: n(data.murattal.length), j: n(data.mujawwad.length) })}
      </p>
      <div className="row" role="tablist">
        {(["murattal", "mujawwad"] as const).map((id) => (
          <button
            key={id}
            type="button"
            role="tab"
            aria-selected={kind === id}
            className={kind === id ? "btn btn-primary" : "btn"}
            onClick={() => setKind(id)}
            data-testid={`shabib-tab-${id}`}
          >
            {t(locale, `shabib.${id}`)} ({n(data[id].length)})
          </button>
        ))}
      </div>
      <p className="muted small" data-testid="shabib-kind-note">
        {t(locale, `shabib.${kind}Note`)}
      </p>
      <input
        type="search"
        className="input"
        value={query}
        placeholder={t(locale, "sharawi.search")}
        aria-label={t(locale, "sharawi.search")}
        data-testid="shabib-search"
        onChange={(e) => setQuery(e.target.value)}
      />
      {list.length === 0 ? <p className="muted">{t(locale, "shabib.noMatch")}</p> : null}
      <ol className="episode-list" data-testid={`shabib-list-${kind}`}>
        {list.map((x) => {
          const on = current === shabibKey(x);
          const isSaved = saved.includes(x.id);
          const state = busy[x.id];
          return (
            <li key={x.id} aria-current={on ? "true" : undefined} className={on ? "row has-player" : "row"}>
              <button
                type="button"
                className="episode"
                data-testid={`shabib-${x.id}`}
                aria-pressed={on}
                onClick={() => {
                  const tr = tracks.find((y) => y.key === shabibKey(x));
                  if (tr) onPlay(tr);
                }}
              >
                <Icon name={on ? "pause" : "play"} />
                <span className="tile-text">
                  <strong>{shabibTitle(x, locale)}</strong>
                  <span className="muted small">{shabibSubtitle(x, locale)}</span>
                </span>
              </button>
              {canSave ? (
                <button
                  type="button"
                  className="btn btn-sm"
                  data-testid={`shabib-save-${x.id}`}
                  disabled={state === "saving"}
                  aria-label={t(
                    locale,
                    isSaved ? "sharawi.delete" : state === "saving" ? "sharawi.saving" : "sharawi.save",
                  )}
                  title={t(locale, isSaved ? "sharawi.delete" : "sharawi.save")}
                  onClick={() => void toggleSave(x)}
                >
                  <Icon name={isSaved ? "trash" : "download"} />
                  {isSaved ? ` ${t(locale, "sharawi.saved")}` : state === "error" ? " ⚠" : ""}
                </button>
              ) : null}
              {/* Under the row: the player's buttons (owner 2026-11-16: not at the top of the page). */}
              {on ? <div className="nasheed-slot" ref={onSlot} data-testid="library-slot" /> : null}
            </li>
          );
        })}
      </ol>
    </>
  );
}
