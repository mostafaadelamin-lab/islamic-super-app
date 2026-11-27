"use client";
import { useState, useSyncExternalStore } from "react";
import { t, type Locale } from "@/lib/i18n";
import { localizeDigits } from "@/lib/digits";
import { renderQuranText } from "@/lib/quran-render";
import { surahName } from "@/lib/pages";
import { player } from "@/lib/audio-player";
import type { RuqyahItem } from "@/lib/kids";
import { AyahMarker } from "./AyahMarker";
import { Icon } from "./Icon";
import { AdhkarLookFrame, AdhkarSettingsButton, DhikrText } from "./AdhkarLook";
import { DhikrListen } from "./DhikrAudio";
import { DhikrOfflineCard } from "./DhikrOffline";

/** A Quran passage of the ruqyah with its canonical ayah texts (and the basmala before a whole surah). */
export interface RuqyahPassage {
  s: number;
  from: number;
  to: number;
  ayahs: string[];
  basmala?: string;
}

/** «الرقية الشرعية» / «الرقية الشرعية للأطفال»: the verses (Mushaf text, recited with the chosen reciter) and the duas. */
export function RuqyahView({
  locale,
  kids,
  items,
  passages,
  full,
}: {
  locale: Locale;
  kids: boolean;
  items: RuqyahItem[];
  passages: RuqyahPassage[];
  full?: { url: string; seconds?: number };
}) {
  const ps = useSyncExternalStore(player.subscribe, player.get, player.getServer);
  const cur = ps.status === "idle" ? null : ps.queue[ps.cursor.index];
  const playingKey = cur && cur.kind === "ayah" ? `${cur.s}:${cur.a}` : null;
  const n = (v: number): string => localizeDigits(v, locale);
  const ranges = passages.map((p) => [p.s, p.from, p.to] as const);
  let q = 0;
  return (
    <AdhkarLookFrame>
      <div data-testid={kids ? "ruqyah-kids" : "ruqyah"}>
        <p className="muted">{t(locale, kids ? "ruqyah.kidsNote" : "ruqyah.note")}</p>
        <p>
          <AdhkarSettingsButton locale={locale} view={false} />
        </p>
        <DhikrOfflineCard
          locale={locale}
          group={kids ? "ruqyah-kids" : "ruqyah"}
          urls={items.flatMap((it) => (it.t === "d" && it.audio ? [it.audio] : []))}
        />
        <p>
          <button
            type="button"
            className="btn btn-primary"
            data-testid="ruqyah-play"
            onClick={() => player.play({ kind: "ranges", ranges })}
          >
            <Icon name="play" /> {t(locale, "ruqyah.listenQuran")}
          </button>
        </p>
        {full ? (
          <figure className="card" data-testid="ruqyah-full">
            <figcaption>
              <strong>
                <Icon name="headphones" /> {t(locale, "ruqyah.full")}
              </strong>
              {full.seconds ? (
                <span className="muted small">
                  {" "}
                  · {t(locale, "ruqyah.fullSub", { n: n(Math.round(full.seconds / 60)) })}
                </span>
              ) : null}
            </figcaption>
            <audio controls preload="none" src={full.url} />
          </figure>
        ) : null}
        {items.map((item, i) => {
          if (item.t === "q") {
            const p = passages[q++];
            if (!p) return null;
            const title =
              p.from === p.to
                ? t(locale, "ruqyah.ayah", { surah: surahName(p.s, locale), n: n(p.from) })
                : t(locale, "ruqyah.from", { surah: surahName(p.s, locale), from: n(p.from), to: n(p.to) });
            return (
              <section key={i} className="card story-segment" data-testid={`ruqyah-item-${i}`}>
                <div className="row">
                  <h2 className="section-title" style={{ flex: 1 }}>
                    {title}
                  </h2>
                  <button
                    type="button"
                    className="btn btn-sm"
                    data-testid={`ruqyah-listen-${p.s}-${p.from}`}
                    onClick={() => player.play({ kind: "ranges", ranges: [[p.s, p.from, p.to]] })}
                  >
                    <Icon name="headphones" /> {t(locale, "ruqyah.listen")}
                  </button>
                </div>
                <div className="reader">
                  {p.basmala ? (
                    <p className="quran" lang="ar" dir="rtl" style={{ textAlign: "center", margin: 0 }}>
                      {renderQuranText(p.basmala)}
                    </p>
                  ) : null}
                  {/* One flowing Mushaf paragraph, ayah after ayah (owner 2026-11-20: not one ayah per row). */}
                  <p
                    className="quran ruqyah-flow"
                    lang="ar"
                    dir="rtl"
                    data-testid={`ruqyah-flow-${p.s}-${p.from}`}
                  >
                    {p.ayahs.map((text, k) => {
                      const a = p.from + k;
                      const key = `${p.s}:${a}`;
                      return (
                        <span
                          className="ruqyah-ayah"
                          key={key}
                          data-ref={key}
                          data-playing={key === playingKey ? "true" : undefined}
                        >
                          {renderQuranText(text)}
                          <AyahMarker n={a} locale={locale} />{" "}
                        </span>
                      );
                    })}
                  </p>
                </div>
              </section>
            );
          }
          return <DuaCard key={i} locale={locale} index={i} item={item} />;
        })}
      </div>
    </AdhkarLookFrame>
  );
}

/** A dua of the ruqyah; one said more than once gets the adhkar counter (owner 2026-11-20). */
function DuaCard({
  locale,
  index,
  item,
}: {
  locale: Locale;
  index: number;
  item: Extract<RuqyahItem, { t: "d" }>;
}) {
  const [count, setCount] = useState(0);
  const n = (v: number): string => localizeDigits(v, locale);
  const counted = item.repeat > 1;
  const done = counted && count >= item.repeat;
  return (
    <section className={done ? "card dhikr done" : "card"} data-testid={`ruqyah-item-${index}`}>
      <h2 className="section-title">{t(locale, "ruqyah.dua")}</h2>
      <DhikrText text={item.text} className="dua-text" />
      <p className="muted small">
        {item.src}
        {counted ? <strong> · {t(locale, "ruqyah.repeat", { n: n(item.repeat) })}</strong> : null}
      </p>
      {item.audio ? (
        <div className="dhikr-tools">
          <DhikrListen locale={locale} url={item.audio} testId={`ruqyah-${index}`} />
        </div>
      ) : null}
      {counted ? (
        <div className="dhikr-foot">
          <button
            type="button"
            className="btn btn-sm"
            disabled={count === 0}
            data-testid={`ruqyah-reset-${index}`}
            onClick={() => setCount(0)}
          >
            <Icon name="reset" size={16} /> {t(locale, "adhkar.reset")}
          </button>
          <button
            type="button"
            className={done ? "counter done" : "counter"}
            data-testid={`ruqyah-count-${index}`}
            disabled={done}
            onClick={() => setCount((c) => c + 1)}
          >
            {done ? <Icon name="check" size={18} /> : null}
            <span className="sr-only">
              {t(locale, "adhkar.countLabel", { i: n(1), n: n(count), total: n(item.repeat) })}
            </span>
            <span aria-hidden="true">
              {n(count)} / {n(item.repeat)}
            </span>
          </button>
        </div>
      ) : null}
    </section>
  );
}
