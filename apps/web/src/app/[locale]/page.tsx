import Link from "next/link";
import { t } from "@/lib/i18n";
import { href } from "@/lib/locale-path";
import { resolveLocale, type LocaleParams } from "@/lib/page-locale";
import { ContinueReading } from "@/components/ContinueReading";
import { NextPrayerCard } from "@/components/NextPrayerCard";

export default async function HomePage({ params }: { params: LocaleParams }) {
  const locale = await resolveLocale(params);
  const tiles = [
    { path: "quran", title: t(locale, "quran.surahs"), sub: t(locale, "nav.quran") },
    {
      path: "page/1",
      title: t(locale, "quran.pages"),
      sub: t(locale, "quran.page", { page: locale === "ar" ? "١" : 1 }),
    },
    { path: "search", title: t(locale, "quran.search"), sub: t(locale, "quran.searchHint") },
    { path: "prayer", title: t(locale, "prayer.title"), sub: t(locale, "prayer.qibla") },
    { path: "bookmarks", title: t(locale, "bookmarks.title"), sub: t(locale, "nav.bookmarks") },
    { path: "settings", title: t(locale, "settings.title"), sub: t(locale, "settings.theme") },
  ];
  return (
    <>
      <h1>{t(locale, "home.title")}</h1>
      <p className="muted">{t(locale, "tagline")}</p>
      <div className="two-col">
        <ContinueReading locale={locale} />
        <NextPrayerCard locale={locale} />
      </div>
      <h2>{t(locale, "home.quick")}</h2>
      <div className="grid">
        {tiles.map((tile) => (
          <Link key={tile.path} className="tile" href={href(locale, tile.path)}>
            <strong>{tile.title}</strong>
            <span className="muted">{tile.sub}</span>
          </Link>
        ))}
      </div>
    </>
  );
}
