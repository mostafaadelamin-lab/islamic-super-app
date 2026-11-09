import Link from "next/link";
import { t, type Locale } from "@/lib/i18n";
import { href } from "@/lib/locale-path";
import { resolveLocale, type LocaleParams } from "@/lib/page-locale";
import { NextPrayerCard } from "@/components/NextPrayerCard";
import { QuranRadio } from "@/components/QuranRadio";
import { SharePrompt } from "@/components/ShareApp";
import { Icon, type IconName } from "@/components/Icon";

interface HomeTile {
  path: string;
  title: string;
  icon: IconName;
}

/** Big tiles, then the wide pairs, as in the owner's mockup (2026-11-09). */
const BIG: readonly HomeTile[] = [
  { path: "quran", title: "home.big.quran", icon: "quran" },
  { path: "adhkar", title: "home.big.adhkar", icon: "dua" },
  { path: "prayer", title: "home.big.prayer", icon: "clock" },
];
const WIDE: readonly HomeTile[] = [
  { path: "tasbih", title: "home.big.tasbih", icon: "beads" },
  { path: "qibla", title: "home.big.qibla", icon: "kaaba" },
  { path: "reels", title: "home.big.reels", icon: "reels" },
  { path: "stories", title: "home.big.stories", icon: "headphones" },
];

function Tiles({ locale, list, kind }: { locale: Locale; list: readonly HomeTile[]; kind: string }) {
  return (
    <ul className={`home-tiles home-tiles-${kind}`}>
      {list.map((s) => (
        <li key={s.path}>
          <Link className={`home-tile home-tile-${kind}`} href={href(locale, s.path)} data-section={s.path}>
            <span className="home-tile-icon">
              <Icon name={s.icon} size={kind === "big" ? 40 : 30} />
            </span>
            <strong>{t(locale, s.title)}</strong>
          </Link>
        </li>
      ))}
    </ul>
  );
}

export default async function HomePage({ params }: { params: LocaleParams }) {
  const locale = await resolveLocale(params);
  return (
    <div className="home">
      <h1 className="sr-only">{t(locale, "home.title")}</h1>
      <div className="home-col">
        <NextPrayerCard locale={locale} />
      </div>
      <div className="home-col" data-testid="home-tiles">
        <Tiles locale={locale} list={BIG} kind="big" />
        <Tiles locale={locale} list={WIDE} kind="wide" />
        <QuranRadio locale={locale} />
        <Link className="card home-more" href={href(locale, "more")} data-testid="home-more">
          <Icon name="more" size={26} />
          <strong>{t(locale, "home.mainSections")}</strong>
          <span className="home-more-chevron">
            <Icon name="chevron" size={20} />
          </span>
        </Link>
        <SharePrompt locale={locale} />
      </div>
    </div>
  );
}
