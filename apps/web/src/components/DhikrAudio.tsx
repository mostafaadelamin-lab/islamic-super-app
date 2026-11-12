"use client";
import { useEffect, useState, useSyncExternalStore } from "react";
import { t, type Locale } from "@/lib/i18n";
import { localizeDigits } from "@/lib/digits";
import type { DhikrHadith } from "@/lib/dhikr-extras";
import { Icon } from "./Icon";

/** One shared player for dhikr recordings: starting one stops the previous; the end stops (no loop). */
interface PlayerState {
  url: string | null;
  playing: boolean;
  failed: boolean;
  position: number;
  duration: number;
}

let state: PlayerState = { url: null, playing: false, failed: false, position: 0, duration: 0 };
const listeners = new Set<() => void>();
let el: HTMLAudioElement | null = null;

function update(patch: Partial<PlayerState>): void {
  state = { ...state, ...patch };
  listeners.forEach((l) => l());
}

function audio(): HTMLAudioElement {
  if (el) return el;
  el = new Audio();
  el.preload = "auto";
  el.addEventListener("playing", () => update({ playing: true, failed: false }));
  el.addEventListener("pause", () => update({ playing: false }));
  el.addEventListener("timeupdate", () => update({ position: el!.currentTime }));
  el.addEventListener("durationchange", () =>
    update({ duration: Number.isFinite(el!.duration) ? el!.duration : 0 }),
  );
  el.addEventListener("ended", () => dhikrPlayer.stop());
  el.addEventListener("error", () => {
    if (state.url) update({ failed: true, playing: false });
  });
  return el;
}

export const dhikrPlayer = {
  get: (): PlayerState => state,
  subscribe(l: () => void): () => void {
    listeners.add(l);
    return () => listeners.delete(l);
  },
  toggle(url: string): void {
    if (state.url === url && state.playing) return dhikrPlayer.stop();
    const a = audio();
    if (state.url !== url) {
      a.src = url;
      update({ url, position: 0, duration: 0, failed: false });
    }
    a.play().catch(() => update({ failed: true, playing: false }));
  },
  pause(): void {
    el?.pause();
  },
  resume(): void {
    el?.play().catch(() => update({ failed: true, playing: false }));
  },
  seek(s: number): void {
    if (el) el.currentTime = s;
  },
  stop(): void {
    if (el) {
      el.pause();
      el.removeAttribute("src");
      el.load();
    }
    update({ url: null, playing: false, position: 0, duration: 0 });
  },
};

const SERVER: PlayerState = { url: null, playing: false, failed: false, position: 0, duration: 0 };
function usePlayer(): PlayerState {
  return useSyncExternalStore(dhikrPlayer.subscribe, dhikrPlayer.get, () => SERVER);
}

function clock(s: number, locale: Locale): string {
  const n = Math.max(0, Math.floor(s));
  return localizeDigits(`${Math.floor(n / 60)}:${String(n % 60).padStart(2, "0")}`, locale);
}

/** "Listen" under a dhikr. Stops its own recording when it leaves the page (another card, another page). */
export function DhikrListen({ locale, url, testId }: { locale: Locale; url: string; testId: string }) {
  const p = usePlayer();
  const mine = p.url === url;
  useEffect(
    () => () => {
      if (dhikrPlayer.get().url === url) dhikrPlayer.stop();
    },
    [url],
  );
  return (
    <>
      <button
        type="button"
        className="btn btn-sm"
        aria-pressed={mine && p.playing}
        onClick={() => dhikrPlayer.toggle(url)}
        data-testid={`${testId}-listen`}
      >
        <Icon name={mine && p.playing ? "stop" : "play"} size={16} />{" "}
        {mine && p.playing ? t(locale, "dhikr.stop") : t(locale, "dhikr.listen")}
      </button>
      {mine && p.failed ? (
        <span className="muted small" role="status">
          {t(locale, "dhikr.listenFailed")}
        </span>
      ) : null}
    </>
  );
}

/** Play/pause bar shown at the bottom while a dhikr recording is loaded. */
export function DhikrPlayerBar({ locale }: { locale: Locale }) {
  const p = usePlayer();
  useEffect(() => () => dhikrPlayer.stop(), []);
  if (!p.url || p.failed) return null;
  return (
    <div
      className="dhikr-player"
      role="region"
      aria-label={t(locale, "dhikr.player")}
      data-testid="dhikr-player"
    >
      <button
        type="button"
        className="btn btn-primary btn-sm"
        onClick={() => (p.playing ? dhikrPlayer.pause() : dhikrPlayer.resume())}
        data-testid="dhikr-player-toggle"
        aria-label={p.playing ? t(locale, "dhikr.pause") : t(locale, "dhikr.play")}
      >
        <Icon name={p.playing ? "pause" : "play"} size={18} />
      </button>
      <span className="small">{clock(p.position, locale)}</span>
      <input
        type="range"
        min={0}
        max={Math.max(1, Math.round(p.duration))}
        value={Math.round(p.position)}
        onChange={(e) => dhikrPlayer.seek(Number(e.target.value))}
        aria-label={t(locale, "dhikr.seek")}
        data-testid="dhikr-player-seek"
      />
      <span className="small">{clock(p.duration, locale)}</span>
      <button
        type="button"
        className="btn btn-sm"
        onClick={() => dhikrPlayer.stop()}
        data-testid="dhikr-player-stop"
        aria-label={t(locale, "dhikr.stop")}
      >
        <Icon name="stop" size={18} />
      </button>
    </div>
  );
}

/** "The hadith" under a dhikr: opens the hadith it comes from, its virtue and where it is reported. */
export function DhikrHadithButton({
  locale,
  hadith,
  testId,
}: {
  locale: Locale;
  hadith: DhikrHadith;
  testId: string;
}) {
  const [open, setOpen] = useState(false);
  const part = (title: string, text: string | undefined): React.JSX.Element | null =>
    text ? (
      <>
        <h3 className="small">{title}</h3>
        <p lang="ar" dir="rtl">
          {text}
        </p>
      </>
    ) : null;
  return (
    <>
      <button
        type="button"
        className="btn btn-sm"
        aria-expanded={open}
        onClick={() => setOpen((o) => !o)}
        data-testid={`${testId}-hadith`}
      >
        <Icon name="book" size={16} /> {t(locale, "dhikr.hadith")}
      </button>
      {open ? (
        <section className="dhikr-hadith" data-testid={`${testId}-hadith-text`}>
          {part(t(locale, "dhikr.hadithText"), hadith.hadith)}
          {part(t(locale, "dhikr.hadithFadl"), hadith.fadl)}
          {part(t(locale, "dhikr.hadithSource"), hadith.source)}
        </section>
      ) : null}
    </>
  );
}
