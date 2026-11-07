import Link from "next/link";
import { t, type Locale } from "@/lib/i18n";
import { href } from "@/lib/locale-path";
import { Icon, type IconName } from "./Icon";

export interface Section {
  path: string;
  title: string;
  sub: string;
  icon: IconName;
}

/** Every section of the app, in the order shown on the home screen and the "More" page. */
export const SECTIONS: readonly Section[] = [
  { path: "page/1", title: "home.tile.mushaf", sub: "home.tile.mushafSub", icon: "quran" },
  { path: "quran", title: "quran.surahs", sub: "home.tile.surahsSub", icon: "book" },
  { path: "adhkar", title: "adhkar.title", sub: "home.tile.adhkarSub", icon: "sun" },
  { path: "hisn", title: "hisn.title", sub: "home.tile.hisnSub", icon: "book" },
  { path: "tasbih", title: "tasbih.title", sub: "home.tile.tasbihSub", icon: "beads" },
  { path: "qibla", title: "qibla.title", sub: "home.tile.qiblaSub", icon: "compass" },
  { path: "hajj", title: "hajj.title", sub: "home.tile.hajjSub", icon: "kaaba" },
  { path: "prayer", title: "prayer.title", sub: "home.tile.prayerSub", icon: "prayer" },
  { path: "search", title: "quran.search", sub: "quran.searchHint", icon: "search" },
  { path: "bookmarks", title: "bookmarks.title", sub: "home.tile.bookmarksSub", icon: "bookmark" },
  { path: "settings", title: "settings.title", sub: "home.tile.settingsSub", icon: "settings" },
  { path: "about", title: "about.title", sub: "home.tile.aboutSub", icon: "info" },
];

export function SectionTiles({ locale, paths }: { locale: Locale; paths?: readonly string[] }) {
  const list = paths ? SECTIONS.filter((s) => paths.includes(s.path)) : SECTIONS;
  return (
    <ul className="tiles" data-testid="section-tiles">
      {list.map((s) => (
        <li key={s.path}>
          <Link className="tile" href={href(locale, s.path)} data-section={s.path}>
            <span className="tile-icon">
              <Icon name={s.icon} />
            </span>
            <span className="tile-text">
              <strong>{t(locale, s.title)}</strong>
              <span className="muted small">{t(locale, s.sub)}</span>
            </span>
          </Link>
        </li>
      ))}
    </ul>
  );
}
