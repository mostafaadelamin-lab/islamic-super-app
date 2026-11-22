"use client";
import { useState, type CSSProperties, type ReactNode } from "react";
import { t, type Locale } from "@/lib/i18n";
import { localizeDigits } from "@/lib/digits";
import { Icon } from "./Icon";
import { PlayerClose } from "./PlayerClose";
import { SleepTimer } from "./SleepTimer";

const SEC_PER_MIN = 60;
const SEC_PER_HOUR = 3600;
const PAD = 2;
const PERCENT = 100;
/** Seconds the back / forward buttons jump. */
const SKIP_SEC = 30;

const two = (n: number): string => String(n).padStart(PAD, "0");

/** "1:05" / "1:02:07" in the page's digits. */
export function playerClock(sec: number, locale: Locale): string {
  const v = Math.max(0, Math.floor(Number.isFinite(sec) ? sec : 0));
  const h = Math.floor(v / SEC_PER_HOUR);
  const m = Math.floor((v % SEC_PER_HOUR) / SEC_PER_MIN);
  const s = two(v % SEC_PER_MIN);
  return localizeDigits(h > 0 ? `${h}:${two(m)}:${s}` : `${m}:${s}`, locale);
}

/** Circular arrow with "30" inside: back (counter-clockwise) or forward 30 seconds. */
function Skip30({ forward }: { forward: boolean }) {
  return (
    <svg
      className="icon"
      width={26}
      height={26}
      viewBox="0 0 24 24"
      aria-hidden="true"
      focusable="false"
      style={forward ? undefined : { transform: "scaleX(-1)" }}
    >
      <path
        d="M12 4a8 8 0 1 1-7.4 5M12 4V1m0 3 3-2.5"
        fill="none"
        stroke="currentColor"
        strokeWidth={1.8}
        strokeLinecap="round"
        strokeLinejoin="round"
        transform="matrix(-1 0 0 1 24 0)"
      />
      <text
        x="12"
        y="15.5"
        textAnchor="middle"
        fontSize="7.5"
        fontWeight="700"
        fill="currentColor"
        style={forward ? undefined : { transform: "scaleX(-1)", transformOrigin: "12px 12px" }}
      >
        30
      </text>
    </svg>
  );
}

export interface LockPlayerProps {
  locale: Locale;
  /** Prefix of the test ids: `${id}-toggle`, `-seek`, `-close`, `-prev`, `-next`, `-back`, `-fwd`. */
  id: string;
  /** Override the ✕ / whole player / error test ids (kept from the older players). */
  closeId?: string;
  groupId?: string;
  errorId?: string;
  title?: string;
  subtitle?: string;
  position: number;
  /** Seconds; 0 while not known. */
  duration: number;
  playing: boolean;
  loading?: boolean;
  error?: string | null;
  live?: boolean;
  onToggle: () => void;
  onSeek?: (sec: number) => void;
  /** Show previous / next (disabled when null). */
  skip?: boolean;
  onPrev?: (() => void) | null;
  onNext?: (() => void) | null;
  onClose: () => void;
  sleep?: boolean;
  /** Floating bar at the bottom (only where the item is not listed on the page). */
  docked?: boolean;
  /** Extra row under the controls (links). */
  extra?: ReactNode;
}

/**
 * The one look of every audio player (owner 2026-11-22: like the lock-screen player, shown right
 * where the item is played): what is playing, a seek bar with the time gone and the full length,
 * and big controls: previous, back 30 s, play/pause, forward 30 s, next; ✕ closes it.
 */
