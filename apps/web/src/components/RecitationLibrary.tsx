"use client";
import { useEffect, useRef, useState } from "react";
import { t, type Locale } from "@/lib/i18n";
import { localizeDigits } from "@/lib/digits";
import { player } from "@/lib/audio-player";
import { normalizeArabic } from "@/lib/search";
import { SURAHS } from "@/lib/pages";
import {
  apiLanguage,
  filterRadios,
  filterReciters,
  loadLibrary,
  surahUrl,
  type Library,
  type Reciter,
} from "@/lib/mp3quran";
import { Icon } from "./Icon";
import { SleepTimer } from "./SleepTimer";

interface Track {
  key: string;
  title: string;
  url: string;
  live: boolean;
}

type Tab = "reciters" | "radios";

/** One native audio player for the chosen surah or radio (stops the app's recitation player: one voice at a time). */
function NowPlaying({ locale, track }: { locale: Locale; track: Track }) {
  const ref = useRef<HTMLAudioElement>(null);
  const [error, setError] = useState(false);
  useEffect(() => {
    setError(false);
    const el = ref.current;
    if (!el) return;
    // The user pressed play; a refusal (autoplay policy) leaves the native controls.
    (async (): Promise<void> => {
      try {
        await el.play();
      } catch {
        /* see above */
      }
    })();
  }, [track.key]);
  return (
    <div className="card series-now" data-testid="library-now">
      <strong>
        {t(locale, "library.nowPlaying")}: {track.title}
        {track.live ? ` · ${t(locale, "library.live")}` : ""}
      </strong>
      <audio
        ref={ref}
        src={track.url}
        controls
        preload="none"
        data-testid="library-audio"
        onPlay={() => {
          setError(false);
          player.stop();
        }}
        onError={() => setError(true)}
      />
      {error ? (
        <p className="alert alert-error" role="alert" data-testid="library-play-error">
          {t(locale, "library.playError")}
        </p>
      ) : null}
      <SleepTimer locale={locale} />
    </div>
  );
}

function ReciterView({
  locale,
  reciter,
  rewaya,
  current,
  onPlay,
  onBack,
}: {
  locale: Locale;
  reciter: Reciter;
  rewaya: number | null;
  current: string | null;
  onPlay: (t: Track) => void;
  onBack: () => void;
}) {
  const first = reciter.moshafs.find((m) => m.rewayaId === rewaya) ?? reciter.moshafs[0]!;
  const [moshafId, setMoshafId] = useState(first.id);
  const moshaf = reciter.moshafs.find((m) => m.id === moshafId) ?? first;
  return (
    <section className="card" data-testid="library-reciter" aria-labelledby="library-reciter-h">
      <p>
        <button type="button" className="btn btn-sm" onClick={onBack} data-testid="library-back">
          {t(locale, "library.back")}
        </button>
      </p>
      <h2 className="card-title" id="library-reciter-h">
        {reciter.name}
      </h2>
      <label className="field">
        <span>{t(locale, "library.rewaya")}</span>
        <select
          value={moshaf.id}
          onChange={(e) => setMoshafId(Number(e.target.value))}
          data-testid="library-moshaf"
        >
          {reciter.moshafs.map((m) => (
            <option key={m.id} value={m.id}>
              {m.name}
            </option>
          ))}
        </select>
      </label>
      <p className="muted small">
        {t(locale, "library.surahCount", { n: localizeDigits(moshaf.surahs.length, locale) })}
      </p>
      <ol className="episode-list">
        {moshaf.surahs.map((n) => {
          const s = SURAHS[n - 1]!;
          const name = locale === "ar" ? s.nameAr : s.translit;
          const key = `${moshaf.id}:${n}`;
          const on = current === key;
          return (
            <li key={n}>
              <button
                type="button"
                className="episode"
                aria-pressed={on}
                data-testid={`library-surah-${n}`}
                onClick={() =>
                  onPlay({
                    key,
                    url: surahUrl(moshaf, n),
                    live: false,
                    title: t(locale, "library.surahTitle", { reciter: reciter.name, surah: name }),
                  })
                }
              >
                <Icon name={on ? "pause" : "play"} />
                <span className="tile-text">
                  <strong>
                    {localizeDigits(n, locale)}. {name}
                  </strong>
                </span>
              </button>
            </li>
          );
        })}
      </ol>
    </section>
  );
}

