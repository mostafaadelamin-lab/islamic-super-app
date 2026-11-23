"use client";
import { useEffect, useMemo, useRef, useState, type CSSProperties, type ReactNode } from "react";
import { t, type Locale } from "@/lib/i18n";
import { localizeDigits } from "@/lib/digits";
import { offlineSupported } from "@/lib/audio-offline";
import {
  deleteLessonAudio,
  filterSeries,
  lessonsDoneStore,
  lessonsProgressStore,
  lessonsSavedStore,
  loadLessons,
  rememberPlay,
  rememberPosition,
  saveLessonAudio,
  setDone,
  type LessonCatalog,
  type LessonEpisode,
  type LessonSeries,
} from "@/lib/lessons";
import { normalizeArabic } from "@/lib/search";
import { useStore } from "@/hooks/useStore";
import { Icon } from "./Icon";
import { NowPlaying, PlayerSlot, type Track } from "./RecitationLibrary";

const norm = (s: string): string => normalizeArabic(s.toLowerCase());

/** Cover colour per topic (deep tones that read well with the gold title); same as the app. */
const TOPIC_COLORS: Record<string, string> = {
  aqeedah: "#1D3A64",
  seerah: "#16433A",
  fiqh: "#2E3D22",
  hadith: "#3B2A12",
  hearts: "#40243A",
  stories: "#25324F",
  quran: "#123B4A",
  family: "#1F4A3A",
  akhlaq: "#4A2A22",
  adab: "#2B2F52",
  muamalat: "#3A3A1A",
  tahara: "#14465A",
  akhira: "#2A1E36",
};
const DEFAULT_COLOR = "#1D3A64";
const SEC_PER_MIN = 60;
const SEC_PER_HOUR = 3600;
/** Longer than this shows hours instead of minutes. */
const HOURS_FROM_MIN = 90;
/** From this many hours the count is rounded to a whole number. */
const WHOLE_HOURS_FROM = 10;
const TENTHS = 10;
/** Save the place in the lesson at most this often (seconds of audio). */
const SAVE_EVERY_SEC = 5;
const PERCENT = 100;

const topicColor = (id: string): string => TOPIC_COLORS[id] ?? DEFAULT_COLOR;
const keyOf = (e: LessonEpisode): string => `lessons:${e.id}`;

/**
 * «سلاسل الدروس»: series cards (filter by scholars and topic, search), then a series page with every lesson,
 * ✓ for those heard, "continue", download per lesson or the whole series. The player sits under the lesson playing.
 */
