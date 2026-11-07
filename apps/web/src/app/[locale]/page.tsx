import { t } from "@/lib/i18n";
import { resolveLocale, type LocaleParams } from "@/lib/page-locale";
import { ContinueReading } from "@/components/ContinueReading";
import { NextPrayerCard } from "@/components/NextPrayerCard";
import { SectionTiles } from "@/components/SectionTiles";

const HOME_TILES = ["page/1", "quran", "adhkar", "hisn", "tasbih", "qibla", "hajj", "search"] as const;

export default async function HomePage({ params }: { params: LocaleParams }) {
  const locale = await resolveLocale(params);
  return (
    <>
      <h1 className="greeting">{t(locale, "home.title")}</h1>
      <div className="home-grid">
        <NextPrayerCard locale={locale} />
        <ContinueReading locale={locale} />
      </div>
      <h2 className="section-title">{t(locale, "home.quick")}</h2>
      <SectionTiles locale={locale} paths={HOME_TILES} />
    </>
  );
}
