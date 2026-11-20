"use client";
import { useCallback, useEffect, useRef, useState } from "react";
import { t, type Locale } from "@/lib/i18n";
import { localizeDigits } from "@/lib/digits";
import { renderQuranText } from "@/lib/quran-render";
import { surahName } from "@/lib/pages";
import { player } from "@/lib/audio-player";
import { KIDS } from "@/lib/kids";
import {
  addStar,
  ayahTokens,
  positionAt,
  quranComWord,
  readStars,
  wordAudioUrl,
  type TeacherAudio,
} from "@/lib/teacher";
import { AyahMarker } from "./AyahMarker";
import { Icon } from "./Icon";

const LABEL: Record<string, string> = {
  Minshawy_Teacher_128kbps: "kids.teacherMinshawy",
  Husary_Muallim_128kbps: "kids.teacherHusary",
};
/** Text sizes in px (kids start one step above the normal Mushaf). */
const SIZE_SMALL = 28;
const SIZE_NORMAL = 34;
const SIZE_BIG = 42;
const SIZE_HUGE = 52;
const SIZES = [SIZE_SMALL, SIZE_NORMAL, SIZE_BIG, SIZE_HUGE] as const;
const REPEATS = 3;
const MS = 1000;
const MAX_STAR_ICONS = 5;

/**
 * «المصحف المعلّم» as a real Mushaf for children (owner 2026-11-20): big Mushaf text, the word being read lights
 * up, a tapped word is said on its own, a tapped ayah number plays that ayah (three times with «كرّر»), and a
 * full listen earns a star. Text = KFGQPC v18 exactly; only colours and spacing are added around it.
 */