export function LessonsView({
  locale,
  loader = loadLessons,
  only,
}: {
  locale: Locale;
  loader?: () => Promise<LessonCatalog>;
  /** One series only (the Sha'rawi section's seerah / prophets' stories): no list, no back button. */
  only?: string;
}) {
  const [data, setData] = useState<LessonCatalog | null>(null);
  const [failed, setFailed] = useState(false);
  const [group, setGroup] = useState<string | null>(null);
  const [topic, setTopic] = useState<string | null>(null);
  const [query, setQuery] = useState("");
  const [open, setOpen] = useState<string | null>(null);
  const [track, setTrack] = useState<Track | null>(null);
  const [slot, setSlot] = useState<HTMLElement | null>(null);
  const done = useStore(lessonsDoneStore);
  const progress = useStore(lessonsProgressStore);
  const ar = locale === "ar";
  const n = (v: number): string => localizeDigits(v, locale);

  useEffect(() => {
    const load = async (): Promise<void> => {
      try {
        setData(await loader());
      } catch {
        setFailed(true);
      }
    };
    void load();
  }, [loader]);
  // The series page is in the address (#series-id), so the back button and links work.
  useEffect(() => {
    if (only) return undefined;
    const read = (): void => setOpen(decodeURIComponent(window.location.hash.slice(1)) || null);
    read();
    window.addEventListener("hashchange", read);
    return () => window.removeEventListener("hashchange", read);
  }, [only]);

  const list = useMemo(() => {
    if (!data) return [];
    const q = norm(query.trim());
    return filterSeries(data, group, topic).filter(
      (s) => !q || [s.ar, s.en, s.sheikh.ar, s.sheikh.en, s.topic.ar].some((x) => norm(x).includes(q)),
    );
  }, [data, group, topic, query]);

  if (failed) return <p className="alert alert-error">{t(locale, "lessons.loadError")}</p>;
  if (!data) return <p className="muted">{t(locale, "common.loading")}</p>;

  const go = (id: string | null): void => {
    window.location.hash = id ? encodeURIComponent(id) : "";
    setOpen(id);
    window.scrollTo?.({ top: 0 });
  };
  const wanted = only ?? open;
  const series = wanted ? [...data.series, ...data.sharawi].find((s) => s.id === wanted) : undefined;
  const heard = (s: LessonSeries): number => s.episodes.filter((e) => done.includes(e.id)).length;
  const duration = (sec: number): string => {
    const m = Math.max(1, Math.round(sec / SEC_PER_MIN));
    if (m < HOURS_FROM_MIN) return t(locale, "lessons.minutes", { n: n(m) });
    const h = sec / SEC_PER_HOUR;
    return t(locale, "lessons.hours", {
      n: n(h >= WHOLE_HOURS_FROM ? Math.round(h) : Math.round(h * TENTHS) / TENTHS),
    });
  };
  const player = track ? (
    <NowPlaying
      locale={locale}
      track={track}
      onTrack={(tr) => {
        setTrack(tr);
        const sid = series?.id;
        if (sid) rememberPlay(sid, tr.key.slice("lessons:".length));
      }}
      onClose={() => setTrack(null)}
      slot={slot}
      onTime={(tr, sec) => {
        const id = tr.key.slice("lessons:".length);
        const was = lessonsProgressStore.get().pos[id] ?? 0;
        if (Math.abs(sec - was) >= SAVE_EVERY_SEC) rememberPosition(id, sec);
      }}
      onEnded={(tr) => {
        const id = tr.key.slice("lessons:".length);
        setDone(id, true);
        rememberPosition(id, 0);
      }}
    />
  ) : null;

  if (series) {
    return (
      <SeriesPage
        locale={locale}
        series={series}
        current={track?.key ?? null}
        done={done}
        lastId={progress.last[series.id] ?? null}
        positions={progress.pos}
        player={player}
        heard={heard(series)}
        duration={duration}
        onSlot={setSlot}
        onBack={only ? undefined : () => go(null)}
        onPlay={(tr) => {
          setTrack(tr);
          rememberPlay(series.id, tr.key.slice("lessons:".length));
        }}
      />
    );
  }

  const last = progress.series ? data.series.find((s) => s.id === progress.series) : undefined;
  const lastEp = last ? last.episodes.find((e) => e.id === progress.last[last.id]) : undefined;
  const chip = (id: string, label: string, on: boolean, tap: () => void) => (
    <button
      key={id}
      type="button"
      className={on ? "btn btn-sm btn-primary" : "btn btn-sm"}
      aria-pressed={on}
      data-testid={id}
      onClick={tap}
    >
      {label}
    </button>
  );
  return (
    <>
      {player}
      <p className="muted" data-testid="lessons-note">
        {t(locale, "lessons.note", {
          series: n(data.series.length),
          lessons: n(data.series.reduce((a, s) => a + s.episodes.length, 0)),
        })}
      </p>
      <div className="row lessons-chips" role="group">
        {chip("lessons-group-all", t(locale, "lessons.all"), group === null, () => setGroup(null))}
        {data.groups.map((g) =>
          chip(`lessons-group-${g.id}`, ar ? g.ar : g.en, group === g.id, () => setGroup(g.id)),
        )}
      </div>
      <div className="row lessons-chips" role="group">
        {chip("lessons-topic-all", t(locale, "lessons.allTopics"), topic === null, () => setTopic(null))}
        {data.topics
          .filter((x) => filterSeries(data, group, x.id).length > 0)
          .map((x) => chip(`lessons-topic-${x.id}`, ar ? x.ar : x.en, topic === x.id, () => setTopic(x.id)))}
      </div>
      <input
        type="search"
        className="input"
        value={query}
        placeholder={t(locale, "lessons.search")}
        aria-label={t(locale, "lessons.search")}
        data-testid="lessons-search"
        onChange={(e) => setQuery(e.target.value)}
      />
      {last && lastEp ? (
        <button
          type="button"
          className="lessons-continue"
          data-testid="lessons-continue"
          onClick={() => go(last.id)}
        >
          <Icon name="playCircle" />
          <span className="tile-text">
            <strong>
              {t(locale, "lessons.continue", { series: ar ? last.ar : last.en, n: n(lastEp.index) })}
            </strong>
            <span className="muted small">{ar ? last.sheikh.ar : last.sheikh.en}</span>
          </span>
        </button>
      ) : null}
      {list.length === 0 ? (
        <p className="muted" data-testid="lessons-empty">
          {t(locale, "lessons.noMatch")}
        </p>
      ) : null}
      <ul className="lessons-grid" data-testid="lessons-grid">
        {list.map((s) => {
          const h = heard(s);
          const total = s.episodes.length;
          const complete = h >= total;
          return (
            <li key={s.id}>
              <a
                className="lessons-card"
                href={`#${encodeURIComponent(s.id)}`}
                data-testid={`lessons-series-${s.id}`}
                onClick={(e) => {
                  e.preventDefault();
                  go(s.id);
                }}
              >
                <span className="lessons-cover" style={{ background: topicColor(s.topic.id) }}>
                  <strong>{ar ? s.ar : s.en}</strong>
                  <span>{ar ? s.sheikh.ar : s.sheikh.en}</span>
                </span>
                <span className="lessons-card-body">
                  <strong className="small">{ar ? s.topic.ar : s.topic.en}</strong>
                  <span className="muted small">
                    {[
                      t(locale, "lessons.count", { n: n(total) }),
                      h > 0 ? t(locale, "lessons.heard", { n: n(h) }) : "",
                    ]
                      .filter(Boolean)
                      .join(" · ")}
                    {complete ? " ✓" : ""}
                  </span>
                  <span className="lessons-bar" aria-hidden="true">
                    <i
                      style={
                        {
                          width: `${total ? (h / total) * PERCENT : 0}%`,
                          background: complete ? "var(--color-success)" : "var(--color-accent)",
                        } as CSSProperties
                      }
                    />
                  </span>
                </span>
              </a>
            </li>
          );
        })}
      </ul>
    </>
  );
}

