"use client";
import { useState } from "react";
import { t, type Locale } from "@/lib/i18n";
import { href } from "@/lib/locale-path";
import { withBase } from "@/lib/base-path";
import { HARAM_CROWD_LINKS, SHOW_HARAM_CROWD } from "@/lib/haram-crowd";
import { LIVE_RADIOS } from "@/lib/live-radios";
import { Icon } from "./Icon";
import { NowPlaying, PlayerSlot, type Track } from "./RecitationLibrary";

const HARAMAIN = LIVE_RADIOS.filter((r) => r.id === "makkah" || r.id === "madinah");

/**
 * Top of the Hajj & Umrah section: crowd levels from the official source (a link, never our own numbers),
 * live sound from the Two Holy Mosques, and shortcuts into the guide.
 */
export function HajjServices({ locale, tawafHref }: { locale: Locale; tawafHref: string | null }) {
  const [track, setTrack] = useState<Track | null>(null);
  const [slot, setSlot] = useState<HTMLElement | null>(null);
  return (
    <section aria-labelledby="hajj-services-h" data-testid="hajj-services">
      <h2 id="hajj-services-h" className="sr-only">
        {t(locale, "hajj.services.title")}
      </h2>
      {SHOW_HARAM_CROWD ? (
        <section className="card hajj-crowd" id="crowd" data-testid="hajj-crowd">
          <h3>
            <Icon name="kaaba" /> {t(locale, "hajj.crowd.title")}
          </h3>
          <p>{t(locale, "hajj.crowd.body")}</p>
          <p className="row">
            <a
              className="btn btn-primary"
              href={HARAM_CROWD_LINKS.official}
              target="_blank"
              rel="noopener noreferrer"
              data-testid="hajj-crowd-official"
            >
              {t(locale, "hajj.crowd.official")} <Icon name="external" size={18} />
            </a>
            <a
              className="btn"
              href={HARAM_CROWD_LINKS.nusuk}
              target="_blank"
              rel="noopener noreferrer"
              data-testid="hajj-crowd-nusuk"
            >
              {t(locale, "hajj.crowd.nusuk")} <Icon name="external" size={18} />
            </a>
          </p>
          <p className="muted small">{t(locale, "hajj.crowd.note")}</p>
        </section>
      ) : null}
      <section className="card" id="live" data-testid="hajj-live">
        <h3>{t(locale, "hajj.live.title")}</h3>
        <ul className="episode-list">
          {HARAMAIN.map((r) => {
            const key = `live:${r.id}`;
            const title = locale === "ar" ? r.ar : r.en;
            return (
              <li key={r.id} className={track?.key === key ? "has-player" : undefined}>
                <button
                  type="button"
                  className="episode"
                  aria-pressed={track?.key === key}
                  onClick={() => setTrack({ key, url: r.url, live: true, title })}
                  data-testid={`hajj-live-${r.id}`}
                >
                  <Icon name={track?.key === key ? "pause" : "play"} />
                  <span className="tile-text">
                    <strong>{title}</strong>
                    <span className="muted small">{t(locale, "library.live")}</span>
                  </span>
                </button>
                {track?.key === key ? <PlayerSlot onSlot={setSlot} /> : null}
              </li>
            );
          })}
        </ul>
        {track ? (
          <NowPlaying
            locale={locale}
            track={track}
            onTrack={setTrack}
            onClose={() => setTrack(null)}
            slot={slot}
          />
        ) : null}
      </section>
      <ul className="tiles" data-testid="hajj-links">
        {(
          [
            // Umrah and the kinds of Hajj have their own pages, linked above (owner 2026-11-15).
            ...(tawafHref ? ([[tawafHref, "hajj.links.tawaf", "refresh"]] as const) : []),
          ] as const
        ).map(([to, key, icon]) => (
          <li key={to}>
            <a className="tile tile-sm" href={to}>
              <span className="tile-icon">
                <Icon name={icon} />
              </span>
              <span className="tile-text">
                <strong>{t(locale, key)}</strong>
              </span>
            </a>
          </li>
        ))}
        <li>
          {/* A full page load, so Hisn al-Muslim reads the #section on arrival. */}
          <a className="tile tile-sm" href={withBase(`${href(locale, "hisn")}#hajj`)}>
            <span className="tile-icon">
              <Icon name="dua" />
            </span>
            <span className="tile-text">
              <strong>{t(locale, "hajj.links.adhkar")}</strong>
            </span>
          </a>
        </li>
      </ul>
    </section>
  );
}