/** mp3quran.net reciters (every riwaya) and Quran radios, streamed. */
export function RecitationLibrary({ locale }: { locale: Locale }) {
  const [lib, setLib] = useState<Library | null>(null);
  const [failed, setFailed] = useState(false);
  const [tab, setTab] = useState<Tab>("reciters");
  const [query, setQuery] = useState("");
  const [rewaya, setRewaya] = useState<number | null>(null);
  const [reciter, setReciter] = useState<Reciter | null>(null);
  const [track, setTrack] = useState<Track | null>(null);

  const load = async (refresh: boolean): Promise<void> => {
    setFailed(false);
    try {
      setLib(await loadLibrary(apiLanguage(locale), { refresh }));
    } catch {
      setFailed(true);
    }
  };
  // eslint-disable-next-line react-hooks/exhaustive-deps
  useEffect(() => void load(false), [locale]);

  const source = (
    <p className="muted small" data-testid="library-source">
      {t(locale, "library.source")}
    </p>
  );

  if (failed) {
    return (
      <div className="card">
        <p className="alert alert-error" role="alert" data-testid="library-error">
          {t(locale, "library.loadError")}
        </p>
        <button type="button" className="btn" onClick={() => void load(true)} data-testid="library-retry">
          {t(locale, "library.retry")}
        </button>
      </div>
    );
  }
  if (!lib) return <p className="muted">{t(locale, "common.loading")}</p>;

  const reciters = filterReciters(lib, query, rewaya, normalizeArabic);
  const radios = filterRadios(lib, query, normalizeArabic);
  return (
    <>
      {track ? <NowPlaying locale={locale} track={track} /> : null}
      {reciter ? (
        <ReciterView
          key={reciter.id}
          locale={locale}
          reciter={reciter}
          rewaya={rewaya}
          current={track?.key ?? null}
          onPlay={setTrack}
          onBack={() => setReciter(null)}
        />
      ) : (
        <section className="card">
          <div className="row" role="tablist">
            {(["reciters", "radios"] as const).map((id) => (
              <button
                key={id}
                type="button"
                role="tab"
                aria-selected={tab === id}
                className={tab === id ? "btn btn-primary" : "btn"}
                onClick={() => setTab(id)}
                data-testid={`library-tab-${id}`}
              >
                {t(locale, `library.${id}`)}
              </button>
            ))}
          </div>
          <label className="field">
            <span>{t(locale, "library.search")}</span>
            <input
              type="search"
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              data-testid="library-search"
            />
          </label>
          {tab === "reciters" ? (
            <>
              <label className="field">
                <span>{t(locale, "library.rewaya")}</span>
                <select
                  value={rewaya ?? ""}
                  onChange={(e) => setRewaya(e.target.value ? Number(e.target.value) : null)}
                  data-testid="library-rewaya"
                >
                  <option value="">{t(locale, "library.allRiwayat")}</option>
                  {lib.riwayat.map((w) => (
                    <option key={w.id} value={w.id}>
                      {w.name}
                    </option>
                  ))}
                </select>
              </label>
              {reciters.length === 0 ? <p className="muted">{t(locale, "library.empty")}</p> : null}
              <ul className="episode-list" data-testid="library-reciters">
                {reciters.map((r) => (
                  <li key={r.id}>
                    <button
                      type="button"
                      className="episode"
                      onClick={() => setReciter(r)}
                      data-testid={`library-reciter-${r.id}`}
                    >
                      <Icon name="headphones" />
                      <span className="tile-text">
                        <strong>{r.name}</strong>
                        <span className="muted small">
                          {r.moshafs
                            .filter((m) => rewaya === null || m.rewayaId === rewaya)
                            .map((m) => m.name)
                            .join(" · ")}
                        </span>
                      </span>
                    </button>
                  </li>
                ))}
              </ul>
            </>
          ) : (
            <>
              {radios.length === 0 ? <p className="muted">{t(locale, "library.empty")}</p> : null}
              <ul className="episode-list" data-testid="library-radios">
                {radios.map((r) => {
                  const key = `radio:${r.id}`;
                  return (
                    <li key={r.id}>
                      <button
                        type="button"
                        className="episode"
                        aria-pressed={track?.key === key}
                        onClick={() => setTrack({ key, url: r.url, live: true, title: r.name })}
                        data-testid={`library-radio-${r.id}`}
                      >
                        <Icon name={track?.key === key ? "pause" : "play"} />
                        <span className="tile-text">
                          <strong>{r.name}</strong>
                          <span className="muted small">{t(locale, "library.live")}</span>
                        </span>
                      </button>
                    </li>
                  );
                })}
              </ul>
            </>
          )}
        </section>
      )}
      {source}
    </>
  );
}
