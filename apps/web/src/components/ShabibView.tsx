"use client";
import { useEffect, useMemo, useRef, useState } from "react";
import { t, type Locale } from "@/lib/i18n";
import { localizeDigits } from "@/lib/digits";
import { pauseOthers } from "@/lib/audio-focus";
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
import { claimMediaSession, mediaSessionState } from "@/lib/element-media-session";
import { Icon } from "./Icon";
import { SleepTimer } from "./SleepTimer";

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

/** Sheikh Mohamed Ahmed Shabib: his murattal surahs and his mujawwad recitations; one native audio player. */
export function ShabibView({
  locale,
  loader = loadShabib,
}: {
  locale: Locale;
  loader?: () => Promise<Shabib>;
}) {
  const [data, setData] = useState<Shabib | null>(null);
  const [failed, setFailed] = useState(false);
  const [kind, setKind] = useState<ShabibKind>("murattal");
  const [query, setQuery] = useState("");
  const [current, setCurrent] = useState<ShabibTrack | null>(null);
  const audioRef = useRef<HTMLAudioElement>(null);
  const saved = useStore(shabibSavedStore);
  const [busy, setBusy] = useState<Record<string, "saving" | "error">>({});
  const canSave = typeof window !== "undefined" && offlineSupported();
  const n = (v: number): string => localizeDigits(v, locale);

  useEffect(() => {
    loader().then(setData, () => setFailed(true));
  }, [loader]);

  useEffect(() => {
    const el = audioRef.current;
    if (current && el) void Promise.resolve(el.play()).catch(() => undefined); // a refusal leaves the native controls
  }, [current]);

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
  /** The track after (or before) the current one in its list: one goes straight on to the next. */
  const step = (delta: 1 | -1): ShabibTrack | null => {
    if (!current) return null;
    const own = data[current.kind];
    const i = own.findIndex((x) => x.id === current.id);
    return i < 0 ? null : (own[i + delta] ?? null);
  };

  return (
    <>
      <p className="muted" data-testid="shabib-note">
        {t(locale, "shabib.note", { m: n(data.murattal.length), j: n(data.mujawwad.length) })}
      </p>
      {current ? (
        <section className="card series-now" data-testid="shabib-now">
          <strong>{shabibTitle(current, locale)}</strong>
          <audio
            ref={audioRef}
            src={current.url}
            controls
            preload="metadata"
            data-testid="shabib-audio"
            onPlay={(e) => {
              pauseOthers(e.currentTarget); // one sound at a time
              const next = step(1);
              const prev = step(-1);
              claimMediaSession(e.currentTarget, {
                title: `${t(locale, "shabib.reciter")} · ${shabibTitle(current, locale)}`,
                next: next ? () => setCurrent(next) : undefined,
                previous: prev ? () => setCurrent(prev) : undefined,
              });
              mediaSessionState(true);
            }}
            onPause={() => mediaSessionState(false)}
            onEnded={() => {
              const next = step(1);
              if (next) setCurrent(next);
            }}
          />
          <div className="row">
            <SleepTimer locale={locale} />
          </div>
        </section>
      ) : null}
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
          const on = current?.id === x.id;
          const isSaved = saved.includes(x.id);
          const state = busy[x.id];
          return (
            <li key={x.id} aria-current={on ? "true" : undefined} className="row">
              <button
                type="button"
                className="episode"
                data-testid={`shabib-${x.id}`}
                aria-pressed={on}
                onClick={() => setCurrent(x)}
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
            </li>
          );
        })}
      </ol>
    </>
  );
}