function SeriesPage({
  locale,
  series: s,
  current,
  done,
  lastId,
  positions,
  player,
  heard,
  duration,
  onSlot,
  onBack,
  onPlay,
}: {
  locale: Locale;
  series: LessonSeries;
  current: string | null;
  done: string[];
  lastId: string | null;
  positions: Record<string, number>;
  player: ReactNode;
  heard: number;
  duration: (sec: number) => string;
  onSlot: (el: HTMLElement | null) => void;
  onBack?: () => void;
  onPlay: (t: Track) => void;
}) {
  const ar = locale === "ar";
  const n = (v: number): string => localizeDigits(v, locale);
  const saved = useStore(lessonsSavedStore);
  const [busy, setBusy] = useState<Record<string, "saving" | "error">>({});
  const [bulk, setBulk] = useState<number | null>(null);
  const [bulkFailed, setBulkFailed] = useState(false);
  const stop = useRef(false);
  const canSave = typeof window !== "undefined" && offlineSupported();
  const sheikh = ar ? s.sheikh.ar : s.sheikh.en;
  const title = ar ? s.ar : s.en;
  const total = s.episodes.reduce((a, e) => a + e.seconds, 0);
  const savedHere = s.episodes.filter((e) => saved.includes(e.id)).length;
  const allSaved = savedHere >= s.episodes.length;

  // The whole series in order: a lesson goes straight on to the next.
  const tracks: Track[] = [];
  s.episodes.forEach((e) =>
    tracks.push({
      key: keyOf(e),
      title: `${title} · ${t(locale, "lessons.lesson", { n: n(e.index) })}${e.title ? ` · ${e.title}` : ""}`,
      url: e.url,
      live: false,
      playlist: tracks,
    }),
  );
  const play = (e: LessonEpisode): void => {
    const tr = tracks[e.index - 1];
    if (tr) onPlay({ ...tr, start: positions[e.id] ?? 0 });
  };
  const last = lastId ? s.episodes.find((e) => e.id === lastId) : undefined;

  const toggleSave = async (e: LessonEpisode): Promise<void> => {
    if (saved.includes(e.id)) return deleteLessonAudio(e);
    setBusy((b) => ({ ...b, [e.id]: "saving" }));
    try {
      await saveLessonAudio(e);
      setBusy((b) => {
        const rest = { ...b };
        delete rest[e.id];
        return rest;
      });
    } catch {
      setBusy((b) => ({ ...b, [e.id]: "error" }));
    }
  };
  /** One lesson after the other; stops at the first failure or when the listener presses stop. */
  const saveAll = async (): Promise<void> => {
    stop.current = false;
    setBulkFailed(false);
    setBulk(savedHere);
    const todo = s.episodes.filter((e) => !lessonsSavedStore.get().includes(e.id));
    await todo.reduce<Promise<boolean>>(async (ok, e) => {
      if (!(await ok) || stop.current) return false;
      try {
        await saveLessonAudio(e);
        setBulk(s.episodes.filter((x) => lessonsSavedStore.get().includes(x.id)).length);
        return true;
      } catch {
        setBulkFailed(true);
        return false;
      }
    }, Promise.resolve(true));
    setBulk(null);
  };
  let bulkButton: ReactNode = null;
  if (canSave && bulk !== null) {
    bulkButton = (
      <button
        type="button"
        className="btn lessons-ghost"
        data-testid="lessons-download-stop"
        onClick={() => {
          stop.current = true;
        }}
      >
        {t(locale, "lessons.downloading", { done: n(bulk), total: n(s.episodes.length) })} ·{" "}
        {t(locale, "lessons.downloadStop")}
      </button>
    );
  } else if (canSave) {
    bulkButton = (
      <button
        type="button"
        className="btn lessons-ghost"
        data-testid="lessons-download-all"
        disabled={allSaved}
        onClick={() => void saveAll()}
      >
        <Icon name={allSaved ? "check" : "download"} />{" "}
        {t(locale, allSaved ? "lessons.downloadedAll" : "lessons.downloadAll")}
      </button>
    );
  }
  const saveLabel = (isSaved: boolean, state: "saving" | "error" | undefined): string => {
    if (isSaved) return t(locale, "sharawi.delete");
    return t(locale, state === "saving" ? "sharawi.saving" : "sharawi.save");
  };

  return (
    <>
      {onBack ? (
        <button type="button" className="btn btn-sm" data-testid="lessons-back" onClick={onBack}>
          <Icon name="back" /> {t(locale, "lessons.title")}
        </button>
      ) : null}
      <section
        className="lessons-hero"
        style={{ background: `linear-gradient(160deg, ${topicColor(s.topic.id)}, #0A1830)` }}
        data-testid="lessons-hero"
      >
        <h2>{title}</h2>
        <p>{sheikh}</p>
        <p className="lessons-meta small" data-testid="lessons-meta">
          {[
            ar ? s.topic.ar : s.topic.en,
            t(locale, "lessons.count", { n: n(s.episodes.length) }),
            total > 0 ? duration(total) : "",
            heard > 0 ? t(locale, "lessons.heard", { n: n(heard) }) : "",
            savedHere > 0 ? t(locale, "lessons.saved", { n: n(savedHere) }) : "",
          ]
            .filter(Boolean)
            .join(" · ")}
        </p>
        <div className="row">
          <button
            type="button"
            className="btn lessons-gold"
            data-testid="lessons-continue-btn"
            onClick={() => play(last ?? s.episodes[0]!)}
          >
            <Icon name="play" />{" "}
            {last ? t(locale, "lessons.continueBtn", { n: n(last.index) }) : t(locale, "lessons.start")}
          </button>
          {bulkButton}
        </div>
        {bulkFailed ? (
          <p className="small" role="alert">
            {t(locale, "lessons.downloadFailed")}
          </p>
        ) : null}
      </section>
      {player}
      <ol className="episode-list" data-testid="lessons-episodes">
        {s.episodes.map((e) => {
          const on = current === keyOf(e);
          const isDone = done.includes(e.id);
          const isSaved = saved.includes(e.id);
          const state = busy[e.id];
          const sub = [
            e.title ?? "",
            e.seconds ? duration(e.seconds) : "",
            isDone ? t(locale, "lessons.done") : "",
          ]
            .filter(Boolean)
            .join(" · ");
          let icon: "pause" | "checkCircle" | "play" = "play";
          if (on) icon = "pause";
          else if (isDone) icon = "checkCircle";
          return (
            <li key={e.id} aria-current={on ? "true" : undefined} className={on ? "row has-player" : "row"}>
              <button
                type="button"
                className={isDone ? "episode lessons-done" : "episode"}
                data-testid={`lesson-${e.id}`}
                aria-pressed={on}
                onClick={() => play(e)}
              >
                <Icon name={icon} />
                <span className="tile-text">
                  <strong>{t(locale, "lessons.lesson", { n: n(e.index) })}</strong>
                  {sub ? <span className="muted small">{sub}</span> : null}
                </span>
              </button>
              <button
                type="button"
                className="btn btn-sm lessons-mark"
                data-testid={`lesson-done-${e.id}`}
                aria-pressed={isDone}
                aria-label={t(locale, "lessons.done")}
                title={t(locale, "lessons.done")}
                onClick={() => setDone(e.id, !isDone)}
              >
                <Icon name={isDone ? "checkCircle" : "check"} />
              </button>
              {canSave ? (
                <button
                  type="button"
                  className="btn btn-sm"
                  data-testid={`lesson-save-${e.id}`}
                  disabled={state === "saving"}
                  aria-label={saveLabel(isSaved, state)}
                  title={t(locale, isSaved ? "sharawi.delete" : "sharawi.save")}
                  onClick={() => void toggleSave(e)}
                >
                  <Icon name={isSaved ? "trash" : "download"} />
                  {state === "error" ? " ⚠" : ""}
                </button>
              ) : null}
              {on ? <PlayerSlot onSlot={onSlot} /> : null}
            </li>
          );
        })}
      </ol>
    </>
  );
}
