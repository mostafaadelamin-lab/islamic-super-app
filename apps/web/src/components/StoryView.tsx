"use client";
import Link from "next/link";
import { useEffect, useRef, useState, useSyncExternalStore } from "react";
import { t, type Locale } from "@/lib/i18n";
import { href } from "@/lib/locale-path";
import { localizeDigits } from "@/lib/digits";
import { renderQuranText } from "@/lib/quran-render";
import { surahName } from "@/lib/pages";
import { player } from "@/lib/audio-player";
import { audioStore, RECITERS } from "@/lib/audio";
import type { Story } from "@/lib/stories";
import { useStore } from "@/hooks/useStore";
import { SleepTimer } from "./SleepTimer";
import { AyahMarker } from "./AyahMarker";
import { TafsirPanel } from "./TafsirPanel";
import { Icon } from "./Icon";

export interface StorySegmentText {
  surah: number;
  from: number;
  to: number;
  /** Canonical ayah texts from `from` to `to`. */
  ayahs: string[];
}

/** One Quranic story: its verses only (Mushaf text), recited in order, with Tafsir al-Muyassar per ayah. */
export function StoryView({
  locale,
  story,
  segments,
}: {
  locale: Locale;
  story: Story;
  segments: StorySegmentText[];
}) {
  const ps = useSyncExternalStore(player.subscribe, player.get, player.getServer);
  const prefs = useStore(audioStore);
  const [tafsirFor, setTafsirFor] = useState<string | null>(null);
  const listRef = useRef<HTMLDivElement>(null);

  const cur = ps.status === "idle" ? null : ps.queue[ps.cursor.index];
  const inStory = (s: number, a: number): boolean =>
    story.segments.some(([ss, f, to]) => ss === s && a >= f && a <= to);
  const currentKey = cur && cur.kind === "ayah" && inStory(cur.s, cur.a) ? `${cur.s}:${cur.a}` : null;

  // Keep the ayah being recited in view.
  useEffect(() => {
    if (!currentKey) return;
    listRef.current
      ?.querySelector<HTMLElement>(`[data-ref="${currentKey}"]`)
      ?.scrollIntoView?.({ behavior: "smooth", block: "center" });
  }, [currentKey]);

  return (
    <>
      <nav className="crumbs">
        <Link href={href(locale, "stories")}>{t(locale, "stories.back")}</Link>
      </nav>
      <header>
        <h1>{locale === "ar" ? story.title.ar : story.title.en}</h1>
        <p className="muted">
          {t(locale, `stories.cat.${story.category}`)} ·{" "}
          {t(locale, "stories.ayahs", { count: localizeDigits(story.ayahCount, locale) })}
        </p>
        <button
          type="button"
          className="btn btn-primary"
          data-testid="story-play"
          onClick={() => player.play({ kind: "ranges", ranges: story.segments })}
        >
          <Icon name="play" /> {t(locale, "stories.listen")}
        </button>
      </header>

      <div className="row story-controls">
        <label className="inline-field">
          <span>{t(locale, "stories.reciter")}</span>
          <select
            value={prefs.reciter}
            data-testid="story-reciter"
            onChange={(e) => {
              const reciter = e.target.value;
              audioStore.set((p) => ({ ...p, reciter }));
              player.reciterChanged();
            }}
          >
            {RECITERS.map((r) => (
              <option key={r.folder} value={r.folder}>
                {locale === "ar" ? r.ar : r.en}
              </option>
            ))}
          </select>
        </label>
        <SleepTimer locale={locale} />
      </div>
      <p className="muted small" data-testid="story-source">
        {t(locale, "stories.source")}
      </p>

      <div ref={listRef}>
        {segments.map((seg) => (
          <section key={`${seg.surah}:${seg.from}`} className="story-segment">
            <h2 className="section-title">
              {t(locale, "stories.from", {
                surah: surahName(seg.surah, locale),
                from: localizeDigits(seg.from, locale),
                to: localizeDigits(seg.to, locale),
              })}
            </h2>
            <div className="reader">
              {seg.ayahs.map((text, i) => {
                const a = seg.from + i;
                const key = `${seg.surah}:${a}`;
                const playing = key === currentKey;
                return (
                  <article
                    className="ayah"
                    key={key}
                    data-ref={key}
                    data-playing={playing ? "true" : undefined}
                    aria-current={playing ? "true" : undefined}
                  >
                    <p className="quran" lang="ar" dir="rtl" style={{ margin: 0 }}>
                      {renderQuranText(text)}
                      <AyahMarker n={a} locale={locale} />
                    </p>
                    <div className="ayah-tools">
                      <button
                        type="button"
                        className="btn btn-sm"
                        aria-expanded={tafsirFor === key}
                        data-testid={`story-tafsir-${key}`}
                        onClick={() => setTafsirFor((c) => (c === key ? null : key))}
                      >
                        {t(locale, "tafsir.show")}
                      </button>
                    </div>
                    {tafsirFor === key ? (
                      <TafsirPanel locale={locale} surah={seg.surah} ayah={a} showNav={false} />
                    ) : null}
                  </article>
                );
              })}
            </div>
          </section>
        ))}
      </div>
    </>
  );
}