export function KidsMushaf({
  locale,
  surah,
  ayahs,
  basmala,
  word,
  audio,
}: {
  locale: Locale;
  surah: number;
  ayahs: string[];
  basmala?: string;
  word: string;
  audio: Record<string, TeacherAudio>;
}) {
  const [reciter, setReciter] = useState(KIDS.teacher.reciters[0] ?? Object.keys(audio)[0]!);
  const [size, setSize] = useState(1);
  const [playing, setPlaying] = useState(false);
  const [pos, setPos] = useState<{ ayah: number; word: number | null } | null>(null);
  const [tapped, setTapped] = useState<string | null>(null);
  const [repeat, setRepeat] = useState(false);
  const [stars, setStars] = useState(0);
  const [cheer, setCheer] = useState(false);
  const rec = useRef<HTMLAudioElement | null>(null);
  const wordEl = useRef<HTMLAudioElement | null>(null);
  // one ayah only: [ayah index, plays left]
  const only = useRef<[number, number] | null>(null);
  const raf = useRef(0);
  const data = audio[reciter]!;
  const n = (v: number) => localizeDigits(v, locale);

  useEffect(() => setStars(readStars()[String(surah)] ?? 0), [surah]);

  const tick = useCallback(() => {
    const el = rec.current;
    if (!el) return;
    const ms = el.currentTime * MS;
    const o = only.current;
    if (o) {
      const [lo, hi] = data.ayahs[o[0]]!;
      if (ms >= hi) {
        if (o[1] > 1) {
          only.current = [o[0], o[1] - 1];
          el.currentTime = lo / MS;
        } else {
          only.current = null;
          el.pause();
          setPos(null);
          return;
        }
      }
    }
    setPos(positionAt(data, ms));
    raf.current = requestAnimationFrame(tick);
  }, [data]);

  useEffect(() => {
    const el = new Audio();
    el.preload = "none";
    rec.current = el;
    const onPlay = () => setPlaying(true);
    const onPause = () => setPlaying(false);
    el.addEventListener("play", onPlay);
    el.addEventListener("pause", onPause);
    return () => {
      el.pause();
      el.removeEventListener("play", onPlay);
      el.removeEventListener("pause", onPause);
      cancelAnimationFrame(raf.current);
      rec.current = null;
    };
  }, []);

  useEffect(() => {
    const el = rec.current;
    if (!el) return;
    const onEnded = () => {
      setPlaying(false);
      setPos(null);
      if (!only.current) {
        setStars(addStar(surah));
        setCheer(true);
      }
      only.current = null;
    };
    el.addEventListener("ended", onEnded);
    return () => el.removeEventListener("ended", onEnded);
  }, [surah]);

  useEffect(() => {
    if (playing) raf.current = requestAnimationFrame(tick);
    return () => cancelAnimationFrame(raf.current);
  }, [playing, tick]);

  const start = (fromAyah: number, onlyThis: boolean) => {
    const el = rec.current;
    if (!el) return;
    player.stop();
    wordEl.current?.pause();
    setTapped(null);
    setCheer(false);
    if (!el.src.endsWith(data.url)) el.src = data.url;
    only.current = onlyThis ? [fromAyah, repeat ? REPEATS : 1] : null;
    const seek = () => {
      el.currentTime = data.ayahs[fromAyah]![0] / MS;
      void el.play();
    };
    if (el.readyState >= 1) seek();
    else {
      el.addEventListener("loadedmetadata", seek, { once: true });
      el.load();
    }
  };

  const toggle = () => {
    const el = rec.current;
    if (!el) return;
    if (playing) el.pause();
    else if (pos && el.currentTime > 0) void el.play();
    else start(0, false);
  };

  const step = (d: 1 | -1) => {
    const cur = pos?.ayah ?? -1;
    const next = Math.min(Math.max(cur + d, 0), ayahs.length - 1);
    start(next, false);
  };

  const sayWord = (a: number, k: number, words: string[]) => {
    const w = quranComWord(words, k);
    if (w === null) return;
    rec.current?.pause();
    only.current = null;
    setPos(null);
    const el = wordEl.current ?? new Audio();
    wordEl.current = el;
    el.src = wordAudioUrl(word, surah, a + 1, w);
    setTapped(`${a}:${k}`);
    el.onended = () => setTapped(null);
    const go = async () => {
      try {
        await el.play();
      } catch {
        setTapped(null);
      }
    };
    void go();
  };

  const pickReciter = (r: string) => {
    rec.current?.pause();
    only.current = null;
    setPos(null);
    setReciter(r);
  };

  return (
    <div className="kids-mushaf" data-testid="kids-mushaf">
      <div className="kids-mushaf-tools">
        <div className="row" role="group" style={{ flexWrap: "wrap", gap: "0.5rem" }}>
          {KIDS.teacher.reciters.map((r) => (
            <button
              key={r}
              type="button"
              className={`btn btn-sm${r === reciter ? " btn-primary" : ""}`}
              aria-pressed={r === reciter}
              data-testid={`kids-mushaf-reciter-${r}`}
              onClick={() => pickReciter(r)}
            >
              {t(locale, LABEL[r] ?? r)}
            </button>
          ))}
        </div>
        <div className="row" role="group" style={{ gap: "0.4rem" }}>
          <button
            type="button"
            className="btn btn-sm kids-round"
            aria-label={t(locale, "kids.teacherSmaller")}
            disabled={size === 0}
            onClick={() => setSize((v) => Math.max(0, v - 1))}
          >
            أ-
          </button>
          <button
            type="button"
            className="btn btn-sm kids-round"
            aria-label={t(locale, "kids.teacherBigger")}
            disabled={size === SIZES.length - 1}
            data-testid="kids-mushaf-bigger"
            onClick={() => setSize((v) => Math.min(SIZES.length - 1, v + 1))}
          >
            أ+
          </button>
        </div>
      </div>
      <p className="muted small kids-mushaf-hint">{t(locale, "kids.teacherHint")}</p>

      <div className="mushaf-frame kids-page" style={{ ["--k-size" as string]: `${SIZES[size]}px` }}>
        <div className="kids-surah-band">{t(locale, "kids.teacherSurah", { name: surahName(surah, "ar") })}</div>
        {basmala ? (
          <p className="quran kids-basmala" lang="ar" dir="rtl">
            {renderQuranText(basmala)}
          </p>
        ) : null}
        <p className="quran kids-text" lang="ar" dir="rtl" data-testid="kids-mushaf-text">
          {ayahs.map((text, a) => {
            const { words, gaps } = ayahTokens(text);
            const on = pos?.ayah === a;
            return (
              <span key={a} className="k-ayah" data-on={on ? "true" : undefined} data-ayah={a + 1}>
                {words.map((w, k) => (
                  <span key={k}>
                    <button
                      type="button"
                      className="k-word"
                      data-on={(on && pos?.word === k) || tapped === `${a}:${k}` ? "true" : undefined}
                      data-testid={`kids-word-${a + 1}-${k + 1}`}
                      onClick={() => sayWord(a, k, words)}
                    >
                      {renderQuranText(w)}
                    </button>
                    {gaps[k] ?? ""}
                  </span>
                ))}
                <button
                  type="button"
                  className="k-num"
                  aria-label={t(locale, "kids.teacherAyah", { n: n(a + 1) })}
                  data-testid={`kids-ayah-${a + 1}`}
                  onClick={() => start(a, true)}
                >
                  <AyahMarker n={a + 1} locale="ar" />
                </button>{" "}
              </span>
            );
          })}
        </p>
      </div>

      {cheer ? (
        <p className="kids-cheer" role="status" data-testid="kids-mushaf-cheer">
          ⭐ {t(locale, "kids.teacherWell")}
        </p>
      ) : null}
      <p className="kids-stars" data-testid="kids-mushaf-stars">
        {"⭐".repeat(Math.min(stars, MAX_STAR_ICONS))} {t(locale, "kids.teacherStars", { n: n(stars) })}
      </p>

      <div className="kids-bar" role="group">
        <button
          type="button"
          className="btn kids-round"
          aria-label={t(locale, "kids.teacherPrev")}
          onClick={() => step(-1)}
        >
          <Icon name="prev" />
        </button>
        <button
          type="button"
          className="btn btn-primary kids-play"
          data-testid="kids-mushaf-play"
          onClick={toggle}
        >
          <Icon name={playing ? "pause" : "play"} />{" "}
          {t(locale, playing ? "kids.teacherPause" : "kids.teacherPlay")}
        </button>
        <button
          type="button"
          className="btn kids-round"
          aria-label={t(locale, "kids.teacherNext")}
          onClick={() => step(1)}
        >
          <Icon name="next" />
        </button>
        <button
          type="button"
          className={`btn btn-sm${repeat ? " btn-primary" : ""}`}
          aria-pressed={repeat}
          data-testid="kids-mushaf-repeat"
          onClick={() => setRepeat((v) => !v)}
        >
          <Icon name="repeat" /> {t(locale, "kids.teacherRepeat")}
        </button>
      </div>
    </div>
  );
}
