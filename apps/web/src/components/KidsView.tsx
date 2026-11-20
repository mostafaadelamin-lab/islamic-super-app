"use client";
import Link from "next/link";
import { useEffect, useState } from "react";
import { t, type Locale } from "@/lib/i18n";
import { href } from "@/lib/locale-path";
import { localizeDigits } from "@/lib/digits";
import { surahName } from "@/lib/pages";
import { KIDS, type KidsEpisode, type KidsSeries } from "@/lib/kids";
import { readStars } from "@/lib/teacher";
import { Icon, type IconName } from "./Icon";

const SECONDS_PER_MINUTE = 60;
const BYTES_PER_MB = 1e6;
const VIDEO_RADIUS_PX = 8;

/** One episode: watch (video in place), listen (sound only) or save the file. */
function EpisodeRow({
  ep,
  locale,
  open,
  setOpen,
}: {
  ep: KidsEpisode;
  locale: Locale;
  open: string | null;
  setOpen: (v: string | null) => void;
}) {
  const n = (v: number): string => localizeDigits(v, locale);
  const watching = open === `v:${ep.id}`;
  const listening = open === `a:${ep.id}`;
  const meta = [
    ep.seconds
      ? t(locale, "kids.minutes", { n: n(Math.max(1, Math.round(ep.seconds / SECONDS_PER_MINUTE))) })
      : null,
    ep.bytes ? t(locale, "kids.size", { n: n(Math.max(1, Math.round(ep.bytes / BYTES_PER_MB))) }) : null,
  ].filter(Boolean);
  return (
    <li className="card kids-episode" data-testid={`kids-ep-${ep.id}`}>
      <div className="row" style={{ flexWrap: "wrap", gap: "0.5rem" }}>
        <div style={{ flex: 1, minWidth: "12rem" }}>
          <strong>{ep.title}</strong>
          {meta.length ? <div className="muted small">{meta.join(" · ")}</div> : null}
        </div>
        <button
          type="button"
          className={`btn btn-sm${watching ? " btn-primary" : ""}`}
          aria-pressed={watching}
          onClick={() => setOpen(watching ? null : `v:${ep.id}`)}
        >
          <Icon name="video" /> {t(locale, "kids.watch")}
        </button>
        <button
          type="button"
          className={`btn btn-sm${listening ? " btn-primary" : ""}`}
          aria-pressed={listening}
          onClick={() => setOpen(listening ? null : `a:${ep.id}`)}
        >
          <Icon name="headphones" /> {t(locale, "kids.listen")}
        </button>
        <a className="btn btn-sm" href={ep.url} download target="_blank" rel="noopener noreferrer">
          <Icon name="download" /> {t(locale, "kids.download")}
        </a>
      </div>
      {watching ? (
        <video
          controls
          autoPlay
          playsInline
          preload="metadata"
          src={ep.url}
          style={{ width: "100%", marginTop: "0.5rem", borderRadius: VIDEO_RADIUS_PX, background: "#000" }}
        />
      ) : null}
      {listening ? <audio controls autoPlay preload="none" src={ep.url} style={{ width: "100%" }} /> : null}
    </li>
  );
}

function SeriesBlock({
  series,
  locale,
  title,
  sub,
  open,
  setOpen,
}: {
  series: KidsSeries | undefined;
  locale: Locale;
  title: string;
  sub: string;
  open: string | null;
  setOpen: (v: string | null) => void;
}) {
  if (!series) return null;
  return (
    <>
      <h3 className="section-title">{title}</h3>
      <p className="muted small">{sub}</p>
      <ul
        className="kids-episodes"
        style={{ listStyle: "none", padding: 0 }}
        data-testid={`kids-series-${series.id}`}
      >
        {series.episodes.map((ep) => (
          <EpisodeRow key={ep.id} ep={ep} locale={locale} open={open} setOpen={setOpen} />
        ))}
      </ul>
    </>
  );
}