export function LockPlayer(p: LockPlayerProps) {
  const { locale, id } = p;
  const [drag, setDrag] = useState<number | null>(null);
  const seekable = !p.live && !!p.onSeek && p.duration > 0;
  const shown = drag ?? p.position;
  const jump = (d: number): void => {
    if (!p.onSeek) return;
    const max = p.duration > 0 ? p.duration : Infinity;
    p.onSeek(Math.min(max, Math.max(0, p.position + d)));
  };
  const subtitle = p.loading && !p.playing ? t(locale, "audio.loading") : p.subtitle;
  const fill = p.duration > 0 ? Math.min(PERCENT, (shown / p.duration) * PERCENT) : 0;
  const prevIcon = locale === "ar" ? "next" : "prev";
  const nextIcon = locale === "ar" ? "prev" : "next";
  let body: ReactNode;
  if (p.error) {
    body = (
      <p className="alert alert-error" role="alert" data-testid={p.errorId ?? `${id}-error`}>
        {p.error}
      </p>
    );
  } else if (p.live) {
    body = (
      <p className="lp-live small">
        <span className="lp-dot" aria-hidden="true" /> {t(locale, "library.live")}
      </p>
    );
  } else {
    body = (
      <div className="lp-progress">
        <input
          type="range"
          min={0}
          step={1}
          max={Math.max(1, Math.round(p.duration))}
          value={Math.round(Math.min(shown, p.duration || shown))}
          disabled={!seekable}
          aria-label={t(locale, "dhikr.seek")}
          aria-valuetext={`${playerClock(shown, locale)} / ${playerClock(p.duration, locale)}`}
          data-testid={`${id}-seek`}
          style={{ "--lp-fill": `${fill}%` } as CSSProperties}
          onChange={(e) => {
            const v = Number(e.target.value);
            setDrag(v);
            p.onSeek?.(v);
          }}
          onPointerUp={() => setDrag(null)}
          onBlur={() => setDrag(null)}
        />
        <div className="lp-times small">
          <span data-testid={`${id}-elapsed`}>{playerClock(shown, locale)}</span>
          <span data-testid={`${id}-total`}>
            {p.duration > 0 ? playerClock(p.duration, locale) : "--:--"}
          </span>
        </div>
      </div>
    );
  }
  return (
    <div
      className={p.docked ? "lock-player docked" : "lock-player"}
      role="group"
      aria-label={t(locale, "audio.player")}
      data-testid={p.groupId ?? id}
    >
      <div className="lp-head">
        <span className="lp-art" aria-hidden="true">
          <Icon name="headphones" size={22} />
        </span>
        <span className="lp-titles">
          <strong className="lp-title">{p.title ?? t(locale, "audio.player")}</strong>
          {subtitle ? <span className="lp-sub">{subtitle}</span> : null}
        </span>
        <PlayerClose
          locale={locale}
          testId={p.closeId ?? `${id}-close`}
          className="btn-sm"
          onClose={p.onClose}
        />
      </div>
      {body}
      <div className="lp-controls">
        {p.skip ? (
          <button
            type="button"
            className="btn btn-icon lp-btn"
            aria-label={t(locale, "nasheeds.prev")}
            data-testid={`${id}-prev`}
            disabled={!p.onPrev}
            onClick={() => p.onPrev?.()}
          >
            <Icon name={prevIcon} size={22} />
          </button>
        ) : null}
        {seekable ? (
          <button
            type="button"
            className="btn btn-icon lp-btn"
            aria-label={t(locale, "stories.rewind")}
            title={t(locale, "stories.rewind")}
            data-testid={`${id}-back`}
            onClick={() => jump(-SKIP_SEC)}
          >
            <Skip30 forward={false} />
          </button>
        ) : null}
        <button
          type="button"
          className="btn btn-primary lp-play"
          aria-label={p.playing ? t(locale, "audio.pause") : t(locale, "audio.play")}
          data-testid={`${id}-toggle`}
          onClick={p.onToggle}
        >
          {p.loading && !p.playing ? (
            <span className="lp-spin" aria-hidden="true" />
          ) : (
            <Icon name={p.playing ? "pause" : "play"} size={28} />
          )}
        </button>
        {seekable ? (
          <button
            type="button"
            className="btn btn-icon lp-btn"
            aria-label={t(locale, "stories.forward")}
            title={t(locale, "stories.forward")}
            data-testid={`${id}-fwd`}
            onClick={() => jump(SKIP_SEC)}
          >
            <Skip30 forward />
          </button>
        ) : null}
        {p.skip ? (
          <button
            type="button"
            className="btn btn-icon lp-btn"
            aria-label={t(locale, "nasheeds.next")}
            data-testid={`${id}-next`}
            disabled={!p.onNext}
            onClick={() => p.onNext?.()}
          >
            <Icon name={nextIcon} size={22} />
          </button>
        ) : null}
      </div>
      {p.sleep || p.extra ? (
        <div className="lp-extra">
          {p.sleep ? <SleepTimer locale={locale} /> : null}
          {p.extra}
        </div>
      ) : null}
    </div>
  );
}
