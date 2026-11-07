"use client";
import { t, type Locale } from "@/lib/i18n";
import { localizeDigits } from "@/lib/digits";
import { resolveLocation } from "@/lib/cities";
import { qiblaBearing } from "@/lib/prayer";
import { prayerStore } from "@/lib/settings";
import { useStore } from "@/hooks/useStore";
import { LiveCompass } from "./LiveCompass";

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
      <LiveCompass locale={locale} bearing={bearing} />
      <p className="muted small">{t(locale, "qibla.note")}</p>
    </section>
  );
}
