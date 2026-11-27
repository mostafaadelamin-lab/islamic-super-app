"use client";
import { useEffect, useState, useSyncExternalStore } from "react";
import { t, type Locale } from "@/lib/i18n";
import type { DhikrHadith } from "@/lib/dhikr-extras";
import { registerAudio } from "@/lib/audio-focus";
import { Icon } from "./Icon";
import { LockPlayer } from "./LockPlayer";
import { SaveAudioButton } from "./SaveAudioButton";
import { dhikrSavedStore } from "@/lib/audio-offline";

/** One shared player for dhikr recordings: starting one stops the previous; the end stops (no loop). */
interface PlayerState {
  url: string | null;
  playing: boolean;
  failed: boolean;
  position: number;
  duration: number;
  /** What is playing, shown on the player (none: the item is right above it). */
  title?: string;
  subtitle?: string;
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
  // One sound at a time: a dhikr pauses the Quran recitation (which resumes from its ayah) and vice versa.
  registerAudio(el);
  return el;
}

export const dhikrPlayer = {
  get: (): PlayerState => state,
  subscribe(l: () => void): () => void {
    listeners.add(l);
    return () => listeners.delete(l);
  },
  toggle(url: string, meta: { title?: string; subtitle?: string } = {}): void {
    if (state.url === url && state.playing) return dhikrPlayer.stop();
    const a = audio();
    if (state.url !== url) {
      a.src = url;
      update({ url, position: 0, duration: 0, failed: false, title: meta.title, subtitle: meta.subtitle });
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
    update({ url: null, playing: false, position: 0, duration: 0, title: undefined, subtitle: undefined });
  },
};

const SERVER: PlayerState = { url: null, playing: false, failed: false, position: 0, duration: 0 };
function usePlayer(): PlayerState {
  return useSyncExternalStore(dhikrPlayer.subscribe, dhikrPlayer.get, () => SERVER);
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
      {/* «⬇» keeps this recording for listening without internet (owner 2026-11-27). */}
      <SaveAudioButton locale={locale} store={dhikrSavedStore} url={url} testId={`${testId}-save`} />
      {mine && p.failed ? (
        <span className="muted small" role="status">
          {t(locale, "dhikr.listenFailed")}
        </span>
      ) : null}
      {/* The player sits right under the dhikr being heard (owner 2026-11-22). */}
      <DhikrPlayerBar locale={locale} urls={[url]} />
    </>
  );
}

/**
 * The dhikr recording's player, in the lock-screen look of every player (owner 2026-11-22): shown
 * right under the item playing. [urls]: only for these recordings (the item it sits under).
 */
export function DhikrPlayerBar({ locale, urls }: { locale: Locale; urls?: readonly string[] }) {
  const p = usePlayer();
  const key = urls?.join("|");
  useEffect(
    () => () => {
      const now = dhikrPlayer.get().url;
      if (now && (!key || key.split("|").includes(now))) dhikrPlayer.stop();
    },
    [key],
  );
  if (!p.url || p.failed || (urls && !urls.includes(p.url))) return null;
  return (
    <LockPlayer
      locale={locale}
      id="dhikr-player"
      closeId="dhikr-player-stop"
      title={p.title}
      subtitle={p.subtitle}
      position={p.position}
      duration={p.duration}
      playing={p.playing}
      loading={!p.playing && p.position === 0 && p.duration === 0}
      onToggle={() => (p.playing ? dhikrPlayer.pause() : dhikrPlayer.resume())}
      onSeek={(s) => dhikrPlayer.seek(s)}
      onClose={() => dhikrPlayer.stop()}
    />
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
