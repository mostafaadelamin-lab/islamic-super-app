"use client";
import { useSyncExternalStore } from "react";
import { t, type Locale } from "@/lib/i18n";
import { localizeDigits } from "@/lib/digits";
import { surahName } from "@/lib/pages";
import { audioStore, RECITERS, REPEAT_CHOICES, SPEED_CHOICES } from "@/lib/audio";
import { player } from "@/lib/audio-player";
import { useStore } from "@/hooks/useStore";
import { Icon } from "./Icon";
import { ReaderIcon } from "./ReaderIcon";

const ERROR_KEYS = { offline: "audio.errOffline", network: "audio.errNetwork", blocked: "audio.errBlocked" };

/**
 * The Mushaf reader's floating recitation card: reciter (drop-down), previous / play-pause / next,
 * repeat count and the "Listen with tafsir" switch. While nothing is queued, play starts the current page.
 */
export function ReaderPlayer({ locale, page }: { locale: Locale; page: number }) {
  const ps = useSyncExternalStore(player.subscribe, player.get, player.getServer);
  const prefs = useStore(audioStore);
  const active = ps.status !== "idle";
  const playing = ps.status === "playing" || ps.status === "loading";
  const reciter = RECITERS.find((r) => r.folder === prefs.reciter) ?? RECITERS[0]!;
  const reciterName = locale === "ar" ? reciter.ar : reciter.en;
  const item = active ? ps.queue[ps.cursor.index] : undefined;
  const surah = item ? surahName(item.s, locale) : "";
  let now = t(locale, "reader.pageNow", { page: localizeDigits(page, locale) });
  if (item?.kind === "basmala") now = t(locale, "audio.basmala", { surah });
  if (item?.kind === "ayah")
    now = t(locale, "quran.ayahRef", { surah, ayah: localizeDigits(item.a, locale) });
  const prevIcon = locale === "ar" ? "next" : "prev";
  const nextIcon = locale === "ar" ? "prev" : "next";

  return (
    <section className="rd-player" aria-label={t(locale, "audio.player")} data-testid="reader-player">
      <div className="rdp-top">
        <span className="rdp-avatar" aria-hidden="true">
          <ReaderIcon name="reciter" size={22} />
        </span>
        <label className="rdp-reciter">
          <span className="sr-only">{t(locale, "audio.reciter")}</span>
          <select
            value={prefs.reciter}
            data-testid="player-reciter"
            onChange={(e) => {
              const folder = e.target.value;
              audioStore.set((p) => ({ ...p, reciter: folder }));
              player.reciterChanged();
            }}
          >
            {RECITERS.map((r) => (
              <option key={r.folder} value={r.folder}>
                {locale === "ar" ? r.ar : r.en}
              </option>
            ))}
          </select>
          <span className="rdp-reciter-name" aria-hidden="true">
            {reciterName}
          </span>
          <span className="rdp-chevron" aria-hidden="true">
            <ReaderIcon name="chevronDown" size={16} />
          </span>
        </label>
        <span className="rdp-now" data-testid="player-now" aria-live="polite">
          {now}
        </span>
      </div>
      <div className="rdp-row">
        <label
          className="rdp-btn rdp-tafsir"
          title={t(locale, "reader.listenWithTafsir")}
          data-on={prefs.tafsir ? "true" : "false"}
        >
          <input
            type="checkbox"
            className="rdp-hit"
            checked={prefs.tafsir}
            data-testid="player-tafsir"
            onChange={(e) => {
              const tafsir = e.target.checked;
              audioStore.set((p) => ({ ...p, tafsir }));
              // "Listen with tafsir" also starts listening when nothing is playing yet.
              if (tafsir && !active) player.play({ kind: "pageOn", page });
            }}
          />
          <ReaderIcon name="split" size={20} />
          <span className="rdp-btn-label">{t(locale, "reader.listenWithTafsir")}</span>
        </label>
        <button
          type="button"
          className="rdp-btn"
          aria-label={t(locale, "audio.prev")}
          data-testid="player-prev"
          disabled={!active}
          onClick={() => player.step(-1)}
        >
          <Icon name={prevIcon} />
        </button>
        {active ? (
          <button
            type="button"
            className="rdp-play"
            aria-label={playing ? t(locale, "audio.pause") : t(locale, "audio.play")}
            data-testid="player-toggle"
            data-state={ps.status}
            onClick={() => player.toggle()}
          >
            <Icon name={playing ? "pause" : "play"} size={26} />
          </button>
        ) : (
          <button
            type="button"
            className="rdp-play"
            aria-label={t(locale, "audio.playPage")}
            data-testid="play-page"
            onClick={() => player.play({ kind: "pageOn", page })}
          >
            <Icon name="play" size={26} />
          </button>
        )}
        <button
          type="button"
          className="rdp-btn"
          aria-label={t(locale, "audio.next")}
          data-testid="player-next"
          disabled={!active}
          onClick={() => player.step(1)}
        >
          <Icon name={nextIcon} />
        </button>
        <label className="rdp-btn rdp-repeat" title={t(locale, "audio.repeat")} data-on={prefs.repeat > 1}>
          <span className="sr-only">{t(locale, "audio.repeat")}</span>
          <ReaderIcon name="repeat" size={20} />
          {prefs.repeat > 1 ? (
            <span className="rdp-badge" aria-hidden="true">
              {localizeDigits(prefs.repeat, locale)}
            </span>
          ) : null}
          <select
            value={prefs.repeat}
            data-testid="player-repeat"
            onChange={(e) => audioStore.set((p) => ({ ...p, repeat: Number(e.target.value) }))}
          >
            {REPEAT_CHOICES.map((n) => (
              <option key={n} value={n}>
                {t(locale, "audio.times", { n: localizeDigits(n, locale) })}
              </option>
            ))}
          </select>
        </label>
        <label className="rdp-btn rdp-speed" title={t(locale, "audio.speed")} data-on={prefs.speed !== 1}>
          <span className="sr-only">{t(locale, "audio.speed")}</span>
          <span aria-hidden="true">{localizeDigits(`${prefs.speed}×`, locale)}</span>
          <select
            value={prefs.speed}
            data-testid="player-speed"
            onChange={(e) => audioStore.set((p) => ({ ...p, speed: Number(e.target.value) }))}
          >
            {SPEED_CHOICES.map((n) => (
              <option key={n} value={n}>
                {localizeDigits(`${n}×`, locale)}
              </option>
            ))}
          </select>
        </label>
        {active ? (
          <button
            type="button"
            className="rdp-btn rdp-stop"
            aria-label={t(locale, "audio.stop")}
            data-testid="player-stop"
            onClick={() => player.stop()}
          >
            <Icon name="close" size={18} />
          </button>
        ) : null}
      </div>
      {ps.status === "loading" ? (
        <p className="sr-only" data-testid="player-status">
          {t(locale, "audio.loading")}
        </p>
      ) : null}
      {ps.status === "error" && ps.error ? (
        <p className="alert alert-error rdp-error" role="alert" data-testid="player-error">
          {t(locale, ERROR_KEYS[ps.error])}
        </p>
      ) : null}
    </section>
  );
}
