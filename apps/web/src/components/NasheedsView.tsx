"use client";
import { useEffect, useMemo, useRef, useState } from "react";
import { t, type Locale } from "@/lib/i18n";
import { localizeDigits } from "@/lib/digits";
import { player } from "@/lib/audio-player";
import { offlineSupported } from "@/lib/audio-offline";
import {
  deleteNasheed,
  loadNasheeds,
  nasheedsSavedStore,
  normalizeArabic as norm,
  saveNasheed,
  type Munshid,
  type Nasheed,
} from "@/lib/nasheeds";
import { useStore } from "@/hooks/useStore";
import { claimMediaSession, mediaSessionState } from "@/lib/element-media-session";
import { Icon } from "./Icon";
import { SleepTimer } from "./SleepTimer";

interface Playing {
  n: Nasheed;
  m: Munshid;
}

/** Nasheeds: pick a munshid, then a nasheed; one native audio player; save any nasheed for offline listening. */
export function NasheedsView({
  locale,
  loader = loadNasheeds,
}: {
  locale: Locale;
  loader?: () => Promise<Munshid[]>;
}) {
  const [data, setData] = useState<Munshid[] | null>(null);
  const [failed, setFailed] = useState(false);
  const [query, setQuery] = useState("");
  const [open, setOpen] = useState<number | null>(null);
  const [current, setCurrent] = useState<Playing | null>(null);
  const audioRef = useRef<HTMLAudioElement>(null);
  const saved = useStore(nasheedsSavedStore);
  const [busy, setBusy] = useState<Record<number, "saving" | "error">>({});
  const canSave = typeof window !== "undefined" && offlineSupported();
  const n = (v: number): string => localizeDigits(v, locale);

  useEffect(() => {
    loader().then(setData, () => setFailed(true));
  }, [loader]);
  useEffect(() => {
    const el = audioRef.current;
    if (current && el) void Promise.resolve(el.play()).catch(() => undefined);
  }, [current]);

  const toggleSave = async (x: Nasheed): Promise<void> => {
    if (saved.includes(x.id)) return deleteNasheed(x);
    setBusy((b) => ({ ...b, [x.id]: "saving" }));
    try {
      await saveNasheed(x);
      setBusy((b) => {
        const rest = { ...b };
        delete rest[x.id];
        return rest;
      });
    } catch {
      setBusy((b) => ({ ...b, [x.id]: "error" }));
    }
  };

  const q = norm(query.trim());
  const singers = useMemo(() => (data ?? []).filter((m) => !q || norm(m.name).includes(q)), [data, q]);
  const hits = useMemo(
    () =>
      q
        ? (data ?? []).flatMap((m) =>
            m.items.filter((x) => norm(x.title).includes(q)).map((x) => ({ n: x, m })),
          )
        : [],
    [data, q],
  );

  if (failed) return <p className="alert alert-error">{t(locale, "nasheeds.loadError")}</p>;
  if (!data) return <p className="muted">…</p>;

  const step = (delta: 1 | -1): Playing | null => {
    if (!current) return null;
    const i = current.m.items.findIndex((x) => x.id === current.n.id);
    const next = current.m.items[i + delta];
    return i < 0 || !next ? null : { n: next, m: current.m };
  };

  const row = (p: Playing, withSinger: boolean) => {
    const on = current?.n.id === p.n.id;
    const isSaved = saved.includes(p.n.id);
    const state = busy[p.n.id];
    return (
      <li key={`${p.m.id}-${p.n.id}`} aria-current={on ? "true" : undefined} className="row">
        <button
          type="button"
          className="episode"
          data-testid={`nasheed-${p.n.id}`}
          aria-pressed={on}
          onClick={() => setCurrent(p)}
        >
          <Icon name={on ? "pause" : "play"} />
          <span className="tile-text">
            <strong>{p.n.title}</strong>
            {withSinger ? <span className="muted small">{p.m.name}</span> : null}
          </span>
        </button>
        {canSave ? (
          <button
            type="button"
            className="btn btn-sm"
            data-testid={`nasheed-save-${p.n.id}`}
            disabled={state === "saving"}
            aria-label={t(
              locale,
              isSaved ? "sharawi.delete" : state === "saving" ? "sharawi.saving" : "sharawi.save",
            )}
            title={t(locale, isSaved ? "sharawi.delete" : "sharawi.save")}
            onClick={() => void toggleSave(p.n)}
          >
            <Icon name={isSaved ? "trash" : "download"} />
            {isSaved ? ` ${t(locale, "sharawi.saved")}` : state === "error" ? " ⚠" : ""}
          </button>
        ) : null}
      </li>
    );
  };

  return (
    <>
      <p className="muted" data-testid="nasheeds-note">
        {t(locale, "nasheeds.note")}
      </p>
      {current ? (
        <section className="card series-now" data-testid="nasheeds-now">
          <strong>
            {current.n.title} · {current.m.name}
          </strong>
          <audio
            ref={audioRef}
            src={current.n.url}
            controls
            preload="metadata"
            data-testid="nasheeds-audio"
            onPlay={(e) => {
              player.stop();
              const next = step(1);
              const prev = step(-1);
              claimMediaSession(e.currentTarget, {
                title: `${current.n.title} · ${current.m.name}`,
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
      <input
        type="search"
        className="input"
        value={query}
        placeholder={t(locale, "nasheeds.search")}
        aria-label={t(locale, "nasheeds.search")}
        data-testid="nasheeds-search"
        onChange={(e) => setQuery(e.target.value)}
      />
      {singers.length === 0 && hits.length === 0 ? (
        <p className="muted">{t(locale, "nasheeds.noMatch")}</p>
      ) : null}
      <ul className="story-list" data-testid="nasheeds-singers">
        {singers.map((m) => (
          <li key={m.id}>
            <details open={open === m.id} onToggle={(e) => e.currentTarget.open && setOpen(m.id)}>
              <summary className="story-item" data-munshid={m.id}>
                <span className="tile-icon">
                  <Icon name="headphones" />
                </span>
                <span className="tile-text">
                  <strong>{m.name}</strong>
                  <span className="muted small">{t(locale, "nasheeds.count", { n: n(m.items.length) })}</span>
                </span>
              </summary>
              {open === m.id ? (
                <ol className="episode-list">{m.items.map((x) => row({ n: x, m }, false))}</ol>
              ) : null}
            </details>
          </li>
        ))}
      </ul>
      {hits.length > 0 ? (
        <ol className="episode-list" data-testid="nasheeds-hits">
          {hits.map((p) => row(p, true))}
        </ol>
      ) : null}
    </>
  );
}
