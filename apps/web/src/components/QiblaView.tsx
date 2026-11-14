"use client";
import { t, type Locale } from "@/lib/i18n";
import { localizeDigits } from "@/lib/digits";
import { resolveLocation } from "@/lib/cities";
import { qiblaBearing } from "@/lib/prayer";
import { prayerStore } from "@/lib/settings";
import { useStore } from "@/hooks/useStore";
import { distanceM } from "@/lib/mosques";
import { LiveCompass } from "./LiveCompass";
import { Icon } from "./Icon";

/** The Kaaba, Makkah (for the distance, as in the app). */
const KAABA = { lat: 21.4225, lng: 39.8262 };

export function QiblaView({ locale }: { locale: Locale }) {
  const prefs = useStore(prayerStore);
  const loc = resolveLocation(prefs);
  const bearing = qiblaBearing(loc.lat, loc.lng);
  const cityName = locale === "ar" ? loc.city?.nameAr : loc.city?.nameEn;
  return (
    <section className="card qibla" aria-labelledby="qibla-h">
      <h2 id="qibla-h" className="card-title">
        {cityName ?? t(locale, "home.myPlace")}
      </h2>
      <p className="countdown" data-testid="qibla-bearing">
        {t(locale, "prayer.qiblaDeg", { deg: localizeDigits(bearing.toFixed(1), locale) })}
      </p>
      <LiveCompass locale={locale} bearing={bearing} lat={loc.lat} lng={loc.lng} />
      <p className="row qibla-facts">
        <span className="chip" data-testid="qibla-distance">
          {t(locale, "qibla.distance")}:{" "}
          {t(locale, "mosques.km", {
            n: localizeDigits(Math.round(distanceM(loc.lat, loc.lng, KAABA.lat, KAABA.lng) / 1000), locale),
          })}
        </span>
      </p>
      <p className="muted small">{t(locale, "qibla.placeNote")}</p>
      <h3 className="qibla-tips-h">{t(locale, "qibla.tipsTitle")}</h3>
      <p className="muted small">{t(locale, "qibla.note")}</p>
      <p>
        <a
          className="btn btn-sm"
          href="https://qiblafinder.withgoogle.com/"
          target="_blank"
          rel="noopener noreferrer"
          data-testid="qibla-map-check"
        >
          <Icon name="external" size={16} /> {t(locale, "qibla.mapCheck")}
        </a>
      </p>
    </section>
  );
}