/** «المصحف المعلّم»: each surah opens the interactive kids' Mushaf (owner 2026-11-20), with the stars earned so far. */
function Teacher({ locale }: { locale: Locale }) {
  const [stars, setStars] = useState<Record<string, number>>({});
  useEffect(() => setStars(readStars()), []);
  const n = (v: number): string => localizeDigits(v, locale);
  return (
    <>
      <p className="muted">{t(locale, "kids.teacherNote")}</p>
      <ul className="tiles tiles-sm" data-testid="kids-teacher-surahs">
        {KIDS.teacher.surahs.map((s) => (
          <li key={s}>
            <Link
              className="tile tile-sm"
              href={href(locale, `kids/teacher/${s}`)}
              data-testid={`kids-teacher-surah-${s}`}
              style={{ width: "100%" }}
            >
              <span className="tile-icon">{n(s)}</span>
              <span className="tile-text">
                <strong>{surahName(s, locale)}</strong>
                {stars[String(s)] ? <span className="muted small">⭐ {n(stars[String(s)] ?? 0)}</span> : null}
              </span>
              <Icon name="quran" />
            </Link>
          </li>
        ))}
      </ul>
    </>
  );
}

const SECTIONS: readonly [string, IconName][] = [
  ["prophets", "book"],
  ["teacher", "quran"],
  ["stories", "kids"],
];

/** «قسم الأطفال» (owner 2026-11-20): prophets' stories, the teaching Mushaf, stories, and the kids' ruqyah. */
export function KidsView({ locale }: { locale: Locale }) {
  const [tab, setTab] = useState("prophets");
  const [open, setOpen] = useState<string | null>(null);
  const pick = (id: string) => {
    setTab(id);
    setOpen(null);
    if (window.location.hash !== `#${id}`) window.history.replaceState(null, "", `#${id}`);
  };
  // The site menu links to kids#prophets / #teacher / #stories (owner 2026-11-20: Kids is its own section).
  useEffect(() => {
    const fromHash = () => {
      const id = window.location.hash.slice(1);
      if (SECTIONS.some(([s]) => s === id)) {
        setTab(id);
        setOpen(null);
      }
    };
    fromHash();
    window.addEventListener("hashchange", fromHash);
    return () => window.removeEventListener("hashchange", fromHash);
  }, []);
  return (
    <div data-testid="kids">
      <p className="muted">{t(locale, "kids.note")}</p>
      <ul className="tiles tiles-sm">
        {SECTIONS.map(([id, icon]) => (
          <li key={id}>
            <button
              type="button"
              className="tile tile-sm"
              aria-pressed={tab === id}
              data-testid={`kids-tab-${id}`}
              onClick={() => pick(id)}
              style={{ width: "100%" }}
            >
              <span className="tile-icon">
                <Icon name={icon} />
              </span>
              <span className="tile-text">
                <strong>{t(locale, `kids.${id}`)}</strong>
                <span className="muted small">{t(locale, `kids.${id}Sub`)}</span>
              </span>
            </button>
          </li>
        ))}
        <li>
          <Link className="tile tile-sm" href={href(locale, "kids/ruqyah")} data-testid="kids-tab-ruqyah">
            <span className="tile-icon">
              <Icon name="shield" />
            </span>
            <span className="tile-text">
              <strong>{t(locale, "ruqyah.kidsTitle")}</strong>
              <span className="muted small">{t(locale, "kids.ruqyahSub")}</span>
            </span>
          </Link>
        </li>
      </ul>
      <section className="kids-section">
        {tab === "prophets" ? (
          <>
            <p className="muted small">{t(locale, "kids.offlineNote")}</p>
            <SeriesBlock
              series={KIDS.series.find((s) => s.id === "kids-prophets")}
              locale={locale}
              title={t(locale, "kids.prophets")}
              sub={t(locale, "kids.prophetsSub")}
              open={open}
              setOpen={setOpen}
            />
          </>
        ) : null}
        {tab === "teacher" ? (
          <>
            <h3 className="section-title">{t(locale, "kids.teacher")}</h3>
            <Teacher locale={locale} />
          </>
        ) : null}
        {tab === "stories" ? (
          <>
            <p className="muted small">{t(locale, "kids.offlineNote")}</p>
            {KIDS.series
              .filter((s) => s.group === "stories")
              .map((s) => {
                const key = s.id.replace("kids-", "");
                return (
                  <SeriesBlock
                    key={s.id}
                    series={s}
                    locale={locale}
                    title={t(locale, `kids.${key}`)}
                    sub={t(locale, `kids.${key}Sub`)}
                    open={open}
                    setOpen={setOpen}
                  />
                );
              })}
          </>
        ) : null}
      </section>
    </div>
  );
}
